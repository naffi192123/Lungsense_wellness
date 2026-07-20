# Project Folder Structure - LungSense Wellness

The codebase follows a feature-first Clean Architecture directory hierarchy, keeping shared elements in `core` and self-contained logical verticals in `features`.

```
lib/
 ├── core/                          # Shared cross-cutting modules
 │    ├── constants/                # App-wide string/key constants (app_constants.dart)
 │    ├── di/                       # Dependency Injection setup (injection_container.dart)
 │    ├── errors/                   # Unified Failures and Exceptions models
 │    ├── router/                   # Declarative routing configuration (app_router.dart)
 │    ├── secrets/                  # Supabase Credentials configuration (supabase_secrets.dart)
 │    ├── theme/                    # Light & Dark palettes (app_colors.dart, app_theme.dart)
 │    └── usecase/                  # Base UseCase abstract signature (usecase.dart)
 ├── features/                      # Encapsulated application features
 │    ├── auth/                     # Supabase Email & Google Login/Registration & Verification
 │    ├── daily_log/                # Daily symptoms tracker (sliders, toggles)
 │    ├── dashboard/                # Home interface, metrics summaries, navigation hubs
 │    ├── history/                  # Chronological timeline checklist of previous check-ins
 │    ├── onboarding/               # Multi-step demographic onboarding profile form
 │    ├── profile/                  # User details view, Settings, and Ads info
 │    ├── recording/                # Dual-mode respiratory audio recorder (pills layout)
 │    └── splash/                   # concentric background waves transition screen
 └── main.dart                      # Framework bootloader initiating Supabase and services
```

---

## Folder Breakdown per Feature

Each feature directory (e.g. `lib/features/auth`) is divided into sub-layers to enforce Clean Architecture boundaries:

```
features/feature_name/
 ├── data/
 │    ├── datasources/              # Queries and transactions with local (Hive) and remote (Supabase) DBs
 │    ├── models/                   # JSON-serializable extensions of entities with factory adapters
 │    └── repositories/             # Repository implementations coordinating data sources
 ├── domain/
 │    ├── entities/                 # Pure Dart business data models
 │    ├── repositories/             # Abstract interfaces specifying data operations
 │    └── usecases/                 # Single-purpose query/command actions called by presentation
 └── presentation/
      ├── bloc/                     # BLoC state, event, and controller definitions
      ├── pages/                    # Main full-screen widgets mapped by routers
      └── widgets/                  # Reusable UI widgets scoped to this feature
```
