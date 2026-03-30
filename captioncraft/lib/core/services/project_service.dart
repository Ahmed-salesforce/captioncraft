import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../models/project.dart';

class ProjectService {
  static const _projectExtension = '.captioncraft.json';
  String? _cachedDir;

  Future<String> getProjectsDir() async {
    if (kIsWeb) return '';
    if (_cachedDir != null) return _cachedDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/projects');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedDir = dir.path;
    return _cachedDir!;
  }

  Future<List<Project>> loadAllProjects() async {
    if (kIsWeb) return [];
    final dirPath = await getProjectsDir();
    final dir = Directory(dirPath);
    final files = await dir
        .list()
        .where((f) => f.path.endsWith(_projectExtension))
        .toList();

    final projects = <Project>[];
    for (final file in files) {
      try {
        final content = await File(file.path).readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        projects.add(Project.fromJson(json));
      } catch (_) {
        // Skip corrupted project files
      }
    }

    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects.take(20).toList();
  }

  Future<void> saveProject(Project project) async {
    if (kIsWeb) return;
    final dirPath = await getProjectsDir();
    final file = File('$dirPath/${project.id}$_projectExtension');
    final updated = project.copyWith(updatedAt: DateTime.now());
    final json = jsonEncode(updated.toJson());
    await file.writeAsString(json);
  }

  Future<Project?> loadProject(String id) async {
    if (kIsWeb) return null;
    final dirPath = await getProjectsDir();
    final file = File('$dirPath/$id$_projectExtension');
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Project.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteProject(String id) async {
    if (kIsWeb) return;
    final dirPath = await getProjectsDir();
    final file = File('$dirPath/$id$_projectExtension');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
