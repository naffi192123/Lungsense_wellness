import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/features/daily_checkin/presentation/bloc/daily_checkin_bloc.dart';
import 'package:lungsense_wellness/features/daily_checkin/presentation/bloc/daily_checkin_enums.dart';
import 'package:lungsense_wellness/features/daily_checkin/presentation/bloc/daily_checkin_event.dart';
import 'package:lungsense_wellness/features/daily_checkin/presentation/bloc/daily_checkin_state.dart';
import 'package:lungsense_wellness/features/dashboard/data/datasources/score_remote_data_source.dart';
import 'package:lungsense_wellness/features/onboarding/domain/entities/wellness_entities.dart';
import 'package:lungsense_wellness/features/onboarding/domain/repositories/wellness_repository.dart';

class MockScoreRemoteDataSource extends Mock implements ScoreRemoteDataSource {}
class MockWellnessRepository extends Mock implements WellnessRepository {}

void main() {
  group('DailyCheckinBloc Tests', () {
    late DailyCheckinBloc bloc;
    late MockScoreRemoteDataSource mockScoreRemoteDataSource;
    late MockWellnessRepository mockWellnessRepository;

    final mockCough = AudioAnalysisEntity(
      id: 'cough_123',
      title: 'Cough Recording',
      type: 'Cough',
      status: 'complete',
      duration: 14,
      confidence: 88,
      lungsScore: 88,
      insight: 'Acoustic parameters processed',
      intensity: 'Normal',
      breathingRate: 16,
      rhythm: 'Normal',
      signalQuality: 'Quality: 88%',
      backgroundNoise: 'Low',
      timestamp: DateTime.now(),
      tags: const ['FastAPI Engine'],
      coughEventCount: 3,
    );

    final mockBreathing = AudioAnalysisEntity(
      id: 'breathing_123',
      title: 'Breathing Recording',
      type: 'Breathing',
      status: 'complete',
      duration: 22,
      confidence: 90,
      lungsScore: 90,
      insight: 'Acoustic parameters processed',
      intensity: 'Normal',
      breathingRate: 15,
      rhythm: 'Normal',
      signalQuality: 'Quality: 90%',
      backgroundNoise: 'Low',
      timestamp: DateTime.now(),
      tags: const ['FastAPI Engine'],
      breathingRateBpm: 15.4,
    );

    final mockSymptoms = DailyLogEntity(
      id: 'symptoms_123',
      checkinDate: '2026-08-24',
      breathlessness: 0.0,
      activityLimitation: 0.0,
      changeFromUsual: 0.0,
      fever: 0.0,
      chestTightness: 0.0,
      chestDiscomfortBreathing: 0.0,
      wheezing: 0.0,
      coughSeverity: 1.0,
      mucus: 0.0,
      sleepDisruption: 0.0,
      chestPain: 0.0,
      smokedToday: false,
      exerciseMinutes: 30.0,
      sleepHours: 8.0,
      waterIntakeLiters: 2.0,
      timestamp: DateTime.now(),
    );

    final mockScore = ScoreHistoryEntity(
      id: 'score_123',
      score: 85,
      lungWellnessScore: 85.0,
      coughScore: 88.0,
      breathingScore: 90.0,
      symptomScore: 82.0,
      trendScore: 80.0,
      band: 'good',
      message: 'Score computed fresh from backend.',
      timestamp: DateTime.now(),
    );

    setUp(() {
      mockScoreRemoteDataSource = MockScoreRemoteDataSource();
      mockWellnessRepository = MockWellnessRepository();

      when(() => mockScoreRemoteDataSource.computeScore())
          .thenAnswer((_) async => {'score': 85, 'lung_wellness_score': 85.0});
      when(() => mockScoreRemoteDataSource.completeSession())
          .thenAnswer((_) async {});
      when(() => mockWellnessRepository.getLatestScore())
          .thenAnswer((_) async => mockScore);
      when(() => mockWellnessRepository.getScoreHistory(limit: any(named: 'limit')))
          .thenAnswer((_) async => [mockScore]);
      when(() => mockWellnessRepository.getBaselineStatus())
          .thenAnswer((_) async => {'status': 'active'});

      bloc = DailyCheckinBloc(
        scoreRemoteDataSource: mockScoreRemoteDataSource,
        wellnessRepository: mockWellnessRepository,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should have start step and ready status', () {
      expect(bloc.state.currentStep, equals(CheckinStep.start));
      expect(bloc.state.sessionStatus, equals(CheckinSessionStatus.ready));
      expect(bloc.state.coughCompleted, isFalse);
      expect(bloc.state.breathingCompleted, isFalse);
      expect(bloc.state.symptomsCompleted, isFalse);
    });

    test('CheckinStartEvent transitions to cough step', () async {
      bloc.add(const CheckinStartEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<DailyCheckinState>((s) => s.currentStep == CheckinStep.cough)),
      );
    });

    test('Sequential check-in flow advances from Cough -> Breathing -> Symptoms -> Review', () async {
      // Step 1: Cough completed
      bloc.add(CheckinCoughCompletedEvent(mockCough));
      await expectLater(
        bloc.stream,
        emits(predicate<DailyCheckinState>(
          (s) => s.currentStep == CheckinStep.breathing && s.coughCompleted,
        )),
      );

      // Step 2: Breathing completed
      bloc.add(CheckinBreathingCompletedEvent(mockBreathing));
      await expectLater(
        bloc.stream,
        emits(predicate<DailyCheckinState>(
          (s) => s.currentStep == CheckinStep.symptoms && s.breathingCompleted,
        )),
      );

      // Step 3: Symptoms completed
      bloc.add(CheckinSymptomsCompletedEvent(mockSymptoms));
      await expectLater(
        bloc.stream,
        emits(predicate<DailyCheckinState>(
          (s) => s.currentStep == CheckinStep.review && s.allStepsCompleted,
        )),
      );
    });

    test('CheckinGoBackEvent transitions back sequentially', () async {
      // Move to cough
      bloc.add(const CheckinStartEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<DailyCheckinState>((s) => s.currentStep == CheckinStep.cough)),
      );

      // Go back to start
      bloc.add(const CheckinGoBackEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<DailyCheckinState>((s) => s.currentStep == CheckinStep.start)),
      );
    });

    test('CheckinSubmitEvent executes full API pipeline and completes', () async {
      // Populate all 3 steps
      bloc.add(CheckinCoughCompletedEvent(mockCough));
      bloc.add(CheckinBreathingCompletedEvent(mockBreathing));
      bloc.add(CheckinSymptomsCompletedEvent(mockSymptoms));

      // Submit checkin
      bloc.add(const CheckinSubmitEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<DailyCheckinState>((s) => s.currentStep == CheckinStep.breathing),
          predicate<DailyCheckinState>((s) => s.currentStep == CheckinStep.symptoms),
          predicate<DailyCheckinState>((s) => s.currentStep == CheckinStep.review),
          predicate<DailyCheckinState>((s) => s.currentStep == CheckinStep.completing && s.sessionStatus == CheckinSessionStatus.computingScore),
          predicate<DailyCheckinState>((s) => s.sessionStatus == CheckinSessionStatus.completingSession),
          predicate<DailyCheckinState>((s) => s.sessionStatus == CheckinSessionStatus.refreshingScore),
          predicate<DailyCheckinState>((s) => s.currentStep == CheckinStep.completed && s.sessionStatus == CheckinSessionStatus.completed && s.computedScore != null),
        ]),
      );

      verify(() => mockScoreRemoteDataSource.computeScore()).called(1);
      verify(() => mockScoreRemoteDataSource.completeSession()).called(1);
      verify(() => mockWellnessRepository.getLatestScore()).called(1);
    });
  });
}
