import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/features/dashboard/presentation/bloc/wellness_bloc.dart';
import 'package:lungsense_wellness/features/dashboard/presentation/bloc/wellness_event.dart';
import 'package:lungsense_wellness/features/dashboard/presentation/bloc/wellness_state.dart';
import 'package:lungsense_wellness/features/onboarding/domain/entities/wellness_entities.dart';
import 'package:lungsense_wellness/features/onboarding/domain/repositories/wellness_repository.dart';

class MockWellnessRepository extends Mock implements WellnessRepository {}

void main() {
  group('WellnessBloc and WellnessState Baseline Tests', () {
    late WellnessBloc bloc;
    late MockWellnessRepository mockRepository;

    final mockScore = ScoreHistoryEntity(
      id: 'score_1',
      score: 85,
      lungWellnessScore: 85.0,
      coughScore: 88.0,
      breathingScore: 90.0,
      symptomScore: 82.0,
      band: 'good',
      message: 'All metrics within normal ranges.',
      timestamp: DateTime(2026, 9, 16, 12, 0),
    );

    setUp(() {
      mockRepository = MockWellnessRepository();
      when(() => mockRepository.getLatestScore()).thenAnswer((_) async => mockScore);
      when(() => mockRepository.getDailyLogs()).thenAnswer((_) async => []);
      when(() => mockRepository.getAudioAnalyses()).thenAnswer((_) async => []);
      when(() => mockRepository.getScoreHistory(limit: any(named: 'limit'))).thenAnswer((_) async => [mockScore]);

      bloc = WellnessBloc(repository: mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    test('WellnessState.baselineValue extracts baseline_mean as double', () {
      const stateWithBaseline = WellnessState(
        dailyLogs: [],
        audioAnalyses: [],
        status: WellnessStatus.success,
        baselineStatus: {
          'session_count': 7,
          'status': 'active',
          'baseline_mean': 78.1,
          'message': 'Your personal baseline is active and updating.',
        },
      );

      expect(stateWithBaseline.baselineValue, equals(78.1));
      expect(stateWithBaseline.baselineStatusText, equals('Active'));
      expect(stateWithBaseline.baselineMessage, equals('Your personal baseline is active and updating.'));
    });

    test('WellnessState.baselineValue returns null when status is initializing or baseline_mean missing', () {
      const stateInitializing = WellnessState(
        dailyLogs: [],
        audioAnalyses: [],
        status: WellnessStatus.success,
        baselineStatus: {
          'session_count': 1,
          'status': 'initializing',
          'message': 'Baseline will be available after a few sessions.',
        },
      );

      expect(stateInitializing.baselineValue, isNull);
      expect(stateInitializing.baselineStatusText, equals('Forming'));
      expect(stateInitializing.baselineMessage, equals('Baseline will be available after a few sessions.'));
    });

    test('WellnessState.baselineValue returns null when baselineStatus is null or empty', () {
      const stateEmpty = WellnessState(
        dailyLogs: [],
        audioAnalyses: [],
        status: WellnessStatus.initial,
      );

      expect(stateEmpty.baselineValue, isNull);
      expect(stateEmpty.baselineStatusText, isNull);
      expect(stateEmpty.baselineMessage, isNull);
    });

    test('WellnessFetchDataEvent fetches baseline status dynamically from repository', () async {
      when(() => mockRepository.getBaselineStatus()).thenAnswer(
        (_) async => {
          'session_count': 7,
          'status': 'active',
          'baseline_mean': 78.1,
          'message': 'Your personal baseline is active and updating.',
        },
      );

      bloc.add(const WellnessFetchDataEvent());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<WellnessState>((s) {
          return s.status == WellnessStatus.success &&
              s.baselineValue == 78.1 &&
              s.baselineStatusText == 'Active';
        })),
      );

      verify(() => mockRepository.getBaselineStatus()).called(1);
    });

    test('WellnessFetchScoreEvent dynamically refreshes baselineStatus concurrently with latest score', () async {
      when(() => mockRepository.getBaselineStatus()).thenAnswer(
        (_) async => {
          'session_count': 8,
          'status': 'active',
          'baseline_mean': 79.25,
          'message': 'Updated baseline.',
        },
      );

      bloc.add(const WellnessFetchScoreEvent());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<WellnessState>((s) {
          return s.status == WellnessStatus.success &&
              s.baselineValue == 79.25 &&
              s.baselineMessage == 'Updated baseline.';
        })),
      );

      verify(() => mockRepository.getBaselineStatus()).called(1);
    });
  });
}
