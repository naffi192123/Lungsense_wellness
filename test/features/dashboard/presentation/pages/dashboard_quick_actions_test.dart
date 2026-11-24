import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/core/network/api_client.dart';
import 'package:lungsense_wellness/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:lungsense_wellness/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:lungsense_wellness/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:lungsense_wellness/features/auth/domain/entities/user_entity.dart';
import 'package:lungsense_wellness/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lungsense_wellness/features/auth/presentation/bloc/auth_state.dart';
import 'package:lungsense_wellness/features/dashboard/presentation/bloc/wellness_bloc.dart';
import 'package:lungsense_wellness/features/dashboard/presentation/bloc/wellness_event.dart';
import 'package:lungsense_wellness/features/dashboard/presentation/bloc/wellness_state.dart';
import 'package:lungsense_wellness/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:lungsense_wellness/features/onboarding/domain/entities/wellness_entities.dart';

class MockWellnessBloc extends Mock implements WellnessBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockAnalyticsBloc extends Mock implements AnalyticsBloc {}
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockWellnessBloc mockWellnessBloc;
  late MockAuthBloc mockAuthBloc;
  late MockAnalyticsBloc mockAnalyticsBloc;
  late MockApiClient mockApiClient;
  late StreamController<WellnessState> wellnessStateController;

  setUpAll(() {
    registerFallbackValue(const WellnessFetchDataEvent());
    registerFallbackValue(const WellnessFetchScoreEvent());
    registerFallbackValue(const AnalyticsLoadEvent());
  });

  setUp(() async {
    mockWellnessBloc = MockWellnessBloc();
    mockAuthBloc = MockAuthBloc();
    mockAnalyticsBloc = MockAnalyticsBloc();
    mockApiClient = MockApiClient();
    wellnessStateController = StreamController<WellnessState>.broadcast();

    when(() => mockApiClient.userName).thenReturn('Test User');
    when(() => mockWellnessBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    when(() => mockAnalyticsBloc.close()).thenAnswer((_) async {});

    const testUser = UserEntity(id: 'u1', email: 'test@example.com', name: 'Test User');
    when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(testUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState.initial());
    when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

    final sl = GetIt.instance;
    await sl.reset();
    sl.registerSingleton<ApiClient>(mockApiClient);
  });

  tearDown(() async {
    wellnessStateController.close();
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WellnessBloc>.value(value: mockWellnessBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<AnalyticsBloc>.value(value: mockAnalyticsBloc),
      ],
      child: const MaterialApp(
        home: DashboardPage(initialTab: 0),
      ),
    );
  }

  group('Home Dashboard Quick Actions Card States', () {
    testWidgets('displays Pending state when account has zero activities', (tester) async {
      when(() => mockWellnessBloc.state).thenReturn(WellnessState.initial());
      when(() => mockWellnessBloc.stream).thenAnswer((_) => wellnessStateController.stream);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Daily Check-in'), findsWidgets);
      expect(find.text('Daily Check-in Pending'), findsOneWidget);
      expect(find.text("Complete 3 steps to get today's score."), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Record More'), findsNothing);
      expect(find.text('All 3 steps completed today'), findsNothing);
    });

    testWidgets('displays Pending state when only 2 of 3 activities are complete (cough + breathing, no symptoms)', (tester) async {
      final now = DateTime.now();
      final partialState = WellnessState(
        status: WellnessStatus.success,
        dailyLogs: const [], // No symptom log today
        audioAnalyses: [
          AudioAnalysisEntity(
            id: 'c1',
            title: 'Cough Recording',
            type: 'Cough',
            status: 'complete',
            duration: 15,
            confidence: 85,
            lungsScore: 85,
            insight: '',
            intensity: '',
            breathingRate: 0,
            rhythm: '',
            signalQuality: '',
            backgroundNoise: '',
            timestamp: now,
            tags: const [],
          ),
          AudioAnalysisEntity(
            id: 'b1',
            title: 'Breathing Recording',
            type: 'Breathing',
            status: 'complete',
            duration: 30,
            confidence: 90,
            lungsScore: 90,
            insight: '',
            intensity: '',
            breathingRate: 16,
            rhythm: '',
            signalQuality: '',
            backgroundNoise: '',
            timestamp: now,
            tags: const [],
          ),
        ],
      );

      when(() => mockWellnessBloc.state).thenReturn(partialState);
      when(() => mockWellnessBloc.stream).thenAnswer((_) => wellnessStateController.stream);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Must still show Pending because symptom check-in is incomplete
      expect(find.text('Daily Check-in Pending'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Record More'), findsNothing);
    });

    testWidgets('displays Pending state when activities are from yesterday, not today', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayState = WellnessState(
        status: WellnessStatus.success,
        dailyLogs: [
          DailyLogEntity(
            id: 'l1',
            checkinDate: '2026-11-23',
            breathlessness: 0,
            activityLimitation: 0,
            changeFromUsual: 0,
            fever: 0,
            chestTightness: 0,
            chestDiscomfortBreathing: 0,
            wheezing: 0,
            coughSeverity: 0,
            mucus: 0,
            sleepDisruption: 0,
            chestPain: 0,
            smokedToday: false,
            exerciseMinutes: 30,
            sleepHours: 8,
            waterIntakeLiters: 2,
            timestamp: yesterday,
          ),
        ],
        audioAnalyses: [
          AudioAnalysisEntity(
            id: 'c1',
            title: 'Cough Recording',
            type: 'Cough',
            status: 'complete',
            duration: 15,
            confidence: 85,
            lungsScore: 85,
            insight: '',
            intensity: '',
            breathingRate: 0,
            rhythm: '',
            signalQuality: '',
            backgroundNoise: '',
            timestamp: yesterday,
            tags: const [],
          ),
          AudioAnalysisEntity(
            id: 'b1',
            title: 'Breathing Recording',
            type: 'Breathing',
            status: 'complete',
            duration: 30,
            confidence: 90,
            lungsScore: 90,
            insight: '',
            intensity: '',
            breathingRate: 16,
            rhythm: '',
            signalQuality: '',
            backgroundNoise: '',
            timestamp: yesterday,
            tags: const [],
          ),
        ],
      );

      when(() => mockWellnessBloc.state).thenReturn(yesterdayState);
      when(() => mockWellnessBloc.stream).thenAnswer((_) => wellnessStateController.stream);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Daily Check-in Pending'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Record More'), findsNothing);
    });

    testWidgets('displays Completed state when ALL THREE activities are complete today', (tester) async {
      final now = DateTime.now();
      final completedState = WellnessState(
        status: WellnessStatus.success,
        dailyLogs: [
          DailyLogEntity(
            id: 'l1',
            checkinDate: '2026-11-24',
            breathlessness: 0,
            activityLimitation: 0,
            changeFromUsual: 0,
            fever: 0,
            chestTightness: 0,
            chestDiscomfortBreathing: 0,
            wheezing: 0,
            coughSeverity: 0,
            mucus: 0,
            sleepDisruption: 0,
            chestPain: 0,
            smokedToday: false,
            exerciseMinutes: 30,
            sleepHours: 8,
            waterIntakeLiters: 2,
            timestamp: now,
          ),
        ],
        audioAnalyses: [
          AudioAnalysisEntity(
            id: 'c1',
            title: 'Cough Recording',
            type: 'Cough',
            status: 'complete',
            duration: 15,
            confidence: 85,
            lungsScore: 85,
            insight: '',
            intensity: '',
            breathingRate: 0,
            rhythm: '',
            signalQuality: '',
            backgroundNoise: '',
            timestamp: now,
            tags: const [],
          ),
          AudioAnalysisEntity(
            id: 'b1',
            title: 'Breathing Recording',
            type: 'Breathing',
            status: 'complete',
            duration: 30,
            confidence: 90,
            lungsScore: 90,
            insight: '',
            intensity: '',
            breathingRate: 16,
            rhythm: '',
            signalQuality: '',
            backgroundNoise: '',
            timestamp: now,
            tags: const [],
          ),
        ],
      );

      when(() => mockWellnessBloc.state).thenReturn(completedState);
      when(() => mockWellnessBloc.stream).thenAnswer((_) => wellnessStateController.stream);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Daily Check-in'), findsWidgets);
      expect(find.text('All 3 steps completed today'), findsOneWidget);
      expect(find.text('Record More'), findsOneWidget);
      expect(find.text('Tap to add more recordings anytime'), findsOneWidget);
      expect(find.text('Daily Check-in Pending'), findsNothing);
      expect(find.text('Start'), findsNothing);
    });
  });
}
