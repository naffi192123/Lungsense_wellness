# Session Log - LungSense Wellness

## Session: 2026-07-13

### Today's Work
- Configured local storage Box dependencies inside dependency locator.
- Created `OnboardingData` Domain entities, `OnboardingModel` data models, and Onboarding Repository interfaces.
- Developed UseCases for onboarding saving, dynamic condition fetching, profile completion check, and local draft caching.
- Created `OnboardingBloc` coordinating real-time BMI calculations, draft caching on page step-ups, and Supabase upserts.
- Designed `EmailVerificationPage` locking unverified users.
- Designed `OnboardingPage` multi-step wizard matching reference mockups.
- Refactored `SplashBloc` checks for authentication, email confirmation, and profile completion states.
- Developed comprehensive unit tests verifying onboarding steps, BMI calculations, and splash redirects.

### Files Changed
- `lib/core/constants/app_constants.dart`
- `lib/core/di/injection_container.dart`
- `lib/core/router/app_router.dart`
- `lib/features/auth/domain/entities/user_entity.dart`
- `lib/features/auth/data/models/user_model.dart`
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `lib/features/auth/presentation/pages/email_verification_page.dart`
- `lib/features/splash/presentation/bloc/splash_bloc.dart`
- `lib/features/splash/presentation/bloc/splash_state.dart`
- `lib/features/splash/presentation/pages/splash_page.dart`
- `lib/features/onboarding/domain/entities/*`
- `lib/features/onboarding/domain/repositories/*`
- `lib/features/onboarding/domain/usecases/*`
- `lib/features/onboarding/data/models/*`
- `lib/features/onboarding/data/datasources/*`
- `lib/features/onboarding/data/repositories/*`
- `lib/features/onboarding/presentation/bloc/*`
- `lib/features/onboarding/presentation/pages/*`
- `test/features/onboarding/presentation/bloc/onboarding_bloc_test.dart`
- `test/features/splash/presentation/bloc/splash_bloc_test.dart`
- `test/widget_test.dart`
- `docs/*`

### Decisions Made
- Added `isEmailVerified` into `UserEntity` and resolved it dynamically from `emailConfirmedAt != null` in `UserModel.fromSupabase`.
- Forced session refresh within `AuthRemoteDataSource.getCurrentUser` to get the latest status when the user taps check status on the verification page.
- Calculated BMI reactively inside `OnboardingBloc` on `OnboardingUpdateDataEvent` to keep math out of the UI widgets.

## Session: 2026-07-12

### Today's Work
- Implemented Google Sign-In redirect flow in data datasource, repositories, and presentation screens.
- Created `GoogleSignInUseCase` and `ObserveUserUseCase` UseCases.
- Refactored `AuthBloc` constructor to reactively listen to session changes via `ObserveUserUseCase` and automatically yield `AuthAuthenticated`.
- Created temporary `DashboardPage` featuring welcome details and a Logout button.
- Updated `AppRouter` routing definitions to map to the new `DashboardPage`.
- Added a dedicated unit test suite in `test/features/auth/presentation/bloc/auth_bloc_test.dart` to verify all state transitions, and confirmed all tests pass successfully.

### Files Changed
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/domain/usecases/google_sign_in_usecase.dart`
- `lib/features/auth/domain/usecases/observe_user_usecase.dart`
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/presentation/bloc/auth_event.dart`
- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/auth/presentation/pages/register_page.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/core/router/app_router.dart`
- `lib/core/di/injection_container.dart`
- `test/features/auth/presentation/bloc/auth_bloc_test.dart`
- `docs/*`

### Decisions Made
- Chose to use reactive subscription listening to auth changes inside `AuthBloc` to handle redirection callbacks cleanly without UI polling.
- Moved `_AuthUserChangedEvent` to a public event `AuthUserChangedEvent` to bypass Dart library scope compilation warnings.

## Session: 2026-07-11

### Today's Work
- Copied horizontal logo transparent background asset into `assets/images/`.
- Configured and fetched Supabase dependency (`supabase_flutter`).
- Created credentials configuration in `lib/core/secrets/supabase_secrets.dart`.
- Initialized Supabase inside `main.dart` at boot.
- Registered remote data source, repositories, use cases, and blocs for authentication in dependency injection container.
- Designed `LoginPage`, `RegisterPage`, and `ForgotPasswordPage` UI layouts matching mockup requirements.
- Implemented real-time password strength regex checks on registration page.
- Refactored `SplashPage` and `SplashBloc` to check session state on start.
- Created and successfully passed unit and widget tests for the authentication flows.

### Files Changed
- `pubspec.yaml`
- `lib/main.dart`
- `lib/core/router/app_router.dart`
- `lib/core/di/injection_container.dart`
- `lib/core/secrets/supabase_secrets.dart`
- `lib/features/splash/presentation/bloc/*`
- `lib/features/splash/presentation/pages/splash_page.dart`
- `lib/features/auth/*`
- `test/widget_test.dart`
- `test/features/splash/presentation/bloc/splash_bloc_test.dart`
- `docs/*`

### Decisions Made
- Exposed Supabase credentials inside `supabase_secrets.dart` which is kept clean and isolated from code logic.
- Managed page transitions using `GoRouter` declarative path definitions.
- Refactored widget tests to stub `close()` of BLoCs to prevent mock teardown errors.

## Session: 2026-07-10

### Today's Work
- Initialized workspace as a Flutter project.
- Configured and fetched project dependencies in `pubspec.yaml`.
- Created Clean Architecture core modules (Theme, Routing, Dependency Injection, Error Handling, UseCase).
- Refactored `widget_test.dart` to verify skeleton rendering.
- Initialized Git repository and created a custom `.gitignore`.
- Structured the Project Memory System by generating 11 documentation files.
- Registered assets directory and copied branding and feature icons.
- Created `SplashBloc`, `SplashEvent`, and `SplashState` for 3-second delay logic.
- Built the `SplashPage` UI containing custom concentric background waves, logo assets, feature items row, and footer.
- Updated `AppRouter` to set `SplashPage` as the initial route and added a login page route placeholder.
- Wrote unit and widget tests for the Splash screen and verified they pass.
- Copied custom launcher icons for Android (mipmap folders) and iOS (AppIcon.appiconset) from resources.
- Defined native Android background color `#F8FAFC` in `colors.xml` and centered the launcher icon in both default and v21 `launch_background.xml` drawables.
- Overwrote iOS native `LaunchImage.png` assets with the high-resolution logo to resolve the blank white startup flash.

### Files Changed
- `pubspec.yaml`
- `.gitignore`
- `test/widget_test.dart`
- `lib/main.dart`
- `lib/core/theme/*`
- `lib/core/router/app_router.dart`
- `lib/core/di/injection_container.dart`
- `lib/core/errors/*`
- `lib/core/usecase/*`
- `lib/core/constants/app_constants.dart`
- `lib/features/splash/presentation/bloc/*`
- `lib/features/splash/presentation/pages/splash_page.dart`
- `test/features/splash/presentation/bloc/splash_bloc_test.dart`
- `android/app/src/main/res/values/colors.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png`
- `docs/*`

### Decisions Made
- Replaced default Counter UI with clean architecture base routing.
- Set up `CardThemeData` in `AppTheme` to avoid deprecated Flutter types.
- Configured local caching skeletons using `hive_flutter`.
- Wrote stream-based BLoC unit tests natively (with `expectLater` and `emitsInOrder`) instead of utilizing the `bloc_test` library to avoid version solving conflicts with the `hive_generator` package.
- Simulated design curves inside `SplashPage` using a lightweight custom Canvas painter (`_SplashBackgroundPainter`) for maximum rendering performance.
- Replaced native splash drawables and LaunchImages directly on the disk rather than adding `flutter_native_splash` to keep project configuration lightweight.
- Used custom launcher icons provided directly by the user rather than generating them.
