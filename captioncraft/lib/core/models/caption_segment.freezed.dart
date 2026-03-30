// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'caption_segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CaptionSegment _$CaptionSegmentFromJson(Map<String, dynamic> json) {
  return _CaptionSegment.fromJson(json);
}

/// @nodoc
mixin _$CaptionSegment {
  String get id => throw _privateConstructorUsedError;
  int get startMs => throw _privateConstructorUsedError;
  int get endMs => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  CaptionStyle? get styleOverride => throw _privateConstructorUsedError;
  AnimPreset? get animPreset => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CaptionSegmentCopyWith<CaptionSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CaptionSegmentCopyWith<$Res> {
  factory $CaptionSegmentCopyWith(
          CaptionSegment value, $Res Function(CaptionSegment) then) =
      _$CaptionSegmentCopyWithImpl<$Res, CaptionSegment>;
  @useResult
  $Res call(
      {String id,
      int startMs,
      int endMs,
      String text,
      CaptionStyle? styleOverride,
      AnimPreset? animPreset});

  $CaptionStyleCopyWith<$Res>? get styleOverride;
}

/// @nodoc
class _$CaptionSegmentCopyWithImpl<$Res, $Val extends CaptionSegment>
    implements $CaptionSegmentCopyWith<$Res> {
  _$CaptionSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startMs = null,
    Object? endMs = null,
    Object? text = null,
    Object? styleOverride = freezed,
    Object? animPreset = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startMs: null == startMs
          ? _value.startMs
          : startMs // ignore: cast_nullable_to_non_nullable
              as int,
      endMs: null == endMs
          ? _value.endMs
          : endMs // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      styleOverride: freezed == styleOverride
          ? _value.styleOverride
          : styleOverride // ignore: cast_nullable_to_non_nullable
              as CaptionStyle?,
      animPreset: freezed == animPreset
          ? _value.animPreset
          : animPreset // ignore: cast_nullable_to_non_nullable
              as AnimPreset?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $CaptionStyleCopyWith<$Res>? get styleOverride {
    if (_value.styleOverride == null) {
      return null;
    }

    return $CaptionStyleCopyWith<$Res>(_value.styleOverride!, (value) {
      return _then(_value.copyWith(styleOverride: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CaptionSegmentImplCopyWith<$Res>
    implements $CaptionSegmentCopyWith<$Res> {
  factory _$$CaptionSegmentImplCopyWith(_$CaptionSegmentImpl value,
          $Res Function(_$CaptionSegmentImpl) then) =
      __$$CaptionSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      int startMs,
      int endMs,
      String text,
      CaptionStyle? styleOverride,
      AnimPreset? animPreset});

  @override
  $CaptionStyleCopyWith<$Res>? get styleOverride;
}

/// @nodoc
class __$$CaptionSegmentImplCopyWithImpl<$Res>
    extends _$CaptionSegmentCopyWithImpl<$Res, _$CaptionSegmentImpl>
    implements _$$CaptionSegmentImplCopyWith<$Res> {
  __$$CaptionSegmentImplCopyWithImpl(
      _$CaptionSegmentImpl _value, $Res Function(_$CaptionSegmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startMs = null,
    Object? endMs = null,
    Object? text = null,
    Object? styleOverride = freezed,
    Object? animPreset = freezed,
  }) {
    return _then(_$CaptionSegmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startMs: null == startMs
          ? _value.startMs
          : startMs // ignore: cast_nullable_to_non_nullable
              as int,
      endMs: null == endMs
          ? _value.endMs
          : endMs // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      styleOverride: freezed == styleOverride
          ? _value.styleOverride
          : styleOverride // ignore: cast_nullable_to_non_nullable
              as CaptionStyle?,
      animPreset: freezed == animPreset
          ? _value.animPreset
          : animPreset // ignore: cast_nullable_to_non_nullable
              as AnimPreset?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CaptionSegmentImpl extends _CaptionSegment {
  const _$CaptionSegmentImpl(
      {required this.id,
      required this.startMs,
      required this.endMs,
      required this.text,
      this.styleOverride,
      this.animPreset})
      : super._();

  factory _$CaptionSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CaptionSegmentImplFromJson(json);

  @override
  final String id;
  @override
  final int startMs;
  @override
  final int endMs;
  @override
  final String text;
  @override
  final CaptionStyle? styleOverride;
  @override
  final AnimPreset? animPreset;

  @override
  String toString() {
    return 'CaptionSegment(id: $id, startMs: $startMs, endMs: $endMs, text: $text, styleOverride: $styleOverride, animPreset: $animPreset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CaptionSegmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startMs, startMs) || other.startMs == startMs) &&
            (identical(other.endMs, endMs) || other.endMs == endMs) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.styleOverride, styleOverride) ||
                other.styleOverride == styleOverride) &&
            (identical(other.animPreset, animPreset) ||
                other.animPreset == animPreset));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, startMs, endMs, text, styleOverride, animPreset);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CaptionSegmentImplCopyWith<_$CaptionSegmentImpl> get copyWith =>
      __$$CaptionSegmentImplCopyWithImpl<_$CaptionSegmentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CaptionSegmentImplToJson(
      this,
    );
  }
}

abstract class _CaptionSegment extends CaptionSegment {
  const factory _CaptionSegment(
      {required final String id,
      required final int startMs,
      required final int endMs,
      required final String text,
      final CaptionStyle? styleOverride,
      final AnimPreset? animPreset}) = _$CaptionSegmentImpl;
  const _CaptionSegment._() : super._();

  factory _CaptionSegment.fromJson(Map<String, dynamic> json) =
      _$CaptionSegmentImpl.fromJson;

  @override
  String get id;
  @override
  int get startMs;
  @override
  int get endMs;
  @override
  String get text;
  @override
  CaptionStyle? get styleOverride;
  @override
  AnimPreset? get animPreset;
  @override
  @JsonKey(ignore: true)
  _$$CaptionSegmentImplCopyWith<_$CaptionSegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
