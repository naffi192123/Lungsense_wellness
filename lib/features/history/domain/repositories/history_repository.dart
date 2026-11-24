import '../entities/history_entry.dart';

/// Repository interface for history entries.
abstract class HistoryRepository {
  /// Fetches history from the API and returns consolidated [HistoryEntry] list,
  /// grouped by activity_id, sorted by most recent timestamp first.
  Future<List<HistoryEntry>> getHistory({int limit = 50, int offset = 0});

  /// Total count of raw entries from the most recent fetch.
  int get totalCount;
}
