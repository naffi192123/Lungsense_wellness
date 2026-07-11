import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// Central routing management using GoRouter.
abstract class AppRouter {
  /// Named route constants.
  static const String splashPath = '/';
  static const String splashName = 'splash';
  static const String loginPath = '/login';
  static const String loginName = 'login';
  static const String registerPath = '/register';
  static const String registerName = 'register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String forgotPasswordName = 'forgot-password';
  static const String dashboardPath = '/dashboard';
  static const String dashboardName = 'dashboard';

  /// GoRouter configuration.
  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: splashPath,
        name: splashName,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<SplashBloc>(),
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: loginPath,
        name: loginName,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<AuthBloc>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: registerPath,
        name: registerName,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<AuthBloc>(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: forgotPasswordPath,
        name: forgotPasswordName,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<AuthBloc>(),
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: dashboardPath,
        name: dashboardName,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Dashboard Screen Placeholder (Phase 4)'),
          ),
        ),
      ),
    ],
  );
}
