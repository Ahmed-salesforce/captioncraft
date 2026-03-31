import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:video_player/video_player.dart';

import '../../../core/providers/playback_provider.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import 'caption_overlay.dart';

class VideoPreview extends ConsumerWidget {
  const VideoPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);

    if (!playback.isInitialized || playback.controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final controller = playback.controller!;
    final aspectRatio = controller.value.aspectRatio;

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(controller),
                    const CaptionOverlay(),
                  ],
                ),
              ),
            ),
          ),
          _Controls(playback: playback, ref: ref),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final PlaybackState playback;
  final WidgetRef ref;

  const _Controls({required this.playback, required this.ref});

  @override
  Widget build(BuildContext context) {
    final posMs = playback.positionMs;
    final durMs = playback.durationMs;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              playback.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.textPrimary,
              size: 28,
            ),
            onPressed: () => ref.read(playbackProvider.notifier).togglePlayPause(),
          ),
          Text(
            TimeFormatter.formatMsShort(posMs),
            style: AppTypography.mono.copyWith(fontSize: 12),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.surface3,
                thumbColor: AppColors.accent,
                overlayColor: AppColors.accentDim,
              ),
              child: Slider(
                value: durMs > 0 ? posMs.toDouble().clamp(0, durMs.toDouble()) : 0,
                min: 0,
                max: durMs > 0 ? durMs.toDouble() : 1,
                onChanged: (v) => ref.read(playbackProvider.notifier).seekTo(v.toInt()),
              ),
            ),
          ),
          Text(
            TimeFormatter.formatMsShort(durMs),
            style: AppTypography.mono.copyWith(fontSize: 12),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
