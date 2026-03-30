// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caption_style.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CaptionStyleImpl _$$CaptionStyleImplFromJson(Map<String, dynamic> json) =>
    _$CaptionStyleImpl(
      fontFamily: json['fontFamily'] as String? ?? 'Montserrat',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      fontColor: (json['fontColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      bgColor: (json['bgColor'] as num?)?.toInt() ?? 0x99000000,
      bgShape: $enumDecodeNullable(_$BgShapeEnumMap, json['bgShape']) ??
          BgShape.roundedRect,
      verticalPosition:
          $enumDecodeNullable(_$VPosEnumMap, json['verticalPosition']) ??
              VPos.bottom,
      verticalOffset: (json['verticalOffset'] as num?)?.toDouble() ?? 0.0,
      hAlignment: $enumDecodeNullable(_$HAlignEnumMap, json['hAlignment']) ??
          HAlign.center,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
    );

Map<String, dynamic> _$$CaptionStyleImplToJson(_$CaptionStyleImpl instance) =>
    <String, dynamic>{
      'fontFamily': instance.fontFamily,
      'fontSize': instance.fontSize,
      'fontColor': instance.fontColor,
      'bgColor': instance.bgColor,
      'bgShape': _$BgShapeEnumMap[instance.bgShape]!,
      'verticalPosition': _$VPosEnumMap[instance.verticalPosition]!,
      'verticalOffset': instance.verticalOffset,
      'hAlignment': _$HAlignEnumMap[instance.hAlignment]!,
      'bold': instance.bold,
      'italic': instance.italic,
    };

const _$BgShapeEnumMap = {
  BgShape.none: 'none',
  BgShape.roundedRect: 'roundedRect',
  BgShape.fullBar: 'fullBar',
};

const _$VPosEnumMap = {
  VPos.top: 'top',
  VPos.center: 'center',
  VPos.bottom: 'bottom',
};

const _$HAlignEnumMap = {
  HAlign.left: 'left',
  HAlign.center: 'center',
  HAlign.right: 'right',
};
