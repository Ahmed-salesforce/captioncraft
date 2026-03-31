import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/anim_preset.dart';
import '../../../core/models/caption_style.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/utils/undo_redo.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/font_picker.dart';

class GlobalStylePanel extends ConsumerStatefulWidget {
  const GlobalStylePanel({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const GlobalStylePanel(),
    );
  }

  @override
  ConsumerState<GlobalStylePanel> createState() => _GlobalStylePanelState();
}

class _GlobalStylePanelState extends ConsumerState<GlobalStylePanel> {
  Timer? _debounce;

  void _updateStyle(CaptionStyle newStyle) {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;

    final oldStyle = project.globalStyle;
    if (oldStyle == newStyle) return;

    ref.read(currentProjectProvider.notifier).updateProject(
      project.copyWith(globalStyle: newStyle),
    );

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(historyProvider.notifier).execute(
        ChangeStyleCommand(
          oldStyle: oldStyle,
          newStyle: newStyle,
          mutate: (style) {
            final p = ref.read(currentProjectProvider);
            if (p != null) {
              ref.read(currentProjectProvider.notifier).updateProject(
                p.copyWith(globalStyle: style),
              );
              ref.read(projectServiceProvider).saveProject(
                p.copyWith(globalStyle: style),
              );
            }
          },
        ),
      );
    });
  }

  void _updateAnim(AnimPreset anim) {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;

    final oldAnim = project.globalAnim;
    ref.read(currentProjectProvider.notifier).updateProject(
      project.copyWith(globalAnim: anim),
    );

    ref.read(historyProvider.notifier).execute(
      ChangeGlobalAnimCommand(
        oldAnim: oldAnim,
        newAnim: anim,
        mutate: (a) {
          final p = ref.read(currentProjectProvider);
          if (p != null) {
            ref.read(currentProjectProvider.notifier).updateProject(
              p.copyWith(globalAnim: a),
            );
            ref.read(projectServiceProvider).saveProject(
              p.copyWith(globalAnim: a),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(currentProjectProvider);
    if (project == null) return const SizedBox.shrink();

    final style = project.globalStyle;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text('Global Style', style: AppTypography.title)),
                const SizedBox(height: 16),

                _PreviewBox(style: style),
                const SizedBox(height: 20),

                Text('Font Family', style: AppTypography.label),
                const SizedBox(height: 8),
                FontPicker(
                  selectedFont: style.fontFamily,
                  onChanged: (f) => _updateStyle(style.copyWith(fontFamily: f)),
                ),
                const SizedBox(height: 16),

                _SliderRow(
                  label: 'Font Size',
                  value: style.fontSize,
                  min: 12,
                  max: 72,
                  divisions: 60,
                  suffix: '${style.fontSize.round()}pt',
                  onChanged: (v) => _updateStyle(style.copyWith(fontSize: v)),
                ),
                const SizedBox(height: 12),

                _ColorRow(
                  label: 'Font Color',
                  color: Color(style.fontColor),
                  onChanged: (c) => _updateStyle(style.copyWith(fontColor: c.value)),
                ),
                const SizedBox(height: 12),

                _ColorRow(
                  label: 'BG Color',
                  color: Color(style.bgColor).withOpacity(1),
                  onChanged: (c) {
                    final alpha = Color(style.bgColor).opacity;
                    _updateStyle(style.copyWith(
                      bgColor: c.withOpacity(alpha).value,
                    ));
                  },
                ),
                const SizedBox(height: 12),

                _SliderRow(
                  label: 'BG Opacity',
                  value: Color(style.bgColor).opacity,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  suffix: '${(Color(style.bgColor).opacity * 100).round()}%',
                  onChanged: (v) {
                    final base = Color(style.bgColor).withOpacity(v);
                    _updateStyle(style.copyWith(bgColor: base.value));
                  },
                ),
                const SizedBox(height: 16),

                Text('BG Shape', style: AppTypography.label),
                const SizedBox(height: 8),
                _SegmentedRow<BgShape>(
                  values: BgShape.values,
                  selected: style.bgShape,
                  labels: const {'none': 'None', 'roundedRect': 'Rounded', 'fullBar': 'Full Bar'},
                  onChanged: (v) => _updateStyle(style.copyWith(bgShape: v)),
                ),
                const SizedBox(height: 16),

                Text('Vertical Position', style: AppTypography.label),
                const SizedBox(height: 8),
                _SegmentedRow<VPos>(
                  values: VPos.values,
                  selected: style.verticalPosition,
                  labels: const {'top': 'Top', 'center': 'Center', 'bottom': 'Bottom'},
                  onChanged: (v) => _updateStyle(style.copyWith(verticalPosition: v)),
                ),
                const SizedBox(height: 12),

                _SliderRow(
                  label: 'V Offset',
                  value: style.verticalOffset,
                  min: -200,
                  max: 200,
                  divisions: 80,
                  suffix: '${style.verticalOffset.round()}px',
                  onChanged: (v) => _updateStyle(style.copyWith(verticalOffset: v)),
                ),
                const SizedBox(height: 16),

                Text('H Alignment', style: AppTypography.label),
                const SizedBox(height: 8),
                _SegmentedRow<HAlign>(
                  values: HAlign.values,
                  selected: style.hAlignment,
                  labels: const {'left': 'Left', 'center': 'Center', 'right': 'Right'},
                  onChanged: (v) => _updateStyle(style.copyWith(hAlignment: v)),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Text('Bold', style: AppTypography.label),
                    const SizedBox(width: 8),
                    Switch(
                      value: style.bold,
                      activeColor: AppColors.accent,
                      onChanged: (v) => _updateStyle(style.copyWith(bold: v)),
                    ),
                    const SizedBox(width: 20),
                    Text('Italic', style: AppTypography.label),
                    const SizedBox(width: 8),
                    Switch(
                      value: style.italic,
                      activeColor: AppColors.accent,
                      onChanged: (v) => _updateStyle(style.copyWith(italic: v)),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),

                Text('Animation', style: AppTypography.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: AnimPreset.values.map((p) {
                    final isSelected = project.globalAnim == p;
                    return ChoiceChip(
                      label: Text(_animLabel(p)),
                      selected: isSelected,
                      selectedColor: AppColors.accentDim,
                      backgroundColor: AppColors.surface3,
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      onSelected: (_) => _updateAnim(p),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _animLabel(AnimPreset p) {
    switch (p) {
      case AnimPreset.none:      return 'None';
      case AnimPreset.fade:      return 'Fade';
      case AnimPreset.pop:       return 'Pop';
      case AnimPreset.slideUp:   return 'Slide Up';
      case AnimPreset.wordByWord: return 'Word by Word';
      case AnimPreset.karaoke:   return 'Karaoke';
    }
  }
}

class _PreviewBox extends StatelessWidget {
  final CaptionStyle style;

  const _PreviewBox({required this.style});

  @override
  Widget build(BuildContext context) {
    Widget text = Text(
      'Preview text',
      style: TextStyle(
        fontFamily: style.fontFamily,
        fontSize: style.fontSize.clamp(14, 32),
        color: Color(style.fontColor),
        fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      ),
    );

    if (style.bgShape != BgShape.none) {
      text = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(style.bgColor),
          borderRadius: style.bgShape == BgShape.roundedRect
              ? BorderRadius.circular(6)
              : null,
        ),
        child: text,
      );
    }

    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(child: text),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: AppTypography.caption),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.surface3,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(suffix, style: AppTypography.mono.copyWith(fontSize: 11), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: AppTypography.caption),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
            style: AppTypography.mono.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    Color picked = color;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(label, style: AppTypography.title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              onChanged(picked);
              Navigator.pop(ctx);
            },
            child: const Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

class _SegmentedRow<T extends Enum> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final Map<String, String> labels;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.values,
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((v) {
        final isSelected = v == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentDim : AppColors.surface3,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: v == values.first ? const Radius.circular(8) : Radius.zero,
                  right: v == values.last ? const Radius.circular(8) : Radius.zero,
                ),
              ),
              child: Center(
                child: Text(
                  labels[v.name] ?? v.name,
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
