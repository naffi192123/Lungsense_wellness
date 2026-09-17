import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:lungsense_wellness/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:lungsense_wellness/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:lungsense_wellness/features/analytics/presentation/pages/analytics_page.dart';
import 'package:lungsense_wellness/features/onboarding/domain/entities/wellness_entities.dart';

class MockAnalyticsBloc extends Mock implements AnalyticsBloc {}

void main() {
  late MockAnalyticsBloc mockAnalyticsBloc;

  setUpAll(() {
    registerFallbackValue(const AnalyticsLoadEvent());
  });

  setUp(() {
    mockAnalyticsBloc = MockAnalyticsBloc();
    when(() => mockAnalyticsBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AnalyticsBloc>.value(
        value: mockAnalyticsBloc,
        child: const AnalyticsPage(),
      ),
    );
  }

  group('AnalyticsPage Widget Tests', () {
    testWidgets('renders Header with title, subtitle, filter dropdown, and refresh button', (tester) async {
      when(() => mockAnalyticsBloc.state).thenReturn(const AnalyticsState(
        status: AnalyticsStatus.success,
        scoreHistory: [],
      ));
      when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Your lung wellness insights'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.byTooltip('Refresh analytics'), findsOneWidget);
    });

    testWidgets('renders 3 summary cards with correct LATEST, AVERAGE, PEAK calculations', (tester) async {
      final now = DateTime.now();
      final history = [
        ScoreHistoryEntity(
          id: 's3',
          score: 85,
          lungWellnessScore: 85.0,
          band: 'good',
          message: 'Good',
          timestamp: now,
        ),
        ScoreHistoryEntity(
          id: 's2',
          score: 75,
          lungWellnessScore: 75.0,
          band: 'moderate',
          message: 'Moderate',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
        ScoreHistoryEntity(
          id: 's1',
          score: 95,
          lungWellnessScore: 95.0,
          band: 'good',
          message: 'Great',
          timestamp: now.subtract(const Duration(days: 2)),
        ),
      ];

      when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState(
        status: AnalyticsStatus.success,
        scoreHistory: history,
        baselineStatus: const {'session_count': 3, 'status': 'progressing'},
      ));
      when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Card 1: Latest = 85
      expect(find.text('LATEST SCORE'), findsOneWidget);
      expect(find.text('85'), findsWidgets); // Latest score card and bar

      // Card 2: Average = (85 + 75 + 95) / 3 = 85
      expect(find.text('AVERAGE SCORE'), findsOneWidget);

      // Card 3: Peak = 95
      expect(find.text('PEAK SCORE'), findsOneWidget);
      expect(find.text('95'), findsWidgets);
    });

    testWidgets('renders BUILDING baseline panel when valid sessions < 7', (tester) async {
      final now = DateTime.now();
      final history = List.generate(
        4,
        (i) => ScoreHistoryEntity(
          id: 's$i',
          score: 70 + i * 2,
          lungWellnessScore: (70 + i * 2).toDouble(),
          band: 'moderate',
          message: 'Moderate',
          timestamp: now.subtract(Duration(days: 4 - i)),
        ),
      );

      when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState(
        status: AnalyticsStatus.success,
        scoreHistory: history,
        baselineStatus: const {
          'session_count': 4,
          'status': 'progressing',
        },
      ));
      when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('PERSONAL BASELINE'), findsOneWidget);
      expect(find.text('BUILDING'), findsOneWidget);
      expect(find.text('4 / 7 sessions'), findsOneWidget);
      expect(find.text('Complete 7 sessions to establish your personal baseline.'), findsOneWidget);

      // Baseline number and vs Baseline must NOT be visible
      expect(find.text('vs Baseline'), findsNothing);
      expect(find.textContaining('Personal baseline'), findsNothing);
    });

    testWidgets('renders ACTIVE baseline panel and chart line when valid sessions >= 7', (tester) async {
      final now = DateTime.now();
      // Generate 7 sessions
      final history = List.generate(
        7,
        (i) => ScoreHistoryEntity(
          id: 's$i',
          score: 70 + i,
          lungWellnessScore: (70 + i).toDouble(),
          band: 'good',
          message: 'Good',
          timestamp: now.subtract(Duration(days: 7 - i)),
        ),
      );

      when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState(
        status: AnalyticsStatus.success,
        scoreHistory: history,
        baselineStatus: const {
          'session_count': 7,
          'status': 'active',
          'baseline_mean': 73.0,
        },
      ));
      when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Personal Baseline'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('73.0'), findsNWidgets(2));
      expect(find.text('LATEST VS BASELINE'), findsOneWidget);
    });

    testWidgets('renders Key Insights with Trend, Baseline, and Performance cards', (tester) async {
      final now = DateTime.now();
      // Sessions with upward trend
      final history = [
        ScoreHistoryEntity(
          id: 's3',
          score: 90,
          lungWellnessScore: 90.0,
          band: 'good',
          message: 'Good',
          timestamp: now,
        ),
        ScoreHistoryEntity(
          id: 's2',
          score: 80,
          lungWellnessScore: 80.0,
          band: 'good',
          message: 'Good',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
        ScoreHistoryEntity(
          id: 's1',
          score: 70,
          lungWellnessScore: 70.0,
          band: 'moderate',
          message: 'Moderate',
          timestamp: now.subtract(const Duration(days: 2)),
        ),
      ];

      when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState(
        status: AnalyticsStatus.success,
        scoreHistory: history,
        baselineStatus: const {'session_count': 3, 'status': 'progressing'},
      ));
      when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Key Insights'), findsOneWidget);
      // Upward trend: slope > 0.5
      expect(find.text('Trends Upward'), findsOneWidget);
      expect(find.text('Your wellness score is trending upward over recent sessions.'), findsOneWidget);

      // Building baseline: < 7 sessions
      expect(find.text('Building Baseline'), findsOneWidget);
      expect(find.text('Complete 7 sessions to unlock your personal baseline insights.'), findsOneWidget);

      // Latest = 90, Peak = 90 -> Personal Best
      expect(find.text('Personal Best'), findsOneWidget);
      expect(find.text('Your latest score (90) is your highest so far!'), findsOneWidget);
    });

    testWidgets('renders Score Distribution card with What is this button and opens bottom sheet', (tester) async {
      final now = DateTime.now();
      final history = [
        ScoreHistoryEntity(
          id: 's2',
          score: 85,
          lungWellnessScore: 85.0,
          band: 'good',
          message: 'Good',
          timestamp: now,
        ),
        ScoreHistoryEntity(
          id: 's1',
          score: 65,
          lungWellnessScore: 65.0,
          band: 'moderate',
          message: 'Moderate',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ];

      when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState(
        status: AnalyticsStatus.success,
        scoreHistory: history,
      ));
      when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Score Distribution'), findsOneWidget);
      expect(find.text('Based on 2 sessions'), findsOneWidget);
      expect(find.text('What is this?'), findsOneWidget);
      expect(find.text('80 – 100'), findsOneWidget);
      expect(find.text('60 – 79'), findsOneWidget);

      // Scroll to "What is this?" and tap
      await tester.ensureVisible(find.text('What is this?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('What is this?'));
      await tester.pumpAndSettle();

      expect(find.text('About Score Distribution'), findsOneWidget);
      expect(
        find.text(
          'Score Distribution shows how your completed Wellness Scores are spread across different score ranges. The percentage represents the proportion of your completed sessions within each range.',
        ),
        findsOneWidget,
      );
      expect(find.text('Got it'), findsOneWidget);

      // Dismiss bottom sheet
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('About Score Distribution'), findsNothing);
    });

    testWidgets('chart is automatically positioned at rightmost sessions by default', (tester) async {
      final now = DateTime.now();
      // Generate 30 sessions so content width (886px) exceeds test viewport (682px)
      final history = List.generate(
        30,
        (i) => ScoreHistoryEntity(
          id: 's$i',
          score: 70 + (i % 25),
          lungWellnessScore: (70 + (i % 25)).toDouble(),
          band: 'good',
          message: 'Good',
          timestamp: now.subtract(Duration(days: 30 - i)),
        ),
      );

      when(() => mockAnalyticsBloc.state).thenReturn(AnalyticsState(
        status: AnalyticsStatus.success,
        scoreHistory: history,
      ));
      when(() => mockAnalyticsBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Locate the horizontal chart SingleChildScrollView
      final scrollViews = find.byType(SingleChildScrollView);
      final chartScrollView = tester.widgetList<SingleChildScrollView>(scrollViews).firstWhere(
        (w) => w.scrollDirection == Axis.horizontal,
      );

      expect(chartScrollView.controller, isNotNull);
      expect(chartScrollView.controller!.hasClients, isTrue);
      expect(chartScrollView.controller!.position.maxScrollExtent, greaterThan(0));
      expect(
        chartScrollView.controller!.position.pixels,
        equals(chartScrollView.controller!.position.maxScrollExtent),
      );
    });
  });
}
