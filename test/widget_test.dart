import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_state.dart';
import 'package:lungsense_wellness/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lungsense_wellness/features/auth/presentation/bloc/auth_state.dart';
import 'package:lungsense_wellness/main.dart';

import 'package:lungsense_wellness/core/network/network_cubit.dart';

class MockSplashBloc extends Mock implements SplashBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockNetworkCubit extends Mock implements NetworkCubit {}

void main() {
  late MockSplashBloc mockSplashBloc;
  late MockAuthBloc mockAuthBloc;
  late MockNetworkCubit mockNetworkCubit;
  late StreamController<SplashState> splashStateController;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockSplashBloc = MockSplashBloc();
    mockAuthBloc = MockAuthBloc();
    mockNetworkCubit = MockNetworkCubit();
    splashStateController = StreamController<SplashState>.broadcast();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockNetworkCubit.state).thenReturn(const NetworkState(isDisconnected: false));
    when(() => mockNetworkCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockNetworkCubit.close()).thenAnswer((_) async {});

    // Register mocks in GetIt to bypass real Hive and Supabase network initialization
    final sl = GetIt.instance;
    sl.reset();
    sl.registerFactory<SplashBloc>(() => mockSplashBloc);
    sl.registerFactory<AuthBloc>(() => mockAuthBloc);
    sl.registerFactory<NetworkCubit>(() => mockNetworkCubit);

    // Stub BLoC close method to prevent Null is not a subtype of Future<void> exceptions during teardown
    when(() => mockSplashBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    splashStateController.close();
    authStateController.close();
    GetIt.instance.reset();
  });

  testWidgets('App renders SplashPage and transitions to Login after state update', (WidgetTester tester) async {
    // Stub initial states
    when(() => mockSplashBloc.state).thenReturn(const SplashInitial());
    when(() => mockSplashBloc.stream).thenAnswer((_) => splashStateController.stream);

    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);

    // Build our app and trigger a frame
    await tester.pumpWidget(const LungSenseApp());
    await tester.pump();

    // Verify SplashPage features render successfully
    expect(find.text('Daily Tracking'), findsOneWidget);
    expect(find.text('Lung Wellness\nScore'), findsOneWidget);
    expect(find.text('Smart Insights'), findsOneWidget);
    expect(find.text('POWERED BY'), findsOneWidget);

    // Simulate SplashBloc emitting navigation state
    when(() => mockSplashBloc.state).thenReturn(const SplashNavigateToLogin());
    splashStateController.add(const SplashNavigateToLogin());

    // Trigger navigation frames
    await tester.pumpAndSettle();

    // Verify successful routing transition to LoginPage
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
