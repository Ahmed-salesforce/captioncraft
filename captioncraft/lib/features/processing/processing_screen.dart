import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/project_provider.dart';
import '../../core/services/ffmpeg_service.dart';
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

      if (captions.isEmpty) {
        if (!mounted) return;
        final proceed = await _showZeroSegmentsDialog();
        if (!proceed || !mounted) return;
        await _createEmptyProjectAndNavigate();
        return;
      }

      final durationMs = captions.last.endMs + 500;

      final notifier = ref.read(projectListProvider.notifier);
      final projectId = await notifier.createProject(
        videoPath: widget.videoPath,
        durationMs: durationMs,
      );

      final service = ref.read(projectServiceProvider);
      final project = await service.loadProject(projectId);
      if (project != null) {
        await service.saveProject(project.copyWith(captions: captions));
      }

      if (!mounted) return;
      context.go('/editor/$projectId');
    } on FFmpegException catch (e) {
      if (_cancelled || !mounted) return;
      final isNoAudio = e.message.contains('Audio extraction failed');
      if (isNoAudio) {
        final proceed = await _showNoAudioDialog();
        if (proceed && mounted) {
          await _createEmptyProjectAndNavigate();
        }
      } else {
        setState(() => _error = e.toString());
      }
    } catch (e) {
      if (_cancelled || !mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _createEmptyProjectAndNavigate() async {
    final notifier = ref.read(projectListProvider.notifier);
    final projectId = await notifier.createProject(
      videoPath: widget.videoPath,
      durationMs: 30000,
    );
    if (!mounted) return;
    context.go('/editor/$projectId');
  }

  Future<bool> _showNoAudioDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('No audio track found', style: AppTypography.title),
        content: Text(
          'This video has no audio to transcribe.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go Back', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add captions manually', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (result == false && mounted) context.go('/');
    return result ?? false;
  }

  Future<bool> _showZeroSegmentsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text("Couldn't detect speech", style: AppTypography.title),
        content: Text(
          'No speech was found in the audio.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go Back', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue with empty captions', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (result == false && mounted) context.go('/');
    return result ?? false;
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
