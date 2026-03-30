import 'package:freezed_annotation/freezed_annotation.dart';

part 'caption_style.freezed.dart';
part 'caption_style.g.dart';

enum BgShape { none, roundedRect, fullBar }

enum VPos { top, center, bottom }

enum HAlign { left, center, right }

@freezed
class CaptionStyle with _$CaptionStyle {
  const factory CaptionStyle({
    @Default('Montserrat') String fontFamily,
    @Default(24.0) double fontSize,
    @Default(0xFFFFFFFF) int fontColor,
    @Default(0x99000000) int bgColor,
    @Default(BgShape.roundedRect) BgShape bgShape,
    @Default(VPos.bottom) VPos verticalPosition,
    @Default(0.0) double verticalOffset,
    @Default(HAlign.center) HAlign hAlignment,
    @Default(false) bool bold,
    @Default(false) bool italic,
  }) = _CaptionStyle;

  factory CaptionStyle.fromJson(Map<String, dynamic> json) =>
      _$CaptionStyleFromJson(json);
}
