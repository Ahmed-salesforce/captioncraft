import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/anim_preset.dart';
import '../../../core/models/caption_segment.dart';
import '../../../core/models/caption_style.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../shared/theme/app_colors.dart';

class CaptionOverlay extends ConsumerWidget {
  const CaptionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final captions = ref.watch(captionProvider);
    final project = ref.watch(currentProjectProvider);

    final activeSeg = ref.read(playbackProvider.notifier).currentCaption(captions);
    if (activeSeg == null || project == null) return const SizedBox.shrink();

    final style = activeSeg.styleOverride ?? project.globalStyle;
    final anim = activeSeg.animPreset ?? project.globalAnim;

    final alignment = _verticalAlignment(style.verticalPosition);
    final offset = style.verticalOffset;

    Widget text = _buildStyledText(activeSeg, style, playback.positionMs);

    text = _applyAnimation(text, anim, activeSeg, playback.positionMs);

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 + offset.abs()),
        child: Align(
          alignment: Alignment(
            _hAlignValue(style.hAlignment),
            alignment + (offset / 200),
          ),
          child: text,
        ),
      ),
    );
  }

  Widget _buildStyledText(CaptionSegment seg, CaptionStyle style, int positionMs) {
    final textStyle = TextStyle(
      fontFamily: style.fontFamily,
      fontSize: style.fontSize,
      color: Color(style.fontColor),
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
    );

    final anim = seg.animPreset ?? AnimPreset.none;

    if (anim == AnimPreset.karaoke || anim == AnimPreset.wordByWord) {
      return _buildWordHighlight(seg, style, textStyle, positionMs, anim);
    }

    Widget child = Text(
      seg.text,
      style: textStyle,
      textAlign: _textAlign(style.hAlignment),
    );

    if (style.bgShape != BgShape.none) {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(style.bgColor),
          borderRadius: style.bgShape == BgShape.roundedRect
              ? BorderRadius.circular(6)
              : null,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _buildWordHighlight(
    CaptionSegment seg,
    CaptionStyle style,
    TextStyle baseStyle,
    int positionMs,
    AnimPreset anim,
  ) {
    final words = seg.text.split(RegExp(r'\s+'));
    if (words.isEmpty) return const SizedBox.shrink();

    final totalMs = seg.endMs - seg.startMs;
    final elapsed = (positionMs - seg.startMs).clamp(0, totalMs);
    final progress = totalMs > 0 ? elapsed / totalMs : 1.0;
    final currentWordIndex = (progress * words.length).floor().clamp(0, words.length - 1);

    final spans = <TextSpan>[];
    for (var i = 0; i < words.length; i++) {
      final isActive = anim == AnimPreset.karaoke
          ? i == currentWordIndex
          : i <= currentWordIndex;

      spans.add(TextSpan(
        text: i < words.length - 1 ? '${words[i]} ' : words[i],
        style: baseStyle.copyWith(
          color: isActive
              ? Color(style.fontColor)
              : Color(style.fontColor).withOpacity(0.35),
          backgroundColor: (anim == AnimPreset.karaoke && isActive)
              ? AppColors.accent.withOpacity(0.3)
              : null,
        ),
      ));
    }

    Widget child = RichText(
      text: TextSpan(children: spans),
      textAlign: _textAlign(style.hAlignment),
    );

    if (style.bgShape != BgShape.none) {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(style.bgColor),
          borderRadius: style.bgShape == BgShape.roundedRect
              ? BorderRadius.circular(6)
              : null,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _applyAnimation(Widget child, AnimPreset anim, CaptionSegment seg, int positionMs) {
    switch (anim) {
      case AnimPreset.fade:
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 150),
          child: child,
        );
      case AnimPreset.slideUp:
        return AnimatedSlide(
          offset: Offset.zero,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: child,
        );
      case AnimPreset.pop:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
          builder: (_, scale, c) => Transform.scale(scale: scale, child: c),
          child: child,
        );
      case AnimPreset.none:
      case AnimPreset.wordByWord:
      case AnimPreset.karaoke:
        return child;
    }
  }

  double _verticalAlignment(VPos pos) {
    switch (pos) {
      case VPos.top:
        return -0.85;
      case VPos.center:
        return 0.0;
      case VPos.bottom:
        return 0.85;
    }
  }

  double _hAlignValue(HAlign align) {
    switch (align) {
      case HAlign.left:
        return -1.0;
      case HAlign.center:
        return 0.0;
      case HAlign.right:
        return 1.0;
    }
  }

  TextAlign _textAlign(HAlign align) {
    switch (align) {
      case HAlign.left:
        return TextAlign.left;
      case HAlign.center:
        return TextAlign.center;
      case HAlign.right:
        return TextAlign.right;
    }
  }
}
