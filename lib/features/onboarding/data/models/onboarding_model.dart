import '../../domain/entities/onboarding_data.dart';

/// Data layer model representing onboarding profile variables.
class OnboardingModel extends OnboardingData {
  const OnboardingModel({
    required super.fullName,
    required super.dateOfBirth,
    required super.gender,
    required super.height,
    required super.weight,
    required super.bmi,
    required super.activityLevel,
    required super.occupation,
    super.sleepHours,
    super.waterIntake,
    super.exerciseDays,
    required super.smokingStatus,
    required super.selectedConditionIds,
    required super.otherNotes,
  });

  /// Factory helper to build model records from raw Domain entity profiles.
  factory OnboardingModel.fromEntity(OnboardingData entity) {
    return OnboardingModel(
      fullName: entity.fullName,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      height: entity.height,
      weight: entity.weight,
      bmi: entity.bmi,
      activityLevel: entity.activityLevel,
      occupation: entity.occupation,
      sleepHours: entity.sleepHours,
      waterIntake: entity.waterIntake,
      exerciseDays: entity.exerciseDays,
      smokingStatus: entity.smokingStatus,
      selectedConditionIds: entity.selectedConditionIds,
      otherNotes: entity.otherNotes,
    );
  }

  /// Maps variables to a JSON payload.
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'activityLevel': activityLevel,
      'occupation': occupation,
      'sleepHours': sleepHours,
      'waterIntake': waterIntake,
      'exerciseDays': exerciseDays,
      'smokingStatus': smokingStatus,
      'selectedConditionIds': selectedConditionIds,
      'otherNotes': otherNotes,
    };
  }

  /// Parses JSON payload into an onboarding model instance.
  factory OnboardingModel.fromJson(Map<String, dynamic> json) {
    return OnboardingModel(
      fullName: json['fullName'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
      activityLevel: json['activityLevel'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      waterIntake: (json['waterIntake'] as num?)?.toDouble(),
      exerciseDays: json['exerciseDays'] as int?,
      smokingStatus: json['smokingStatus'] as String? ?? '',
      selectedConditionIds: List<String>.from(json['selectedConditionIds'] ?? []),
      otherNotes: json['otherNotes'] as String? ?? '',
    );
  }
}
