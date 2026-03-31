import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/project.dart';
import '../../core/providers/export_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/services/export_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/cc_button.dart';

enum _ExportFormat { srt, vtt, video }

class ExportSheet extends ConsumerStatefulWidget {
  const ExportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ExportSheet(),
    );
  }

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  _ExportFormat _format = _ExportFormat.video;
  ExportQuality _quality = ExportQuality.p1080;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exportProvider.notifier).reset();
    });
  }

  void _startExport() {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;

    final notifier = ref.read(exportProvider.notifier);
    switch (_format) {
      case _ExportFormat.srt:
        notifier.exportSrt(project);
      case _ExportFormat.vtt:
        notifier.exportVtt(project);
      case _ExportFormat.video:
        notifier.exportBurnedVideo(project, _quality);
    }
  }

  void _share(String path) {
    Share.shareXFiles([XFile(path)]);
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);
    final project = ref.watch(currentProjectProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Export', style: AppTypography.title),
          const SizedBox(height: 16),
          if (project != null && project.hasOverlaps)
            _buildOverlapWarning(),
          _buildBody(exportState, project),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildOverlapWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x33FFDD57),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some captions overlap. Fix before exporting.',
              style: AppTypography.caption.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ExportState exportState, Project? project) {
    switch (exportState.status) {
      case ExportStatus.idle:
        return _buildIdleState();
      case ExportStatus.exporting:
        return _buildExportingState(exportState);
      case ExportStatus.done:
        return _buildDoneState(exportState);
      case ExportStatus.error:
        return _buildErrorState(exportState);
    }
  }

  Widget _buildIdleState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Format', style: AppTypography.label),
          const SizedBox(height: 8),
          _buildFormatSelector(),
          if (_format == _ExportFormat.video) ...[
            const SizedBox(height: 16),
            Text('Quality', style: AppTypography.label),
            const SizedBox(height: 8),
            _buildQualityChips(),
          ],
          const SizedBox(height: 24),
          CCButton(
            label: 'Export',
            icon: Icons.ios_share,
            onPressed: _startExport,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _formatChip('SRT', _ExportFormat.srt),
          _formatChip('VTT', _ExportFormat.vtt),
          _formatChip('Video (MP4)', _ExportFormat.video),
        ],
      ),
    );
  }

  Widget _formatChip(String label, _ExportFormat format) {
    final selected = _format == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _format = format),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: selected ? AppColors.surface : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityChips() {
    return Row(
      children: [
        _qualityChip('720p', ExportQuality.p720),
        const SizedBox(width: 8),
        _qualityChip('1080p', ExportQuality.p1080),
        const SizedBox(width: 8),
        _qualityChip('Original', ExportQuality.original),
      ],
    );
  }

  Widget _qualityChip(String label, ExportQuality quality) {
    final selected = _quality == quality;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _quality = quality),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentDim : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportingState(ExportState exportState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Exporting…',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: exportState.progress > 0 ? exportState.progress : null,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(exportState.progress * 100).round()}%',
            style: AppTypography.mono,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneState(ExportState exportState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.check_circle, color: AppColors.accent, size: 48),
          const SizedBox(height: 12),
          Text('Export complete!', style: AppTypography.title),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CCButton(
                  label: 'Share',
                  icon: Icons.share,
                  onPressed: exportState.outputPath != null
                      ? () => _share(exportState.outputPath!)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CCButton.outlined(
                  label: 'Done',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ExportState exportState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text('Export failed', style: AppTypography.title),
          const SizedBox(height: 8),
          Text(
            exportState.errorMessage ?? 'Unknown error',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CCButton(
                  label: 'Try Again',
                  onPressed: () {
                    ref.read(exportProvider.notifier).reset();
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (_format == _ExportFormat.video)
                Expanded(
                  child: CCButton.outlined(
                    label: 'Export SRT instead',
                    onPressed: () {
                      setState(() => _format = _ExportFormat.srt);
                      ref.read(exportProvider.notifier).reset();
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
