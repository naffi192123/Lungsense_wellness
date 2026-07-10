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

/// Emitted when loading is complete, notifying the UI to navigate to the Login page.
class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}
