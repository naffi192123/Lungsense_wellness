import 'package:equatable/equatable.dart';
import '../../domain/entities/medical_condition_entity.dart';
import '../../domain/entities/onboarding_data.dart';

/// Status state of Onboarding transactions.
enum OnboardingStatus { 
  initial, 
  loading, 
  success, 
  error, 
  submitting, 
  submitSuccess 
}

/// Represents onboarding state values.
class OnboardingState extends Equatable {
  final int currentStep;
  final OnboardingData data;
  final List<MedicalConditionEntity> conditions;
  final OnboardingStatus status;
  final String? errorMessage;

  const OnboardingState({
    required this.currentStep,
    required this.data,
    required this.conditions,
    required this.status,
    this.errorMessage,
  });

  /// Factory representing starting state.
  factory OnboardingState.initial() {
    return OnboardingState(
      currentStep: 1,
      data: OnboardingData.empty(),
      conditions: const [],
      status: OnboardingStatus.initial,
    );
  }

  OnboardingState copyWith({
    int? currentStep,
    OnboardingData? data,
    List<MedicalConditionEntity>? conditions,
    OnboardingStatus? status,
    String? errorMessage,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      data: data ?? this.data,
      conditions: conditions ?? this.conditions,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [currentStep, data, conditions, status, errorMessage];
}
