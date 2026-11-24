import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_wellness/features/history/domain/entities/history_entry.dart';
import 'package:lungsense_wellness/features/history/domain/repositories/history_repository.dart';
import 'package:lungsense_wellness/features/history/presentation/bloc/history_bloc.dart';
import 'package:lungsense_wellness/features/history/presentation/bloc/history_event.dart';
import 'package:lungsense_wellness/features/history/presentation/bloc/history_state.dart';

class MockHistoryRepository implements HistoryRepository {
  List<HistoryEntry> entries = [];
  int count = 0;

  @override
  int get totalCount => count;

  @override
  Future<List<HistoryEntry>> getHistory({int limit = 50, int offset = 0}) async {
    return entries;
  }
}

void main() {
  late MockHistoryRepository mockRepository;
  late HistoryBloc historyBloc;

  setUp(() {
    mockRepository = MockHistoryRepository();
    historyBloc = HistoryBloc(repository: mockRepository);
  });

  tearDown(() {
    historyBloc.close();
  });

  group('HistoryBloc', () {
    test('initial state has empty entries and initial status', () {
      expect(historyBloc.state.status, HistoryStatus.initial);
      expect(historyBloc.state.entries, isEmpty);
      expect(historyBloc.state.recentActivities, isEmpty);
    });

    test('emits [loading, success] on successful HistoryFetchEvent', () async {
      final sampleEntry = HistoryEntry(
        activityId: 'act-1',
        latestTimestamp: DateTime.now(),
        overallStatus: 'complete',
        records: [
          HistoryRecord(
            type: 'cough',
            activityId: 'act-1',
            timestamp: DateTime.now(),
            status: 'complete',
          ),
        ],
      );

      mockRepository.entries = [sampleEntry];
      mockRepository.count = 1;

      expectLater(
        historyBloc.stream,
        emitsInOrder([
          const HistoryState(status: HistoryStatus.loading),
          HistoryState(
            status: HistoryStatus.success,
            entries: [sampleEntry],
            totalCount: 1,
          ),
        ]),
      );

      historyBloc.add(const HistoryFetchEvent());
    });

    test('HistoryClearEvent resets state to initial (account isolation on logout)', () async {
      final sampleEntry = HistoryEntry(
        activityId: 'act-1',
        latestTimestamp: DateTime.now(),
        overallStatus: 'complete',
        records: [],
      );

      mockRepository.entries = [sampleEntry];
      mockRepository.count = 1;

      historyBloc.add(const HistoryFetchEvent());
      await pumpEventQueue();

      expect(historyBloc.state.entries.length, 1);

      // On logout:
      historyBloc.add(const HistoryClearEvent());
      await pumpEventQueue();

      expect(historyBloc.state.status, HistoryStatus.initial);
      expect(historyBloc.state.entries, isEmpty);
      expect(historyBloc.state.totalCount, 0);
    });
  });
}
