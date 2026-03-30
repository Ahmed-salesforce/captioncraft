import 'package:freezed_annotation/freezed_annotation.dart';

import 'anim_preset.dart';
import 'caption_segment.dart';
import 'caption_style.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
class Project with _$Project {
  const Project._();

  const factory Project({
    required String id,
    required String name,
    required String videoPath,
    required int videoDurationMs,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(CaptionStyle()) CaptionStyle globalStyle,
    @Default(AnimPreset.none) AnimPreset globalAnim,
    @Default([]) List<CaptionSegment> captions,
  }) = _Project;

  bool get hasOverlaps {
    final sorted = List<CaptionSegment>.from(captions)
      ..sort((a, b) => a.startMs.compareTo(b.startMs));
    for (var i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].endMs > sorted[i + 1].startMs) {
        return true;
      }
    }
    return false;
  }

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
