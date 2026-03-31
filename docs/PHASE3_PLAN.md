# Phase 3 — Transcription Pipeline

**Goal**: After video selected, transcribe it locally using Whisper. For now, Whisper FFI is mocked with sample segments so the full flow works end-to-end. Real native integration comes when building on a physical device.

---

## 1. FFmpeg Service

- [ ] Implement `lib/core/services/ffmpeg_service.dart` — wrapper around ffmpeg_kit: extractAudio (video → 16kHz WAV mono), with kIsWeb guard returning early

## 2. Transcription Service (mocked Whisper)

- [ ] Implement `lib/core/services/transcription_service.dart` — `RawSegment` class (startMs, endMs, text), `TranscriptionService.transcribe()` method that:
  - On mobile: extracts audio via FFmpeg, then runs mocked Whisper (Future.delayed returning sample segments) — marked with TODO for real whisper.cpp FFI
  - On web: returns sample segments directly for preview
  - Reports progress via `onProgress(double)` callback at each step milestone

## 3. Segment Grouper

- [ ] Implement `lib/core/utils/segment_grouper.dart` — `groupSegments(List<RawSegment>)` → `List<CaptionSegment>`: max 7 words per segment, max 3000ms duration, splits at word boundaries, assigns UUIDs, preserves timing proportionally

## 4. Processing Screen

- [ ] Rewrite `lib/features/processing/processing_screen.dart` — ConsumerStatefulWidget that:
  - Receives videoPath from route extra
  - On mount: starts transcription pipeline
  - Shows: app icon/name, animated status messages by progress range (Preparing audio / Transcribing / Processing segments / Almost done), LinearProgressIndicator, percent text, Cancel button
  - On completion: creates project via ProjectListNotifier, saves captions, navigates to `/editor/:id` (replaceNamed)
  - On cancel: navigates back to home
  - On error: shows error dialog with message + back button

## 5. Verification

- [ ] Run `flutter analyze` — zero errors, zero warnings
- [ ] Run on Chrome — picking a video from home screen navigates to processing screen, shows progress, completes and navigates to editor stub

---

**Phase 3 is complete when all boxes above are checked.**
