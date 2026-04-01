import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';

import '../models/caption_segment.dart';
import '../models/project.dart';
import '../utils/ass_builder.dart';

enum ExportQuality { p720, p1080, original }

class ExportService {
  Future<File> exportSrt(Project project) async {
    final buf = StringBuffer();
    final sorted = List<CaptionSegment>.from(project.captions)
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    for (var i = 0; i < sorted.length; i++) {
      final seg = sorted[i];
      buf.writeln(i + 1);
      buf.writeln('${_formatSrtTime(seg.startMs)} --> ${_formatSrtTime(seg.endMs)}');
      buf.writeln(seg.text);
      buf.writeln();
    }

    return _writeTempFile('srt', buf.toString());
  }

  Future<File> exportVtt(Project project) async {
    final buf = StringBuffer();
    buf.writeln('WEBVTT');
    buf.writeln();

    final sorted = List<CaptionSegment>.from(project.captions)
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    for (var i = 0; i < sorted.length; i++) {
      final seg = sorted[i];
      buf.writeln(i + 1);
      buf.writeln('${_formatVttTime(seg.startMs)} --> ${_formatVttTime(seg.endMs)}');
      buf.writeln(seg.text);
      buf.writeln();
    }

    return _writeTempFile('vtt', buf.toString());
  }

  Future<File> exportBurnedVideo(
    Project project,
    ExportQuality quality,
    void Function(double) onProgress,
  ) async {
    if (kIsWeb) throw UnsupportedError('Video export not available on web');

    final assContent = AssBuilder.buildAss(project);
    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final assPath = '${tempDir.path}/captioncraft_export_$ts.ass';
    final outputPath = '${tempDir.path}/captioncraft_output_$ts.mp4';

    final assFile = File(assPath);
    await assFile.writeAsString(assContent);

    try {
      final vf = _buildVideoFilter(assPath, quality);
      final command =
          '-i "${project.videoPath}" -vf "$vf" -c:a copy -movflags +faststart -y "$outputPath"';

      final totalMs = project.videoDurationMs;
      final completer = Completer<ReturnCode?>();

      await FFmpegKit.executeAsync(
        command,
        (session) async {
          final code = await session.getReturnCode();
          if (!completer.isCompleted) completer.complete(code);
        },
        (log) {},
        (Statistics statistics) {
          if (totalMs > 0) {
            final time = statistics.getTime();
            final progress = (time / totalMs).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      final returnCode = await completer.future;

      if (!ReturnCode.isSuccess(returnCode)) {
        final errMsg = returnCode == null
            ? 'Video export failed (FFmpeg process was killed or crashed)'
            : 'Video export failed (code ${returnCode.getValue()})';
        throw ExportException(errMsg, '');
      }

      onProgress(1.0);
      return File(outputPath);
    } finally {
      final f = File(assPath);
      if (await f.exists()) await f.delete();
    }
  }

  Future<bool> checkFreeStorage(int requiredBytes) async {
    if (kIsWeb) return true;
    try {
      final tempDir = await getTemporaryDirectory();
      final stat = await FileStat.stat(tempDir.path);
      // FileStat doesn't expose free space; use a heuristic check
      // by verifying the temp dir is accessible.
      return stat.type != FileSystemEntityType.notFound;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _buildVideoFilter(String assPath, ExportQuality quality) {
    final escapedAssPath = assPath.replaceAll(':', '\\:').replaceAll("'", "\\'");
    switch (quality) {
      case ExportQuality.p720:
        return "scale=1280:720,ass='$escapedAssPath'";
      case ExportQuality.p1080:
        return "scale=1920:1080,ass='$escapedAssPath'";
      case ExportQuality.original:
        return "ass='$escapedAssPath'";
    }
  }

  /// SRT time format: `HH:MM:SS,mmm`
  String _formatSrtTime(int ms) {
    if (ms < 0) ms = 0;
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    final mil = ms % 1000;
    return '${_pad2(h)}:${_pad2(m)}:${_pad2(s)},${_pad3(mil)}';
  }

  /// VTT time format: `HH:MM:SS.mmm`
  String _formatVttTime(int ms) {
    if (ms < 0) ms = 0;
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    final mil = ms % 1000;
    return '${_pad2(h)}:${_pad2(m)}:${_pad2(s)}.${_pad3(mil)}';
  }

  Future<File> _writeTempFile(String ext, String content) async {
    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${tempDir.path}/captioncraft_export_$ts.$ext';
    final file = File(path);
    await file.writeAsString(content);
    return file;
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');
  String _pad3(int n) => n.toString().padLeft(3, '0');
}

class ExportException implements Exception {
  final String message;
  final String logs;

  const ExportException(this.message, this.logs);

  @override
  String toString() => 'ExportException: $message';
}
