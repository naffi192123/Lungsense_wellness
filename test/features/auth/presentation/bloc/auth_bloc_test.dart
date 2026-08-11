import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lungsense_wellness/features/auth/presentation/bloc/auth_event.dart';
import 'package:lungsense_wellness/features/auth/presentation/bloc/auth_state.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/login_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/register_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/confirm_reset_password_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/logout_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/usecases/observe_user_usecase.dart';
import 'package:lungsense_wellness/features/auth/domain/entities/user_entity.dart';
import 'package:lungsense_wellness/core/usecase/usecase.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
class MockConfirmResetPasswordUseCase extends Mock implements ConfirmResetPasswordUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockGoogleSignInUseCase extends Mock implements GoogleSignInUseCase {}
class MockObserveUserUseCase extends Mock implements ObserveUserUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(const ForgotPasswordParams(email: ''));
    registerFallbackValue(const ConfirmResetPasswordParams(email: '', otpCode: '', newPassword: ''));
    registerFallbackValue(const NoParams());
  });

  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late MockLoginUseCase mockLoginUseCase;
    late MockRegisterUseCase mockRegisterUseCase;
    late MockResetPasswordUseCase mockResetPasswordUseCase;
    late MockForgotPasswordUseCase mockForgotPasswordUseCase;
    late MockConfirmResetPasswordUseCase mockConfirmResetPasswordUseCase;
    late MockLogoutUseCase mockLogoutUseCase;
    late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
    late MockGoogleSignInUseCase mockGoogleSignInUseCase;
    late MockObserveUserUseCase mockObserveUserUseCase;

    setUp(() {
      mockLoginUseCase = MockLoginUseCase();
      mockRegisterUseCase = MockRegisterUseCase();
      mockResetPasswordUseCase = MockResetPasswordUseCase();
      mockForgotPasswordUseCase = MockForgotPasswordUseCase();
      mockConfirmResetPasswordUseCase = MockConfirmResetPasswordUseCase();
      mockLogoutUseCase = MockLogoutUseCase();
      mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
      mockGoogleSignInUseCase = MockGoogleSignInUseCase();
      mockObserveUserUseCase = MockObserveUserUseCase();

      // Stub observeUserUseCase to return an empty stream by default
      when(() => mockObserveUserUseCase()).thenAnswer((_) => const Stream.empty());

      authBloc = AuthBloc(
        loginUseCase: mockLoginUseCase,
        registerUseCase: mockRegisterUseCase,
        resetPasswordUseCase: mockResetPasswordUseCase,
        forgotPasswordUseCase: mockForgotPasswordUseCase,
        confirmResetPasswordUseCase: mockConfirmResetPasswordUseCase,
        logoutUseCase: mockLogoutUseCase,
        getCurrentUserUseCase: mockGetCurrentUserUseCase,
        googleSignInUseCase: mockGoogleSignInUseCase,
        observeUserUseCase: mockObserveUserUseCase,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    test(
      'emits [AuthLoading, AuthAuthenticated] when LoginUseCase returns UserEntity',
      () async {
        const dummyUser = UserEntity(id: '1', email: 'test@example.com');
        when(() => mockLoginUseCase(any())).thenAnswer((_) async => const Right(dummyUser));

        final expectedStates = [
          const AuthLoading(),
          const AuthAuthenticated(dummyUser),
        ];

        expectLater(authBloc.stream, emitsInOrder(expectedStates));

        authBloc.add(const AuthLoginEvent(email: 'test@example.com', password: 'password'));
      },
    );

    test(
      'emits [AuthLoading, AuthPasswordResetSent] on AuthForgotPasswordEvent',
      () async {
        when(() => mockForgotPasswordUseCase(any())).thenAnswer((_) async => const Right(null));

        final expectedStates = [
          const AuthLoading(),
          const AuthPasswordResetSent('test@example.com'),
        ];

        expectLater(authBloc.stream, emitsInOrder(expectedStates));

        authBloc.add(const AuthForgotPasswordEvent(email: 'test@example.com'));
      },
    );

    test(
      'emits [AuthLoading, AuthPasswordResetSuccess] on AuthResetPasswordWithOtpEvent',
      () async {
        when(() => mockConfirmResetPasswordUseCase(any())).thenAnswer((_) async => const Right(null));

        final expectedStates = [
          const AuthLoading(),
          const AuthPasswordResetSuccess(),
        ];

        expectLater(authBloc.stream, emitsInOrder(expectedStates));

        authBloc.add(const AuthResetPasswordWithOtpEvent(
          email: 'test@example.com',
          otpCode: '123456',
          newPassword: 'newpassword123',
        ));
      },
    );

    test(
      'emits [AuthLoading] and calls GoogleSignInUseCase on AuthGoogleSignInEvent',
      () async {
        when(() => mockGoogleSignInUseCase(any())).thenAnswer((_) async => const Right(null));

        final expectedStates = [
          const AuthLoading(),
        ];

        expectLater(authBloc.stream, emitsInOrder(expectedStates));

        authBloc.add(const AuthGoogleSignInEvent());
      },
    );

    test(
      'emits [AuthAuthenticated] when AuthUserChangedEvent receives non-null user',
      () async {
        const dummyUser = UserEntity(id: '1', email: 'stream@example.com');

        final expectedStates = [
          const AuthAuthenticated(dummyUser),
        ];

        expectLater(authBloc.stream, emitsInOrder(expectedStates));

        authBloc.add(const AuthUserChangedEvent(dummyUser));
      },
    );

    test(
      'emits [AuthUnauthenticated] when AuthUserChangedEvent receives null user',
      () async {
        final expectedStates = [
          const AuthUnauthenticated(),
        ];

        expectLater(authBloc.stream, emitsInOrder(expectedStates));

        authBloc.add(const AuthUserChangedEvent(null));
      },
    );
  });
}
