import 'dart:ui';

import '../models/anim_preset.dart';
import '../models/caption_segment.dart';
import '../models/caption_style.dart';
import '../models/project.dart';

abstract final class AssBuilder {
  static String buildAss(Project project) {
    final buf = StringBuffer();
    _writeScriptInfo(buf, project);
    buf.writeln();
    _writeStyles(buf, project);
    buf.writeln();
    _writeEvents(buf, project);
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // [Script Info]
  // ---------------------------------------------------------------------------

  static void _writeScriptInfo(StringBuffer buf, Project project) {
    buf.writeln('[Script Info]');
    buf.writeln('Title: ${project.name}');
    buf.writeln('ScriptType: v4.00+');
    buf.writeln('Collisions: Normal');
    buf.writeln('PlayDepth: 0');
    buf.writeln('Timer: 100.0000');
    buf.writeln('WrapStyle: 0');
  }

  // ---------------------------------------------------------------------------
  // [V4+ Styles]
  // ---------------------------------------------------------------------------

  static void _writeStyles(StringBuffer buf, Project project) {
    buf.writeln('[V4+ Styles]');
    buf.writeln(
      'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, '
      'OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, '
      'ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, '
      'Alignment, MarginL, MarginR, MarginV, Encoding',
    );

    _writeStyleLine(buf, 'Default', project.globalStyle);

    for (final seg in project.captions) {
      if (seg.hasStyleOverride) {
        _writeStyleLine(buf, 'Override_${seg.id}', seg.styleOverride!);
      }
    }
  }

  static void _writeStyleLine(
    StringBuffer buf,
    String name,
    CaptionStyle style,
  ) {
    final primary = _colorToAss(Color(style.fontColor));
    final back = _colorToAss(Color(style.bgColor));
    final bold = style.bold ? -1 : 0;
    final italic = style.italic ? -1 : 0;
    final alignment = _alignmentToAss(style.hAlignment, style.verticalPosition);
    final borderStyle = style.bgShape == BgShape.none ? 1 : 3;

    buf.writeln(
      'Style: $name,${style.fontFamily},${style.fontSize.round()},'
      '$primary,&H000000FF,$primary,$back,'
      '$bold,$italic,0,0,'
      '100,100,0,0,$borderStyle,2,0,$alignment,10,10,10,1',
    );
  }

  // ---------------------------------------------------------------------------
  // [Events]
  // ---------------------------------------------------------------------------

  static void _writeEvents(StringBuffer buf, Project project) {
    buf.writeln('[Events]');
    buf.writeln(
      'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text',
    );

    for (final seg in project.captions) {
      final styleName = seg.hasStyleOverride ? 'Override_${seg.id}' : 'Default';
      final start = _msToAssTime(seg.startMs);
      final end = _msToAssTime(seg.endMs);
      final style = seg.hasStyleOverride ? seg.styleOverride! : project.globalStyle;
      final anim = seg.animPreset ?? project.globalAnim;
      final text = _buildAssText(seg, style, anim);

      buf.writeln('Dialogue: 0,$start,$end,$styleName,,0,0,0,,$text');
    }
  }

  static String _buildAssText(
    CaptionSegment seg,
    CaptionStyle style,
    AnimPreset anim,
  ) {
    final tags = StringBuffer();

    if (style.verticalOffset != 0.0) {
      final x = _posXForAlignment(style.hAlignment);
      final baseY = _posYForVertical(style.verticalPosition);
      final y = baseY + style.verticalOffset.round();
      tags.write('{\\pos($x,$y)}');
    }

    switch (anim) {
      case AnimPreset.none:
        break;
      case AnimPreset.fade:
        tags.write('{\\fad(150,150)}');
      case AnimPreset.pop:
        tags.write('{\\t(0,80,\\fscx110\\fscy110)\\t(80,160,\\fscx100\\fscy100)}');
      case AnimPreset.slideUp:
        final x = _posXForAlignment(style.hAlignment);
        final baseY = _posYForVertical(style.verticalPosition) +
            style.verticalOffset.round();
        tags.write('{\\move($x,${baseY + 50},$x,$baseY,0,200)}');
      case AnimPreset.karaoke:
        return _buildKaraokeText(tags.toString(), seg);
      case AnimPreset.wordByWord:
        return _buildWordByWordText(tags.toString(), seg);
    }

    return '$tags${seg.text}';
  }

  static String _buildKaraokeText(String prefixTags, CaptionSegment seg) {
    final words = seg.text.split(RegExp(r'\s+'));
    if (words.isEmpty) return '$prefixTags${seg.text}';

    final totalMs = seg.endMs - seg.startMs;
    final perWordMs = totalMs ~/ words.length;
    final perWordCs = (perWordMs / 10).round();

    final buf = StringBuffer(prefixTags);
    for (final word in words) {
      buf.write('{\\k$perWordCs}$word ');
    }
    return buf.toString().trimRight();
  }

  static String _buildWordByWordText(String prefixTags, CaptionSegment seg) {
    final words = seg.text.split(RegExp(r'\s+'));
    if (words.isEmpty) return '$prefixTags${seg.text}';

    final totalMs = seg.endMs - seg.startMs;
    final perWordMs = totalMs ~/ words.length;

    final buf = StringBuffer(prefixTags);
    for (var i = 0; i < words.length; i++) {
      final startMs = i * perWordMs;
      final endMs = (i + 1) * perWordMs;
      final startCs = (startMs / 10).round();
      final endCs = (endMs / 10).round();
      buf.write('{\\alpha&HFF&\\t($startCs,$endCs,\\alpha&H00&)}${words[i]} ');
    }
    return buf.toString().trimRight();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// ASS time format: `H:MM:SS.cc` (centiseconds).
  static String _msToAssTime(int ms) {
    if (ms < 0) ms = 0;
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    final cs = (ms % 1000) ~/ 10;
    return '$h:${_pad2(m)}:${_pad2(s)}.${_pad2(cs)}';
  }

  /// Converts a Flutter [Color] ARGB int to ASS `&HAABBGGRR` format.
  static String _colorToAss(Color c) {
    final a = 255 - c.alpha;
    final r = c.red;
    final g = c.green;
    final b = c.blue;
    return '&H${_hex2(a)}${_hex2(b)}${_hex2(g)}${_hex2(r)}';
  }

  /// ASS alignment uses numpad convention: 1-3 bottom, 4-6 middle, 7-9 top.
  static int _alignmentToAss(HAlign h, VPos v) {
    int base;
    switch (v) {
      case VPos.bottom:
        base = 1;
      case VPos.center:
        base = 4;
      case VPos.top:
        base = 7;
    }
    switch (h) {
      case HAlign.left:
        return base;
      case HAlign.center:
        return base + 1;
      case HAlign.right:
        return base + 2;
    }
  }

  static int _posXForAlignment(HAlign h) {
    switch (h) {
      case HAlign.left:
        return 100;
      case HAlign.center:
        return 640;
      case HAlign.right:
        return 1180;
    }
  }

  static int _posYForVertical(VPos v) {
    switch (v) {
      case VPos.top:
        return 60;
      case VPos.center:
        return 360;
      case VPos.bottom:
        return 660;
    }
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
  static String _hex2(int n) => n.toRadixString(16).padLeft(2, '0').toUpperCase();
}
