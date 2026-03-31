import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../models/caption_segment.dart';

class PlaybackState {
  final VideoPlayerController? controller;
  final bool isPlaying;
  final int positionMs;
  final int durationMs;
  final bool isInitialized;

  const PlaybackState({
    this.controller,
    this.isPlaying = false,
    this.positionMs = 0,
    this.durationMs = 0,
    this.isInitialized = false,
  });

  PlaybackState copyWith({
    VideoPlayerController? controller,
    bool? isPlaying,
    int? positionMs,
    int? durationMs,
    bool? isInitialized,
  }) {
    return PlaybackState(
      controller: controller ?? this.controller,
      isPlaying: isPlaying ?? this.isPlaying,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier() : super(const PlaybackState());

  Future<void> initialize(String videoPath) async {
    await state.controller?.dispose();

    final controller = VideoPlayerController.file(File(videoPath));
    await controller.initialize();

    controller.addListener(_onTick);

    state = PlaybackState(
      controller: controller,
      isPlaying: false,
      positionMs: 0,
      durationMs: controller.value.duration.inMilliseconds,
      isInitialized: true,
    );
  }

  void _onTick() {
    final c = state.controller;
    if (c == null || !mounted) return;
    final val = c.value;
    state = state.copyWith(
      positionMs: val.position.inMilliseconds,
      isPlaying: val.isPlaying,
    );
  }

  void play() => state.controller?.play();

  void pause() => state.controller?.pause();

  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void seekTo(int ms) {
    state.controller?.seekTo(Duration(milliseconds: ms));
  }

  CaptionSegment? currentCaption(List<CaptionSegment> captions) {
    final pos = state.positionMs;
    for (final seg in captions) {
      if (seg.startMs <= pos && pos < seg.endMs) return seg;
    }
    return null;
  }

  @override
  void dispose() {
    state.controller?.removeListener(_onTick);
    state.controller?.dispose();
    super.dispose();
  }
}

final playbackProvider =
    StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  return PlaybackNotifier();
});
