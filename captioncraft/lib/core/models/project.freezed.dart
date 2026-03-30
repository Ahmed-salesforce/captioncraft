// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return _Project.fromJson(json);
}

/// @nodoc
mixin _$Project {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get videoPath => throw _privateConstructorUsedError;
  int get videoDurationMs => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  CaptionStyle get globalStyle => throw _privateConstructorUsedError;
  AnimPreset get globalAnim => throw _privateConstructorUsedError;
  List<CaptionSegment> get captions => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call(
      {String id,
      String name,
      String videoPath,
      int videoDurationMs,
      DateTime createdAt,
      DateTime updatedAt,
      CaptionStyle globalStyle,
      AnimPreset globalAnim,
      List<CaptionSegment> captions});

  $CaptionStyleCopyWith<$Res> get globalStyle;
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? videoPath = null,
    Object? videoDurationMs = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? globalStyle = null,
    Object? globalAnim = null,
    Object? captions = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      videoPath: null == videoPath
          ? _value.videoPath
          : videoPath // ignore: cast_nullable_to_non_nullable
              as String,
      videoDurationMs: null == videoDurationMs
          ? _value.videoDurationMs
          : videoDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      globalStyle: null == globalStyle
          ? _value.globalStyle
          : globalStyle // ignore: cast_nullable_to_non_nullable
              as CaptionStyle,
      globalAnim: null == globalAnim
          ? _value.globalAnim
          : globalAnim // ignore: cast_nullable_to_non_nullable
              as AnimPreset,
      captions: null == captions
          ? _value.captions
          : captions // ignore: cast_nullable_to_non_nullable
              as List<CaptionSegment>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $CaptionStyleCopyWith<$Res> get globalStyle {
    return $CaptionStyleCopyWith<$Res>(_value.globalStyle, (value) {
      return _then(_value.copyWith(globalStyle: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
          _$ProjectImpl value, $Res Function(_$ProjectImpl) then) =
      __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String videoPath,
      int videoDurationMs,
      DateTime createdAt,
      DateTime updatedAt,
      CaptionStyle globalStyle,
      AnimPreset globalAnim,
      List<CaptionSegment> captions});

  @override
  $CaptionStyleCopyWith<$Res> get globalStyle;
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
      _$ProjectImpl _value, $Res Function(_$ProjectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? videoPath = null,
    Object? videoDurationMs = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? globalStyle = null,
    Object? globalAnim = null,
    Object? captions = null,
  }) {
    return _then(_$ProjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      videoPath: null == videoPath
          ? _value.videoPath
          : videoPath // ignore: cast_nullable_to_non_nullable
              as String,
      videoDurationMs: null == videoDurationMs
          ? _value.videoDurationMs
          : videoDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      globalStyle: null == globalStyle
          ? _value.globalStyle
          : globalStyle // ignore: cast_nullable_to_non_nullable
              as CaptionStyle,
      globalAnim: null == globalAnim
          ? _value.globalAnim
          : globalAnim // ignore: cast_nullable_to_non_nullable
              as AnimPreset,
      captions: null == captions
          ? _value._captions
          : captions // ignore: cast_nullable_to_non_nullable
              as List<CaptionSegment>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImpl extends _Project {
  const _$ProjectImpl(
      {required this.id,
      required this.name,
      required this.videoPath,
      required this.videoDurationMs,
      required this.createdAt,
      required this.updatedAt,
      this.globalStyle = const CaptionStyle(),
      this.globalAnim = AnimPreset.none,
      final List<CaptionSegment> captions = const []})
      : _captions = captions,
        super._();

  factory _$ProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String videoPath;
  @override
  final int videoDurationMs;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final CaptionStyle globalStyle;
  @override
  @JsonKey()
  final AnimPreset globalAnim;
  final List<CaptionSegment> _captions;
  @override
  @JsonKey()
  List<CaptionSegment> get captions {
    if (_captions is EqualUnmodifiableListView) return _captions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_captions);
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, videoPath: $videoPath, videoDurationMs: $videoDurationMs, createdAt: $createdAt, updatedAt: $updatedAt, globalStyle: $globalStyle, globalAnim: $globalAnim, captions: $captions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.videoPath, videoPath) ||
                other.videoPath == videoPath) &&
            (identical(other.videoDurationMs, videoDurationMs) ||
                other.videoDurationMs == videoDurationMs) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.globalStyle, globalStyle) ||
                other.globalStyle == globalStyle) &&
            (identical(other.globalAnim, globalAnim) ||
                other.globalAnim == globalAnim) &&
            const DeepCollectionEquality().equals(other._captions, _captions));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      videoPath,
      videoDurationMs,
      createdAt,
      updatedAt,
      globalStyle,
      globalAnim,
      const DeepCollectionEquality().hash(_captions));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImplToJson(
      this,
    );
  }
}

abstract class _Project extends Project {
  const factory _Project(
      {required final String id,
      required final String name,
      required final String videoPath,
      required final int videoDurationMs,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final CaptionStyle globalStyle,
      final AnimPreset globalAnim,
      final List<CaptionSegment> captions}) = _$ProjectImpl;
  const _Project._() : super._();

  factory _Project.fromJson(Map<String, dynamic> json) = _$ProjectImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get videoPath;
  @override
  int get videoDurationMs;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  CaptionStyle get globalStyle;
  @override
  AnimPreset get globalAnim;
  @override
  List<CaptionSegment> get captions;
  @override
  @JsonKey(ignore: true)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
