import 'transcription_service.dart';

/// Stub for web — Whisper FFI is not available on web.
Future<List<RawSegment>> runWhisperInIsolate(
  String modelPath,
  String wavPath,
  void Function(double) onProgress,
) async {
  throw UnsupportedError('Whisper FFI is not available on web');
}
