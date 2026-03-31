# Phase 4 — Editor Screen

**Goal**: Full caption editing experience — video playback with caption overlay, interactive timeline, editable caption list, per-caption and global styling, undo/redo. This is the most complex phase; widgets are built bottom-up (providers → utilities → shared widgets → editor widgets → screen).

---

## 1. Undo/Redo System

- [ ] Implement `lib/core/utils/undo_redo.dart` — abstract `Command` class with `execute()`, `undo()`, and `String get description`; implement all 9 command classes:
  - `EditTextCommand` — changes segment text
  - `ResizeSegmentCommand` — changes segment startMs/endMs
  - `MoveSegmentCommand` — shifts both startMs and endMs by a delta
  - `AddSegmentCommand` — inserts a new CaptionSegment
  - `DeleteSegmentCommand` — removes a CaptionSegment (stores it for undo)
  - `SplitSegmentCommand` — splits one segment into two at a given ms position
  - `MergeSegmentsCommand` — merges two adjacent segments into one
  - `ChangeStyleCommand` — changes global CaptionStyle (stores old/new)
  - `ChangeGlobalAnimCommand` — changes global AnimPreset (stores old/new)

## 2. Providers

- [ ] Implement `lib/core/providers/history_provider.dart` — `HistoryNotifier` (StateNotifierProvider) with `execute(Command)`, `undo()`, `redo()`; `HistoryState` exposes `canUndo`, `canRedo`; max stack size 100 (drops oldest)
- [ ] Add `CaptionNotifier` to `lib/core/providers/project_provider.dart` — StateNotifierProvider for `List<CaptionSegment>` with methods: `updateSegment`, `addSegment`, `removeSegment`, `replaceAll`, `splitSegment(id, atMs)`, `mergeSegments(id1, id2)`; debounced auto-save (500ms) via ProjectService after every mutation
- [ ] Implement `lib/core/providers/playback_provider.dart` — `PlaybackNotifier` (StateNotifierProvider) with `PlaybackState` (controller, isPlaying, positionMs, durationMs, isInitialized); methods: `initialize(videoPath)`, `play()`, `pause()`, `seekTo(int ms)`, `dispose()`; `currentCaption(List<CaptionSegment>)` returns active segment for current position

## 3. Shared Widgets

- [ ] Implement `lib/shared/widgets/time_input.dart` — displays `HH:mm:ss,mmm` format, tap opens numeric keyboard dialog, validates input (non-negative, within video duration), `onChanged(int ms)` callback
- [ ] Implement `lib/shared/widgets/font_picker.dart` — horizontal scrollable `ListView.builder`, each item 80×60 showing "Aa" in that font + font name below, selected item has accent border + accentDim bg; uses the 8 bundled caption fonts

## 4. Editor Widgets (build order matters — least dependent first)

- [ ] Implement `lib/features/editor/widgets/caption_overlay.dart` — ConsumerWidget; watches playback position + captions, finds active segment, renders styled text (global or override), positioned by verticalPosition + offset; implements animation presets: fade (AnimatedOpacity), slideUp (AnimatedSlide), pop (scale animation), wordByWord (reveal words proportionally), karaoke (highlight current word)
- [ ] Implement `lib/features/editor/widgets/video_preview.dart` — ConsumerWidget; uses chewie wrapping VideoPlayerController, aspect ratio preserved, black bars; `showControls: false` on ChewieController; custom controls: play/pause button, position slider, time text; CaptionOverlay rendered on top via Stack
- [ ] Implement `lib/features/editor/widgets/timeline_strip.dart` — ConsumerStatefulWidget with CustomPainter; 64px height; paints: dark bg, caption bars (accentDim fill, accent border, proportional to time), playhead needle (accent), time ticks every 5s; gestures: tap to seek, horizontal drag to scrub, long-press on bar edge (±12px) to resize → ResizeSegmentCommand, long-press on bar center to move → MoveSegmentCommand; scrollable for long videos
- [ ] Implement `lib/features/editor/widgets/caption_list.dart` — ConsumerWidget; ListView.builder of caption rows (index, text preview truncated 1 line, start→end time formatted, style override indicator dot); active segment highlighted with accentDim bg; toolbar above list: [+ Add], [Split at ↕], [Merge] icon buttons triggering respective commands
- [ ] Implement `lib/features/editor/widgets/caption_edit_sheet.dart` — modal bottom sheet (isScrollControlled); receives CaptionSegment; contains: multiline text field (max 4 lines, debounced 400ms → EditTextCommand), start/end time rows with TimeInput + ±1s buttons, duration display, style override toggle + style fields when on, AnimPreset chip row, "Delete segment" danger button with confirm dialog; all changes create Commands through HistoryNotifier
- [ ] Implement `lib/features/editor/widgets/global_style_panel.dart` — bottom sheet; all CaptionStyle fields: FontPicker, font size slider (12–72), font/bg color pickers (flutter_colorpicker), bg opacity slider (0–1), bg shape segmented control, vertical position segmented control, vertical offset slider (-200 to +200), h-alignment segmented control, bold/italic toggles, animation chip row; live preview box at top; changes dispatch ChangeStyleCommand (debounced 300ms)

## 5. Editor Screen

- [ ] Rewrite `lib/features/editor/editor_screen.dart` — ConsumerStatefulWidget; on init: load project by id from ProjectService, initialize PlaybackNotifier with videoPath, populate CaptionNotifier with project captions; layout: Column → VideoPreview (flex 4) → TimelineStrip (fixed 64px) → CaptionList (flex 5); AppBar: back button (unsaved changes warning dialog), tappable project name (inline rename), action buttons [Undo] [Redo] [Style] [Export]; undo/redo icons disabled when stack empty (watch HistoryState); keyboard shortcuts: Cmd/Ctrl+Z = undo, Cmd/Ctrl+Shift+Z = redo, Space = play/pause

## 6. Verification

- [ ] Run `flutter analyze` — zero errors, zero warnings
- [ ] Run on device/emulator — editor shows video, captions appear in list, tapping a caption opens edit sheet, undo/redo works, timeline scrubs and seeks, caption overlay renders on video

---

**Phase 4 is complete when all boxes above are checked.**
