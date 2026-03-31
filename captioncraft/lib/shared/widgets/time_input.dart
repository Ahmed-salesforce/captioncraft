import 'package:flutter/material.dart';

import '../../core/utils/time_formatter.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TimeInput extends StatelessWidget {
  final int valueMs;
  final int maxMs;
  final ValueChanged<int> onChanged;

  const TimeInput({
    super.key,
    required this.valueMs,
    required this.maxMs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEditDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          TimeFormatter.formatMs(valueMs),
          style: AppTypography.mono.copyWith(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: TimeFormatter.formatMs(valueMs),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Edit Time', style: AppTypography.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: AppTypography.mono.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'HH:mm:ss,mmm',
            hintStyle: AppTypography.mono.copyWith(
              color: AppColors.textSecondary,
            ),
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
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final ms = TimeFormatter.parseMs(controller.text);
              final clamped = ms.clamp(0, maxMs);
              Navigator.pop(ctx, clamped);
            },
            child: const Text('OK',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}
