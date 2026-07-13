# Changelog - LungSense Wellness

All notable changes to this project will be documented in this file.

## [0.4.0-alpha] - 2026-07-13
### Added
- **Phase 3 User Onboarding (Profile Setup)**
  - Configured `userPreferencesBox` for local caching and registered `OnboardingLocalDataSource` and `OnboardingRemoteDataSource` in dependency injection.
  - Implemented `OnboardingData` aggregated entity, model maps, use cases (`SaveOnboarding`, `FetchConditions`, `CheckProfileCompleted`, `SaveDraft`, `LoadDraft`, `ClearDraft`), and `OnboardingBloc`.
  - Built `OnboardingPage` step-by-step forms collecting Basic Info, Lifestyle, and Respiratory health:
    - Added real-time BMI calculations in Step 1.
    - Added placeholder properties for Sleep, Water, and Exercise in Step 2.
    - Added dynamic medical condition chip selectors in Step 3 loading from Supabase.
  - Built `EmailVerificationPage` restricting access to unverified users and providing status updates.
  - Refactored `SplashBloc` checks for authentication, email confirmation, and profile completion states.
  - Wrote comprehensive BLoC unit tests in `onboarding_bloc_test.dart` and `splash_bloc_test.dart`.

## [0.3.0-alpha] - 2026-07-11
### Added
- **Phase 2 Authentication (Supabase)**
  - Added `supabase_flutter` dependency and initialized it during app boot via `supabase_secrets.dart` credentials.
  - Registered `AuthRemoteDataSource`, `AuthRepository`, use cases (`Login`, `Register`, `Logout`, `ResetPassword`, `GetCurrentUser`), and `AuthBloc` inside `injection_container.dart`.
  - Implemented `LoginPage` replicating mockup elements (tabs, email/password fields, "Forgot?" link, Google Sign-in stub, and card layout).
  - Implemented `RegisterPage` adding real-time validation indicator ticks (min 8 chars, uppercase, digits, symbols) as the user types.
  - Implemented `ForgotPasswordPage` allowing password recovery request linkages.
  - Completed Google Sign-In OAuth flow routing with `signInWithGoogle` and registered the new `GoogleSignInUseCase` and `ObserveUserUseCase` streams.
  - Implemented reactive `AuthUserChangedEvent` session update checks listening directly to Supabase auth changes.
  - Created a temporary `DashboardPage` featuring a session detail welcome card and a test Logout button.
  - Refactored `SplashPage` and `SplashBloc` to verify user sessions on startup and redirect appropriately.
  - Added a dedicated unit test suite for `AuthBloc` verifying state mappings under stream events.

## [0.2.1-alpha] - 2026-07-10
### Added
- **Launcher Icons & App Customizations**
  - Integrated custom launcher icons for Android (all mipmap densities) and iOS (`AppIcon.appiconset`) from the uploaded resources.
  - Configured Android resources with `colors.xml` to define the `#F8FAFC` background.
  - Updated Android `launch_background.xml` (default and API 21+) to draw the launcher icon centered on `#F8FAFC` to prevent flash of blank white page.
  - Replaced the default blank iOS `LaunchImage` files with the high-resolution brand logo to ensure a smooth transition from iOS launch storyboard to Flutter.

## [0.2.0-alpha] - 2026-07-10
### Added
- **Phase 1 Splash Screen**
  - Registered and copied required graphic assets (logo, DigiBiomics logo, and feature icons) into `assets/images/`.
  - Implemented `SplashBloc` to handle the 3-second startup and routing trigger.
  - Implemented `SplashPage` UI layout utilizing a `CustomPainter` to draw curved waves and concentric ring lines matching the design.
  - Updated `AppRouter` routing tables to load `SplashPage` and set up `/login` placeholder redirection.
  - Wrote BLoC unit tests and widget tests verifying state output and screen navigation.

## [0.1.0-alpha] - 2026-07-10
### Added
- **Phase 0 Architecture**
  - Git repository initialization and customized `.gitignore`.
  - External package configuration (`flutter_bloc`, `get_it`, `go_router`, `hive_flutter`, `fpdart`, `google_fonts`).
  - Centralized theme config (`AppColors`, `AppTextTheme`, `AppTheme`).
  - Base routing (`AppRouter`) and Dependency Injection (`injection_container.dart`).
  - Functional error structures (`failures.dart`, `exceptions.dart`, `usecase.dart`).
  - Widget skeleton unit tests (passing).
  - Project documentation memory system (`/docs`).
