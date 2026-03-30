import 'package:freezed_annotation/freezed_annotation.dart';

import 'anim_preset.dart';
import 'caption_style.dart';

part 'caption_segment.freezed.dart';
part 'caption_segment.g.dart';

@freezed
class CaptionSegment with _$CaptionSegment {
  const CaptionSegment._();

  const factory CaptionSegment({
    required String id,
    required int startMs,
    required int endMs,
    required String text,
    CaptionStyle? styleOverride,
    AnimPreset? animPreset,
  }) = _CaptionSegment;

  bool get hasStyleOverride => styleOverride != null;

  Duration get duration => Duration(milliseconds: endMs - startMs);

  factory CaptionSegment.fromJson(Map<String, dynamic> json) =>
      _$CaptionSegmentFromJson(json);
}
