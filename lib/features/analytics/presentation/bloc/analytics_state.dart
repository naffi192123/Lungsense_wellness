import 'package:equatable/equatable.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Status for analytics data loading lifecycle.
enum AnalyticsStatus {
  initial,
  loading,
  success,
  error,
}

/// Immutable state for the Analytics feature.
class AnalyticsState extends Equatable {
  final AnalyticsStatus status;

  /// Score history from GET /score/history (most recent first).
  final List<ScoreHistoryEntity> scoreHistory;

  /// Baseline status from GET /score/baseline.
  final Map<String, dynamic>? baselineStatus;

  /// Score band definitions from GET /score/bands.
  /// Contains a 'bands' key → List of {band, label, min, max, message}.
  final Map<String, dynamic>? scoreBands;

  final String? errorMessage;

  const AnalyticsState({
    this.status = AnalyticsStatus.initial,
    this.scoreHistory = const [],
    this.baselineStatus,
    this.scoreBands,
    this.errorMessage,
  });

  /// Initial empty state before any fetch.
  factory AnalyticsState.initial() => const AnalyticsState();

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    List<ScoreHistoryEntity>? scoreHistory,
    Map<String, dynamic>? baselineStatus,
    Map<String, dynamic>? scoreBands,
    String? errorMessage,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      baselineStatus: baselineStatus ?? this.baselineStatus,
      scoreBands: scoreBands ?? this.scoreBands,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convenience: valid (non-null) lung wellness scores from history.
  List<double> get validScores {
    return scoreHistory
        .map((e) => e.lungWellnessScore ?? e.score.toDouble())
        .where((s) => s > 0)
        .toList();
  }

  /// Parsed list of band definitions from the API response.
  List<Map<String, dynamic>> get bandList {
    if (scoreBands == null) return [];
    final raw = scoreBands!['bands'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  @override
  List<Object?> get props => [
        status,
        scoreHistory,
        baselineStatus,
        scoreBands,
        errorMessage,
      ];
}
