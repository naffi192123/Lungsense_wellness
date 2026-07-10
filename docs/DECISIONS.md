# Architectural Decisions - LungSense Wellness

## ADR 1: Feature-First Clean Architecture
- **Decision**: Adopt a feature-first clean architecture model.
- **Rationale**: Isolates features cleanly. Allows scaling of individual modules (splash, auth, dashboard) without side effects.
- **Status**: Approved.

## ADR 2: State Management with BLoC
- **Decision**: Use `flutter_bloc` exclusively.
- **Rationale**: Strict unidirectional data flow, separation of concerns, testability, and predictability.
- **Status**: Approved.

## ADR 3: Service Locator with GetIt
- **Decision**: Use `get_it` for dependency injection.
- **Rationale**: Light, fast, does not require context parameter passing, keeps business layers clean from Flutter frameworks.
- **Status**: Approved.

## ADR 4: Routing with GoRouter
- **Decision**: Use `go_router`.
- **Rationale**: Declarative routing configuration, built-in support for query parameters, path variables, sub-routes, and guards.
- **Status**: Approved.

## ADR 5: Functional Error Handling with fpdart
- **Decision**: Use `fpdart`'s `Either<Failure, T>` instead of `dartz`.
- **Rationale**: Offers better compatibility with modern Dart type safety and active community support.
- **Status**: Approved.

## ADR 6: Local Caching with Hive
- **Decision**: Use `hive_flutter`.
- **Rationale**: Highly optimized, lightweight key-value database ideal for mobile offline caching.
- **Status**: Approved.
