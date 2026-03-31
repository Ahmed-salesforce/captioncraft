import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/anim_preset.dart';
import '../../../core/models/caption_segment.dart';
import '../../../core/models/caption_style.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/utils/undo_redo.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/font_picker.dart';
import '../../../shared/widgets/time_input.dart';

class CaptionEditSheet extends StatefulWidget {
  final CaptionSegment segment;
  final WidgetRef ref;

  const CaptionEditSheet({
    super.key,
    required this.segment,
    required this.ref,
  });

  static Future<void> open(
      BuildContext context, WidgetRef ref, CaptionSegment segment) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CaptionEditSheet(segment: segment, ref: ref),
    );
  }

  @override
  State<CaptionEditSheet> createState() => _CaptionEditSheetState();
}

class _CaptionEditSheetState extends State<CaptionEditSheet> {
  late TextEditingController _textCtrl;
  Timer? _textDebounce;
  late CaptionSegment _seg;

  WidgetRef get ref => widget.ref;

  @override
  void initState() {
    super.initState();
    _seg = widget.segment;
    _textCtrl = TextEditingController(text: _seg.text);
  }

  @override
  void dispose() {
    _textDebounce?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _textDebounce?.cancel();
    _textDebounce = Timer(const Duration(milliseconds: 400), () {
      if (value == _seg.text) return;
      final notifier = ref.read(captionProvider.notifier);
      ref.read(historyProvider.notifier).execute(
            EditTextCommand(
              segmentId: _seg.id,
              oldText: _seg.text,
              newText: value,
              mutate: notifier.applyMutation,
            ),
          );
      setState(() => _seg = _seg.copyWith(text: value));
    });
  }

  void _changeStart(int ms) {
    final notifier = ref.read(captionProvider.notifier);
    ref.read(historyProvider.notifier).execute(
          ResizeSegmentCommand(
            segmentId: _seg.id,
            oldStartMs: _seg.startMs,
            oldEndMs: _seg.endMs,
            newStartMs: ms,
            newEndMs: _seg.endMs,
            mutate: notifier.applyMutation,
          ),
        );
    setState(() => _seg = _seg.copyWith(startMs: ms));
  }

  void _changeEnd(int ms) {
    final notifier = ref.read(captionProvider.notifier);
    ref.read(historyProvider.notifier).execute(
          ResizeSegmentCommand(
            segmentId: _seg.id,
            oldStartMs: _seg.startMs,
            oldEndMs: _seg.endMs,
            newStartMs: _seg.startMs,
            newEndMs: ms,
            mutate: notifier.applyMutation,
          ),
        );
    setState(() => _seg = _seg.copyWith(endMs: ms));
  }

  void _toggleStyleOverride(bool on) {
    final project = ref.read(currentProjectProvider);
    final notifier = ref.read(captionProvider.notifier);
    final newStyle = on ? (project?.globalStyle ?? const CaptionStyle()) : null;
    final updated = _seg.copyWith(styleOverride: newStyle);
    notifier.updateSegment(updated);
    setState(() => _seg = updated);
  }

  void _updateStyleField(CaptionStyle Function(CaptionStyle) updater) {
    if (_seg.styleOverride == null) return;
    final newStyle = updater(_seg.styleOverride!);
    final notifier = ref.read(captionProvider.notifier);
    final updated = _seg.copyWith(styleOverride: newStyle);
    notifier.updateSegment(updated);
    setState(() => _seg = updated);
  }

  void _changeAnim(AnimPreset anim) {
    final notifier = ref.read(captionProvider.notifier);
    final updated = _seg.copyWith(animPreset: anim);
    notifier.updateSegment(updated);
    setState(() => _seg = updated);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Delete segment?', style: AppTypography.title),
        content: Text('This action can be undone.', style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              final notifier = ref.read(captionProvider.notifier);
              ref.read(historyProvider.notifier).execute(
                    DeleteSegmentCommand(
                      segment: _seg,
                      mutate: notifier.applyMutation,
                    ),
                  );
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = ref.read(playbackProvider).durationMs;
    final segDuration = _seg.endMs - _seg.startMs;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Text field
              TextField(
                controller: _textCtrl,
                onChanged: _onTextChanged,
                maxLines: 4,
                minLines: 2,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Caption text…',
                  hintStyle: AppTypography.caption,
                  filled: true,
                  fillColor: AppColors.surface3,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timing rows
              _buildTimeRow('Start', _seg.startMs, durationMs, _changeStart),
              const SizedBox(height: 8),
              _buildTimeRow('End', _seg.endMs, durationMs, _changeEnd),
              const SizedBox(height: 8),
              Text(
                'Duration: ${(segDuration / 1000).toStringAsFixed(1)}s',
                style: AppTypography.caption,
              ),
              const Divider(height: 24, color: AppColors.border),

              // Style override
              Row(
                children: [
                  Text('Style override', style: AppTypography.label),
                  const Spacer(),
                  Switch(
                    value: _seg.hasStyleOverride,
                    activeColor: AppColors.accent,
                    onChanged: _toggleStyleOverride,
                  ),
                ],
              ),
              if (_seg.hasStyleOverride) ...[
                const SizedBox(height: 8),
                Text('Font', style: AppTypography.caption),
                const SizedBox(height: 4),
                FontPicker(
                  selectedFont: _seg.styleOverride!.fontFamily,
                  onChanged: (f) =>
                      _updateStyleField((s) => s.copyWith(fontFamily: f)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Size', style: AppTypography.caption),
                    Expanded(
                      child: Slider(
                        value: _seg.styleOverride!.fontSize,
                        min: 12,
                        max: 72,
                        divisions: 60,
                        activeColor: AppColors.accent,
                        onChanged: (v) =>
                            _updateStyleField((s) => s.copyWith(fontSize: v)),
                      ),
                    ),
                    Text('${_seg.styleOverride!.fontSize.toInt()}',
                        style: AppTypography.mono),
                  ],
                ),
                Row(
                  children: [
                    _toggleBtn(
                      'B',
                      _seg.styleOverride!.bold,
                      () => _updateStyleField(
                          (s) => s.copyWith(bold: !s.bold)),
                    ),
                    const SizedBox(width: 8),
                    _toggleBtn(
                      'I',
                      _seg.styleOverride!.italic,
                      () => _updateStyleField(
                          (s) => s.copyWith(italic: !s.italic)),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24, color: AppColors.border),

              // Animation preset
              Text('Animation', style: AppTypography.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AnimPreset.values.map((a) {
                  final isSelected = (_seg.animPreset ?? AnimPreset.none) == a;
                  return ChoiceChip(
                    label: Text(a.name),
                    selected: isSelected,
                    selectedColor: AppColors.accentDim,
                    backgroundColor: AppColors.surface3,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.border,
                    ),
                    onSelected: (_) => _changeAnim(a),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Delete
              Center(
                child: TextButton(
                  onPressed: _delete,
                  child: Text(
                    'Delete segment',
                    style: AppTypography.label
                        .copyWith(color: AppColors.danger),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(
      String label, int valueMs, int maxMs, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(label, style: AppTypography.caption),
        ),
        TimeInput(
          valueMs: valueMs,
          maxMs: maxMs,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        _nudgeBtn('-1s', () {
          final v = (valueMs - 1000).clamp(0, maxMs);
          onChanged(v);
        }),
        const SizedBox(width: 4),
        _nudgeBtn('+1s', () {
          final v = (valueMs + 1000).clamp(0, maxMs);
          onChanged(v);
        }),
      ],
    );
  }

  Widget _nudgeBtn(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          textStyle: const TextStyle(fontSize: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? AppColors.accentDim : AppColors.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle:
                label == 'I' ? FontStyle.italic : FontStyle.normal,
            color: active ? AppColors.accent : AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
