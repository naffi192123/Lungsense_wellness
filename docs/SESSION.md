# Session Log - LungSense Wellness

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
