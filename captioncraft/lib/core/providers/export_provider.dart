import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../services/export_service.dart';

enum ExportStatus { idle, exporting, done, error }

class ExportState {
  final ExportStatus status;
  final double progress;
  final String? outputPath;
  final String? errorMessage;

  const ExportState({
    this.status = ExportStatus.idle,
    this.progress = 0.0,
    this.outputPath,
    this.errorMessage,
  });

  ExportState copyWith({
    ExportStatus? status,
    double? progress,
    String? outputPath,
    String? errorMessage,
  }) {
    return ExportState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ExportNotifier extends StateNotifier<ExportState> {
  final ExportService _service;

  ExportNotifier(this._service) : super(const ExportState());

  Future<void> exportSrt(Project project) async {
    state = const ExportState(status: ExportStatus.exporting, progress: 0.5);
    try {
      final file = await _service.exportSrt(project);
      state = ExportState(
        status: ExportStatus.done,
        progress: 1.0,
        outputPath: file.path,
      );
    } catch (e) {
      state = ExportState(
        status: ExportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> exportVtt(Project project) async {
    state = const ExportState(status: ExportStatus.exporting, progress: 0.5);
    try {
      final file = await _service.exportVtt(project);
      state = ExportState(
        status: ExportStatus.done,
        progress: 1.0,
        outputPath: file.path,
      );
    } catch (e) {
      state = ExportState(
        status: ExportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> exportBurnedVideo(
    Project project,
    ExportQuality quality,
  ) async {
    state = const ExportState(status: ExportStatus.exporting);
    try {
      final file = await _service.exportBurnedVideo(
        project,
        quality,
        (progress) {
          if (mounted) {
            state = state.copyWith(progress: progress);
          }
        },
      );
      state = ExportState(
        status: ExportStatus.done,
        progress: 1.0,
        outputPath: file.path,
      );
    } catch (e) {
      String message = e.toString();
      if (e is ExportException) {
        message = e.message;
        if (e.logs.isNotEmpty) {
          final preview =
              e.logs.length > 200 ? e.logs.substring(0, 200) : e.logs;
          message = '$message\n$preview';
        }
      }
      state = ExportState(
        status: ExportStatus.error,
        errorMessage: message,
      );
    }
  }

  void reset() {
    state = const ExportState();
  }
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  final service = ref.watch(exportServiceProvider);
  return ExportNotifier(service);
});
