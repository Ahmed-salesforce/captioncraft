# Phase 6 — Polish, Error Handling & Real Whisper Integration

**Goal**: Replace the mocked transcription with real on-device Whisper inference via `whisper.cpp` FFI. Harden the app with proper error states for every failure path. Add auto-save indicator and undo/redo snackbar feedback.

---

## Already Implemented (completed early in prior phases)

These items from the agent spec were built proactively during Phases 4–5 and need no further work:

- [x] **Overlap detection in TimelineStrip** — overlapping caption bars already painted with `danger` color (`0x80FF4D4D` fill, red border) in `_drawCaptionBars()` (timeline_strip.dart lines 268–288)
- [x] **Overlap detection in CaptionList** — overlapping segments already show `!` warning icon in `_CaptionRow` (caption_list.dart lines 46–53, 224–229)
- [x] **Command `description` getters** — all 9 command classes already have `String get description` (undo_redo.dart)
- [x] **ExportSheet FFmpeg error** — error state already shows error message (first 200 chars of stderr from ExportException) + "Try Again" + "Export SRT instead" fallback button (export_sheet.dart lines 313–356)

---

## 0. Real Whisper.cpp Integration (replaces mock transcription)

Currently `TranscriptionService.transcribe()` calls `_runMocked()` which returns hardcoded sample segments. This section replaces that with real on-device Whisper inference.

### 0a. Whisper Model Asset

- [ ] Download `ggml-tiny.bin` (39MB) from `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin`
- [ ] Place at `assets/models/ggml-tiny.bin`
- [ ] Verify it is registered in `pubspec.yaml` under `flutter: assets:` (already declared in Phase 1, but file was deferred)

### 0b. Native Build — Android

- [ ] Copy `whisper.cpp` source files into `android/app/src/main/cpp/`: at minimum `whisper.cpp`, `whisper.h`, and the required ggml sources (`ggml.c`, `ggml.h`, `ggml-alloc.c`, `ggml-alloc.h`, `ggml-backend.c`, `ggml-backend.h`, etc.) from the whisper.cpp repo
- [ ] Create `android/app/src/main/cpp/CMakeLists.txt`:
  - Build a shared library `libwhisper.so`
  - Compile all ggml + whisper C/C++ sources
  - Link `-lm -llog`
  - Set appropriate C/C++ standard flags (`-std=c11` / `-std=c++17`)
  - Enable optimizations (`-O3 -DNDEBUG`) for release
- [ ] Register the CMake build in `android/app/build.gradle`:
  ```groovy
  android {
      externalNativeBuild {
          cmake {
              path "src/main/cpp/CMakeLists.txt"
          }
      }
  }
  ```

### 0c. Native Build — iOS

- [ ] Add whisper.cpp source files to the Xcode project under `ios/Runner/`
- [ ] Configure as a static library linked into the Runner target
- [ ] Ensure the C/C++ sources compile under iOS (arm64)
- [ ] Note: if iOS signing is unavailable, this step can be deferred; the Android build is primary

### 0d. Dart FFI Bindings

Update `lib/core/services/transcription_service.dart`:

- [ ] Add `dart:ffi` imports and native function typedefs for:
  - `whisper_init_from_file(const char* path) → Pointer<Void>` (whisper_context*)
  - `whisper_full_default_params(int strategy) → whisper_full_params` (strategy = 0 for GREEDY)
  - `whisper_full(ctx, params, float* samples, int n_samples) → int`
  - `whisper_full_n_segments(ctx) → int`
  - `whisper_full_get_segment_text(ctx, int i) → Pointer<Utf8>`
  - `whisper_full_get_segment_t0(ctx, int i) → int64` (start time in centiseconds × 10)
  - `whisper_full_get_segment_t1(ctx, int i) → int64` (end time)
  - `whisper_free(ctx) → void`
- [ ] Load native library:
  - Android: `DynamicLibrary.open('libwhisper.so')`
  - iOS: `DynamicLibrary.process()` (static linking)
- [ ] Create a `WhisperBinding` class that wraps all FFI lookups

### 0e. Transcription Pipeline (replace mock)

Update `lib/core/services/transcription_service.dart`:

- [ ] Replace `_runMocked()` call with real pipeline:
  1. Copy `ggml-tiny.bin` from assets to app documents dir (first run only, check if already exists)
  2. Extract audio via FFmpeg → 16kHz mono WAV (already done)
  3. Load WAV file → read PCM samples as `Float32List` (parse WAV header, skip to data chunk, convert Int16 samples to float by dividing by 32768.0)
  4. Call `whisper_init_from_file()` with model path
  5. Call `whisper_full()` with `WHISPER_SAMPLING_GREEDY` strategy and the float samples
  6. Iterate segments via `whisper_full_n_segments()` / `whisper_full_get_segment_text()` / `t0` / `t1`
  7. Convert whisper timestamps (centiseconds × 10 = ms) to `RawSegment` list
  8. Call `whisper_free()` to release context
  9. Clean up temp WAV file
- [ ] Run steps 3–8 in an `Isolate` (via `Isolate.run()` or `compute()`) to avoid blocking the UI thread
- [ ] Report progress via `onProgress`: 0.0–0.1 = audio extraction, 0.1–0.8 = whisper inference (estimated), 0.8–0.9 = segment processing, 0.9–1.0 = cleanup
- [ ] Keep `_runMocked()` available behind a `kIsWeb` check (Whisper can't run on web)

### 0f. Verification

- [ ] Build and run on Android emulator or device — pick a video with speech, transcription produces real caption text matching the audio
- [ ] Progress indicator shows during transcription
- [ ] Short videos (< 30s) complete in reasonable time with tiny model

---

## 0g. Fix Video Export "code null" Bug

The burned video export fails immediately with "Video export failed (code null)" because `FFmpegKit.executeAsync()` returns the session before execution completes. Calling `session.getReturnCode()` right after returns `null` since FFmpeg hasn't finished yet.

Update `lib/core/services/export_service.dart`:

- [ ] Replace the current `executeAsync` + immediate `getReturnCode()` pattern with one of:
  - **Option A (preferred)**: Use a `Completer<ReturnCode?>` — pass a completion callback to `executeAsync` that completes the future, then `await` it before checking the return code
  - **Option B**: Switch to `FFmpegKit.execute()` which blocks the Dart isolate until FFmpeg finishes (still runs FFmpeg on a native thread, but the Dart `await` properly waits)
- [ ] Keep the `Statistics` callback for progress reporting (works correctly with both approaches)
- [ ] Handle the case where returnCode is still null after completion (FFmpeg killed/crashed) — throw a clear error message instead of "code null"
- [ ] Verify on device: export a short video → produces a playable MP4

---

## 1. ProcessingScreen Error States

Update `lib/features/processing/processing_screen.dart`:

- [ ] **No audio track**: After `TranscriptionService.transcribe()` throws an FFmpegException (audio extraction fails), detect it and show a dialog: "No audio track found." with two buttons — "Go Back" (returns to home) and "Add captions manually" (creates project with empty captions, navigates to editor)
- [ ] **Zero segments**: After transcription completes but `rawSegments` is empty (or `groupSegments()` returns empty list), show a dialog: "Couldn't detect speech." with two buttons — "Go Back" and "Continue with empty captions" (creates project with empty captions, navigates to editor)
- [ ] Extract the "create project with empty captions and navigate to editor" logic into a shared helper method `_createEmptyProject()` to avoid duplication

## 2. EditorScreen — Video File Not Found

Update `lib/features/editor/editor_screen.dart`:

- [ ] In `_initProject()`, after loading the project, check if the video file exists at `project.videoPath` (use `File(path).existsSync()` with a kIsWeb guard)
- [ ] If the video file is missing, show a full-screen error state (instead of the normal editor) with:
  - Error icon
  - "Video not found" title
  - "The original video file has been moved or deleted." subtitle
  - "Re-link Video" button — opens file picker (video only: mp4, mov, mkv, webm), updates `project.videoPath`, saves via `ProjectService`, then retries `_initProject()`
  - "Go Back" text button — navigates back to home

## 3. ExportSheet — Low Storage Warning

Update `lib/features/export/export_sheet.dart`:

- [ ] Before showing the idle state, check available storage (on mobile only, skip on web)
- [ ] If free storage is below 500 MB, show a yellow warning banner (similar to the existing overlap warning) at the top of the sheet: "Low storage: {available}MB free. Export may fail."
- [ ] Note: `dart:io` `FileStat` doesn't expose free disk space directly; use a best-effort approach — attempt to stat the temp directory and warn if the directory is inaccessible, or use the `path_provider` temp dir combined with a platform-specific approach if feasible. If accurate free-space detection is not possible without a native plugin, show the warning only when temp dir creation fails during export (the error state already handles this)

## 4. Auto-Save Indicator

Update `lib/core/providers/project_provider.dart` and `lib/features/editor/editor_screen.dart`:

- [ ] Add a `saveStatus` field to `CaptionNotifier` (or create a simple `saveStatusProvider`): enum `SaveStatus { idle, saving, saved }` — transitions: `idle → saving` when `_scheduleSave()` fires, `saving → saved` when `_persistToProject()` completes, `saved → idle` after 2 seconds
- [ ] Expose `saveStatusProvider` (StateProvider<SaveStatus>) that `CaptionNotifier` writes to during save lifecycle
- [ ] In `editor_screen.dart` AppBar, watch `saveStatusProvider` and show a subtle subtitle text below the project name:
  - `SaveStatus.saving` → "Saving…" (textSecondary, small font)
  - `SaveStatus.saved` → "Saved" (textSecondary, small font, fades after 2s)
  - `SaveStatus.idle` → nothing shown

## 5. Undo/Redo SnackBar Feedback

Update `lib/features/editor/editor_screen.dart`:

- [ ] Listen to `historyProvider` for `lastAction` changes (use `ref.listen` in `initState` or build)
- [ ] When `historyState.lastAction` is non-null (set by `undo()` / `redo()` in HistoryNotifier), show a brief `SnackBar`:
  - Text: the `lastAction` string (e.g. "Undone: Edit text", "Redone: Move segment")
  - Duration: 1.5 seconds
  - Behavior: `SnackBarBehavior.floating`
  - Background: `AppColors.surface3`
  - No action button needed

## 6. Verification

- [ ] Run `flutter analyze` — zero errors, zero warnings
- [ ] ProcessingScreen: simulating no-audio error shows dialog with "Add captions manually" option *(requires device/emulator)*
- [ ] ProcessingScreen: simulating 0 segments shows dialog with "Continue with empty captions" *(requires device/emulator)*
- [ ] EditorScreen: loading project with invalid videoPath shows "Re-link Video" error screen *(requires device/emulator)*
- [ ] Undo/redo actions show brief snackbar with command name *(requires device/emulator)*
- [ ] Auto-save indicator appears briefly after editing a caption *(requires device/emulator)*

---

**Phase 6 is complete when all boxes above are checked.**
