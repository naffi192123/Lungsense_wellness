import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_event.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_state.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:lungsense_wellness/features/onboarding/domain/usecases/check_profile_completed_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/entities/user_entity.dart';
import 'package:lungsense_wellness/core/usecase/usecase.dart';

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockCheckProfileCompletedUseCase extends Mock implements CheckProfileCompletedUseCase {}

void main() {
  group('SplashBloc Tests', () {
    late SplashBloc splashBloc;
    late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
    late MockCheckProfileCompletedUseCase mockCheckProfileCompletedUseCase;

    setUp(() {
      mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
      mockCheckProfileCompletedUseCase = MockCheckProfileCompletedUseCase();
      splashBloc = SplashBloc(
        mockGetCurrentUserUseCase,
        mockCheckProfileCompletedUseCase,
      );
    });

    tearDown(() {
      splashBloc.close();
    });

    test('initial state should be SplashInitial', () {
      expect(splashBloc.state, equals(const SplashInitial()));
    });

    test(
      'emits [SplashLoading, SplashNavigateToLogin] when session is null',
      () async {
        when(() => mockGetCurrentUserUseCase(const NoParams()))
            .thenAnswer((_) async => const Right(null));

        final expectedStates = [
          const SplashLoading(),
          const SplashNavigateToLogin(),
        ];

        expectLater(
          splashBloc.stream,
          emitsInOrder(expectedStates),
        );

        splashBloc.add(const SplashStartTimerEvent());
      },
    );

    test(
      'emits [SplashLoading, SplashNavigateToVerification] when email is unverified',
      () async {
        const dummyUser = UserEntity(
          id: '123',
          email: 'test@example.com',
          name: 'Test User',
          isEmailVerified: false,
        );
        when(() => mockGetCurrentUserUseCase(const NoParams()))
            .thenAnswer((_) async => const Right(dummyUser));

        final expectedStates = [
          const SplashLoading(),
          const SplashNavigateToVerification(),
        ];

        expectLater(
          splashBloc.stream,
          emitsInOrder(expectedStates),
        );

        splashBloc.add(const SplashStartTimerEvent());
      },
    );

    test(
      'emits [SplashLoading, SplashNavigateToOnboarding] when user session is active but profile incomplete',
      () async {
        const dummyUser = UserEntity(
          id: '123',
          email: 'test@example.com',
          name: 'Test User',
          isEmailVerified: true,
        );
        when(() => mockGetCurrentUserUseCase(const NoParams()))
            .thenAnswer((_) async => const Right(dummyUser));
        when(() => mockCheckProfileCompletedUseCase(const NoParams()))
            .thenAnswer((_) async => const Right(false));

        final expectedStates = [
          const SplashLoading(),
          const SplashNavigateToOnboarding(),
        ];

        expectLater(
          splashBloc.stream,
          emitsInOrder(expectedStates),
        );

        splashBloc.add(const SplashStartTimerEvent());
      },
    );

    test(
      'emits [SplashLoading, SplashNavigateToDashboard] when user session is active and profile complete',
      () async {
        const dummyUser = UserEntity(
          id: '123',
          email: 'test@example.com',
          name: 'Test User',
          isEmailVerified: true,
        );
        when(() => mockGetCurrentUserUseCase(const NoParams()))
            .thenAnswer((_) async => const Right(dummyUser));
        when(() => mockCheckProfileCompletedUseCase(const NoParams()))
            .thenAnswer((_) async => const Right(true));

        final expectedStates = [
          const SplashLoading(),
          const SplashNavigateToDashboard(),
        ];

        expectLater(
          splashBloc.stream,
          emitsInOrder(expectedStates),
        );

        splashBloc.add(const SplashStartTimerEvent());
      },
    );
  });
}
