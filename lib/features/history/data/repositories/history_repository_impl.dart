import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_data_source.dart';

/// Implementation of [HistoryRepository] that fetches from the History API
/// and groups records by activity_id.
class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _remoteDataSource;
  int _totalCount = 0;

  HistoryRepositoryImpl({required HistoryRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  int get totalCount => _totalCount;

  @override
  Future<List<HistoryEntry>> getHistory({int limit = 50, int offset = 0}) async {
    final response = await _remoteDataSource.getHistory(limit: limit, offset: offset);
    _totalCount = (response['count'] as num?)?.toInt() ?? 0;

    final rawEntries = response['entries'];
    if (rawEntries == null || rawEntries is! List) {
      return [];
    }

    // Parse raw records
    final List<HistoryRecord> records = [];
    for (final entry in rawEntries) {
      if (entry is Map<String, dynamic>) {
        records.add(HistoryRecord.fromJson(entry));
      }
    }

    // Group by activity_id
    return _groupByActivityId(records);
  }

  /// Groups [HistoryRecord]s by their activity_id into consolidated [HistoryEntry]s.
  /// Records with the same activity_id are merged into a single entry.
  /// Sorted by most recent timestamp, newest first.
  List<HistoryEntry> _groupByActivityId(List<HistoryRecord> records) {
    final Map<String, List<HistoryRecord>> groups = {};

    for (final record in records) {
      final key = record.activityId.isNotEmpty ? record.activityId : record.hashCode.toString();
      groups.putIfAbsent(key, () => []).add(record);
    }

    final List<HistoryEntry> entries = [];

    for (final entry in groups.entries) {
      final groupRecords = entry.value;

      // Sort records within the group by timestamp descending
      groupRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Latest timestamp across all records in this group
      final latestTimestamp = groupRecords.first.timestamp;

      // Overall status: 'complete' if ANY record is complete, else 'failed'
      final hasComplete = groupRecords.any((r) => r.status == 'complete');
      final overallStatus = hasComplete ? 'complete' : 'failed';

      entries.add(HistoryEntry(
        activityId: entry.key,
        latestTimestamp: latestTimestamp,
        overallStatus: overallStatus,
        records: groupRecords,
      ));
    }

    // Sort consolidated entries by most recent timestamp, newest first
    entries.sort((a, b) => b.latestTimestamp.compareTo(a.latestTimestamp));

    return entries;
  }
}
