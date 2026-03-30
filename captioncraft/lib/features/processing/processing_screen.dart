import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

class ProcessingScreen extends StatelessWidget {
  final String videoPath;

  const ProcessingScreen({super.key, required this.videoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.accent,
              ),
              const SizedBox(height: 24),
              Text('Preparing audio…', style: AppTypography.title),
              const SizedBox(height: 24),
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text('0%', style: AppTypography.mono),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
