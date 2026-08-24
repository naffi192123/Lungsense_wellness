import 'package:equatable/equatable.dart';

/// Base class for all states emitted by [SplashBloc].
abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// The initial state when the bloc is first instantiated.
class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Emitted while the splash loading sequence/timer is in progress.
class SplashLoading extends SplashState {
  const SplashLoading();
}

/// Emitted when loading is complete and there is no valid session, navigating to the Welcome Screen.
class SplashNavigateToWelcome extends SplashState {
  const SplashNavigateToWelcome();
}

/// Emitted when loading is complete, notifying the UI to navigate to the Login page.
/// Still used for direct deep-link or email-verification redirect scenarios.
class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}

/// Emitted when loading is complete and session is active, navigating to Dashboard.
class SplashNavigateToDashboard extends SplashState {
  const SplashNavigateToDashboard();
}

/// Emitted when the user is logged in but their email is not verified yet.
class SplashNavigateToVerification extends SplashState {
  const SplashNavigateToVerification();
}

/// Emitted when the user is authenticated but has not finished profile onboarding.
class SplashNavigateToOnboarding extends SplashState {
  const SplashNavigateToOnboarding();
}
