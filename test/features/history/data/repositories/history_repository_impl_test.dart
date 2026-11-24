import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_wellness/features/history/data/datasources/history_remote_data_source.dart';
import 'package:lungsense_wellness/features/history/data/repositories/history_repository_impl.dart';

class MockHistoryRemoteDataSource implements HistoryRemoteDataSource {
  Map<String, dynamic> response = {'count': 0, 'entries': []};

  @override
  Future<Map<String, dynamic>> getHistory({int limit = 50, int offset = 0}) async {
    return response;
  }
}

void main() {
  late MockHistoryRemoteDataSource mockDataSource;
  late HistoryRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockHistoryRemoteDataSource();
    repository = HistoryRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('HistoryRepositoryImpl - activity_id grouping', () {
    test('groups multiple records with the same activity_id into ONE single entry', () async {
      mockDataSource.response = {
        'count': 3,
        'entries': [
          {
            'type': 'cough',
            'activity_id': 'act-101',
            'timestamp': '2026-11-24T10:00:00Z',
            'status': 'complete',
            'results': {'quality_score': 85},
            'error': null,
          },
          {
            'type': 'breathing',
            'activity_id': 'act-101',
            'timestamp': '2026-11-24T10:02:00Z',
            'status': 'complete',
            'results': {'breathing_rate_bpm': 16.5},
            'error': null,
          },
          {
            'type': 'symptom',
            'activity_id': 'act-101',
            'timestamp': '2026-11-24T10:03:00Z',
            'status': 'complete',
            'results': {'breathlessness': 1},
            'error': null,
          },
          {
            'type': 'cough',
            'activity_id': 'act-102',
            'timestamp': '2026-11-23T08:00:00Z',
            'status': 'failed',
            'results': null,
            'error': 'Recording too short',
          },
        ],
      };

      final result = await repository.getHistory(limit: 50, offset: 0);

      // Should be grouped into 2 entries (act-101 and act-102)
      expect(result.length, 2);

      final act101 = result.firstWhere((e) => e.activityId == 'act-101');
      expect(act101.records.length, 3);
      expect(act101.hasCough, isTrue);
      expect(act101.hasBreathing, isTrue);
      expect(act101.hasSymptom, isTrue);
      expect(act101.overallStatus, 'complete');
      expect(act101.title, 'Daily Check-in');

      // Latest timestamp should be 10:03:00
      expect(act101.latestTimestamp, DateTime.parse('2026-11-24T10:03:00Z').toLocal());

      final act102 = result.firstWhere((e) => e.activityId == 'act-102');
      expect(act102.records.length, 1);
      expect(act102.overallStatus, 'failed');
      expect(act102.errorMessage, 'Recording too short');
    });

    test('sorts consolidated entries newest first', () async {
      mockDataSource.response = {
        'count': 2,
        'entries': [
          {
            'type': 'cough',
            'activity_id': 'older-act',
            'timestamp': '2026-11-20T10:00:00Z',
            'status': 'complete',
          },
          {
            'type': 'cough',
            'activity_id': 'newer-act',
            'timestamp': '2026-11-24T10:00:00Z',
            'status': 'complete',
          },
        ],
      };

      final result = await repository.getHistory(limit: 50, offset: 0);

      expect(result.first.activityId, 'newer-act');
      expect(result.last.activityId, 'older-act');
    });

    test('handles empty response gracefully', () async {
      mockDataSource.response = {'count': 0, 'entries': []};

      final result = await repository.getHistory(limit: 50, offset: 0);

      expect(result, isEmpty);
      expect(repository.totalCount, 0);
    });
  });
}
