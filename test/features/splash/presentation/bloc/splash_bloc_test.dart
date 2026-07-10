import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_event.dart';
import 'package:lungsense_wellness/features/splash/presentation/bloc/splash_state.dart';

void main() {
  group('SplashBloc Tests', () {
    late SplashBloc splashBloc;

    setUp(() {
      splashBloc = SplashBloc();
    });

    tearDown(() {
      splashBloc.close();
    });

    test('initial state should be SplashInitial', () {
      expect(splashBloc.state, equals(const SplashInitial()));
    });

    test(
      'emits [SplashLoading, SplashNavigateToLogin] in sequence when SplashStartTimerEvent is dispatched',
      () async {
        final expectedStates = [
          const SplashLoading(),
          const SplashNavigateToLogin(),
        ];

        // Expect the states to be emitted in order on the stream
        expectLater(
          splashBloc.stream,
          emitsInOrder(expectedStates),
        );

        // Dispatch the timer event
        splashBloc.add(const SplashStartTimerEvent());
      },
    );
  });
}
