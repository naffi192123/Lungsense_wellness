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

  /// Dynamic baseline value fetched directly from GET /score/baseline.
  /// Returns null if baseline is not yet available, missing, or initializing.
  /// Does not calculate, estimate, or hardcode any baseline value.
  double? get baselineValue {
    if (baselineStatus == null) return null;
    final status = baselineStatus!['status']?.toString().toLowerCase();
    if (status == 'initializing' || status == 'pending') {
      return null;
    }
    final dynamic raw = baselineStatus!['baseline_mean'] ??
        baselineStatus!['baseline'] ??
        baselineStatus!['baseline_value'] ??
        baselineStatus!['mean'] ??
        baselineStatus!['value'];
    if (raw is num && raw > 0) {
      return raw.toDouble();
    }
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  /// Lifecycle status string from GET /score/baseline (e.g. 'Active', 'Forming').
  String? get baselineStatusText {
    if (baselineStatus == null) return null;
    final status = baselineStatus!['status']?.toString();
    if (status != null && status.trim().isNotEmpty) {
      final trimmed = status.trim();
      if (trimmed.toLowerCase() == 'initializing') return 'Forming';
      return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    }
    return null;
  }

  /// User-facing message from GET /score/baseline.
  String? get baselineMessage {
    if (baselineStatus == null) return null;
    final msg = baselineStatus!['message']?.toString();
    if (msg != null && msg.trim().isNotEmpty) {
      return msg.trim();
    }
    return null;
  }

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
