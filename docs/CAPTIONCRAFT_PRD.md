# CaptionCraft — Product, Design & Technical Document
> Version 1.0 | Mobile-only Flutter App | Offline-first | Captions only

---

## 1. Product Overview

**CaptionCraft** is a mobile-only Flutter application that does one thing exceptionally well: adding captions to videos. No video editing, no filters, no trimming. It takes a video, transcribes it locally (offline), lets users fine-tune every caption, style it beautifully, and exports the result — all without sending a single byte to the cloud.

### 1.1 Problem Statement
Existing captioning tools (CapCut, Premiere, etc.) bundle captions inside massive video editing suites. Users who only need captions must learn heavy tools or rely on cloud AI services that cost money, require internet, and raise privacy concerns. CaptionCraft gives them a dedicated, fast, private, offline-first captioning experience on their phone.

### 1.2 Target Users
- Content creators (YouTube Shorts, TikTok, Reels)
- Accessibility-focused creators who want accurate captions
- Journalists, educators, interviewers
- Anyone who doesn't want to upload videos to a third-party server

### 1.3 Core Value Props
- **Offline-first**: Everything runs on-device. No account, no cloud.
- **Precision timing**: Frame-accurate caption start/end adjustment.
- **Rich styling**: Per-caption or global font, color, size, position, animation presets.
- **Fast auto-transcription**: On-device Whisper model.
- **Non-destructive**: Original video is never modified; captions are a separate layer burned in at export.

---

## 2. Feature Scope

### 2.1 In Scope (v1.0)
| Feature | Description |
|---|---|
| Video import | Pick from gallery or files. Supported: MP4, MOV, MKV, WEBM |
| Auto-transcription | Local Whisper model (tiny/base), word-level timestamps |
| Manual caption editing | Add, delete, split, merge caption segments |
| Timing adjustment | Drag handles on timeline to shift start/end of each caption |
| Global styling | Font family, font size, font color, background color/opacity, text alignment, vertical position (top/center/bottom) |
| Per-caption style override | Override any global style for a single segment |
| Caption animation presets | None, Fade, Pop, Slide-up, Word-by-word reveal, Karaoke highlight |
| SRT / VTT export | Export subtitle file only |
| Burned-in video export | FFmpeg renders captions onto video, output MP4 |
| Project save/load | JSON project files stored locally |
| Undo / Redo | Full history stack for all edit actions |

### 2.2 Out of Scope (v1.0)
- Video trimming or editing
- Multi-track audio
- Cloud sync
- Translation
- Multiple speaker diarization
- In-app social sharing (OS share sheet only)

### 2.3 Future Scope (v2+)
- Multiple language models / faster-whisper
- Speaker labels
- Cloud backup (optional, opt-in)
- Caption templates marketplace

---

## 3. User Flows

### 3.1 Primary Flow: New Project
```
Launch App
  → Home Screen (recent projects + "New Project" button)
  → Pick Video (gallery / files)
  → Processing Screen (transcription progress, local Whisper)
  → Editor Screen (video preview + caption timeline + caption list)
  → [User edits captions, timing, styles]
  → Export Sheet (choose: SRT / VTT / Burned video)
  → Share / Save to gallery
```

### 3.2 Secondary Flow: Load Existing Project
```
Home Screen → Tap recent project card
  → Editor Screen (restored state)
```

### 3.3 Caption Editing Sub-Flow
```
Tap caption segment in timeline OR list
  → Segment highlights + edit drawer opens from bottom
  → Edit text, drag handles for timing, toggle style override
  → Tap elsewhere to dismiss, changes auto-saved to project
```

---

## 4. Screens & UI Design

### 4.1 Home Screen
- List of recent projects (thumbnail, video name, duration, date)
- Prominent "+" FAB or "New Caption Project" button
- Empty state illustration + CTA

### 4.2 Transcription Processing Screen
- Video thumbnail
- Animated progress bar with status text ("Analyzing audio…", "Transcribing…", "Done!")
- Cancel button
- Estimated time display

### 4.3 Editor Screen (Main)
This is the core screen — most time is spent here.

**Layout (portrait):**
```
┌─────────────────────────────┐
│      VIDEO PREVIEW          │  ~35% height
│      [Play/Pause]           │
│      [Current caption shown]│
├─────────────────────────────┤
│      TIMELINE STRIP         │  ~12% height
│ ──[caption bar]──[bar]────  │
│      scrubber needle        │
├─────────────────────────────┤
│    CAPTION LIST / EDITOR    │  ~53% height (scrollable)
│  Each row: text + time code │
│  Active row highlighted     │
│  [+ Add] [Split] [Merge]    │
└─────────────────────────────┘
```

**Bottom Sheet (Caption Edit):**  
Opens when a caption is tapped. Contains:
- Multiline text field
- Start time / End time input (tap to type, or drag on timeline)
- Style override toggle (uses global style by default)
- If override on: font, size, color, bg pickers
- Animation preset selector (chip row)

**Top App Bar:**
- Back (with unsaved changes warning)
- Project name (editable tap)
- Style button → opens Global Style Panel
- Export button

### 4.4 Global Style Panel (Bottom Sheet / Modal)
- Font family picker (bundled fonts: 6–8 curated options)
- Font size slider (12–72pt)
- Font color (color picker + presets)
- Text background color + opacity slider
- Background shape: none / rounded rect / full-width bar
- Vertical position: top / center / bottom + px offset
- Horizontal alignment: left / center / right
- Animation preset (applies to all unless overridden)
- "Apply to all" / "Set as default" buttons

### 4.5 Export Screen (Bottom Sheet)
- Video preview thumbnail
- Format selector: "Subtitle file" (SRT/VTT) | "Burned video" (MP4)
- Quality selector for burned video: 720p / 1080p / Original
- Progress indicator during export
- Done: share sheet or save to gallery

---

## 5. Caption Data Model

### Caption Segment
```
id:           UUID
startMs:      int  (milliseconds)
endMs:        int  (milliseconds)
text:         String
styleOverride: CaptionStyle? (null = use global)
animPreset:   AnimPreset? (null = use global)
```

### Caption Style
```
fontFamily:      String
fontSize:        double
fontColor:       Color (ARGB)
bgColor:         Color (ARGB)
bgShape:         none | roundedRect | fullBar
verticalPos:     top | center | bottom
verticalOffset:  double (px, signed)
hAlignment:      left | center | right
bold:            bool
italic:          bool
```

### Project
```
id:             UUID
name:           String
videoPath:      String (local absolute path)
videoDurationMs: int
createdAt:      DateTime
updatedAt:      DateTime
globalStyle:    CaptionStyle
globalAnim:     AnimPreset
captions:       List<CaptionSegment>
```

---

## 6. Technical Architecture

### 6.1 Tech Stack
| Layer | Choice | Reason |
|---|---|---|
| Framework | Flutter 3.x (Dart) | Cross-platform, single codebase, good FFI |
| State Management | Riverpod (hooks_riverpod) | Scalable, testable, no boilerplate hell |
| Local DB / Storage | Hive 2 | Fast, no-SQL, offline, Flutter-native |
| Video Playback | video_player + chewie | Standard Flutter video |
| Transcription | whisper.cpp via FFI (dart:ffi) | On-device, C library, best quality |
| Video Export | ffmpeg_kit_flutter_new | Community fork of retired ffmpeg_kit, updated bindings |
| File Picking | file_picker | Gallery + files, all platforms |
| Color Picker | flutter_colorpicker | Simple, MIT licensed |
| Font Rendering | google_fonts (bundled subset) | Curated, offline safe |
| Navigation | go_router | Declarative, deep-link ready |
| Undo/Redo | Custom command pattern | Full control |

### 6.2 Transcription Pipeline
```
VideoPath
  → FFmpeg: extract audio → 16kHz WAV mono
  → whisper.cpp (via dart:ffi): transcribe → JSON with word timestamps
  → Parser: group words into sentence-level segments (max 7 words or 3s)
  → List<CaptionSegment>
```

**Whisper model selection:**
- Default: `whisper-tiny` (39MB, fast, ~80% accuracy)
- Optional: `whisper-base` (74MB, better, ~88% accuracy)
- Models bundled in app assets or downloaded on first run (user choice)
- Stored in app documents directory

### 6.3 Export Pipeline

**SRT/VTT:**
- Pure Dart: iterate captions, format timestamps, write file

**Burned video:**
```
captions → generate ASS subtitle string (advanced styling, timing, animations)
  → ffmpeg_kit: ffmpeg -i input.mp4 -vf ass=captions.ass -c:a copy output.mp4
```
ASS format is used (not SRT) for burned-in because it supports:
- Per-line position, color, font, size
- Fade and animation effects via `\fad`, `\t()` tags
- Karaoke `\k` tags for word-by-word highlighting

### 6.4 Project Persistence
- Projects stored as JSON files in `getApplicationDocumentsDirectory()/projects/`
- One file per project: `{uuid}.captioncraft.json`
- Home screen reads metadata from each file header
- Video path stored as absolute path; warn user if video moved

### 6.5 Folder / Module Structure
```
lib/
  main.dart
  app.dart                     # MaterialApp + router setup
  
  core/
    models/                    # CaptionSegment, CaptionStyle, Project, AnimPreset
    providers/                 # Riverpod providers (project, playback, export)
    services/
      transcription_service.dart    # whisper.cpp FFI wrapper
      ffmpeg_service.dart           # ffmpeg_kit wrappers
      project_service.dart          # load/save project JSON
      export_service.dart           # SRT/VTT/ASS generation
    utils/
      time_formatter.dart
      ass_builder.dart
      undo_redo.dart

  features/
    home/
      home_screen.dart
      project_card.dart
    processing/
      processing_screen.dart
    editor/
      editor_screen.dart
      video_preview.dart
      timeline_strip.dart
      caption_list.dart
      caption_edit_sheet.dart
      global_style_panel.dart
    export/
      export_sheet.dart

  shared/
    widgets/                   # Buttons, color pickers, font picker, etc.
    theme/                     # App theme, colors, typography

assets/
  models/
    whisper-tiny.bin           # or downloaded on first run
  fonts/
    [6-8 curated font files]
```

### 6.6 FFI Integration (Whisper)
- Use `whisper.cpp` compiled as a shared library (`.so` on Android, `.dylib` on iOS)
- Dart FFI bindings auto-generated or hand-written for:
  - `whisper_init_from_file()`
  - `whisper_full()` with params
  - `whisper_full_n_segments()`, `whisper_full_get_segment_text()`, `whisper_full_get_segment_t0/t1()`
  - `whisper_free()`
- Run transcription in an `Isolate` to avoid blocking UI

### 6.7 Timeline Strip Widget
- Custom `CustomPainter` implementation
- Displays: audio waveform (pre-computed), caption bars color-coded, playhead needle
- Gesture: horizontal scroll, tap to seek, long-press + drag on caption bar edges to resize timing
- Renders at 60fps; caption bars recalculate on state change

### 6.8 Undo / Redo
- Command pattern: each edit action implements `execute()` / `undo()`
- Stack stored in Riverpod `StateNotifier`
- Commands: `EditTextCommand`, `MoveSegmentCommand`, `ResizeSegmentCommand`, `AddSegmentCommand`, `DeleteSegmentCommand`, `MergeSegmentsCommand`, `SplitSegmentCommand`, `ChangeStyleCommand`
- Max history: 100 actions

---

## 7. Performance Considerations

| Concern | Mitigation |
|---|---|
| Whisper transcription blocks UI | Run in `Isolate`, stream progress via `ReceivePort` |
| FFmpeg export blocks UI | `ffmpeg_kit` runs async with progress callback |
| Large video files | Never load video into memory; use file path for all ops |
| Timeline custom painter | Cache waveform paint, only repaint on scrub/segment change |
| Caption render on video | Overlay widget only (not re-encoding during preview) |
| App size (whisper model) | Offer tiny model bundled; base model optional download |

---

## 8. Permissions

| Platform | Permissions Required |
|---|---|
| Android | `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` (API < 33), `READ_MEDIA_VIDEO` (API 33+) |
| iOS | `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` |

---

## 9. Design System

### Colors
| Token | Value | Usage |
|---|---|---|
| `surface` | `#0F0F0F` | App background |
| `surface2` | `#1A1A1A` | Cards, sheets |
| `accent` | `#FFDD57` | Active states, timeline needle, CTAs |
| `accentDim` | `#FFDD5740` | Caption bar highlight |
| `textPrimary` | `#FFFFFF` | Body text |
| `textSecondary` | `#888888` | Timestamps, labels |
| `danger` | `#FF4D4D` | Delete actions |

### Typography
- Display: `Space Mono` (timestamps, codes, monospace UI)
- Body: `DM Sans` (caption text, labels, general UI)
- Caption preview: user-selected font from bundled set

### Bundled Caption Fonts (8)
`Anton`, `Oswald`, `Bebas Neue`, `Montserrat`, `Pacifico`, `Roboto Slab`, `Inter`, `Playfair Display`

### Spacing
- Base unit: 4px
- Standard padding: 16px
- Sheet handle: 4×40px pill, centered

---

## 10. Error States & Edge Cases

| Scenario | Handling |
|---|---|
| Video has no audio | Show message: "No audio track found." Offer manual-only mode |
| Transcription produces no text | Empty state with option to add captions manually |
| Video moved/deleted after project saved | Warning dialog, offer to re-link video |
| Export fails (FFmpeg error) | Show error with FFmpeg stderr, option to export SRT instead |
| Low storage during export | Check free space before export, warn at <500MB |
| Very long video (>30min) | Warn that transcription may take several minutes; show ETA |
| Overlapping caption segments | Visual warning in timeline (red overlap indicator); prevent export until resolved |

---

## 11. Testing Strategy

| Level | Coverage |
|---|---|
| Unit tests | Models serialization, ASS builder output, time formatter, undo/redo stack |
| Widget tests | Caption list, timeline strip interactions, edit sheet fields |
| Integration tests | Full flow: import → transcribe (mocked) → edit → export SRT |
| Manual QA | Real Whisper transcription on 3 test videos, export validation |

---

## 12. Release & Distribution

- **Platform**: Android (primary), iOS (secondary if signing available)
- **Min SDK**: Android API 24 (Android 7.0), iOS 14
- **Build**: `flutter build apk --release` / `flutter build ipa`
- **Distribution**: APK sideload for testing; Play Store / App Store for release
- **App size target**: <80MB (with tiny Whisper model bundled)
