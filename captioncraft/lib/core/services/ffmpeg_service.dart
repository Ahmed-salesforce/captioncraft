import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class FFmpegService {
  /// Extracts audio from [videoPath] as 16 kHz mono WAV.
  /// Returns the path to the temporary WAV file.
  /// On web, returns an empty string (FFmpeg unavailable).
  Future<String> extractAudio(String videoPath) async {
    if (kIsWeb) return '';

    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/captioncraft_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

    final session = await FFmpegKit.execute(
      '-i "$videoPath" -vn -acodec pcm_s16le -ar 16000 -ac 1 -y "$outputPath"',
    );

    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw FFmpegException(
        'Audio extraction failed (code ${returnCode?.getValue()})',
        logs ?? '',
      );
    }

    return outputPath;
  }

  /// Deletes a temporary file if it exists.
  Future<void> cleanUp(String path) async {
    if (kIsWeb || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class FFmpegException implements Exception {
  final String message;
  final String logs;

  const FFmpegException(this.message, this.logs);

  @override
  String toString() => 'FFmpegException: $message';
}
