import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum _CCButtonVariant { filled, outlined, danger }

class CCButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final _CCButtonVariant _variant;

  const CCButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  }) : _variant = _CCButtonVariant.filled;

  const CCButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  }) : _variant = _CCButtonVariant.outlined;

  const CCButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  }) : _variant = _CCButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.dmSans(
      fontWeight: FontWeight.w500,
      fontSize: 15,
    );

    switch (_variant) {
      case _CCButtonVariant.filled:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.surface,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildChild(AppColors.surface),
        );

      case _CCButtonVariant.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildChild(AppColors.accent),
        );

      case _CCButtonVariant.danger:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildChild(Colors.white),
        );
    }
  }

  Widget _buildChild(Color iconColor) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}
