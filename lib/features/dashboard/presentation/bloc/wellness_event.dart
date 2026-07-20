import 'package:equatable/equatable.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Base class for wellness metrics events.
abstract class WellnessEvent extends Equatable {
  const WellnessEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to pull all daily logs and audio recordings from local storage.
class WellnessFetchDataEvent extends WellnessEvent {
  const WellnessFetchDataEvent();
}

/// Dispatched to store a daily logs entry.
class WellnessSaveDailyLogEvent extends WellnessEvent {
  final DailyLogEntity log;

  const WellnessSaveDailyLogEvent(this.log);

  @override
  List<Object?> get props => [log];
}

/// Dispatched to store a recorded respiratory audio analysis.
class WellnessSaveAudioAnalysisEvent extends WellnessEvent {
  final AudioAnalysisEntity analysis;

  const WellnessSaveAudioAnalysisEvent(this.analysis);

  @override
  List<Object?> get props => [analysis];
}
