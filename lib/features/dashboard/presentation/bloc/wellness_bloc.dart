import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../../onboarding/domain/repositories/wellness_repository.dart';
import 'wellness_event.dart';
import 'wellness_state.dart';

/// Business Logic Component managing user wellness statistics, score history, and real data updates.
class WellnessBloc extends Bloc<WellnessEvent, WellnessState> {
  final WellnessRepository _repository;

  WellnessBloc({
    required WellnessRepository repository,
  })  : _repository = repository,
        super(WellnessState.initial()) {
    on<WellnessFetchDataEvent>(_onFetchData);
    on<WellnessFetchScoreEvent>(_onFetchScore);
    on<WellnessSaveDailyLogEvent>(_onSaveDailyLog);
    on<WellnessSaveAudioAnalysisEvent>(_onSaveAudioAnalysis);
  }

  /// Full data fetch: score + logs + recordings + history + baseline.
  /// Used on app open and initial dashboard load.
  Future<void> _onFetchData(WellnessFetchDataEvent event, Emitter<WellnessState> emit) async {
    emit(state.copyWith(status: WellnessStatus.loading));
    try {
      // 1. Fetch latest score first (fastest, most important for home screen)
      final latestScore = await _repository.getLatestScore();
      final componentScores = _parseComponentScores(latestScore);

      // Emit score immediately so the dial updates without waiting for heavy data
      emit(state.copyWith(
        status: WellnessStatus.loading,
        latestScore: latestScore,
        componentScores: componentScores,
      ));

      // 2. Fetch supporting data concurrently
      final results = await Future.wait([
        _repository.getDailyLogs(),
        _repository.getAudioAnalyses(),
        _repository.getScoreHistory(limit: 30),
        _repository.getBaselineStatus(),
      ]);

      final logs = (results[0] as List).cast<DailyLogEntity>();
      final analyses = (results[1] as List).cast<AudioAnalysisEntity>();
      final scoreHistory = (results[2] as List).cast<ScoreHistoryEntity>();
      final baselineStatus = results[3] as Map<String, dynamic>?;

      final fullComponentScores = _parseComponentScores(
        latestScore,
        dailyLogs: logs,
        audioAnalyses: analyses,
      );

      emit(state.copyWith(
        status: WellnessStatus.success,
        dailyLogs: logs,
        audioAnalyses: analyses,
        scoreHistory: scoreHistory,
        latestScore: latestScore,
        baselineStatus: baselineStatus,
        componentScores: fullComponentScores,
      ));
    } catch (e) {
      emit(state.copyWith(status: WellnessStatus.error, errorMessage: e.toString()));
    }
  }

  /// Lightweight score-only refresh: only calls GET /score/latest.
  /// Used after recording/symptom submission and on tab switch to Home.
  Future<void> _onFetchScore(WellnessFetchScoreEvent event, Emitter<WellnessState> emit) async {
    emit(state.copyWith(status: WellnessStatus.scoreLoading));
    try {
      final latestScore = await _repository.getLatestScore();
      final componentScores = _parseComponentScores(
        latestScore,
        dailyLogs: state.dailyLogs,
        audioAnalyses: state.audioAnalyses,
      );
      emit(state.copyWith(
        status: WellnessStatus.success,
        latestScore: latestScore,
        componentScores: componentScores,
      ));
    } catch (e) {
      // On score fetch error, revert to success without updating score
      emit(state.copyWith(status: WellnessStatus.success));
    }
  }

  Future<void> _onSaveDailyLog(WellnessSaveDailyLogEvent event, Emitter<WellnessState> emit) async {
    emit(state.copyWith(status: WellnessStatus.saving));
    try {
      await _repository.saveDailyLog(event.log);

      // Fetch fresh score after computation (POST /score/compute is triggered inside saveDailyLog)
      final latestScore = await _repository.getLatestScore();
      final logs = await _repository.getDailyLogs();
      final scoreHistory = await _repository.getScoreHistory(limit: 30);
      final componentScores = _parseComponentScores(
        latestScore,
        dailyLogs: logs,
        audioAnalyses: state.audioAnalyses,
      );

      emit(state.copyWith(
        status: WellnessStatus.saveSuccess,
        dailyLogs: logs,
        scoreHistory: scoreHistory,
        latestScore: latestScore,
        componentScores: componentScores,
      ));
    } catch (e) {
      emit(state.copyWith(status: WellnessStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveAudioAnalysis(WellnessSaveAudioAnalysisEvent event, Emitter<WellnessState> emit) async {
    emit(state.copyWith(status: WellnessStatus.saving));
    try {
      await _repository.saveAudioAnalysis(event.analysis);

      // Fetch fresh score after computation (POST /score/compute is triggered inside saveAudioAnalysis)
      final latestScore = await _repository.getLatestScore();
      final analyses = await _repository.getAudioAnalyses();
      final scoreHistory = await _repository.getScoreHistory(limit: 30);
      final componentScores = _parseComponentScores(
        latestScore,
        dailyLogs: state.dailyLogs,
        audioAnalyses: analyses,
      );

      emit(state.copyWith(
        status: WellnessStatus.saveSuccess,
        audioAnalyses: analyses,
        scoreHistory: scoreHistory,
        latestScore: latestScore,
        componentScores: componentScores,
      ));
    } catch (e) {
      emit(state.copyWith(status: WellnessStatus.error, errorMessage: e.toString()));
    }
  }

  /// Parses the C/B/S/T component scores from backend breakdown map.
  /// Handles both integer and nested object formats.
  /// Ensures Trend Score ('T') is ONLY included when sufficient underlying data is present.
  Map<String, int> _parseComponentScores(
    ScoreHistoryEntity? latestScore, {
    List<DailyLogEntity>? dailyLogs,
    List<AudioAnalysisEntity>? audioAnalyses,
  }) {
    final result = <String, int>{};

    int? extractVal(dynamic val) {
      if (val == null) return null;
      if (val is num && val > 0) return val.toInt();
      if (val is Map) {
        final inner = val['score'] ?? val['value'] ?? val['score_val'];
        if (inner is num && inner > 0) return inner.toInt();
        if (inner is String) {
          final p = int.tryParse(inner);
          if (p != null && p > 0) return p;
        }
      }
      if (val is String) {
        final p = int.tryParse(val);
        if (p != null && p > 0) return p;
      }
      return null;
    }

    if (latestScore != null) {
      if (latestScore.coughScore != null) {
        result['C'] = latestScore.coughScore!.round();
      }
      if (latestScore.breathingScore != null) {
        result['B'] = latestScore.breathingScore!.round();
      }
      if (latestScore.symptomScore != null) {
        result['S'] = latestScore.symptomScore!.round();
      }

      // Check if trend score has sufficient underlying historical data:
      // Trend requires at least 2 sessions/days of underlying user activity.
      final bool hasSufficientTrendData = (latestScore.sessionNumber != null && latestScore.sessionNumber! >= 2) ||
          (dailyLogs != null && dailyLogs.length >= 2) ||
          (audioAnalyses != null && audioAnalyses.length >= 2);

      if (latestScore.trendScore != null && hasSufficientTrendData) {
        result['T'] = latestScore.trendScore!.round();
      }

      final breakdown = latestScore.breakdown;
      if (breakdown != null && breakdown.isNotEmpty) {
        final keyAliases = {
          'C': ['C', 'cough', 'cough_score', 'coughScore', 'cough_wellness_score'],
          'B': ['B', 'breathing', 'breathing_score', 'breathingScore', 'breathing_wellness_score'],
          'S': ['S', 'symptom', 'symptom_score', 'symptomScore', 'daily_checkin_score'],
          'T': ['T', 'trend', 'trend_score', 'trendScore', 'trend_score_val'],
        };

        for (final compKey in ['C', 'B', 'S', 'T']) {
          if (compKey == 'T' && !hasSufficientTrendData) {
            continue; // Do not assign default/dummy trend score without sufficient data
          }
          if (!result.containsKey(compKey)) {
            final aliases = keyAliases[compKey]!;
            for (final alias in aliases) {
              if (breakdown.containsKey(alias)) {
                final v = extractVal(breakdown[alias]);
                if (v != null) {
                  result[compKey] = v;
                  break;
                }
              }
            }
          }
        }
      }
    }

    return result;
  }
}
