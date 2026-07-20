import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../onboarding/domain/repositories/wellness_repository.dart';
import 'wellness_event.dart';
import 'wellness_state.dart';

/// Business Logic Component managing user wellness statistics and local updates.
class WellnessBloc extends Bloc<WellnessEvent, WellnessState> {
  final WellnessRepository _repository;

  WellnessBloc({
    required WellnessRepository repository,
  })  : _repository = repository,
        super(WellnessState.initial()) {
    on<WellnessFetchDataEvent>(_onFetchData);
    on<WellnessSaveDailyLogEvent>(_onSaveDailyLog);
    on<WellnessSaveAudioAnalysisEvent>(_onSaveAudioAnalysis);
  }

  Future<void> _onFetchData(WellnessFetchDataEvent event, Emitter<WellnessState> emit) async {
    emit(state.copyWith(status: WellnessStatus.loading));
    try {
      final logs = await _repository.getDailyLogs();
      final analyses = await _repository.getAudioAnalyses();
      emit(state.copyWith(
        status: WellnessStatus.success,
        dailyLogs: logs,
        audioAnalyses: analyses,
      ));
    } catch (e) {
      emit(state.copyWith(status: WellnessStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveDailyLog(WellnessSaveDailyLogEvent event, Emitter<WellnessState> emit) async {
    emit(state.copyWith(status: WellnessStatus.saving));
    try {
      await _repository.saveDailyLog(event.log);
      final logs = await _repository.getDailyLogs();
      emit(state.copyWith(
        status: WellnessStatus.saveSuccess,
        dailyLogs: logs,
      ));
    } catch (e) {
      emit(state.copyWith(status: WellnessStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveAudioAnalysis(WellnessSaveAudioAnalysisEvent event, Emitter<WellnessState> emit) async {
    emit(state.copyWith(status: WellnessStatus.saving));
    try {
      await _repository.saveAudioAnalysis(event.analysis);
      final analyses = await _repository.getAudioAnalyses();
      emit(state.copyWith(
        status: WellnessStatus.saveSuccess,
        audioAnalyses: analyses,
      ));
    } catch (e) {
      emit(state.copyWith(status: WellnessStatus.error, errorMessage: e.toString()));
    }
  }
}
