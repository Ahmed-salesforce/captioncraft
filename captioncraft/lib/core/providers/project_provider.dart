import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/anim_preset.dart';
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
