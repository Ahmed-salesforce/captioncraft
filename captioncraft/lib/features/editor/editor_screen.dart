import 'package:flutter/material.dart';

import '../../shared/theme/app_typography.dart';

class EditorScreen extends StatelessWidget {
  final String projectId;

  const EditorScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor', style: AppTypography.title),
        actions: [
          const IconButton(
            icon: Icon(Icons.undo),
            onPressed: null,
            tooltip: 'Undo',
          ),
          const IconButton(
            icon: Icon(Icons.redo),
            onPressed: null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.text_format),
            onPressed: () {},
            tooltip: 'Style',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () {},
            tooltip: 'Export',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Editor — project: $projectId',
          style: AppTypography.body,
        ),
      ),
    );
  }
}
