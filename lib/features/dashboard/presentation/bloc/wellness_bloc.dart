import 'package:flutter_bloc/flutter_bloc.dart';
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
      final componentScores = _parseComponentScores(latestScore?.breakdown);

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

      final logs = results[0] as List;
      final analyses = results[1] as List;
      final scoreHistory = results[2] as List;
      final baselineStatus = results[3] as Map<String, dynamic>?;

      emit(state.copyWith(
        status: WellnessStatus.success,
        dailyLogs: logs.cast(),
        audioAnalyses: analyses.cast(),
        scoreHistory: scoreHistory.cast(),
        latestScore: latestScore,
        baselineStatus: baselineStatus,
        componentScores: componentScores,
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
      final componentScores = _parseComponentScores(latestScore?.breakdown);
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
      final componentScores = _parseComponentScores(latestScore?.breakdown);
      final logs = await _repository.getDailyLogs();
      final scoreHistory = await _repository.getScoreHistory(limit: 30);

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
      final componentScores = _parseComponentScores(latestScore?.breakdown);
      final analyses = await _repository.getAudioAnalyses();
      final scoreHistory = await _repository.getScoreHistory(limit: 30);

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
  Map<String, int> _parseComponentScores(Map<String, dynamic>? breakdown) {
    if (breakdown == null || breakdown.isEmpty) return {};
    final result = <String, int>{};
    for (final key in ['C', 'B', 'S', 'T']) {
      final val = breakdown[key];
      if (val == null) continue;
      if (val is num) {
        result[key] = val.toInt();
      } else if (val is Map) {
        // Some backends return {"score": 77, "band": "fair"} per component
        final inner = val['score'] ?? val['value'];
        if (inner is num) result[key] = inner.toInt();
      } else if (val is String) {
        final parsed = int.tryParse(val);
        if (parsed != null) result[key] = parsed;
      }
    }
    return result;
  }
}
