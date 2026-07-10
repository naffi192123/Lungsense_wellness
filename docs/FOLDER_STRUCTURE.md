# Project Folder Structure - LungSense Wellness

The codebase follows a feature-first Clean Architecture directory hierarchy.

```
lib/
 ├── core/                          # Shared cross-cutting modules
 │    ├── constants/                # App-wide constants (app_constants.dart)
 │    ├── di/                       # Dependency Injection setup (injection_container.dart)
 │    ├── errors/                   # Failures (failures.dart) and Exceptions (exceptions.dart)
 │    ├── router/                   # Routing configuration (app_router.dart)
 │    ├── theme/                    # Centralized theme (app_colors.dart, app_text_theme.dart, app_theme.dart)
 │    └── usecase/                  # Base UseCase signature (usecase.dart)
 ├── features/                      # Encapsulated application features
 │    └── splash/                   # Phase 1: Splash feature (to be added)
 └── main.dart                      # Framework entry point, boots DI & Hive
```
