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

  testWidgets('Dashboard renders Baseline card with active value when baseline is available', (tester) async {
    const testUser = UserEntity(id: 'u1', email: 'test@example.com', name: 'Test User');
    when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(testUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState.initial());
    when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

    final activeState = WellnessState(
      dailyLogs: const [],
      audioAnalyses: const [],
      status: WellnessStatus.success,
      latestScore: ScoreHistoryEntity(
        id: 's1',
        score: 85,
        lungWellnessScore: 85.0,
        coughScore: 88.0,
        breathingScore: 90.0,
        symptomScore: 82.0,
        band: 'good',
        message: 'Good score',
        timestamp: DateTime.now(),
      ),
      componentScores: const {'C': 88, 'B': 90, 'S': 82},
      baselineStatus: const {
        'session_count': 7,
        'status': 'active',
        'baseline_mean': 78.1,
        'message': 'Your personal baseline is active and updating.',
      },
    );

    when(() => mockWellnessBloc.state).thenReturn(activeState);
    when(() => mockWellnessBloc.stream).thenAnswer((_) => wellnessStateController.stream);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify Baseline card header is present
    expect(find.text('Baseline'), findsOneWidget);
    // Verify formatted baseline value is displayed
    expect(find.text('78.1'), findsOneWidget);
    // Verify Active status is displayed
    expect(find.text('Active'), findsOneWidget);
    // Verify message is displayed
    expect(find.text('Your personal baseline is active and updating.'), findsOneWidget);
    // Verify Trend Score is completely gone from the dashboard
    expect(find.text('Trend Score'), findsNothing);
  });

  testWidgets('Dashboard renders user-friendly message when baseline is not yet available', (tester) async {
    const testUser = UserEntity(id: 'u1', email: 'test@example.com', name: 'Test User');
    when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(testUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState.initial());
    when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

    final formingState = WellnessState(
      dailyLogs: const [],
      audioAnalyses: const [],
      status: WellnessStatus.success,
      latestScore: null,
      componentScores: const {},
      baselineStatus: const {
        'session_count': 1,
        'status': 'initializing',
        'message': 'Baseline will be available after a few sessions.',
      },
    );

    when(() => mockWellnessBloc.state).thenReturn(formingState);
    when(() => mockWellnessBloc.stream).thenAnswer((_) => wellnessStateController.stream);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify Baseline card header is present
    expect(find.text('Baseline'), findsOneWidget);
    // Verify friendly message is displayed
    expect(find.text('Baseline will be available after a few sessions.'), findsOneWidget);
    // Verify Forming status is displayed
    expect(find.text('Forming'), findsOneWidget);
    // Verify placeholder numbers or N/A are NOT displayed for baseline
    expect(find.text('0'), findsNothing);
    expect(find.text('N/A'), findsNothing);
    // Verify Trend Score is NOT displayed
    expect(find.text('Trend Score'), findsNothing);
  });
}
