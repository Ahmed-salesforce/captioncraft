import 'package:flutter/foundation.dart' show kIsWeb;

import 'ffmpeg_service.dart';

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

  /// Transcribes audio from [videoPath] and returns raw segments.
  ///
  /// On mobile: extracts audio via FFmpeg, then runs mocked Whisper.
  /// On web: returns sample segments directly.
  ///
  /// [onProgress] reports 0.0–1.0 at each pipeline milestone.
  Future<List<RawSegment>> transcribe(
    String videoPath, {
    required void Function(double progress) onProgress,
  }) async {
    if (kIsWeb) {
      return _runMocked(onProgress);
    }

    // Step 1: Extract audio
    onProgress(0.05);
    String wavPath = '';
    try {
      wavPath = await _ffmpeg.extractAudio(videoPath);
      onProgress(0.10);

      // TODO: Real whisper.cpp FFI — load model, run inference on wavPath
      // For now, use mocked transcription output.
      final segments = await _runMocked(onProgress);

      return segments;
    } finally {
      await _ffmpeg.cleanUp(wavPath);
    }
  }

  /// Mocked transcription that simulates Whisper output with sample segments.
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
