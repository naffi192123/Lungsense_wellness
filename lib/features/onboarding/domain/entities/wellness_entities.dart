import 'package:equatable/equatable.dart';

/// Entity representing daily symptom tracker entries aligned with backend payload schema.
class DailyLogEntity extends Equatable {
  final String id;
  final String checkinDate;
  final double breathlessness;
  final double activityLimitation;
  final double changeFromUsual;
  final double fever;
  final double chestTightness;
  final double chestDiscomfortBreathing;
  final double wheezing;
  final double coughSeverity;
  final double mucus;
  final double sleepDisruption;
  final double chestPain;
  final bool smokedToday;
  final double exerciseMinutes;
  final double sleepHours;
  final double waterIntakeLiters;
  final DateTime timestamp;

  const DailyLogEntity({
    required this.id,
    required this.checkinDate,
    required this.breathlessness,
    required this.activityLimitation,
    required this.changeFromUsual,
    required this.fever,
    required this.chestTightness,
    required this.chestDiscomfortBreathing,
    required this.wheezing,
    required this.coughSeverity,
    required this.mucus,
    required this.sleepDisruption,
    required this.chestPain,
    required this.smokedToday,
    required this.exerciseMinutes,
    required this.sleepHours,
    required this.waterIntakeLiters,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        checkinDate,
        breathlessness,
        activityLimitation,
        changeFromUsual,
        fever,
        chestTightness,
        chestDiscomfortBreathing,
        wheezing,
        coughSeverity,
        mucus,
        sleepDisruption,
        chestPain,
        smokedToday,
        exerciseMinutes,
        sleepHours,
        waterIntakeLiters,
        timestamp,
      ];
}

/// Entity representing a recorded and analyzed respiratory audio file.
class AudioAnalysisEntity extends Equatable {
  final String id;
  final String title;
  final String type; // Cough or Breathing
  final int duration; // in seconds
  final int confidence; // percentage (e.g. 98%)
  final int lungsScore; // e.g. 89
  final String insight; // AI insight text
  final String intensity; // Moderate, Low, High
  final int breathingRate; // e.g. 16 bpm
  final String rhythm; // Steady, irregular
  final String signalQuality; // Excellent, etc.
  final String backgroundNoise; // Low, etc.
  final DateTime timestamp;
  final List<String> tags;

  const AudioAnalysisEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.duration,
    required this.confidence,
    required this.lungsScore,
    required this.insight,
    required this.intensity,
    required this.breathingRate,
    required this.rhythm,
    required this.signalQuality,
    required this.backgroundNoise,
    required this.timestamp,
    required this.tags,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        duration,
        confidence,
        lungsScore,
        insight,
        intensity,
        breathingRate,
        rhythm,
        signalQuality,
        backgroundNoise,
        timestamp,
        tags,
      ];
}
