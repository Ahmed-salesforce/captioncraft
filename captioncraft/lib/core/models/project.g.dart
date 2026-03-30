// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      videoPath: json['videoPath'] as String,
      videoDurationMs: (json['videoDurationMs'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      globalStyle: json['globalStyle'] == null
          ? const CaptionStyle()
          : CaptionStyle.fromJson(json['globalStyle'] as Map<String, dynamic>),
      globalAnim:
          $enumDecodeNullable(_$AnimPresetEnumMap, json['globalAnim']) ??
              AnimPreset.none,
      captions: (json['captions'] as List<dynamic>?)
              ?.map((e) => CaptionSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'videoPath': instance.videoPath,
      'videoDurationMs': instance.videoDurationMs,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'globalStyle': instance.globalStyle,
      'globalAnim': _$AnimPresetEnumMap[instance.globalAnim]!,
      'captions': instance.captions,
    };

const _$AnimPresetEnumMap = {
  AnimPreset.none: 'none',
  AnimPreset.fade: 'fade',
  AnimPreset.pop: 'pop',
  AnimPreset.slideUp: 'slideUp',
  AnimPreset.wordByWord: 'wordByWord',
  AnimPreset.karaoke: 'karaoke',
};
