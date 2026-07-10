import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

/// Central routing management using GoRouter.
abstract class AppRouter {
  /// Named route constants.
  static const String splashPath = '/';
  static const String splashName = 'splash';
  static const String loginPath = '/login';
  static const String loginName = 'login';

  /// GoRouter configuration.
  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: splashPath,
        name: splashName,
        builder: (context, state) => BlocProvider(
          create: (context) => SplashBloc(),
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: loginPath,
        name: loginName,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Login Screen Placeholder (Phase 2)'),
          ),
        ),
      ),
    ],
  );
}
