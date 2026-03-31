import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

const List<String> kCaptionFonts = [
  'Anton',
  'Oswald',
  'BebasNeue',
  'Montserrat',
  'Pacifico',
  'RobotoSlab',
  'Inter',
  'PlayfairDisplay',
];

class FontPicker extends StatelessWidget {
  final String selectedFont;
  final ValueChanged<String> onChanged;

  const FontPicker({
    super.key,
    required this.selectedFont,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kCaptionFonts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final font = kCaptionFonts[index];
          final isSelected = font == selectedFont;

          return GestureDetector(
            onTap: () => onChanged(font),
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentDim : AppColors.surface3,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Aa',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    font,
                    style: AppTypography.caption.copyWith(fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
