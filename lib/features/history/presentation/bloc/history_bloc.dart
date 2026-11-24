import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository _repository;

  HistoryBloc({required HistoryRepository repository})
      : _repository = repository,
        super(HistoryState.initial()) {
    on<HistoryFetchEvent>(_onFetch);
    on<HistoryRefreshEvent>(_onRefresh);
    on<HistoryClearEvent>(_onClear);
  }

  Future<void> _onFetch(HistoryFetchEvent event, Emitter<HistoryState> emit) async {
    // Only show full loading if we have no entries yet
    if (state.entries.isEmpty) {
      emit(state.copyWith(status: HistoryStatus.loading));
    }
    try {
      final entries = await _repository.getHistory(
        limit: event.limit,
        offset: event.offset,
      );
      emit(state.copyWith(
        status: HistoryStatus.success,
        entries: entries,
        totalCount: _repository.totalCount,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(HistoryRefreshEvent event, Emitter<HistoryState> emit) async {
    try {
      final entries = await _repository.getHistory(
        limit: event.limit,
        offset: 0,
      );
      emit(state.copyWith(
        status: HistoryStatus.success,
        entries: entries,
        totalCount: _repository.totalCount,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClear(HistoryClearEvent event, Emitter<HistoryState> emit) {
    emit(HistoryState.initial());
  }
}
