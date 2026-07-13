import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/clear_onboarding_draft_usecase.dart';
import '../../domain/usecases/fetch_conditions_usecase.dart';
import '../../domain/usecases/load_onboarding_draft_usecase.dart';
import '../../domain/usecases/save_onboarding_draft_usecase.dart';
import '../../domain/usecases/save_onboarding_usecase.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Business Logic Component managing onboarding flow states.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final SaveOnboardingUseCase _saveOnboardingUseCase;
  final FetchConditionsUseCase _fetchConditionsUseCase;
  final SaveOnboardingDraftUseCase _saveOnboardingDraftUseCase;
  final LoadOnboardingDraftUseCase _loadOnboardingDraftUseCase;
  final ClearOnboardingDraftUseCase _clearOnboardingDraftUseCase;

  OnboardingBloc({
    required SaveOnboardingUseCase saveOnboardingUseCase,
    required FetchConditionsUseCase fetchConditionsUseCase,
    required SaveOnboardingDraftUseCase saveOnboardingDraftUseCase,
    required LoadOnboardingDraftUseCase loadOnboardingDraftUseCase,
    required ClearOnboardingDraftUseCase clearOnboardingDraftUseCase,
  })  : _saveOnboardingUseCase = saveOnboardingUseCase,
        _fetchConditionsUseCase = fetchConditionsUseCase,
        _saveOnboardingDraftUseCase = saveOnboardingDraftUseCase,
        _loadOnboardingDraftUseCase = loadOnboardingDraftUseCase,
        _clearOnboardingDraftUseCase = clearOnboardingDraftUseCase,
        super(OnboardingState.initial()) {
    on<OnboardingLoadConditionsEvent>(_onLoadConditions);
    on<OnboardingLoadDraftEvent>(_onLoadDraft);
    on<OnboardingUpdateDataEvent>(_onUpdateData);
    on<OnboardingNextStepEvent>(_onNextStep);
    on<OnboardingPreviousStepEvent>(_onPreviousStep);
    on<OnboardingSubmitEvent>(_onSubmit);
  }

  Future<void> _onLoadConditions(OnboardingLoadConditionsEvent event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    final result = await _fetchConditionsUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(status: OnboardingStatus.error, errorMessage: failure.message)),
      (conditions) => emit(state.copyWith(status: OnboardingStatus.success, conditions: conditions)),
    );
  }

  Future<void> _onLoadDraft(OnboardingLoadDraftEvent event, Emitter<OnboardingState> emit) async {
    final result = await _loadOnboardingDraftUseCase(const NoParams());
    result.fold(
      (_) => null,
      (draft) {
        if (draft != null) {
          emit(state.copyWith(data: draft));
        }
      },
    );
  }

  void _onUpdateData(OnboardingUpdateDataEvent event, Emitter<OnboardingState> emit) {
    // Dynamic real-time BMI calculations
    final data = event.data;
    final bmi = _calculateBmi(data.height, data.weight);
    final updatedData = data.copyWith(bmi: bmi);
    emit(state.copyWith(data: updatedData));
  }

  double _calculateBmi(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return double.parse((weightKg / (heightM * heightM)).toStringAsFixed(1));
  }

  Future<void> _onNextStep(OnboardingNextStepEvent event, Emitter<OnboardingState> emit) async {
    if (state.currentStep < 3) {
      final nextStep = state.currentStep + 1;
      emit(state.copyWith(currentStep: nextStep));
      // Autosave draft progress when moving forward
      await _saveOnboardingDraftUseCase(state.data);
    }
  }

  void _onPreviousStep(OnboardingPreviousStepEvent event, Emitter<OnboardingState> emit) {
    if (state.currentStep > 1) {
      final prevStep = state.currentStep - 1;
      emit(state.copyWith(currentStep: prevStep));
    }
  }

  Future<void> _onSubmit(OnboardingSubmitEvent event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.submitting));
    final result = await _saveOnboardingUseCase(state.data);
    await result.fold(
      (failure) async {
        emit(state.copyWith(status: OnboardingStatus.error, errorMessage: failure.message));
      },
      (_) async {
        // Clear local drafts on successfully registering profile details
        await _clearOnboardingDraftUseCase(const NoParams());
        emit(state.copyWith(status: OnboardingStatus.submitSuccess));
      },
    );
  }
}
