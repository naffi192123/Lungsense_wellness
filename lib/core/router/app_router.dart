import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Central routing management using GoRouter.
abstract class AppRouter {
  /// Named route constants.
  static const String splashPath = '/';
  static const String splashName = 'splash';

  /// GoRouter configuration.
  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: splashPath,
        name: splashName,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 64,
                  color: Color(0xFF5A7438), // Supporting green
                ),
                SizedBox(height: 16),
                Text(
                  'LungSense Wellness',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF140F2D), // Text color
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Phase 0: Architecture Ready',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5C5870), // Secondary text
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
