import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// BLoC that manages state transitions and routing delays for the Splash Screen.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashInitial()) {
    on<SplashStartTimerEvent>(_onStartTimer);
  }

  Future<void> _onStartTimer(
    SplashStartTimerEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());
    
    // Perform initial loading actions here if needed (e.g., check cache, token verification)
    await Future.delayed(const Duration(seconds: 3));
    
    emit(const SplashNavigateToLogin());
  }
}
