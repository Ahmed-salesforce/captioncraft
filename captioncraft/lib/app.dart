import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/editor/editor_screen.dart';
import 'features/home/home_screen.dart';
import 'features/processing/processing_screen.dart';
import 'shared/theme/app_theme.dart';

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/processing',
      builder: (context, state) {
        final videoPath = state.extra as String? ?? '';
        return ProcessingScreen(videoPath: videoPath);
      },
    ),
    GoRoute(
      path: '/editor/:projectId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        return EditorScreen(projectId: projectId);
      },
    ),
  ],
);

class CaptionCraftApp extends StatelessWidget {
  const CaptionCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CaptionCraft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
