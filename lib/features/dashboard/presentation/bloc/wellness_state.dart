import 'package:equatable/equatable.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Status indicator for wellness actions.
enum WellnessStatus { 
  initial, 
  loading, 
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

  const WellnessState({
    required this.dailyLogs,
    required this.audioAnalyses,
    this.scoreHistory = const [],
    this.latestScore,
    this.baselineStatus,
    required this.status,
    this.errorMessage,
  });

  /// Initial empty state.
  factory WellnessState.initial() {
    return const WellnessState(
      dailyLogs: [],
      audioAnalyses: [],
      scoreHistory: [],
      status: WellnessStatus.initial,
    );
  }

  WellnessState copyWith({
    List<DailyLogEntity>? dailyLogs,
    List<AudioAnalysisEntity>? audioAnalyses,
    List<ScoreHistoryEntity>? scoreHistory,
    ScoreHistoryEntity? latestScore,
    Map<String, dynamic>? baselineStatus,
    WellnessStatus? status,
    String? errorMessage,
  }) {
    return WellnessState(
      dailyLogs: dailyLogs ?? this.dailyLogs,
      audioAnalyses: audioAnalyses ?? this.audioAnalyses,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      latestScore: latestScore ?? this.latestScore,
      baselineStatus: baselineStatus ?? this.baselineStatus,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
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
      ];
}
