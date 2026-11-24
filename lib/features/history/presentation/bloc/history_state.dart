import 'package:equatable/equatable.dart';
import '../../domain/entities/history_entry.dart';

enum HistoryStatus { initial, loading, success, error }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<HistoryEntry> entries;
  final int totalCount;
  final String? errorMessage;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.entries = const [],
    this.totalCount = 0,
    this.errorMessage,
  });

  factory HistoryState.initial() => const HistoryState();

  HistoryState copyWith({
    HistoryStatus? status,
    List<HistoryEntry>? entries,
    int? totalCount,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Recent activities for home dashboard (first 3-5 grouped entries).
  List<HistoryEntry> get recentActivities => entries.take(5).toList();

  @override
  List<Object?> get props => [status, entries, totalCount, errorMessage];
}
