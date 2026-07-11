# Changelog - LungSense Wellness

All notable changes to this project will be documented in this file.

## [0.3.0-alpha] - 2026-07-11
### Added
- **Phase 2 Authentication (Supabase)**
  - Added `supabase_flutter` dependency and initialized it during app boot via `supabase_secrets.dart` credentials.
  - Registered `AuthRemoteDataSource`, `AuthRepository`, use cases (`Login`, `Register`, `Logout`, `ResetPassword`, `GetCurrentUser`), and `AuthBloc` inside `injection_container.dart`.
  - Implemented `LoginPage` replicating mockup elements (tabs, email/password fields, "Forgot?" link, Google Sign-in stub, and card layout).
  - Implemented `RegisterPage` adding real-time validation indicator ticks (min 8 chars, uppercase, digits, symbols) as the user types.
  - Implemented `ForgotPasswordPage` allowing password recovery request linkages.
  - Refactored `SplashPage` and `SplashBloc` to verify user sessions on startup and redirect appropriately.
  - Rewrote widget test suites to mock dependency configurations and verify auth route mappings.

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
