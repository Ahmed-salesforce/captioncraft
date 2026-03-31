import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/caption_segment.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/utils/undo_redo.dart';
import '../../../shared/theme/app_colors.dart';

class TimelineStrip extends ConsumerStatefulWidget {
  const TimelineStrip({super.key});

  @override
  ConsumerState<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends ConsumerState<TimelineStrip> {
  final ScrollController _scrollController = ScrollController();

  _DragMode _dragMode = _DragMode.none;
  String? _dragSegmentId;
  int? _dragOrigStartMs;
  int? _dragOrigEndMs;

  static const double _edgeHitZone = 12;
  static const double _pixelsPerSecond = 30;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _totalWidth(int durationMs) {
    return (durationMs / 1000) * _pixelsPerSecond;
  }

  int _xToMs(double x, int durationMs) {
    final total = _totalWidth(durationMs);
    if (total <= 0) return 0;
    return ((x / total) * durationMs).round().clamp(0, durationMs);
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);
    final captions = ref.watch(captionProvider);
    final durationMs = playback.durationMs;

    final totalWidth = math.max(_totalWidth(durationMs), MediaQuery.of(context).size.width);

    return SizedBox(
      height: 64,
      child: GestureDetector(
        onTapDown: (d) => _onTap(d, totalWidth, durationMs),
        onHorizontalDragStart: (d) => _onDragStart(d, totalWidth, durationMs, captions),
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, totalWidth, durationMs),
        onHorizontalDragEnd: (_) => _onDragEnd(),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: CustomPaint(
            size: Size(totalWidth, 64),
            painter: _TimelinePainter(
              captions: captions,
              positionMs: playback.positionMs,
              durationMs: durationMs,
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(TapDownDetails details, double totalWidth, int durationMs) {
    final localX = details.localPosition.dx + _scrollController.offset;
    final ms = _xToMs(localX, durationMs);
    ref.read(playbackProvider.notifier).seekTo(ms);
  }

  void _onDragStart(DragStartDetails details, double totalWidth, int durationMs, List<CaptionSegment> captions) {
    final localX = details.localPosition.dx + _scrollController.offset;
    final tapMs = _xToMs(localX, durationMs);

    for (final seg in captions) {
      final segStartX = (seg.startMs / durationMs) * totalWidth;
      final segEndX = (seg.endMs / durationMs) * totalWidth;
      final tapX = localX;

      if ((tapX - segStartX).abs() < _edgeHitZone) {
        _dragMode = _DragMode.resizeStart;
        _dragSegmentId = seg.id;
        _dragOrigStartMs = seg.startMs;
        _dragOrigEndMs = seg.endMs;
        return;
      }
      if ((tapX - segEndX).abs() < _edgeHitZone) {
        _dragMode = _DragMode.resizeEnd;
        _dragSegmentId = seg.id;
        _dragOrigStartMs = seg.startMs;
        _dragOrigEndMs = seg.endMs;
        return;
      }
      if (tapX > segStartX && tapX < segEndX) {
        _dragMode = _DragMode.move;
        _dragSegmentId = seg.id;
        _dragOrigStartMs = seg.startMs;
        _dragOrigEndMs = seg.endMs;
        return;
      }
    }

    _dragMode = _DragMode.scrub;
    ref.read(playbackProvider.notifier).seekTo(tapMs);
  }

  void _onDragUpdate(DragUpdateDetails details, double totalWidth, int durationMs) {
    final localX = details.localPosition.dx + _scrollController.offset;
    final ms = _xToMs(localX, durationMs);

    if (_dragMode == _DragMode.scrub) {
      ref.read(playbackProvider.notifier).seekTo(ms);
      return;
    }

    if (_dragSegmentId == null) return;
    final captions = ref.read(captionProvider);
    final seg = captions.where((s) => s.id == _dragSegmentId).firstOrNull;
    if (seg == null) return;

    switch (_dragMode) {
      case _DragMode.resizeStart:
        final newStart = ms.clamp(0, seg.endMs - 100);
        ref.read(captionProvider.notifier).updateSegment(
          seg.copyWith(startMs: newStart),
        );
        break;
      case _DragMode.resizeEnd:
        final newEnd = ms.clamp(seg.startMs + 100, durationMs);
        ref.read(captionProvider.notifier).updateSegment(
          seg.copyWith(endMs: newEnd),
        );
        break;
      case _DragMode.move:
        if (_dragOrigStartMs == null || _dragOrigEndMs == null) return;
        final segDur = _dragOrigEndMs! - _dragOrigStartMs!;
        final midMs = _xToMs(localX, durationMs);
        var newStart = midMs - segDur ~/ 2;
        newStart = newStart.clamp(0, durationMs - segDur);
        ref.read(captionProvider.notifier).updateSegment(
          seg.copyWith(startMs: newStart, endMs: newStart + segDur),
        );
        break;
      default:
        break;
    }
  }

  void _onDragEnd() {
    if (_dragSegmentId != null && _dragMode != _DragMode.scrub && _dragMode != _DragMode.none) {
      final captions = ref.read(captionProvider);
      final seg = captions.where((s) => s.id == _dragSegmentId).firstOrNull;

      if (seg != null && _dragOrigStartMs != null && _dragOrigEndMs != null) {
        if (seg.startMs != _dragOrigStartMs || seg.endMs != _dragOrigEndMs) {
          if (_dragMode == _DragMode.move) {
            final delta = seg.startMs - _dragOrigStartMs!;
            ref.read(captionProvider.notifier).updateSegment(
              seg.copyWith(startMs: _dragOrigStartMs!, endMs: _dragOrigEndMs!),
            );
            ref.read(historyProvider.notifier).execute(
              MoveSegmentCommand(
                segmentId: seg.id,
                deltaMs: delta,
                mutate: ref.read(captionProvider.notifier).applyMutation,
              ),
            );
          } else {
            final newStart = seg.startMs;
            final newEnd = seg.endMs;
            ref.read(captionProvider.notifier).updateSegment(
              seg.copyWith(startMs: _dragOrigStartMs!, endMs: _dragOrigEndMs!),
            );
            ref.read(historyProvider.notifier).execute(
              ResizeSegmentCommand(
                segmentId: seg.id,
                oldStartMs: _dragOrigStartMs!,
                oldEndMs: _dragOrigEndMs!,
                newStartMs: newStart,
                newEndMs: newEnd,
                mutate: ref.read(captionProvider.notifier).applyMutation,
              ),
            );
          }
        }
      }
    }

    _dragMode = _DragMode.none;
    _dragSegmentId = null;
    _dragOrigStartMs = null;
    _dragOrigEndMs = null;
  }
}

enum _DragMode { none, scrub, resizeStart, resizeEnd, move }

class _TimelinePainter extends CustomPainter {
  final List<CaptionSegment> captions;
  final int positionMs;
  final int durationMs;

  _TimelinePainter({
    required this.captions,
    required this.positionMs,
    required this.durationMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.surface2;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (durationMs <= 0) return;

    _drawTimeTicks(canvas, size);
    _drawCaptionBars(canvas, size);
    _drawPlayhead(canvas, size);
  }

  void _drawTimeTicks(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    const intervalMs = 5000;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int ms = 0; ms <= durationMs; ms += intervalMs) {
      final x = (ms / durationMs) * size.width;
      canvas.drawLine(Offset(x, size.height - 12), Offset(x, size.height), tickPaint);

      textPainter.text = TextSpan(
        text: TimeFormatter.formatMsShort(ms),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 2, size.height - 12));
    }
  }

  void _drawCaptionBars(Canvas canvas, Size size) {
    final barHeight = size.height - 20;
    const barTop = 4.0;

    final sorted = List<CaptionSegment>.from(captions)
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    for (var i = 0; i < sorted.length; i++) {
      final seg = sorted[i];
      final x1 = (seg.startMs / durationMs) * size.width;
      final x2 = (seg.endMs / durationMs) * size.width;
      final barWidth = math.max(x2 - x1, 2.0);

      bool overlaps = false;
      if (i > 0 && sorted[i - 1].endMs > seg.startMs) overlaps = true;
      if (i < sorted.length - 1 && seg.endMs > sorted[i + 1].startMs) overlaps = true;

      final fillColor = overlaps
          ? const Color(0x80FF4D4D)
          : AppColors.accentDim;

      final fillPaint = Paint()..color = fillColor;
      final borderPaint = Paint()
        ..color = overlaps ? AppColors.danger : AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x1, barTop, barWidth, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, borderPaint);
    }
  }

  void _drawPlayhead(Canvas canvas, Size size) {
    final x = (positionMs / durationMs) * size.width;
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2;

    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    canvas.drawCircle(Offset(x, 3), 4, paint);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) {
    return old.positionMs != positionMs ||
        old.durationMs != durationMs ||
        old.captions != captions;
  }
}
