import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/project_provider.dart';
import '../../core/services/transcription_service.dart';
import '../../core/utils/segment_grouper.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final String videoPath;

  const ProcessingScreen({super.key, required this.videoPath});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  final TranscriptionService _transcription = TranscriptionService();
  double _progress = 0.0;
  bool _cancelled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startPipeline();
  }

  Future<void> _startPipeline() async {
    try {
      final rawSegments = await _transcription.transcribe(
        widget.videoPath,
        onProgress: (p) {
          if (!_cancelled && mounted) setState(() => _progress = p);
        },
      );

      if (_cancelled || !mounted) return;

      final captions = groupSegments(rawSegments);

      // Estimate duration from last caption end or default to 30s
      final durationMs = captions.isNotEmpty
          ? captions.last.endMs + 500
          : 30000;

      final notifier = ref.read(projectListProvider.notifier);
      final projectId = await notifier.createProject(
        videoPath: widget.videoPath,
        durationMs: durationMs,
      );

      // Save captions to the project
      final service = ref.read(projectServiceProvider);
      final project = await service.loadProject(projectId);
      if (project != null) {
        await service.saveProject(project.copyWith(captions: captions));
      }

      if (!mounted) return;
      context.go('/editor/$projectId');
    } catch (e) {
      if (_cancelled || !mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _cancel() {
    _cancelled = true;
    if (mounted) context.go('/');
  }

  String get _statusMessage {
    if (_progress < 0.10) return 'Preparing audio…';
    if (_progress < 0.70) return 'Transcribing… this may take a minute';
    if (_progress < 0.90) return 'Processing segments…';
    return 'Almost done…';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Processing')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 24),
                Text('Something went wrong', style: AppTypography.title),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.accent,
              ),
              const SizedBox(height: 8),
              Text(
                'CaptionCraft',
                style: AppTypography.display.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 32),
              Text(_statusMessage, style: AppTypography.title),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surface3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${(_progress * 100).toInt()}%',
                style: AppTypography.mono,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: _cancel,
                child: Text(
                  'Cancel',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
