# Phase 2 — Home Screen

**Goal**: Users see recent projects and can start a new one.

---

## 1. Services & Utilities

- [x] Implement `lib/core/services/project_service.dart` — full CRUD: loadAllProjects (sorted by updatedAt DESC, limit 20), saveProject, loadProject, deleteProject, getProjectsDir
- [x] Implement `lib/core/utils/time_formatter.dart` — formatMs (`HH:mm:ss,mmm`), parseMs (reverse), formatMsShort (`m:ss` for timeline)

## 2. Providers

- [x] Implement `lib/core/providers/project_provider.dart` — `ProjectListNotifier` (StateNotifierProvider) with createProject, deleteProject, refreshList; loads project list on init

## 3. Shared Widgets

- [x] Implement `lib/shared/widgets/cc_button.dart` — CCButton with 3 variants: filled (accent bg), outlined (accent border), danger (red); all 48px min height, DM Sans medium
- [x] Implement `lib/shared/widgets/cc_bottom_sheet.dart` — reusable bottom sheet wrapper: 4x40px drag handle, surface2 bg, rounded top corners, optional title

## 4. Home Screen UI

- [x] Rewrite `lib/features/home/home_screen.dart` — ConsumerStatefulWidget, watches project list provider with AsyncValue.when (loading/error/data), FAB opens file picker (mp4, mov, mkv, webm) then navigates to `/processing`
- [x] Implement `lib/features/home/widgets/empty_home_state.dart` — centered column: subtitles icon, "No projects yet", subtitle text, "Import Video" outlined button
- [x] Implement `lib/features/home/widgets/project_card.dart` — 80px horizontal card: video thumbnail placeholder, project name, duration + relative date, tap navigates to editor, long press shows delete confirmation dialog

## 5. Verification

- [x] Run `flutter analyze` — zero errors, zero warnings
- [x] Run on Chrome — empty state shows, tapping "New Project" opens file picker

---

**Phase 2 is complete.**
