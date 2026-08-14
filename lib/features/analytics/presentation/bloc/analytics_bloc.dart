import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../../onboarding/domain/repositories/wellness_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

/// BLoC managing the Analytics page data lifecycle.
/// Independently fetches:
///   • GET /score/history  → score history and trend chart data
///   • GET /score/baseline → baseline progress status
///   • GET /score/bands    → category band definitions
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final WellnessRepository _repository;

  AnalyticsBloc({required WellnessRepository repository})
      : _repository = repository,
        super(AnalyticsState.initial()) {
    on<AnalyticsLoadEvent>(_onLoad);
  }

  Future<void> _onLoad(
    AnalyticsLoadEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: AnalyticsStatus.loading));
    try {
      // Fetch all three endpoints concurrently for minimal latency
      final historyFuture = _repository.getScoreHistory(limit: 50);
      final baselineFuture = _repository.getBaselineStatus();
      final bandsFuture = _repository.getScoreBands();

      final List<ScoreHistoryEntity> history = await historyFuture;
      final Map<String, dynamic> baseline = await baselineFuture;
      final Map<String, dynamic> bands = await bandsFuture;

      emit(state.copyWith(
        status: AnalyticsStatus.success,
        scoreHistory: history,
        baselineStatus: baseline,
        scoreBands: bands,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AnalyticsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
