import 'package:equatable/equatable.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Status indicator for wellness actions.
enum WellnessStatus {
  initial,
  loading,
  scoreLoading, // lightweight score-only fetch in progress
  success,
  error,
  saving,
  saveSuccess
}

/// Represents current wellness logs, audio analyses, and computed score states.
class WellnessState extends Equatable {
  final List<DailyLogEntity> dailyLogs;
  final List<AudioAnalysisEntity> audioAnalyses;
  final List<ScoreHistoryEntity> scoreHistory;
  final ScoreHistoryEntity? latestScore;
  final Map<String, dynamic>? baselineStatus;
  final WellnessStatus status;
  final String? errorMessage;

  /// Component scores extracted directly from the backend breakdown (C/B/S/T).
  /// Keys: 'C' (Cough), 'B' (Breathing), 'S' (Symptom), 'T' (Trend)
  final Map<String, int> componentScores;

  const WellnessState({
    required this.dailyLogs,
    required this.audioAnalyses,
    this.scoreHistory = const [],
    this.latestScore,
    this.baselineStatus,
    required this.status,
    this.errorMessage,
    this.componentScores = const {},
  });

  /// Initial empty state.
  factory WellnessState.initial() {
    return const WellnessState(
      dailyLogs: [],
      audioAnalyses: [],
      scoreHistory: [],
      status: WellnessStatus.initial,
      componentScores: {},
    );
  }

  /// Convenience getters for individual component scores.
  int? get coughScore => componentScores['C'];
  int? get breathingScore => componentScores['B'];
  int? get symptomScore => componentScores['S'];
  int? get trendScore => componentScores['T'];

  WellnessState copyWith({
    List<DailyLogEntity>? dailyLogs,
    List<AudioAnalysisEntity>? audioAnalyses,
    List<ScoreHistoryEntity>? scoreHistory,
    ScoreHistoryEntity? latestScore,
    bool clearLatestScore = false,
    Map<String, dynamic>? baselineStatus,
    WellnessStatus? status,
    String? errorMessage,
    Map<String, int>? componentScores,
  }) {
    return WellnessState(
      dailyLogs: dailyLogs ?? this.dailyLogs,
      audioAnalyses: audioAnalyses ?? this.audioAnalyses,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      latestScore: clearLatestScore ? null : (latestScore ?? this.latestScore),
      baselineStatus: baselineStatus ?? this.baselineStatus,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      componentScores: componentScores ?? this.componentScores,
    );
  }

  @override
  List<Object?> get props => [
        dailyLogs,
        audioAnalyses,
        scoreHistory,
        latestScore,
        baselineStatus,
        status,
        errorMessage,
        componentScores,
      ];
}
