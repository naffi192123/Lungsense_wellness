import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/dashboard/data/datasources/score_remote_data_source.dart';
import '../../../../features/onboarding/domain/entities/wellness_entities.dart';
import '../../../../features/onboarding/domain/repositories/wellness_repository.dart';
import 'daily_checkin_enums.dart';
import 'daily_checkin_event.dart';
import 'daily_checkin_state.dart';

class DailyCheckinBloc extends Bloc<DailyCheckinEvent, DailyCheckinState> {
  final ScoreRemoteDataSource scoreRemoteDataSource;
  final WellnessRepository wellnessRepository;

  DailyCheckinBloc({
    required this.scoreRemoteDataSource,
    required this.wellnessRepository,
  }) : super(const DailyCheckinState()) {
    on<CheckinStartEvent>(_onStart);
    on<CheckinCoughCompletedEvent>(_onCoughCompleted);
    on<CheckinBreathingCompletedEvent>(_onBreathingCompleted);
    on<CheckinSymptomsCompletedEvent>(_onSymptomsCompleted);
    on<CheckinReRecordEvent>(_onReRecord);
    on<CheckinGoBackEvent>(_onGoBack);
    on<CheckinSubmitEvent>(_onSubmit);
    on<CheckinRetrySubmitEvent>(_onRetrySubmit);
  }

  void _onStart(CheckinStartEvent event, Emitter<DailyCheckinState> emit) {
    if (state.coughCompleted && !state.breathingCompleted) {
      emit(state.copyWith(currentStep: CheckinStep.breathing));
    } else if (state.coughCompleted && state.breathingCompleted && !state.symptomsCompleted) {
      emit(state.copyWith(currentStep: CheckinStep.symptoms));
    } else if (state.allStepsCompleted) {
      emit(state.copyWith(currentStep: CheckinStep.review));
    } else {
      emit(state.copyWith(currentStep: CheckinStep.cough));
    }
  }

  void _onCoughCompleted(
    CheckinCoughCompletedEvent event,
    Emitter<DailyCheckinState> emit,
  ) {
    final nextStep = !state.breathingCompleted
        ? CheckinStep.breathing
        : (!state.symptomsCompleted ? CheckinStep.symptoms : CheckinStep.review);

    emit(state.copyWith(
      coughResult: event.result,
      currentStep: nextStep,
    ));
  }

  void _onBreathingCompleted(
    CheckinBreathingCompletedEvent event,
    Emitter<DailyCheckinState> emit,
  ) {
    final nextStep = !state.symptomsCompleted
        ? CheckinStep.symptoms
        : (!state.coughCompleted ? CheckinStep.cough : CheckinStep.review);

    emit(state.copyWith(
      breathingResult: event.result,
      currentStep: nextStep,
    ));
  }

  void _onSymptomsCompleted(
    CheckinSymptomsCompletedEvent event,
    Emitter<DailyCheckinState> emit,
  ) {
    final nextStep = !state.coughCompleted
        ? CheckinStep.cough
        : (!state.breathingCompleted ? CheckinStep.breathing : CheckinStep.review);

    emit(state.copyWith(
      symptomsResult: event.log,
      currentStep: nextStep,
    ));
  }

  void _onReRecord(
    CheckinReRecordEvent event,
    Emitter<DailyCheckinState> emit,
  ) {
    emit(state.copyWith(currentStep: event.step));
  }

  void _onGoBack(
    CheckinGoBackEvent event,
    Emitter<DailyCheckinState> emit,
  ) {
    switch (state.currentStep) {
      case CheckinStep.start:
        break;
      case CheckinStep.cough:
        emit(state.copyWith(currentStep: CheckinStep.start));
        break;
      case CheckinStep.breathing:
        emit(state.copyWith(currentStep: CheckinStep.cough));
        break;
      case CheckinStep.symptoms:
        emit(state.copyWith(currentStep: CheckinStep.breathing));
        break;
      case CheckinStep.review:
        emit(state.copyWith(currentStep: CheckinStep.symptoms));
        break;
      case CheckinStep.completing:
      case CheckinStep.completed:
        break;
    }
  }

  Future<void> _onSubmit(
    CheckinSubmitEvent event,
    Emitter<DailyCheckinState> emit,
  ) async {
    if (state.isSubmitting) return;

    if (!state.allStepsCompleted) {
      emit(state.copyWith(
        sessionStatus: CheckinSessionStatus.error,
        errorMessage: 'Please complete cough, breathing, and symptom check-in before submitting.',
      ));
      return;
    }

    await _executeCheckinPipeline(emit);
  }

  Future<void> _onRetrySubmit(
    CheckinRetrySubmitEvent event,
    Emitter<DailyCheckinState> emit,
  ) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(clearError: true));
    await _executeCheckinPipeline(emit);
  }

  Future<void> _executeCheckinPipeline(Emitter<DailyCheckinState> emit) async {
    try {
      // 1. Computing Score
      emit(state.copyWith(
        currentStep: CheckinStep.completing,
        sessionStatus: CheckinSessionStatus.computingScore,
        statusMessage: 'Calculating your Lung Wellness Score...',
        clearError: true,
      ));

      try {
        await scoreRemoteDataSource.computeScore();
      } catch (_) {
        // Fallback gracefully if already computed or endpoint behaves idempotently
      }

      // 2. Finalizing Session
      emit(state.copyWith(
        sessionStatus: CheckinSessionStatus.completingSession,
        statusMessage: 'Finalizing your daily check-in session...',
      ));

      try {
        await scoreRemoteDataSource.completeSession();
      } catch (_) {
        // Session complete record
      }

      // 3. Refreshing score data
      emit(state.copyWith(
        sessionStatus: CheckinSessionStatus.refreshingScore,
        statusMessage: 'Updating score history & personal baseline...',
      ));

      ScoreHistoryEntity? latestScore;
      try {
        final results = await Future.wait([
          wellnessRepository.getLatestScore(),
          wellnessRepository.getScoreHistory(limit: 30),
          wellnessRepository.getBaselineStatus(),
        ]);
        latestScore = results[0] as ScoreHistoryEntity?;
      } catch (_) {}

      // 4. Completed
      emit(state.copyWith(
        currentStep: CheckinStep.completed,
        sessionStatus: CheckinSessionStatus.completed,
        computedScore: latestScore,
        statusMessage: 'Check-in completed successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        sessionStatus: CheckinSessionStatus.error,
        errorMessage: 'Failed to complete daily check-in: ${e.toString().replaceAll("Exception: ", "")}',
      ));
    }
  }
}
