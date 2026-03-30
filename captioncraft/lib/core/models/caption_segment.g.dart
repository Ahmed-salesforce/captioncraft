// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caption_segment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CaptionSegmentImpl _$$CaptionSegmentImplFromJson(Map<String, dynamic> json) =>
    _$CaptionSegmentImpl(
      id: json['id'] as String,
      startMs: (json['startMs'] as num).toInt(),
      endMs: (json['endMs'] as num).toInt(),
      text: json['text'] as String,
      styleOverride: json['styleOverride'] == null
          ? null
          : CaptionStyle.fromJson(
              json['styleOverride'] as Map<String, dynamic>),
      animPreset: $enumDecodeNullable(_$AnimPresetEnumMap, json['animPreset']),
    );

Map<String, dynamic> _$$CaptionSegmentImplToJson(
        _$CaptionSegmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startMs': instance.startMs,
      'endMs': instance.endMs,
      'text': instance.text,
      'styleOverride': instance.styleOverride,
      'animPreset': _$AnimPresetEnumMap[instance.animPreset],
    };

const _$AnimPresetEnumMap = {
  AnimPreset.none: 'none',
  AnimPreset.fade: 'fade',
  AnimPreset.pop: 'pop',
  AnimPreset.slideUp: 'slideUp',
  AnimPreset.wordByWord: 'wordByWord',
  AnimPreset.karaoke: 'karaoke',
};
