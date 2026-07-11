import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_event.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_state.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/entities/user_entity.dart';
import 'package:lungsense_wellness/core/usecase/usecase.dart';

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  group('SplashBloc Tests', () {
    late SplashBloc splashBloc;
    late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

    setUp(() {
      mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
      splashBloc = SplashBloc(mockGetCurrentUserUseCase);
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
      'emits [SplashLoading, SplashNavigateToDashboard] when user session is active',
      () async {
        const dummyUser = UserEntity(id: '123', email: 'test@example.com', name: 'Test User');
        when(() => mockGetCurrentUserUseCase(const NoParams()))
            .thenAnswer((_) async => const Right(dummyUser));

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
