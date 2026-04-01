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

### 0a. Whisper Model Asset

- [ ] Download `ggml-tiny.bin` (39MB) from `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin`
- [ ] Place at `assets/models/ggml-tiny.bin`
- [x] Verify it is registered in `pubspec.yaml` under `flutter: assets:` (already declared in Phase 1, but file was deferred)

### 0b. Native Build — Android

- [ ] Copy `whisper.cpp` source files into `android/app/src/main/cpp/`: at minimum `whisper.cpp`, `whisper.h`, and the required ggml sources (`ggml.c`, `ggml.h`, `ggml-alloc.c`, `ggml-alloc.h`, `ggml-backend.c`, `ggml-backend.h`, etc.) from the whisper.cpp repo
- [x] Create `android/app/src/main/cpp/CMakeLists.txt`:
  - Build a shared library `libwhisper.so`
  - Compile all ggml + whisper C/C++ sources
  - Link `-lm -llog`
  - Set appropriate C/C++ standard flags (`-std=c11` / `-std=c++17`)
  - Enable optimizations (`-O3 -DNDEBUG`) for release
- [x] Register the CMake build in `android/app/build.gradle.kts`:
  ```kotlin
  externalNativeBuild {
      cmake {
          path = file("src/main/cpp/CMakeLists.txt")
      }
  }
  ```

### 0c. Native Build — iOS

- [ ] Add whisper.cpp source files to the Xcode project under `ios/Runner/`
- [ ] Configure as a static library linked into the Runner target
- [ ] Ensure the C/C++ sources compile under iOS (arm64)
- [ ] Note: if iOS signing is unavailable, this step can be deferred; the Android build is primary

### 0d. Dart FFI Bindings

Split into `whisper_binding.dart` (native) and `whisper_binding_stub.dart` (web) with conditional import:

- [x] `whisper_binding.dart`: full `WhisperBinding` class with `dart:ffi` + `package:ffi` — all 8 FFI function bindings, `DynamicLibrary` loading (Android `.so` / iOS `.process()`), `runWhisperInIsolate()` with `Isolate.spawn`
- [x] `whisper_binding_stub.dart`: throws `UnsupportedError` on web
- [x] `transcription_service.dart`: conditional import via `import 'whisper_binding.dart' if (dart.library.html) 'whisper_binding_stub.dart'`

### 0e. Transcription Pipeline (replace mock)

- [x] On mobile: copies `ggml-tiny.bin` from assets to app documents dir, extracts audio via FFmpeg, runs `runWhisperInIsolate()` which parses WAV → `Float32List`, calls `whisper_full()`, extracts segments
- [x] On web: falls back to `_runMocked()` with sample segments
- [x] Runs Whisper inference in `Isolate` to avoid blocking UI
- [x] Progress reporting: 0.0–0.1 = audio extraction, 0.1–0.9 = whisper inference, 0.9–1.0 = cleanup

### 0f. Verification

- [ ] Build and run on Android emulator or device — pick a video with speech, transcription produces real caption text matching the audio *(requires whisper.cpp source files + ggml-tiny.bin)*
- [x] Progress indicator shows during transcription
- [ ] Short videos (< 30s) complete in reasonable time with tiny model *(requires device)*

---

## 0g. Fix Video Export "code null" Bug

- [x] Replaced `executeAsync` + immediate `getReturnCode()` with `Completer<ReturnCode?>` pattern — completion callback resolves the future, then we await it before checking the return code
- [x] Statistics callback for progress reporting preserved
- [x] Handles null returnCode (FFmpeg killed/crashed) with clear error message

---

## 1. ProcessingScreen Error States

- [x] **No audio track**: catches `FFmpegException` from audio extraction, shows dialog "No audio track found." with "Go Back" and "Add captions manually" buttons
- [x] **Zero segments**: detects empty `groupSegments()` result, shows dialog "Couldn't detect speech." with "Go Back" and "Continue with empty captions" buttons
- [x] Shared helper `_createEmptyProjectAndNavigate()` avoids duplication

## 2. EditorScreen — Video File Not Found

- [x] In `_initProject()`, checks `File(videoPath).existsSync()` (with `kIsWeb` guard)
- [x] If missing, shows full-screen error: `videocam_off` icon, "Video not found" title, "Re-link Video" button (opens file picker, updates path, retries init), "Go Back" button

## 3. ExportSheet — Low Storage Warning

- [x] Checks temp dir accessibility on sheet open (skips on web)
- [x] Shows yellow warning banner "Low storage: {available}MB free. Export may fail." if check fails

## 4. Auto-Save Indicator

- [x] `SaveStatus` enum (`idle`, `saving`, `saved`) + `saveStatusProvider` in `project_provider.dart`
- [x] `CaptionNotifier._scheduleSave()` sets `saving`; `_persistToProject()` sets `saved`; resets to `idle` after 2s
- [x] Editor AppBar shows subtle "Saving…" / "Saved" subtitle text below project name

## 5. Undo/Redo SnackBar Feedback

- [x] `ref.listen<HistoryState>` in editor build method
- [x] Shows floating `SnackBar` with command description (e.g. "Undone: Edit text")
- [x] Duration: 1.5s, `SnackBarBehavior.floating`, `AppColors.surface3` background

## 6. Verification

- [x] Run `flutter analyze` — zero errors, zero warnings (only pre-existing info-level hints)
- [x] Run `flutter run -d chrome` — app compiles and launches successfully
- [ ] ProcessingScreen: simulating no-audio error shows dialog with "Add captions manually" option *(requires device/emulator)*
- [ ] ProcessingScreen: simulating 0 segments shows dialog with "Continue with empty captions" *(requires device/emulator)*
- [ ] EditorScreen: loading project with invalid videoPath shows "Re-link Video" error screen *(requires device/emulator)*
- [ ] Undo/redo actions show brief snackbar with command name *(requires device/emulator)*
- [ ] Auto-save indicator appears briefly after editing a caption *(requires device/emulator)*

---

**Phase 6 code is complete.** Remaining unchecked items require either manual file downloads (whisper.cpp sources + ggml-tiny.bin model) or physical device testing.
