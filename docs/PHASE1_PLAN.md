# Phase 1 — Foundation & Theme

**Goal**: Project boots, theme applied, navigation skeleton in place, data models generated.

---

## 1. Project Bootstrap

- [x] Run `flutter create --org com.captioncraft --project-name captioncraft captioncraft`
- [x] Replace `pubspec.yaml` with exact dependencies from agent spec
- [x] Create full directory structure under `lib/` (all folders and empty files)
- [x] Create `assets/models/` and `assets/fonts/` directories
- [ ] Download and place `ggml-tiny.bin` whisper model in `assets/models/` *(deferred — 40MB model, will download in Phase 3)*
- [x] Download and place all 8 bundled caption fonts in `assets/fonts/`
- [x] Register assets and fonts in `pubspec.yaml`
- [x] Run `flutter pub get` — confirm no dependency errors

## 2. Data Models

- [x] Implement `lib/core/models/anim_preset.dart` — `AnimPreset` enum
- [x] Implement `lib/core/models/caption_style.dart` — freezed model with `BgShape`, `VPos`, `HAlign` enums
- [x] Implement `lib/core/models/caption_segment.dart` — freezed model with computed getters
- [x] Implement `lib/core/models/project.dart` — freezed model with `hasOverlaps` getter
- [x] Run `dart run build_runner build --delete-conflicting-outputs`
- [x] Confirm all `.g.dart` and `.freezed.dart` files generate without errors

## 3. Theme

- [x] Implement `lib/shared/theme/app_colors.dart` — `AppColors` abstract final class with all color tokens
- [x] Implement `lib/shared/theme/app_typography.dart` — `AppTypography` abstract final class with Space Mono + DM Sans styles
- [x] Implement `lib/shared/theme/app_theme.dart` — dark `ThemeData` using colors and typography above

## 4. Navigation & App Shell

- [x] Implement `lib/app.dart` — `MaterialApp.router` with go_router, three routes (`/`, `/processing`, `/editor/:projectId`)
- [x] Implement `lib/main.dart` — `ProviderScope` wrapping the app
- [x] Create stub screens for `HomeScreen`, `ProcessingScreen`, `EditorScreen` (placeholder text only, enough to verify routing)

## 5. Android & iOS Configuration

- [x] Set `minSdkVersion 24` and `targetSdkVersion 34` in `android/app/build.gradle`
- [x] Add storage/media permissions to `AndroidManifest.xml`
- [x] Add photo library usage descriptions to `ios/Runner/Info.plist`

## 6. Verification

- [x] Run `flutter analyze` — zero errors, zero warnings
- [ ] Run `flutter run` — app launches, shows home stub screen with no errors *(requires connected device/emulator)*
- [ ] Confirm navigation to `/processing` and `/editor/test` routes works *(requires connected device/emulator)*

---

**Phase 1 is complete.** All code tasks done. Device-level testing deferred until emulator/device is connected.
