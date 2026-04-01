import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'ffmpeg_service.dart';
import 'whisper_binding.dart' if (dart.library.html) 'whisper_binding_stub.dart';

class RawSegment {
  final int startMs;
  final int endMs;
  final String text;

  const RawSegment({
    required this.startMs,
    required this.endMs,
    required this.text,
  });
}

class TranscriptionService {
  final FFmpegService _ffmpeg = FFmpegService();

  Future<List<RawSegment>> transcribe(
    String videoPath, {
    required void Function(double progress) onProgress,
  }) async {
    if (kIsWeb) {
      return _runMocked(onProgress);
    }

    onProgress(0.05);
    String wavPath = '';
    try {
      wavPath = await _ffmpeg.extractAudio(videoPath);
      onProgress(0.10);

      final modelPath = await _ensureModelCopied();
      onProgress(0.12);

      final segments = await runWhisperInIsolate(
        modelPath,
        wavPath,
        onProgress,
      );

      onProgress(0.95);
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress(1.0);
      return segments;
    } finally {
      await _ffmpeg.cleanUp(wavPath);
    }
  }

  Future<String> _ensureModelCopied() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${docsDir.path}/ggml-tiny.bin');
    if (await modelFile.exists()) return modelFile.path;

    final data = await rootBundle.load('assets/models/ggml-tiny.bin');
    await modelFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return modelFile.path;
  }

  /// Parse a 16-bit PCM WAV file into Float32List (normalized to -1..1).
  static Float32List loadWavSamples(String wavPath) {
    final file = File(wavPath);
    final bytes = file.readAsBytesSync();
    final data = ByteData.sublistView(Uint8List.fromList(bytes));

    var offset = 12;
    while (offset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      if (chunkId == 'data') {
        offset += 8;
        final numSamples = chunkSize ~/ 2;
        final samples = Float32List(numSamples);
        for (var i = 0; i < numSamples; i++) {
          final sample = data.getInt16(offset + i * 2, Endian.little);
          samples[i] = sample / 32768.0;
        }
        return samples;
      }
      offset += 8 + chunkSize;
    }
    throw Exception('WAV data chunk not found');
  }

  Future<List<RawSegment>> _runMocked(
    void Function(double progress) onProgress,
  ) async {
    onProgress(0.15);
    await Future.delayed(const Duration(milliseconds: 600));
    onProgress(0.30);
    await Future.delayed(const Duration(milliseconds: 500));
    onProgress(0.50);
    await Future.delayed(const Duration(milliseconds: 500));
    onProgress(0.70);
    await Future.delayed(const Duration(milliseconds: 400));
    onProgress(0.85);
    await Future.delayed(const Duration(milliseconds: 300));
    onProgress(0.95);
    await Future.delayed(const Duration(milliseconds: 200));
    onProgress(1.0);

    return const [
      RawSegment(startMs: 500, endMs: 3200, text: 'Welcome to this video where we explore something amazing'),
      RawSegment(startMs: 3400, endMs: 6100, text: 'Today I want to show you how this works in practice'),
      RawSegment(startMs: 6300, endMs: 8800, text: 'First let us start with the basics'),
      RawSegment(startMs: 9000, endMs: 12500, text: 'This is a really important concept that you need to understand clearly'),
      RawSegment(startMs: 12800, endMs: 15200, text: 'Once you get it everything else becomes much easier'),
      RawSegment(startMs: 15500, endMs: 18000, text: 'So pay attention to the next part'),
      RawSegment(startMs: 18200, endMs: 21000, text: 'Here we can see the result of our work'),
      RawSegment(startMs: 21200, endMs: 24500, text: 'And that is basically how you do it from start to finish'),
      RawSegment(startMs: 24800, endMs: 27000, text: 'Thanks for watching and see you next time'),
    ];
  }
}
