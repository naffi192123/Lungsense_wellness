import 'package:equatable/equatable.dart';

/// Aggregated domain entity representing all onboarding profile information.
class OnboardingData extends Equatable {
  // Step 1: Basic Info
  final String fullName;
  final String dateOfBirth; // YYYY-MM-DD
  final String gender;
  final double height; // in cm
  final double weight; // in kg
  final double bmi;

  // Step 2: Lifestyle
  final String activityLevel;
  final String occupation;
  final double? sleepHours;
  final double? waterIntake;
  final int? exerciseDays;

  // Step 3: Respiratory Health & Conditions
  final String smokingStatus;
  final List<String> selectedConditionIds;
  final String otherNotes;

  const OnboardingData({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.activityLevel,
    required this.occupation,
    this.sleepHours,
    this.waterIntake,
    this.exerciseDays,
    required this.smokingStatus,
    required this.selectedConditionIds,
    required this.otherNotes,
  });

  /// Factory for empty initial onboarding state.
  factory OnboardingData.empty() {
    return const OnboardingData(
      fullName: '',
      dateOfBirth: '',
      gender: '',
      height: 0.0,
      weight: 0.0,
      bmi: 0.0,
      activityLevel: '',
      occupation: '',
      sleepHours: null,
      waterIntake: null,
      exerciseDays: null,
      smokingStatus: '',
      selectedConditionIds: [],
      otherNotes: '',
    );
  }

  /// CopyWith utility for BLoC state modifiers.
  OnboardingData copyWith({
    String? fullName,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    double? bmi,
    String? activityLevel,
    String? occupation,
    double? sleepHours,
    double? waterIntake,
    int? exerciseDays,
    String? smokingStatus,
    List<String>? selectedConditionIds,
    String? otherNotes,
  }) {
    return OnboardingData(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      activityLevel: activityLevel ?? this.activityLevel,
      occupation: occupation ?? this.occupation,
      sleepHours: sleepHours ?? this.sleepHours,
      waterIntake: waterIntake ?? this.waterIntake,
      exerciseDays: exerciseDays ?? this.exerciseDays,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      selectedConditionIds: selectedConditionIds ?? this.selectedConditionIds,
      otherNotes: otherNotes ?? this.otherNotes,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        dateOfBirth,
        gender,
        height,
        weight,
        bmi,
        activityLevel,
        occupation,
        sleepHours,
        waterIntake,
        exerciseDays,
        smokingStatus,
        selectedConditionIds,
        otherNotes,
      ];
}
