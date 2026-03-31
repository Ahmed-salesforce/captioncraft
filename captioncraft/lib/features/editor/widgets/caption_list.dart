import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/caption_segment.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/utils/undo_redo.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import 'caption_edit_sheet.dart';

const _uuid = Uuid();

class CaptionList extends ConsumerWidget {
  const CaptionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captions = ref.watch(captionProvider);
    ref.watch(playbackProvider);
    final activeSeg = ref.read(playbackProvider.notifier).currentCaption(captions);

    return Column(
      children: [
        _Toolbar(activeSeg: activeSeg),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: captions.isEmpty
              ? Center(
                  child: Text(
                    'No captions yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption,
                  ),
                )
              : ListView.builder(
                  itemCount: captions.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final seg = captions[index];
                    final isActive = activeSeg?.id == seg.id;

                    bool hasOverlap = false;
                    if (index > 0 && captions[index - 1].endMs > seg.startMs) {
                      hasOverlap = true;
                    }
                    if (index < captions.length - 1 &&
                        seg.endMs > captions[index + 1].startMs) {
                      hasOverlap = true;
                    }

                    return _CaptionRow(
                      index: index,
                      segment: seg,
                      isActive: isActive,
                      hasOverlap: hasOverlap,
                      onTap: () => CaptionEditSheet.open(context, ref, seg),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Toolbar extends ConsumerWidget {
  final CaptionSegment? activeSeg;

  const _Toolbar({required this.activeSeg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            color: AppColors.accent,
            tooltip: 'Add caption',
            onPressed: () => _addCaption(ref),
          ),
          IconButton(
            icon: const Icon(Icons.splitscreen, size: 20),
            color: activeSeg != null ? AppColors.textPrimary : AppColors.textSecondary,
            tooltip: 'Split at playhead',
            onPressed: activeSeg != null ? () => _splitCaption(ref) : null,
          ),
          IconButton(
            icon: const Icon(Icons.merge, size: 20),
            color: activeSeg != null ? AppColors.textPrimary : AppColors.textSecondary,
            tooltip: 'Merge with next',
            onPressed: activeSeg != null ? () => _mergeCaption(ref) : null,
          ),
          const Spacer(),
          Text(
            '${ref.watch(captionProvider).length} segments',
            style: AppTypography.caption,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _addCaption(WidgetRef ref) {
    final playback = ref.read(playbackProvider);
    final posMs = playback.positionMs;
    final durMs = playback.durationMs;

    final endMs = (posMs + 2000).clamp(0, durMs);
    final seg = CaptionSegment(
      id: _uuid.v4(),
      startMs: posMs,
      endMs: endMs,
      text: 'New caption',
    );

    ref.read(historyProvider.notifier).execute(
      AddSegmentCommand(
        segment: seg,
        mutate: ref.read(captionProvider.notifier).applyMutation,
      ),
    );
  }

  void _splitCaption(WidgetRef ref) {
    if (activeSeg == null) return;
    final posMs = ref.read(playbackProvider).positionMs;

    if (posMs <= activeSeg!.startMs || posMs >= activeSeg!.endMs) return;

    ref.read(historyProvider.notifier).execute(
      SplitSegmentCommand(
        segmentId: activeSeg!.id,
        atMs: posMs,
        newId: _uuid.v4(),
        mutate: ref.read(captionProvider.notifier).applyMutation,
      ),
    );
  }

  void _mergeCaption(WidgetRef ref) {
    if (activeSeg == null) return;
    final captions = ref.read(captionProvider);
    final idx = captions.indexWhere((s) => s.id == activeSeg!.id);
    if (idx == -1 || idx >= captions.length - 1) return;

    ref.read(historyProvider.notifier).execute(
      MergeSegmentsCommand(
        firstId: captions[idx].id,
        secondId: captions[idx + 1].id,
        mutate: ref.read(captionProvider.notifier).applyMutation,
      ),
    );
  }
}

class _CaptionRow extends StatelessWidget {
  final int index;
  final CaptionSegment segment;
  final bool isActive;
  final bool hasOverlap;
  final VoidCallback onTap;

  const _CaptionRow({
    required this.index,
    required this.segment,
    required this.isActive,
    required this.hasOverlap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.accentDim : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${index + 1}',
                  style: AppTypography.mono.copyWith(fontSize: 12),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      segment.text,
                      style: AppTypography.body.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${TimeFormatter.formatMs(segment.startMs)} → ${TimeFormatter.formatMs(segment.endMs)}',
                      style: AppTypography.mono.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (segment.hasStyleOverride)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              if (hasOverlap)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
