import 'package:uuid/uuid.dart';

import '../models/caption_segment.dart';
import '../services/transcription_service.dart';

const _uuid = Uuid();
const _maxWords = 7;
const _maxDurationMs = 3000;

/// Groups raw transcription segments into display-ready [CaptionSegment]s.
///
/// Rules:
/// - Max [_maxWords] words per segment
/// - Max [_maxDurationMs] duration per segment
/// - Splits at word boundaries with proportional timing
List<CaptionSegment> groupSegments(List<RawSegment> raw) {
  final result = <CaptionSegment>[];

  for (final seg in raw) {
    final words = seg.text.split(RegExp(r'\s+'));
    if (words.isEmpty) continue;

    final totalMs = seg.endMs - seg.startMs;

    if (words.length <= _maxWords && totalMs <= _maxDurationMs) {
      result.add(CaptionSegment(
        id: _uuid.v4(),
        startMs: seg.startMs,
        endMs: seg.endMs,
        text: seg.text,
      ));
      continue;
    }

    // Split into chunks respecting both word count and duration limits
    final msPerWord = totalMs / words.length;
    var chunkStart = 0;

    while (chunkStart < words.length) {
      var chunkEnd = (chunkStart + _maxWords).clamp(0, words.length);

      // Shrink chunk if it exceeds duration limit
      while (chunkEnd > chunkStart + 1) {
        final chunkWords = chunkEnd - chunkStart;
        final chunkDuration = (msPerWord * chunkWords).round();
        if (chunkDuration <= _maxDurationMs) break;
        chunkEnd--;
      }

      final chunkText = words.sublist(chunkStart, chunkEnd).join(' ');
      final startMs = seg.startMs + (msPerWord * chunkStart).round();
      final endMs = chunkEnd == words.length
          ? seg.endMs
          : seg.startMs + (msPerWord * chunkEnd).round();

      result.add(CaptionSegment(
        id: _uuid.v4(),
        startMs: startMs,
        endMs: endMs,
        text: chunkText,
      ));

      chunkStart = chunkEnd;
    }
  }

  return result;
}
