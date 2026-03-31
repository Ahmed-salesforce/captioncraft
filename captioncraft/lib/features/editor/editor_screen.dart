import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/history_provider.dart';
import '../../core/providers/playback_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import 'widgets/caption_list.dart';
import 'widgets/global_style_panel.dart';
import 'widgets/timeline_strip.dart';
import 'widgets/video_preview.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String projectId;

  const EditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final FocusNode _focusNode = FocusNode();
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initProject();
  }

  Future<void> _initProject() async {
    try {
      await ref.read(currentProjectProvider.notifier).load(widget.projectId);
      final project = ref.read(currentProjectProvider);
      if (project == null) {
        setState(() => _error = 'Project not found');
        return;
      }

      ref.read(captionProvider.notifier).load(project.captions);
      await ref.read(playbackProvider.notifier).initialize(project.videoPath);
      ref.read(historyProvider.notifier).clear();

      if (mounted) setState(() => _loaded = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    ref.read(playbackProvider.notifier).dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (ctrl && shift && event.logicalKey == LogicalKeyboardKey.keyZ) {
      ref.read(historyProvider.notifier).redo();
      return KeyEventResult.handled;
    }
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
      ref.read(historyProvider.notifier).undo();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      ref.read(playbackProvider.notifier).togglePlayPause();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<bool> _onWillPop() async {
    final history = ref.read(historyProvider);
    if (!history.canUndo) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Unsaved changes', style: AppTypography.title),
        content: Text(
          'You have unsaved edits. Discard changes?',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Stay', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _renameProject() {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;

    final controller = TextEditingController(text: project.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Rename project', style: AppTypography.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: 'Project name',
            hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final updated = project.copyWith(name: name);
                ref.read(currentProjectProvider.notifier).updateProject(updated);
                ref.read(projectServiceProvider).saveProject(updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Editor', style: AppTypography.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: AppTypography.body, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        ),
      );
    }

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading…', style: AppTypography.title)),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final project = ref.watch(currentProjectProvider);
    final history = ref.watch(historyProvider);

    return PopScope(
      canPop: !history.canUndo,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: GestureDetector(
              onTap: _renameProject,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      project?.name ?? 'Editor',
                      style: AppTypography.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: history.canUndo
                    ? () => ref.read(historyProvider.notifier).undo()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                tooltip: 'Redo',
                onPressed: history.canRedo
                    ? () => ref.read(historyProvider.notifier).redo()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.text_format),
                tooltip: 'Style',
                onPressed: () => GlobalStylePanel.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: 'Export',
                onPressed: () {
                  // Phase 5: ExportSheet.show(context)
                },
              ),
            ],
          ),
          body: Column(
            children: const [
              Expanded(flex: 4, child: VideoPreview()),
              TimelineStrip(),
              Expanded(flex: 5, child: CaptionList()),
            ],
          ),
        ),
      ),
    );
  }
}
