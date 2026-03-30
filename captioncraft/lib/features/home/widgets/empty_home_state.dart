import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cc_button.dart';

class EmptyHomeState extends StatelessWidget {
  final VoidCallback onImport;

  const EmptyHomeState({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.subtitles_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 20),
            Text('No projects yet', style: AppTypography.title),
            const SizedBox(height: 8),
            Text(
              'Import a video to get started',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 24),
            CCButton.outlined(
              label: 'Import Video',
              icon: Icons.video_library_outlined,
              onPressed: onImport,
            ),
          ],
        ),
      ),
    );
  }
}
