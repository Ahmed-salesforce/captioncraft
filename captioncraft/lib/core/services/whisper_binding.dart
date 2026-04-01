import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'transcription_service.dart';

// ---------------------------------------------------------------------------
// FFI typedefs
// ---------------------------------------------------------------------------

typedef WhisperInitFromFileNative = Pointer<Void> Function(Pointer<Utf8>);
typedef WhisperInitFromFileDart = Pointer<Void> Function(Pointer<Utf8>);

typedef WhisperFullDefaultParamsNative = Pointer<Void> Function(Int32);
typedef WhisperFullDefaultParamsDart = Pointer<Void> Function(int);

typedef WhisperFullNative = Int32 Function(
    Pointer<Void>, Pointer<Void>, Pointer<Float>, Int32);
typedef WhisperFullDart = int Function(
    Pointer<Void>, Pointer<Void>, Pointer<Float>, int);

typedef WhisperFullNSegmentsNative = Int32 Function(Pointer<Void>);
typedef WhisperFullNSegmentsDart = int Function(Pointer<Void>);

typedef WhisperFullGetSegmentTextNative = Pointer<Utf8> Function(
    Pointer<Void>, Int32);
typedef WhisperFullGetSegmentTextDart = Pointer<Utf8> Function(
    Pointer<Void>, int);

typedef WhisperFullGetSegmentT0Native = Int64 Function(Pointer<Void>, Int32);
typedef WhisperFullGetSegmentT0Dart = int Function(Pointer<Void>, int);

typedef WhisperFullGetSegmentT1Native = Int64 Function(Pointer<Void>, Int32);
typedef WhisperFullGetSegmentT1Dart = int Function(Pointer<Void>, int);

typedef WhisperFreeNative = Void Function(Pointer<Void>);
typedef WhisperFreeDart = void Function(Pointer<Void>);

// ---------------------------------------------------------------------------
// Binding class
// ---------------------------------------------------------------------------

class WhisperBinding {
  late final WhisperInitFromFileDart whisperInitFromFile;
  late final WhisperFullDefaultParamsDart whisperFullDefaultParams;
  late final WhisperFullDart whisperFull;
  late final WhisperFullNSegmentsDart whisperFullNSegments;
  late final WhisperFullGetSegmentTextDart whisperFullGetSegmentText;
  late final WhisperFullGetSegmentT0Dart whisperFullGetSegmentT0;
  late final WhisperFullGetSegmentT1Dart whisperFullGetSegmentT1;
  late final WhisperFreeDart whisperFree;

  WhisperBinding() {
    final lib = Platform.isAndroid
        ? DynamicLibrary.open('libwhisper.so')
        : DynamicLibrary.process();

    whisperInitFromFile = lib
        .lookupFunction<WhisperInitFromFileNative, WhisperInitFromFileDart>(
            'whisper_init_from_file');
    whisperFullDefaultParams = lib.lookupFunction<
        WhisperFullDefaultParamsNative,
        WhisperFullDefaultParamsDart>('whisper_full_default_params');
    whisperFull = lib
        .lookupFunction<WhisperFullNative, WhisperFullDart>('whisper_full');
    whisperFullNSegments = lib.lookupFunction<WhisperFullNSegmentsNative,
        WhisperFullNSegmentsDart>('whisper_full_n_segments');
    whisperFullGetSegmentText = lib.lookupFunction<
        WhisperFullGetSegmentTextNative,
        WhisperFullGetSegmentTextDart>('whisper_full_get_segment_text');
    whisperFullGetSegmentT0 = lib.lookupFunction<
        WhisperFullGetSegmentT0Native,
        WhisperFullGetSegmentT0Dart>('whisper_full_get_segment_t0');
    whisperFullGetSegmentT1 = lib.lookupFunction<
        WhisperFullGetSegmentT1Native,
        WhisperFullGetSegmentT1Dart>('whisper_full_get_segment_t1');
    whisperFree = lib
        .lookupFunction<WhisperFreeNative, WhisperFreeDart>('whisper_free');
  }
}

// ---------------------------------------------------------------------------
// Isolate entry & runner
// ---------------------------------------------------------------------------

class _WhisperRequest {
  final String modelPath;
  final String wavPath;
  final SendPort sendPort;
  _WhisperRequest(this.modelPath, this.wavPath, this.sendPort);
}

class _WhisperResult {
  final List<RawSegment>? segments;
  final String? error;
  _WhisperResult.success(this.segments) : error = null;
  _WhisperResult.failure(this.error) : segments = null;
}

Future<List<RawSegment>> runWhisperInIsolate(
  String modelPath,
  String wavPath,
  void Function(double) onProgress,
) async {
  final receivePort = ReceivePort();
  final request = _WhisperRequest(modelPath, wavPath, receivePort.sendPort);

  await Isolate.spawn(_whisperIsolateEntry, request);
  onProgress(0.15);

  final result = await receivePort.first as _WhisperResult;
  onProgress(0.90);

  if (result.error != null) {
    throw Exception('Whisper transcription failed: ${result.error}');
  }
  return result.segments ?? [];
}

void _whisperIsolateEntry(_WhisperRequest request) {
  try {
    final binding = WhisperBinding();

    final modelPathNative = request.modelPath.toNativeUtf8();
    final ctx = binding.whisperInitFromFile(modelPathNative);
    calloc.free(modelPathNative);

    if (ctx == nullptr) {
      request.sendPort
          .send(_WhisperResult.failure('Failed to load Whisper model'));
      return;
    }

    final samples = TranscriptionService.loadWavSamples(request.wavPath);
    final params = binding.whisperFullDefaultParams(0);

    final nativeSamples = calloc<Float>(samples.length);
    for (var i = 0; i < samples.length; i++) {
      nativeSamples[i] = samples[i];
    }

    final ret =
        binding.whisperFull(ctx, params, nativeSamples, samples.length);
    calloc.free(nativeSamples);

    if (ret != 0) {
      binding.whisperFree(ctx);
      request.sendPort
          .send(_WhisperResult.failure('whisper_full returned $ret'));
      return;
    }

    final nSegments = binding.whisperFullNSegments(ctx);
    final segments = <RawSegment>[];
    for (var i = 0; i < nSegments; i++) {
      final textPtr = binding.whisperFullGetSegmentText(ctx, i);
      final text = textPtr.toDartString().trim();
      final t0 = binding.whisperFullGetSegmentT0(ctx, i) * 10;
      final t1 = binding.whisperFullGetSegmentT1(ctx, i) * 10;
      if (text.isNotEmpty) {
        segments.add(RawSegment(startMs: t0, endMs: t1, text: text));
      }
    }

    binding.whisperFree(ctx);
    request.sendPort.send(_WhisperResult.success(segments));
  } catch (e) {
    request.sendPort.send(_WhisperResult.failure(e.toString()));
  }
}
