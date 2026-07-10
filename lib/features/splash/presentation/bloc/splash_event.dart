import 'package:equatable/equatable.dart';

/// Base class for all events handled by [SplashBloc].
abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the 3-second initialization timer on splash screen load.
class SplashStartTimerEvent extends SplashEvent {
  const SplashStartTimerEvent();
}
