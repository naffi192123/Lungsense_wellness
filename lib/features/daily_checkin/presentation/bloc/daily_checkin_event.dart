import 'package:equatable/equatable.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import 'daily_checkin_enums.dart';

abstract class DailyCheckinEvent extends Equatable {
  const DailyCheckinEvent();
  @override
  List<Object?> get props => [];
}

/// User taps "Start Check-in" on the start screen.
class CheckinStartEvent extends DailyCheckinEvent {
  const CheckinStartEvent();
}

/// Cough audio recording + analysis completed.
class CheckinCoughCompletedEvent extends DailyCheckinEvent {
  final AudioAnalysisEntity result;
  const CheckinCoughCompletedEvent(this.result);
  @override
  List<Object?> get props => [result];
}

/// Breathing audio recording + analysis completed.
class CheckinBreathingCompletedEvent extends DailyCheckinEvent {
  final AudioAnalysisEntity result;
  const CheckinBreathingCompletedEvent(this.result);
  @override
  List<Object?> get props => [result];
}

/// Symptom form saved.
class CheckinSymptomsCompletedEvent extends DailyCheckinEvent {
  final DailyLogEntity log;
  const CheckinSymptomsCompletedEvent(this.log);
  @override
  List<Object?> get props => [log];
}

/// Diagnosis step completed (either submitted with a diagnosis or skipped).
class CheckinDiagnosisCompletedEvent extends DailyCheckinEvent {
  final DiagnosisEntity? diagnosis;
  final bool isSkipped;

  const CheckinDiagnosisCompletedEvent({
    this.diagnosis,
    this.isSkipped = false,
  });

  @override
  List<Object?> get props => [diagnosis, isSkipped];
}

/// User taps "Complete Check-in" on the review screen.
class CheckinSubmitEvent extends DailyCheckinEvent {
  const CheckinSubmitEvent();
}

/// User wants to re-record / re-do a specific step.
class CheckinReRecordEvent extends DailyCheckinEvent {
  final CheckinStep step;
  const CheckinReRecordEvent(this.step);
  @override
  List<Object?> get props => [step];
}

/// User goes back one step.
class CheckinGoBackEvent extends DailyCheckinEvent {
  const CheckinGoBackEvent();
}

/// User retries after a submission error.
class CheckinRetrySubmitEvent extends DailyCheckinEvent {
  const CheckinRetrySubmitEvent();
}
