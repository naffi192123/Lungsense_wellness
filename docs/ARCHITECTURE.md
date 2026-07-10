# System Architecture - LungSense Wellness

## Core Architecture Pattern
We follow **Feature-First Clean Architecture**.

```
lib/
 └── features/
      └── feature_name/
           ├── data/          # DataSources, Repositories implementations, Models (JSON-serializable)
           ├── domain/        # Entities, Repositories interfaces, Use Cases (Pure Dart)
           └── presentation/  # Widgets, Blocs, State, Events
```

## Layer Isolation Rules

| Layer | Imports Permitted | Imports Forbidden |
| :--- | :--- | :--- |
| **Presentation** | Flutter, Blocs, UseCases, Entities, Theme | Direct Database, Direct HTTP Clients |
| **Domain** | Pure Dart, `fpdart` (`Either`), `equatable` | Flutter, Widgets, Hive, Supabase, JSON, HTTP |
| **Data** | Hive, Supabase, HTTP, Models, Domain Interfaces | Flutter UI widgets |

## Core Technologies
- **State Management**: `flutter_bloc` exclusively.
- **Dependency Injection**: `get_it` service locator (`sl`).
- **Routing**: Declarative navigation via `go_router`.
- **Local Cache**: Offline-first via `hive`.
- **Functional error handling**: `fpdart` (`Either<Failure, T>`) propagates failures from Data to Presentation.
