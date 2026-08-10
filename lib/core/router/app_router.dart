import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/bloc/wellness_bloc.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/daily_log/presentation/pages/daily_log_page.dart';
import '../../features/recording/presentation/pages/audio_analysis_page.dart';
import '../../features/recording/presentation/pages/record_page.dart';
import '../../features/recording/presentation/bloc/audio_recording_bloc.dart';
import '../../features/history/presentation/pages/history_detail_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/contact_us_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';

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
  static const String emailVerificationPath = '/email-verification';
  static const String emailVerificationName = 'email-verification';
  static const String onboardingPath = '/onboarding';
  static const String onboardingName = 'onboarding';
  static const String dashboardPath = '/dashboard';
  static const String dashboardName = 'dashboard';
  static const String dailyLogPath = '/daily-log';
  static const String dailyLogName = 'daily-log';
  static const String audioAnalysisPath = '/audio-analysis';
  static const String audioAnalysisName = 'audio-analysis';
  static const String recordPath = '/record';
  static const String recordName = 'record';
  static const String historyDetailsPath = '/history-details';
  static const String historyDetailsName = 'history-details';
  static const String editProfilePath = '/edit-profile';
  static const String editProfileName = 'edit-profile';
  static const String changePasswordPath = '/change-password';
  static const String changePasswordName = 'change-password';
  static const String contactUsPath = '/contact-us';
  static const String contactUsName = 'contact-us';
  static const String privacyPolicyPath = '/privacy-policy';
  static const String privacyPolicyName = 'privacy-policy';

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
        path: emailVerificationPath,
        name: emailVerificationName,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<AuthBloc>(),
          child: const EmailVerificationPage(),
        ),
      ),
      GoRoute(
        path: onboardingPath,
        name: onboardingName,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<OnboardingBloc>(),
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: dashboardPath,
        name: dashboardName,
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabStr ?? '') ?? 0;
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<AuthBloc>()),
              BlocProvider(create: (context) => sl<WellnessBloc>()),
            ],
            child: DashboardPage(initialTab: initialTab),
          );
        },
      ),
      GoRoute(
        path: dailyLogPath,
        name: dailyLogName,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<WellnessBloc>(),
          child: const DailyLogPage(),
        ),
      ),
      GoRoute(
        path: audioAnalysisPath,
        name: audioAnalysisName,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<WellnessBloc>(),
          child: const AudioAnalysisPage(),
        ),
      ),
      GoRoute(
        path: recordPath,
        name: recordName,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<WellnessBloc>()),
            BlocProvider(create: (context) => sl<AudioRecordingBloc>()),
          ],
          child: const RecordPage(),
        ),
      ),
      GoRoute(
        path: historyDetailsPath,
        name: historyDetailsName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final logType = extra['logType'] as String? ?? 'generic';
          final itemData = extra['itemData'];
          return HistoryDetailPage(logType: logType, itemData: itemData);
        },
      ),
      GoRoute(
        path: editProfilePath,
        name: editProfileName,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: changePasswordPath,
        name: changePasswordName,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: contactUsPath,
        name: contactUsName,
        builder: (context, state) => const ContactUsPage(),
      ),
      GoRoute(
        path: privacyPolicyPath,
        name: privacyPolicyName,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
    ],
  );
}
