import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/anim_preset.dart';
import '../models/caption_segment.dart';
import '../models/caption_style.dart';
import '../models/project.dart';
import '../services/project_service.dart';

const _uuid = Uuid();

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

final projectListProvider =
    StateNotifierProvider<ProjectListNotifier, AsyncValue<List<Project>>>(
  (ref) {
    final service = ref.watch(projectServiceProvider);
    return ProjectListNotifier(service);
  },
);

class ProjectListNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final ProjectService _service;

  ProjectListNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final projects = await _service.loadAllProjects();
      if (mounted) state = AsyncValue.data(projects);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshList() => _load();

  Future<String> createProject({
    required String videoPath,
    required int durationMs,
    String? name,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final project = Project(
      id: id,
      name: name ?? 'Untitled Project',
      videoPath: videoPath,
      videoDurationMs: durationMs,
      createdAt: now,
      updatedAt: now,
      globalStyle: const CaptionStyle(),
      globalAnim: AnimPreset.none,
      captions: const [],
    );
    await _service.saveProject(project);
    await _load();
    return id;
  }

  Future<void> deleteProject(String id) async {
    await _service.deleteProject(id);
    await _load();
  }
}

// ---------------------------------------------------------------------------
// Current project provider — holds the loaded Project for the editor
// ---------------------------------------------------------------------------

final currentProjectProvider =
    StateNotifierProvider<CurrentProjectNotifier, Project?>((ref) {
  return CurrentProjectNotifier(ref);
});

class CurrentProjectNotifier extends StateNotifier<Project?> {
  final Ref _ref;

  CurrentProjectNotifier(this._ref) : super(null);

  Future<void> load(String projectId) async {
    final service = _ref.read(projectServiceProvider);
    state = await service.loadProject(projectId);
  }

  void updateProject(Project project) {
    state = project;
  }
}

// ---------------------------------------------------------------------------
// Caption list provider — manages the editable captions for the current project
// ---------------------------------------------------------------------------

final captionProvider =
    StateNotifierProvider<CaptionNotifier, List<CaptionSegment>>((ref) {
  return CaptionNotifier(ref);
});

class CaptionNotifier extends StateNotifier<List<CaptionSegment>> {
  final Ref _ref;
  Timer? _saveTimer;

  CaptionNotifier(this._ref) : super(const []);

  void load(List<CaptionSegment> captions) {
    state = List.from(captions);
  }

  void applyMutation(
      List<CaptionSegment> Function(List<CaptionSegment>) mutate) {
    state = mutate(state);
    _scheduleSave();
  }

  void updateSegment(CaptionSegment updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
    _scheduleSave();
  }

  void addSegment(CaptionSegment seg) {
    state = [...state, seg]..sort((a, b) => a.startMs.compareTo(b.startMs));
    _scheduleSave();
  }

  void removeSegment(String id) {
    state = state.where((s) => s.id != id).toList();
    _scheduleSave();
  }

  void replaceAll(List<CaptionSegment> segments) {
    state = List.from(segments);
    _scheduleSave();
  }

  void splitSegment(String id, int atMs) {
    final idx = state.indexWhere((s) => s.id == id);
    if (idx == -1) return;

    final seg = state[idx];
    if (atMs <= seg.startMs || atMs >= seg.endMs) return;

    final words = seg.text.split(RegExp(r'\s+'));
    final totalMs = seg.endMs - seg.startMs;
    final splitRatio = (atMs - seg.startMs) / totalMs;
    final splitWord =
        (words.length * splitRatio).round().clamp(1, words.length - 1);

    final first = seg.copyWith(
      endMs: atMs,
      text: words.sublist(0, splitWord).join(' '),
    );
    final second = seg.copyWith(
      id: _uuid.v4(),
      startMs: atMs,
      text: words.sublist(splitWord).join(' '),
    );

    final list = List<CaptionSegment>.from(state);
    list[idx] = first;
    list.insert(idx + 1, second);
    state = list;
    _scheduleSave();
  }

  void mergeSegments(String id1, String id2) {
    final i1 = state.indexWhere((s) => s.id == id1);
    final i2 = state.indexWhere((s) => s.id == id2);
    if (i1 == -1 || i2 == -1) return;

    final first = state[i1];
    final second = state[i2];
    final merged = first.copyWith(
      endMs: second.endMs,
      text: '${first.text} ${second.text}',
    );

    final list = List<CaptionSegment>.from(state);
    list[i1] = merged;
    list.removeAt(i2);
    state = list;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _persistToProject();
    });
  }

  void _persistToProject() {
    final project = _ref.read(currentProjectProvider);
    if (project == null) return;
    final updated = project.copyWith(captions: state);
    _ref.read(currentProjectProvider.notifier).updateProject(updated);
    _ref.read(projectServiceProvider).saveProject(updated);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
