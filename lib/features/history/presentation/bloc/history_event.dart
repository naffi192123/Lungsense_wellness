import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch history from backend API (GET /history?limit=...&offset=...).
class HistoryFetchEvent extends HistoryEvent {
  final int limit;
  final int offset;

  const HistoryFetchEvent({this.limit = 50, this.offset = 0});

  @override
  List<Object?> get props => [limit, offset];
}

/// Refresh history data.
class HistoryRefreshEvent extends HistoryEvent {
  final int limit;

  const HistoryRefreshEvent({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}

/// Clears cached history data on user logout.
class HistoryClearEvent extends HistoryEvent {
  const HistoryClearEvent();
}
