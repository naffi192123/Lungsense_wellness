# Changelog - LungSense Wellness

All notable changes to this project will be documented in this file.

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
