import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// BLoC that manages state transitions and routing delays for the Splash Screen.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  SplashBloc(this._getCurrentUserUseCase) : super(const SplashInitial()) {
    on<SplashStartTimerEvent>(_onStartTimer);
  }

  Future<void> _onStartTimer(
    SplashStartTimerEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());
    
    // Perform branding logo display delay
    await Future.delayed(const Duration(seconds: 3));
    
    // Verify session
    final result = await _getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) => emit(const SplashNavigateToLogin()),
      (user) {
        if (user != null) {
          emit(const SplashNavigateToDashboard());
        } else {
          emit(const SplashNavigateToLogin());
        }
      },
    );
  }
}
