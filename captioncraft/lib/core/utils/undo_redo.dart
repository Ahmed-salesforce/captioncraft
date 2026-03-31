import '../models/anim_preset.dart';
import '../models/caption_segment.dart';
import '../models/caption_style.dart';

typedef CaptionMutator = void Function(List<CaptionSegment> Function(List<CaptionSegment>) mutate);
typedef StyleMutator = void Function(CaptionStyle style);
typedef AnimMutator = void Function(AnimPreset anim);

abstract class Command {
  void execute();
  void undo();
  String get description;
}

class EditTextCommand implements Command {
  final String segmentId;
  final String oldText;
  final String newText;
  final CaptionMutator mutate;

  EditTextCommand({
    required this.segmentId,
    required this.oldText,
    required this.newText,
    required this.mutate,
  });

  @override
  String get description => 'Edit text';

  @override
  void execute() => _apply(newText);

  @override
  void undo() => _apply(oldText);

  void _apply(String text) {
    mutate((segments) => [
          for (final s in segments)
            if (s.id == segmentId) s.copyWith(text: text) else s,
        ]);
  }
}

class ResizeSegmentCommand implements Command {
  final String segmentId;
  final int oldStartMs;
  final int oldEndMs;
  final int newStartMs;
  final int newEndMs;
  final CaptionMutator mutate;

  ResizeSegmentCommand({
    required this.segmentId,
    required this.oldStartMs,
    required this.oldEndMs,
    required this.newStartMs,
    required this.newEndMs,
    required this.mutate,
  });

  @override
  String get description => 'Resize segment';

  @override
  void execute() => _apply(newStartMs, newEndMs);

  @override
  void undo() => _apply(oldStartMs, oldEndMs);

  void _apply(int startMs, int endMs) {
    mutate((segments) => [
          for (final s in segments)
            if (s.id == segmentId)
              s.copyWith(startMs: startMs, endMs: endMs)
            else
              s,
        ]);
  }
}

class MoveSegmentCommand implements Command {
  final String segmentId;
  final int deltaMs;
  final CaptionMutator mutate;

  MoveSegmentCommand({
    required this.segmentId,
    required this.deltaMs,
    required this.mutate,
  });

  @override
  String get description => 'Move segment';

  @override
  void execute() => _shift(deltaMs);

  @override
  void undo() => _shift(-deltaMs);

  void _shift(int delta) {
    mutate((segments) => [
          for (final s in segments)
            if (s.id == segmentId)
              s.copyWith(startMs: s.startMs + delta, endMs: s.endMs + delta)
            else
              s,
        ]);
  }
}

class AddSegmentCommand implements Command {
  final CaptionSegment segment;
  final CaptionMutator mutate;

  AddSegmentCommand({required this.segment, required this.mutate});

  @override
  String get description => 'Add segment';

  @override
  void execute() {
    mutate((segments) => [...segments, segment]
      ..sort((a, b) => a.startMs.compareTo(b.startMs)));
  }

  @override
  void undo() {
    mutate((segments) => segments.where((s) => s.id != segment.id).toList());
  }
}

class DeleteSegmentCommand implements Command {
  final CaptionSegment segment;
  final CaptionMutator mutate;
  int _index = 0;

  DeleteSegmentCommand({required this.segment, required this.mutate});

  @override
  String get description => 'Delete segment';

  @override
  void execute() {
    mutate((segments) {
      _index = segments.indexWhere((s) => s.id == segment.id);
      if (_index == -1) _index = segments.length;
      return segments.where((s) => s.id != segment.id).toList();
    });
  }

  @override
  void undo() {
    mutate((segments) {
      final list = List<CaptionSegment>.from(segments);
      list.insert(_index.clamp(0, list.length), segment);
      return list;
    });
  }
}

class SplitSegmentCommand implements Command {
  final String segmentId;
  final int atMs;
  final String newId;
  final CaptionMutator mutate;

  CaptionSegment? _original;

  SplitSegmentCommand({
    required this.segmentId,
    required this.atMs,
    required this.newId,
    required this.mutate,
  });

  @override
  String get description => 'Split segment';

  @override
  void execute() {
    mutate((segments) {
      final idx = segments.indexWhere((s) => s.id == segmentId);
      if (idx == -1) return segments;

      _original = segments[idx];
      final seg = _original!;
      final words = seg.text.split(RegExp(r'\s+'));
      final totalMs = seg.endMs - seg.startMs;
      final splitRatio = (atMs - seg.startMs) / totalMs;
      final splitWord = (words.length * splitRatio).round().clamp(1, words.length - 1);

      final firstText = words.sublist(0, splitWord).join(' ');
      final secondText = words.sublist(splitWord).join(' ');

      final first = seg.copyWith(endMs: atMs, text: firstText);
      final second = seg.copyWith(
        id: newId,
        startMs: atMs,
        text: secondText,
      );

      final list = List<CaptionSegment>.from(segments);
      list[idx] = first;
      list.insert(idx + 1, second);
      return list;
    });
  }

  @override
  void undo() {
    if (_original == null) return;
    mutate((segments) {
      final list = segments.where((s) => s.id != newId).toList();
      final idx = list.indexWhere((s) => s.id == segmentId);
      if (idx != -1) {
        list[idx] = _original!;
      }
      return list;
    });
  }
}

class MergeSegmentsCommand implements Command {
  final String firstId;
  final String secondId;
  final CaptionMutator mutate;

  CaptionSegment? _first;
  CaptionSegment? _second;

  MergeSegmentsCommand({
    required this.firstId,
    required this.secondId,
    required this.mutate,
  });

  @override
  String get description => 'Merge segments';

  @override
  void execute() {
    mutate((segments) {
      final firstIdx = segments.indexWhere((s) => s.id == firstId);
      final secondIdx = segments.indexWhere((s) => s.id == secondId);
      if (firstIdx == -1 || secondIdx == -1) return segments;

      _first = segments[firstIdx];
      _second = segments[secondIdx];

      final merged = _first!.copyWith(
        endMs: _second!.endMs,
        text: '${_first!.text} ${_second!.text}',
      );

      final list = List<CaptionSegment>.from(segments);
      list[firstIdx] = merged;
      list.removeAt(secondIdx);
      return list;
    });
  }

  @override
  void undo() {
    if (_first == null || _second == null) return;
    mutate((segments) {
      final idx = segments.indexWhere((s) => s.id == firstId);
      if (idx == -1) return segments;
      final list = List<CaptionSegment>.from(segments);
      list[idx] = _first!;
      list.insert(idx + 1, _second!);
      return list;
    });
  }
}

class ChangeStyleCommand implements Command {
  final CaptionStyle oldStyle;
  final CaptionStyle newStyle;
  final StyleMutator mutate;

  ChangeStyleCommand({
    required this.oldStyle,
    required this.newStyle,
    required this.mutate,
  });

  @override
  String get description => 'Change style';

  @override
  void execute() => mutate(newStyle);

  @override
  void undo() => mutate(oldStyle);
}

class ChangeGlobalAnimCommand implements Command {
  final AnimPreset oldAnim;
  final AnimPreset newAnim;
  final AnimMutator mutate;

  ChangeGlobalAnimCommand({
    required this.oldAnim,
    required this.newAnim,
    required this.mutate,
  });

  @override
  String get description => 'Change animation';

  @override
  void execute() => mutate(newAnim);

  @override
  void undo() => mutate(oldAnim);
}
