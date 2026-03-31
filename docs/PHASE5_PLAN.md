# Phase 5 — Export

**Goal**: Users can export captions as SRT/VTT subtitle files, or burn captions directly into the video as an MP4. Requires the ASS subtitle builder, export service, export provider, and export UI sheet.

---

## 1. ASS Builder

- [x] Implement `lib/core/utils/ass_builder.dart` — `buildAss(Project project) → String`:
  - Outputs valid ASS subtitle file with `[Script Info]`, `[V4+ Styles]`, `[Events]` sections
  - Style block: global style named "Default"; each segment with a style override gets "Override_{segmentId}"
  - Map `CaptionStyle` fields to ASS style properties: fontFamily → Fontname, fontSize → Fontsize, fontColor → PrimaryColour (ASS `&HAABBGGRR` format), bgColor → BackColour, bold/italic → Bold/Italic flags, hAlignment+verticalPosition → `Alignment` (ASS numpad convention: `\an1`–`\an9`)
  - Events block: one `Dialogue` line per `CaptionSegment`, times in `H:MM:SS.cc` (centiseconds)
  - Animation encoding in ASS override tags:
    - `AnimPreset.fade` → `{\fad(150,150)}`
    - `AnimPreset.pop` → `{\t(\fscx110\fscy110)\t(\fscx100\fscy100)}`
    - `AnimPreset.slideUp` → `{\move(x,y+50,x,y,0,200)}`
    - `AnimPreset.karaoke` → `{\k{duration_cs}}` before each word
    - `AnimPreset.wordByWord` → `{\alpha&HFF&}\t({start},{end},\alpha&H00&)` per word
  - `verticalOffset` applied via `{\pos(x,y)}` override tag

## 2. Export Service

- [x] Implement `lib/core/services/export_service.dart`:
  - `exportSrt(Project) → Future<File>` — iterates captions, formats as SRT (index, `HH:MM:SS,mmm --> HH:MM:SS,mmm`, text), writes to temp file
  - `exportVtt(Project) → Future<File>` — same but WebVTT format (`WEBVTT` header, `HH:MM:SS.mmm --> HH:MM:SS.mmm`)
  - `exportBurnedVideo(Project, ExportQuality, onProgress) → Future<File>`:
    1. Build ASS string via `AssBuilder.buildAss()`
    2. Write ASS to temp file
    3. Determine scale filter from `ExportQuality` enum: `.p720` → `scale=1280:720`, `.p1080` → `scale=1920:1080`, `.original` → no scale
    4. Build FFmpeg command: `ffmpeg -i {videoPath} -vf "ass={assPath}" -c:a copy -movflags +faststart {outputPath}` (prepend `scale=W:H,` before `ass=` if not original)
    5. Execute via `FFmpegKit.executeAsync()`, parse progress from statistics callback
    6. Return output File, cleanup temp ASS file
  - `checkFreeStorage(int requiredBytes) → Future<bool>` — verify available space before export
  - `enum ExportQuality { p720, p1080, original }`

## 3. Export Provider

- [x] Implement `lib/core/providers/export_provider.dart`:
  - `ExportState`: status (`ExportStatus`), progress (0.0–1.0), outputPath, errorMessage
  - `enum ExportStatus { idle, exporting, done, error }`
  - `ExportNotifier` (StateNotifierProvider): `exportSrt(Project)`, `exportVtt(Project)`, `exportBurnedVideo(Project, ExportQuality)`, `reset()`
  - Each export method: sets status to exporting, calls service, updates progress, sets done/error on completion

## 4. Export Sheet UI

- [x] Implement `lib/features/export/export_sheet.dart` — `ConsumerStatefulWidget`, opens via `showModalBottomSheet`:
  - Format selector: segmented control — "SRT" | "VTT" | "Video (MP4)"
  - If Video selected: quality chips — "720p" | "1080p" | "Original"
  - Overlap warning: if `project.hasOverlaps` → yellow warning banner "Some captions overlap. Fix before exporting."
  - "Export" filled button (CCButton) → calls provider method based on selection
  - During export: `LinearProgressIndicator` (accent) + progress percent + "Exporting…" text + cancel button
  - On done: "Export complete!" + two buttons: "Share" (calls `share_plus` SharePlus) + "Save to Gallery" (copy to Downloads/gallery)
  - On error: error message + "Try Again" button

## 5. Wire Export to Editor

- [x] Update `lib/features/editor/editor_screen.dart` — Export button in AppBar opens `ExportSheet.show(context)` instead of empty callback

## 6. Verification

- [x] Run `flutter analyze` — zero errors, zero warnings
- [ ] Export SRT produces valid `.srt` file with correct timestamps and text *(requires device/emulator)*
- [ ] Export VTT produces valid `.vtt` file *(requires device/emulator)*
- [ ] Export burned video produces playable MP4 with styled captions *(requires device with FFmpeg)*

---

**Phase 5 is complete.** All code tasks done. Device-level testing deferred until emulator/device is connected.
