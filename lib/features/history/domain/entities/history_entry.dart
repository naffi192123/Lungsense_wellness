import 'package:equatable/equatable.dart';

/// Represents a single raw record returned by the GET /history API.
class HistoryRecord extends Equatable {
  final String type; // 'cough', 'breathing', or 'symptom'
  final String activityId;
  final DateTime timestamp;
  final String status; // 'complete' or 'failed'
  final Map<String, dynamic>? results;
  final String? error;

  const HistoryRecord({
    required this.type,
    required this.activityId,
    required this.timestamp,
    required this.status,
    this.results,
    this.error,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      type: json['type'] as String? ?? 'unknown',
      activityId: json['activity_id'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString())?.toLocal() ??
              DateTime.now())
          : DateTime.now(),
      status: json['status'] as String? ?? 'complete',
      results: json['results'] is Map
          ? Map<String, dynamic>.from(json['results'] as Map)
          : null,
      error: json['error'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, activityId, timestamp, status, results, error];
}

/// Represents a consolidated history entry grouped by activity_id.
/// Multiple [HistoryRecord]s sharing the same activity_id are merged into one entry.
class HistoryEntry extends Equatable {
  final String activityId;
  final DateTime latestTimestamp;
  final String overallStatus; // 'complete' if any record is complete, else 'failed'
  final List<HistoryRecord> records;

  const HistoryEntry({
    required this.activityId,
    required this.latestTimestamp,
    required this.overallStatus,
    required this.records,
  });

  /// All unique activity types in this group (e.g., ['cough', 'breathing', 'symptom']).
  Set<String> get types => records.map((r) => r.type).toSet();

  /// True if at least one record has type 'cough'.
  bool get hasCough => records.any((r) => r.type == 'cough');

  /// True if at least one record has type 'breathing'.
  bool get hasBreathing => records.any((r) => r.type == 'breathing');

  /// True if at least one record has type 'symptom'.
  bool get hasSymptom => records.any((r) => r.type == 'symptom');

  /// Returns the first failed error message, if any.
  String? get errorMessage {
    for (final r in records) {
      if (r.status == 'failed' && r.error != null && r.error!.isNotEmpty) {
        return r.error;
      }
    }
    return null;
  }

  /// Consolidated results from all records.
  Map<String, dynamic> get consolidatedResults {
    final merged = <String, dynamic>{};
    for (final r in records) {
      if (r.results != null) {
        // Prefix results with the record type to avoid collisions
        merged['${r.type}_results'] = r.results;
      }
    }
    return merged;
  }

  /// User-facing title summarising the activity types.
  String get title {
    final typeNames = <String>[];
    if (hasCough) typeNames.add('Cough');
    if (hasBreathing) typeNames.add('Breathing');
    if (hasSymptom) typeNames.add('Symptom Check-in');
    if (typeNames.isEmpty) return 'Activity';
    if (typeNames.length == 1) return '${typeNames.first} Recording';
    // Multiple types in one activity → "Daily Check-in"
    return 'Daily Check-in';
  }

  /// User-facing subtitle with component summary.
  String get subtitle {
    final parts = <String>[];
    if (hasCough) parts.add('Cough');
    if (hasBreathing) parts.add('Breathing');
    if (hasSymptom) parts.add('Symptoms');
    final statusLabel = overallStatus == 'complete' ? 'Completed' : 'Failed';
    return '${parts.join(' • ')} • $statusLabel';
  }

  @override
  List<Object?> get props => [activityId, latestTimestamp, overallStatus, records];
}
