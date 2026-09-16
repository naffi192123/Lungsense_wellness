import 'package:equatable/equatable.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import 'daily_checkin_enums.dart';

class DailyCheckinState extends Equatable {
  final CheckinStep currentStep;
  final CheckinSessionStatus sessionStatus;
  final AudioAnalysisEntity? coughResult;
  final AudioAnalysisEntity? breathingResult;
  final DailyLogEntity? symptomsResult;
  final DiagnosisEntity? diagnosisResult;
  final bool diagnosisSkipped;
  final ScoreHistoryEntity? computedScore;
  final String? errorMessage;
  final String? statusMessage;

  const DailyCheckinState({
    this.currentStep = CheckinStep.start,
    this.sessionStatus = CheckinSessionStatus.ready,
    this.coughResult,
    this.breathingResult,
    this.symptomsResult,
    this.diagnosisResult,
    this.diagnosisSkipped = false,
    this.computedScore,
    this.errorMessage,
    this.statusMessage,
  });

  bool get coughCompleted => coughResult != null;
  bool get breathingCompleted => breathingResult != null;
  bool get symptomsCompleted => symptomsResult != null;
  bool get diagnosisCompleted => diagnosisResult != null || diagnosisSkipped;

  int get completedStepsCount {
    int count = 0;
    if (coughCompleted) count++;
    if (breathingCompleted) count++;
    if (symptomsCompleted) count++;
    if (diagnosisCompleted) count++;
    return count;
  }

  bool get allStepsCompleted =>
      coughCompleted && breathingCompleted && symptomsCompleted;

  bool get isSubmitting =>
      sessionStatus == CheckinSessionStatus.submitting ||
      sessionStatus == CheckinSessionStatus.computingScore ||
      sessionStatus == CheckinSessionStatus.completingSession ||
      sessionStatus == CheckinSessionStatus.refreshingScore;

  DailyCheckinState copyWith({
    CheckinStep? currentStep,
    CheckinSessionStatus? sessionStatus,
    AudioAnalysisEntity? coughResult,
    bool clearCough = false,
    AudioAnalysisEntity? breathingResult,
    bool clearBreathing = false,
    DailyLogEntity? symptomsResult,
    bool clearSymptoms = false,
    DiagnosisEntity? diagnosisResult,
    bool clearDiagnosis = false,
    bool? diagnosisSkipped,
    ScoreHistoryEntity? computedScore,
    String? errorMessage,
    bool clearError = false,
    String? statusMessage,
  }) {
    return DailyCheckinState(
      currentStep: currentStep ?? this.currentStep,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      coughResult: clearCough ? null : (coughResult ?? this.coughResult),
      breathingResult:
          clearBreathing ? null : (breathingResult ?? this.breathingResult),
      symptomsResult:
          clearSymptoms ? null : (symptomsResult ?? this.symptomsResult),
      diagnosisResult:
          clearDiagnosis ? null : (diagnosisResult ?? this.diagnosisResult),
      diagnosisSkipped: diagnosisSkipped ?? this.diagnosisSkipped,
      computedScore: computedScore ?? this.computedScore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        sessionStatus,
        coughResult,
        breathingResult,
        symptomsResult,
        diagnosisResult,
        diagnosisSkipped,
        computedScore,
        errorMessage,
        statusMessage,
      ];
}
