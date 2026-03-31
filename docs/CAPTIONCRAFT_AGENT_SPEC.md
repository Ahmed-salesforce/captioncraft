# CaptionCraft — AI Coding Agent Build Specification
> READ THIS ENTIRE FILE BEFORE WRITING A SINGLE LINE OF CODE.
> This spec is authoritative. When in doubt, re-read this file. Do not infer or improvise.

---

## AGENT RULES (Non-Negotiable)

1. **Complete each task fully before moving to the next.** Do not leave TODOs or stubs unless the task explicitly says "stub only."
2. **Follow the exact file paths and class names** defined in this spec. Renaming breaks references.
3. **Do not add features not listed here.** Scope is fixed for v1.0.
4. **All dependencies must use the exact versions listed.** Do not upgrade or swap packages.
5. **Every provider, service, and model must be fully implemented** — no placeholder returns.
6. **After completing each Phase, run `flutter analyze` and fix ALL warnings/errors before proceeding.**
7. **Do not split files differently than the structure defined here.** One feature = one file unless spec says otherwise.
8. **When implementing FFI or platform channels, test the binding compiles before wiring UI.**

---

## PROJECT BOOTSTRAP

### App Identity
```
App name:        CaptionCraft
Package name:    com.captioncraft.app
Flutter version: 3.22.x (stable channel)
Dart version:    3.4.x
```

### Create Project
```bash
flutter create --org com.captioncraft --project-name captioncraft captioncraft
cd captioncraft
```

---

## DEPENDENCIES (pubspec.yaml — exact versions)

```yaml
name: captioncraft
description: Offline-first video captioning app
publish_to: none
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  hooks_riverpod: ^2.5.1
  flutter_hooks: ^0.20.5
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.7

  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.3

  # Video
  video_player: ^2.9.1
  chewie: ^1.8.3

  # FFmpeg
  ffmpeg_kit_flutter_new: ^4.1.0

  # File picking
  file_picker: ^8.1.2

  # UI
  flutter_colorpicker: ^1.1.0
  google_fonts: ^6.2.1

  # Utilities
  uuid: ^4.4.0
  json_annotation: ^4.9.0
  freezed_annotation: ^2.4.0
  permission_handler: ^11.3.1
  share_plus: ^10.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  hive_generator: ^2.0.1
  mockito: ^5.4.4
```

---

## FILE STRUCTURE (create exactly this, no additions, no omissions)

```
lib/
  main.dart
  app.dart

  core/
    models/
      caption_segment.dart
      caption_style.dart
      anim_preset.dart
      project.dart
    providers/
      project_provider.dart
      playback_provider.dart
      export_provider.dart
      history_provider.dart
    services/
      transcription_service.dart
      ffmpeg_service.dart
      project_service.dart
      export_service.dart
    utils/
      time_formatter.dart
      ass_builder.dart
      undo_redo.dart
      segment_grouper.dart

  features/
    home/
      home_screen.dart
      widgets/
        project_card.dart
        empty_home_state.dart
    processing/
      processing_screen.dart
    editor/
      editor_screen.dart
      widgets/
        video_preview.dart
        timeline_strip.dart
        caption_list.dart
        caption_edit_sheet.dart
        global_style_panel.dart
        caption_overlay.dart
    export/
      export_sheet.dart

  shared/
    widgets/
      cc_button.dart
      cc_bottom_sheet.dart
      font_picker.dart
      time_input.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_typography.dart

assets/
  models/
    ggml-tiny.bin         # Whisper tiny model (download separately — see Phase 1)
  fonts/
    Anton-Regular.ttf
    Oswald-Regular.ttf
    BebasNeue-Regular.ttf
    Montserrat-Regular.ttf
    Pacifico-Regular.ttf
    RobotoSlab-Regular.ttf
    Inter-Regular.ttf
    PlayfairDisplay-Regular.ttf
```

---

## DATA MODELS (implement first, everything depends on these)

### `lib/core/models/anim_preset.dart`
```dart
enum AnimPreset {
  none,
  fade,
  pop,
  slideUp,
  wordByWord,
  karaoke,
}
```

### `lib/core/models/caption_style.dart`
```dart
// Use freezed + json_serializable
// Fields (all required, all have defaults):
//   fontFamily: String           default: 'Montserrat'
//   fontSize: double             default: 24.0
//   fontColor: int               default: 0xFFFFFFFF  (store Color as ARGB int)
//   bgColor: int                 default: 0x99000000
//   bgShape: BgShape             default: BgShape.roundedRect
//   verticalPosition: VPos       default: VPos.bottom
//   verticalOffset: double       default: 0.0
//   hAlignment: HAlign           default: HAlign.center
//   bold: bool                   default: false
//   italic: bool                 default: false
//
// Also define:
//   enum BgShape { none, roundedRect, fullBar }
//   enum VPos { top, center, bottom }
//   enum HAlign { left, center, right }
//
// Generate: copyWith, toJson, fromJson via freezed
```

### `lib/core/models/caption_segment.dart`
```dart
// Use freezed + json_serializable
// Fields:
//   id: String                   (UUID)
//   startMs: int
//   endMs: int
//   text: String
//   styleOverride: CaptionStyle? (null = use global)
//   animPreset: AnimPreset?      (null = use global)
//
// Computed (NOT serialized, add as getter):
//   bool get hasStyleOverride => styleOverride != null;
//   Duration get duration => Duration(milliseconds: endMs - startMs);
```

### `lib/core/models/project.dart`
```dart
// Use freezed + json_serializable
// Fields:
//   id: String                   (UUID)
//   name: String
//   videoPath: String
//   videoDurationMs: int
//   createdAt: DateTime
//   updatedAt: DateTime
//   globalStyle: CaptionStyle
//   globalAnim: AnimPreset
//   captions: List<CaptionSegment>
//
// Computed (NOT serialized):
//   bool get hasOverlaps — check if any two segments overlap in time
```

---

## PHASE 1 — Foundation & Theme

**Goal**: Project boots, theme applied, navigation skeleton in place.

### Tasks

**1.1 Theme (`lib/shared/theme/`)**

`app_colors.dart` — define as `abstract final class AppColors`:
```dart
static const surface    = Color(0xFF0F0F0F);
static const surface2   = Color(0xFF1A1A1A);
static const surface3   = Color(0xFF242424);
static const accent     = Color(0xFFFFDD57);
static const accentDim  = Color(0x40FFDD57);
static const textPrimary   = Color(0xFFFFFFFF);
static const textSecondary = Color(0xFF888888);
static const danger     = Color(0xFFFF4D4D);
static const border     = Color(0xFF2E2E2E);
```

`app_typography.dart` — define `abstract final class AppTypography`:
- Use `google_fonts` package
- `displayFont` → `GoogleFonts.spaceMono()`
- `bodyFont` → `GoogleFonts.dmSans()`
- Define text styles: `display`, `title`, `body`, `caption`, `label`, `mono`

`app_theme.dart`:
- `ThemeData dark()` — uses colors above, sets `scaffoldBackgroundColor`, `colorScheme`, `textTheme`, `appBarTheme`, `bottomSheetTheme`, `filledButtonTheme`
- Dark theme only. No light theme.

**1.2 Navigation (`lib/app.dart`)**

Use `go_router`. Define routes:
```
/                    → HomeScreen
/processing          → ProcessingScreen  (extra: {videoPath: String})
/editor/:projectId   → EditorScreen
```
Wrap app in `ProviderScope` in `main.dart`.

**1.3 Generate code**
```bash
dart run build_runner build --delete-conflicting-outputs
```
After model code generation, confirm `fromJson`/`toJson` compile with no errors.

**1.4 Whisper model asset**
- Download `ggml-tiny.bin` from: `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin`
- Place at `assets/models/ggml-tiny.bin`
- Register in `pubspec.yaml` under `flutter: assets:`
- Also register all fonts under `flutter: fonts:`

**Completion check**: `flutter run` shows a black screen with no errors. `flutter analyze` is clean.

---

## PHASE 2 — Home Screen

**Goal**: Users see recent projects and can start a new one.

### `lib/core/services/project_service.dart`
```dart
class ProjectService {
  // Directory: getApplicationDocumentsDirectory()/projects/
  // File per project: {id}.captioncraft.json

  Future<List<Project>> loadAllProjects();
  // Sort by updatedAt DESC, limit 20

  Future<void> saveProject(Project project);
  // Write JSON to file; update updatedAt to now

  Future<Project?> loadProject(String id);

  Future<void> deleteProject(String id);
  // Delete file

  Future<String> getProjectsDir();
}
```

### `lib/core/providers/project_provider.dart`
```dart
// StateNotifierProvider<ProjectListNotifier, AsyncValue<List<Project>>>
// ProjectListNotifier:
//   - loads on init
//   - exposes: createProject(videoPath, durationMs), deleteProject(id), refreshList()
//   - createProject: creates new Project with empty captions, saves, returns id
```

### `lib/features/home/home_screen.dart`
- `ConsumerStatefulWidget`
- AppBar: title "CaptionCraft" (SpaceMono font), no back button
- Body: `AsyncValue.when()` on project list provider
  - loading: centered `CircularProgressIndicator` (accent color)
  - error: error text + retry button
  - data empty: `EmptyHomeState` widget
  - data non-empty: `ListView` of `ProjectCard` widgets
- FAB: `FloatingActionButton.extended` label "New Project", icon `Icons.add`
  - onPressed: open file picker (video only: mp4, mov, mkv, webm), then navigate to `/processing` with videoPath

### `lib/features/home/widgets/project_card.dart`
- Shows: video thumbnail (use `video_player` first frame at 0ms), project name, formatted duration, relative date
- Tap: navigate to `/editor/:id`
- Long press: show delete confirmation dialog
- Height: 80px, horizontal layout

### `lib/features/home/widgets/empty_home_state.dart`
- Centered column: icon, "No projects yet", subtitle "Import a video to get started", outlined button "Import Video"

**Completion check**: Can see home screen, empty state shows, tapping "New Project" opens file picker.

---

## PHASE 3 — Transcription Pipeline

**Goal**: After video selected, transcribe it locally using Whisper.

### Whisper FFI Setup

**Android (`android/app/CMakeLists.txt`):**
- Add whisper.cpp source files to CMake build
- Reference: https://github.com/ggerganov/whisper.cpp — copy `whisper.cpp`, `whisper.h`, `ggml.c`, `ggml.h` into `android/app/src/main/cpp/`
- Output: shared library `libwhisper.so`

**iOS:**
- Add whisper.cpp files to Xcode project
- Build as static lib linked into the app

**Dart FFI bindings (`lib/core/services/transcription_service.dart`):**
```dart
// Load native lib:
//   DynamicLibrary.open('libwhisper.so') on Android
//   DynamicLibrary.process() on iOS

// Bind these C functions (use dart:ffi typedefs):
//   whisper_context* whisper_init_from_file(const char* path_model)
//   whisper_full_params whisper_full_default_params(int strategy)
//   int whisper_full(whisper_context* ctx, whisper_full_params params, const float* samples, int n_samples)
//   int whisper_full_n_segments(whisper_context* ctx)
//   const char* whisper_full_get_segment_text(whisper_context* ctx, int i_segment)
//   int64_t whisper_full_get_segment_t0(whisper_context* ctx, int i_segment)
//   int64_t whisper_full_get_segment_t1(whisper_context* ctx, int i_segment)
//   void whisper_free(whisper_context* ctx)

class TranscriptionService {
  // transcribe(videoPath, modelPath, onProgress) → Future<List<RawSegment>>
  // - Run in Isolate via compute() or Isolate.spawn()
  // - Step 1: Extract audio using FFmpeg → temp 16kHz WAV mono
  // - Step 2: Load WAV samples as Float32List
  // - Step 3: Call whisper_full with WHISPER_SAMPLING_GREEDY
  // - Step 4: Iterate segments → build List<RawSegment>
  // - Step 5: Clean up temp WAV, free whisper context
  // - onProgress(double 0.0–1.0): call at each step milestone
  // Returns: List<RawSegment> with startMs, endMs, text

  // RawSegment is a simple class (not freezed): { int startMs, int endMs, String text }
}
```

### `lib/core/utils/segment_grouper.dart`
```dart
// groupSegments(List<RawSegment> raw) → List<CaptionSegment>
// Rules:
//   - Max 7 words per segment
//   - Max 3000ms duration per segment
//   - If a raw segment already fits, use as-is
//   - Split longer segments at word boundaries
//   - Assign new UUID to each result
//   - Preserve timing proportionally when splitting
```

### `lib/features/processing/processing_screen.dart`
- Receives `videoPath` from route extra
- On mount: start transcription via `TranscriptionService`
- Show: video thumbnail (first frame), app name, status message, `LinearProgressIndicator` (accent color), percent text, "Cancel" text button
- Status messages by progress:
  - 0.0–0.1: "Preparing audio…"
  - 0.1–0.7: "Transcribing… this may take a minute"
  - 0.7–0.9: "Processing segments…"
  - 0.9–1.0: "Almost done…"
- On completion: `ProjectService.createProject(videoPath, durationMs)`, save captions, navigate to `/editor/:id` replacing route
- On cancel: stop isolate, delete temp files, go back to home
- On error: show error dialog with message, back button

**Completion check**: Picking a video navigates to processing screen. Screen shows progress. (Whisper integration can be mocked for now with a `Future.delayed` returning sample segments — mark TODO: real Whisper.)

---

## PHASE 4 — Editor Screen

This is the most complex phase. Build widgets bottom-up.

### `lib/core/providers/playback_provider.dart`
```dart
// StateNotifierProvider<PlaybackNotifier, PlaybackState>
// PlaybackState:
//   controller: VideoPlayerController?
//   isPlaying: bool
//   positionMs: int
//   durationMs: int
//   isInitialized: bool

// PlaybackNotifier:
//   initialize(videoPath) — create controller, listen to position updates
//   play(), pause(), seekTo(int ms)
//   dispose()
//   currentCaption(List<CaptionSegment>) → CaptionSegment? 
//     — returns segment where startMs <= positionMs < endMs
```

### `lib/core/providers/history_provider.dart`
```dart
// StateNotifierProvider<HistoryNotifier, HistoryState>
// HistoryState: { canUndo: bool, canRedo: bool }
// HistoryNotifier:
//   execute(Command cmd) — run cmd.execute(), push to undo stack, clear redo stack
//   undo() — pop from undo stack, call cmd.undo(), push to redo
//   redo() — pop from redo stack, call cmd.execute(), push to undo
//   Max stack size: 100 (drop oldest when exceeded)
```

### `lib/core/utils/undo_redo.dart`
```dart
abstract class Command {
  void execute();
  void undo();
}

// Implement ALL of these command classes:
class EditTextCommand implements Command {
  final String segmentId, oldText, newText;
  final CaptionNotifier notifier; // reference to notifier to mutate state
}
class ResizeSegmentCommand implements Command { /* startMs, endMs change */ }
class MoveSegmentCommand implements Command { /* shift both startMs+endMs */ }
class AddSegmentCommand implements Command { /* new CaptionSegment */ }
class DeleteSegmentCommand implements Command { /* deleted CaptionSegment */ }
class SplitSegmentCommand implements Command { /* split at positionMs */ }
class MergeSegmentsCommand implements Command { /* merge two adjacent */ }
class ChangeStyleCommand implements Command { /* old/new CaptionStyle */ }
class ChangeGlobalAnimCommand implements Command { /* old/new AnimPreset */ }
```

### Caption Provider (add to `project_provider.dart`)
```dart
// StateNotifierProvider<CaptionNotifier, List<CaptionSegment>>
// CaptionNotifier:
//   updateSegment(CaptionSegment updated)
//   addSegment(CaptionSegment seg)
//   removeSegment(String id)
//   replaceAll(List<CaptionSegment> segments)
//   splitSegment(String id, int atMs)  // split into two
//   mergeSegments(String id1, String id2)  // merge adjacent (id1 comes first)
//   // After every mutation: auto-save project via ProjectService (debounced 500ms)
```

### `lib/features/editor/widgets/video_preview.dart`
- `ConsumerWidget`
- Uses `chewie` with `ChewieController` wrapping `VideoPlayerController`
- Aspect ratio preserved, black bars on sides
- Shows `CaptionOverlay` on top (Stack)
- Custom controls: only Play/Pause button, position slider, time text
- No chewie default controls (`showControls: false` in ChewieController)

### `lib/features/editor/widgets/caption_overlay.dart`
- `ConsumerWidget`
- Watches playback position + caption list
- Finds active `CaptionSegment` for current position
- Renders caption text with current style (global or override)
- Positioned based on `verticalPosition` + `verticalOffset`
- Implements `AnimPreset.fade` using `AnimatedOpacity`
- Implements `AnimPreset.slideUp` using `AnimatedSlide`
- Other presets (`pop`, `wordByWord`, `karaoke`): implement as basic version — pop = scale animation, wordByWord = reveal words one by one proportionally, karaoke = highlight current word

### `lib/features/editor/widgets/timeline_strip.dart`
- `ConsumerStatefulWidget`
- `CustomPainter` based, wrapped in `GestureDetector`
- Height: 64px
- Paints:
  - Dark background
  - Caption bars (colored rectangles, `accentDim` fill, `accent` border, proportional to segment time/total)
  - Playhead needle (vertical `accent` line at current position)
  - Time ticks every 5s
- Gestures:
  - Tap: seek to tapped position
  - Horizontal drag: scrub playhead
  - Long-press on caption bar edge (within 12px of start or end): drag to resize → creates `ResizeSegmentCommand` on drag end
  - Long-press on caption bar center: drag whole segment → creates `MoveSegmentCommand` on drag end
- Scroll: `InteractiveViewer` or `SingleChildScrollView` for long videos
- DO NOT use FL Chart or any chart library. Pure `CustomPainter` only.

### `lib/features/editor/widgets/caption_list.dart`
- `ConsumerWidget`
- `ListView.builder` of caption rows
- Each row:
  - Index number (monospace)
  - Text preview (truncated 1 line)
  - Start time → End time (formatted `HH:mm:ss,mmm`)
  - Style override indicator dot (if has override)
  - Tap: open `CaptionEditSheet`
- Active segment (matches playback position): highlighted with `accentDim` background
- Toolbar above list: `[+ Add]` `[Split at ↕]` `[Merge]` icon buttons
  - Add: create new segment at current playback position (2s duration), trigger add command
  - Split at: split active segment at current playback position
  - Merge: merge selected segment with the next one

### `lib/features/editor/widgets/caption_edit_sheet.dart`
- Opens as `showModalBottomSheet` with `isScrollControlled: true`
- Receives `CaptionSegment`, dispatches commands via providers
- Contents:
  - Text field (multiline, max 4 lines) — on change: debounced 400ms, then `EditTextCommand`
  - Start time row: label + `TimeInput` widget + "-1s" / "+1s" buttons
  - End time row: label + `TimeInput` widget + "-1s" / "+1s" buttons
  - Duration display (read-only)
  - Divider
  - "Style override" toggle switch
  - If override enabled: show `CaptionStyleFields` (font, size, color, bg)
  - Animation preset: horizontal chip row (all `AnimPreset` values)
  - Danger zone: "Delete segment" red text button → `DeleteSegmentCommand` after confirm dialog
- All changes create and execute Commands through `HistoryNotifier`

### `lib/shared/widgets/time_input.dart`
- Custom widget: displays `HH:mm:ss,mmm` format
- Tap to open numeric keyboard dialog
- Validates input (cannot be negative, cannot exceed video duration)
- `onChanged(int ms)` callback

### `lib/features/editor/widgets/global_style_panel.dart`
- Opens as bottom sheet from editor app bar "Style" button
- Contains all `CaptionStyle` fields:
  - Font family: custom `FontPicker` widget (horizontal scroll of font name previews)
  - Font size: `Slider` (12–72, divisions: 60)
  - Font color: `ColorPicker` from `flutter_colorpicker`
  - BG color: `ColorPicker`
  - BG opacity: `Slider` (0–1)
  - BG shape: segmented control (none / rounded / full bar)
  - Vertical position: segmented control (top / center / bottom)
  - Vertical offset: `Slider` (-200 to +200)
  - H alignment: segmented control (left / center / right)
  - Bold / Italic: toggle buttons
  - Animation: chip row
- Live preview: small text preview box at top of panel
- Changes: immediately dispatch `ChangeStyleCommand` (debounced 300ms)

### `lib/features/editor/editor_screen.dart`
- `ConsumerStatefulWidget`
- On init: load project by id, initialize playback provider
- Layout: `Column` — `VideoPreview` (flex 4) → `TimelineStrip` (fixed 64) → `CaptionList` (flex 5)
- `AppBar`:
  - Back button → if unsaved (check history has changes), show "Discard changes?" dialog
  - Project name: tappable `Text` → inline rename dialog
  - Actions: `[Undo]` `[Redo]` `[Style]` `[Export]`
  - Undo/Redo icons disabled when stack is empty (watch `HistoryState`)
- Keyboard shortcuts (for hardware keyboard): Cmd/Ctrl+Z = undo, Cmd/Ctrl+Shift+Z = redo, Space = play/pause

**Completion check**: Editor shows video, captions appear in list, tapping a caption opens edit sheet, undo/redo works, timeline scrubs.

---

## PHASE 5 — Export

### `lib/core/utils/ass_builder.dart`
```dart
// buildAss(Project project) → String
//
// Output: valid ASS subtitle file string
// Header: [Script Info], [V4+ Styles], [Events]
//
// Style block: One style per unique CaptionStyle used in the project
//   - Global style named "Default"
//   - Each override gets named "Override_{segmentId}"
//
// Events block: One Dialogue line per CaptionSegment
//   Format: Dialogue: 0,{startTime},{endTime},{styleName},,0,0,0,,{assText}
//   Times in H:MM:SS.cc format
//
// AssText encoding:
//   Position: {\an1} bottom-left, {\an2} bottom-center, {\an9} top-center, etc.
//   + {\pos(x,y)} for offset
//   Fade: {\fad(150,150)} for AnimPreset.fade
//   Pop: {\t(\fscx110\fscy110)}\t(\fscx100\fscy100)} scale bounce
//   Karaoke: {\k{duration_cs}} before each word
//   Word-by-word: {\alpha&HFF&}\t({start},{end},\alpha&H00&)} per word
//   SlideUp: {\move(x,y+50,x,y,0,200)}
//
// All timings in centiseconds (1/100 second) as required by ASS format
```

### `lib/core/services/export_service.dart`
```dart
class ExportService {
  // exportSrt(Project project) → Future<File>
  //   Builds SRT format, writes to temp file, returns File
  //
  // exportVtt(Project project) → Future<File>
  //   Builds VTT format, writes to temp file, returns File
  //
  // exportBurnedVideo(Project project, ExportQuality quality, void Function(double) onProgress) → Future<File>
  //   Steps:
  //   1. Build ASS string via AssBuilder
  //   2. Write ASS to temp file
  //   3. Determine output resolution from ExportQuality enum:
  //        ExportQuality.p720  → scale 1280:720
  //        ExportQuality.p1080 → scale 1920:1080
  //        ExportQuality.original → no scale filter
  //   4. Build FFmpeg command:
  //        ffmpeg -i {videoPath} -vf "ass={assPath}" -c:a copy -movflags +faststart {outputPath}
  //        (if quality != original, prepend scale: "scale=W:H,ass={assPath}")
  //   5. Execute via FFmpegKit.executeAsync(), parse progress from statistics
  //   6. On complete: return output File
  //   7. Cleanup temp ASS file
  //
  // checkFreeStorage(int requiredBytes) → Future<bool>
  //   Check available space before export

enum ExportQuality { p720, p1080, original }
}
```

### `lib/core/providers/export_provider.dart`
```dart
// StateNotifierProvider<ExportNotifier, ExportState>
// ExportState:
//   status: ExportStatus (idle | exporting | done | error)
//   progress: double (0.0–1.0)
//   outputPath: String?
//   errorMessage: String?
//
// enum ExportStatus { idle, exporting, done, error }
//
// ExportNotifier:
//   exportSrt(Project)
//   exportVtt(Project)
//   exportBurnedVideo(Project, ExportQuality)
//   reset()
```

### `lib/features/export/export_sheet.dart`
- `ConsumerStatefulWidget`, opens as `showModalBottomSheet`
- Format selector: segmented control — "SRT" | "VTT" | "Video (MP4)"
- If Video selected: quality chips — "720p" | "1080p" | "Original"
- Overlap warning: if `project.hasOverlaps` → show yellow warning banner "Some captions overlap. Fix before exporting."
- "Export" filled button → calls provider based on selection
- During export: `LinearProgressIndicator` + progress percent + "Exporting…" text + cancel button
- On done: show "Export complete!" + two buttons: "Share" (calls `share_plus`) + "Save to Gallery" (uses `ImageGallerySaver` or file copy to Downloads)
- On error: show error message + "Try Again" button

**Completion check**: Export SRT produces valid file, export video produces playable MP4 with captions.

---

## PHASE 6 — Polish & Error Handling

### Error States to Implement

| Location | Condition | UI Response |
|---|---|---|
| ProcessingScreen | No audio track in video | Dialog: "No audio track found." + "Add captions manually" button that skips transcription |
| ProcessingScreen | Transcription produces 0 segments | Dialog: "Couldn't detect speech." + "Continue with empty captions" |
| EditorScreen | Video file not found at path | Full screen error with "Re-link video" button (re-open file picker, update project.videoPath) |
| ExportSheet | Free storage < 500MB | Warning: "Low storage: {available}MB free. Export may fail." |
| ExportSheet | FFmpeg error | Show dialog with first 200 chars of FFmpeg stderr + "Export subtitles only" fallback button |

### Overlap Detection UI
- In `TimelineStrip`: if two bars overlap, color the overlapping zone `danger` (0x80FF4D4D)
- In `CaptionList`: overlapping segments get a `!` icon in their row

### Auto-Save
- After every Command execution, schedule a debounced save (500ms)
- Show subtle "Saving…" / "Saved" text in app bar (bottom of leading area or subtitle)

### Undo/Redo UI Feedback
- Brief `SnackBar` on undo: "Undone: {commandName}"
- Brief `SnackBar` on redo: "Redone: {commandName}"
- Each Command class must have a `String get description` getter for this

---

## PHASE 7 — Testing

### Unit Tests (`test/`)

**`test/core/models/caption_segment_test.dart`**
- Test: `hasStyleOverride` returns false when styleOverride is null
- Test: `duration` returns correct Duration
- Test: `toJson` / `fromJson` round-trip preserves all fields

**`test/core/utils/time_formatter_test.dart`**
- Test: `formatMs(0)` → `"00:00:00,000"`
- Test: `formatMs(3661001)` → `"01:01:01,001"`
- Test: `formatMs(59999)` → `"00:00:59,999"`

**`test/core/utils/ass_builder_test.dart`**
- Test: output contains `[Script Info]`, `[V4+ Styles]`, `[Events]`
- Test: segment with fade produces `\fad` tag
- Test: segment with bottom-center position produces `{\an2}`
- Test: segment times correctly converted to centiseconds

**`test/core/utils/undo_redo_test.dart`**
- Test: execute → undo restores state
- Test: execute → undo → redo re-applies
- Test: stack respects max size (100)

**`test/core/utils/segment_grouper_test.dart`**
- Test: segment under 7 words → single output segment
- Test: segment over 7 words → split at word boundary
- Test: timing preserved proportionally after split

### Widget Tests (`test/features/`)

**`test/features/home/home_screen_test.dart`**
- Test: empty state widget shows when project list is empty
- Test: project cards render when list has items

**`test/features/editor/caption_list_test.dart`**
- Test: correct number of rows rendered for caption count
- Test: tapping row triggers edit sheet

Run with: `flutter test`

---

## SHARED WIDGETS SPEC

### `lib/shared/widgets/cc_button.dart`
- `CCButton` (filled, accent background, dark text)
- `CCButton.outlined` (accent border, transparent fill)
- `CCButton.danger` (red)
- All: 48px height minimum, 16px horizontal padding, DM Sans medium text

### `lib/shared/widgets/cc_bottom_sheet.dart`
- Consistent bottom sheet wrapper
- 4×40px drag handle centered at top
- `surface2` background
- `borderRadius: BorderRadius.vertical(top: Radius.circular(20))`
- Accepts `title` (optional), `child`

### `lib/shared/widgets/font_picker.dart`
- Horizontal `SizedBox` + `ListView.builder` (scroll direction: horizontal)
- Each item: 80×60 `Container`, shows sample text "Aa" in that font, font name below
- Selected: `accent` border 2px, `accentDim` bg
- Uses bundled fonts from assets

### `lib/core/utils/time_formatter.dart`
- `formatMs(int ms) → String` — outputs `HH:mm:ss,mmm`
- `parseMs(String s) → int` — parses the same format
- `formatMsShort(int ms) → String` — outputs `m:ss` for timeline ticks

---

## ANDROID CONFIGURATION

**`android/app/build.gradle`:**
```groovy
android {
  defaultConfig {
    minSdkVersion 24
    targetSdkVersion 34
  }
}
```

**`android/app/src/main/AndroidManifest.xml`** — add permissions:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
```

**CMakeLists.txt** for whisper.cpp — must be configured before Phase 3 tasks are done.

---

## iOS CONFIGURATION

**`ios/Runner/Info.plist`** — add:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>CaptionCraft needs access to your photos to import videos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>CaptionCraft needs permission to save videos to your photo library.</string>
```

---

## BUILD COMMANDS

```bash
# Development
flutter run --debug

# Generate code (run after any model change)
dart run build_runner build --delete-conflicting-outputs

# Analyze (must be clean before each phase completion)
flutter analyze

# Test
flutter test

# Release build
flutter build apk --release --split-per-abi     # Android
flutter build ipa                                # iOS (requires signing)
```

---

## KNOWN CONSTRAINTS & DECISIONS (Do Not Re-Debate)

| Decision | Choice Made | Reason |
|---|---|---|
| State management | Riverpod (not Bloc, not Provider) | Best for this complexity level |
| Local storage | File-based JSON (not Hive, not SQLite) | Projects are large nested objects; JSON is debuggable |
| Transcription | whisper.cpp FFI (not flutter_sound + cloud) | Offline, private |
| Export format | ASS for burned-in (not SRT/FFmpeg drawtext) | ASS supports all required styling |
| Theme | Dark only | Content-focused app; dark reduces eye strain when reviewing video |
| Navigation | go_router (not auto_route, not Navigator 1.0) | Standard, supports deep links |
| Min Android | API 24 | Required by ffmpeg_kit_flutter |
| Caption grouping | Max 7 words OR 3000ms | CapCut default, readable on screen |

---

## DEFINITION OF DONE (per phase)

A phase is complete when:
1. All files listed in that phase exist and are fully implemented (no `// TODO` stubs unless explicitly marked)
2. `flutter analyze` produces zero errors and zero warnings
3. The app runs on a physical device or emulator
4. All tests for that phase pass (`flutter test`)
5. The specific "Completion check" item for that phase passes manually
