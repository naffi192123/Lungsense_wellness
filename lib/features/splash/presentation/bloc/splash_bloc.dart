import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../onboarding/domain/usecases/check_profile_completed_usecase.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// BLoC that manages state transitions and routing delays for the Splash Screen.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckProfileCompletedUseCase _checkProfileCompletedUseCase;

  SplashBloc(
    this._getCurrentUserUseCase,
    this._checkProfileCompletedUseCase,
  ) : super(const SplashInitial()) {
    on<SplashStartTimerEvent>(_onStartTimer);
  }

  Future<void> _onStartTimer(
    SplashStartTimerEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());

    // Run auth check and minimum splash delay concurrently so the splash
    // branding is always visible for at least 2 seconds regardless of how
    // quickly the network/cache responds.
    final results = await Future.wait([
      _getCurrentUserUseCase(const NoParams()),
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);

    // Verify session (first result from Future.wait)
    final result = results[0];
    await result.fold(
      (failure) async => emit(const SplashNavigateToWelcome()),
      (user) async {
        if (user == null) {
          emit(const SplashNavigateToWelcome());
          return;
        }

        // 1. Check if email verified
        if (!user.isEmailVerified) {
          emit(const SplashNavigateToVerification());
          return;
        }

        // 2. Check if profile completed
        final completedResult = await _checkProfileCompletedUseCase(const NoParams());
        completedResult.fold(
          (failure) => emit(const SplashNavigateToOnboarding()),
          (isCompleted) {
            if (isCompleted) {
              emit(const SplashNavigateToDashboard());
            } else {
              emit(const SplashNavigateToOnboarding());
            }
          },
        );
      },
    );
  }
}
