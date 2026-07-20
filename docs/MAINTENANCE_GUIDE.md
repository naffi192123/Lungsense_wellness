# Developer Maintenance Guide - LungSense Wellness

This guide provides instructions for developers looking to maintain, extend, or troubleshoot the LungSense Wellness Flutter application.

---

## 📂 1. Adding a New Feature Module

When creating a new feature (e.g. `report_history`), follow the Clean Architecture boundaries by creating the following directory structure:

1. **Create Folders**:
   ```bash
   mkdir -p lib/features/report_history/data/datasources
   mkdir -p lib/features/report_history/data/models
   mkdir -p lib/features/report_history/data/repositories
   mkdir -p lib/features/report_history/domain/entities
   mkdir -p lib/features/report_history/domain/repositories
   mkdir -p lib/features/report_history/domain/usecases
   mkdir -p lib/features/report_history/presentation/bloc
   mkdir -p lib/features/report_history/presentation/pages
   ```

2. **Define the Entities & Contracts**:
   - Write standard domain classes inheriting from `Equatable` under `entities/`.
   - Write abstract repository definitions under `domain/repositories/`.

3. **Implement Data Models and Repositories**:
   - Create JSON/Hive serializable models extending the domain entities.
   - Implement the repository contracts, linking cache boxes (Hive) and database clients (Supabase).

4. **Coordinate UI using BLoC**:
   - Define events (`Event`), state states (`State`), and event handler logic (`Bloc`) under `presentation/bloc/`.

---

## 💉 2. Dependency Injection Registration

All dependencies must be registered inside [injection_container.dart](file:///c:/Users/naffi/OneDrive/Documents/DigiBiomics/Lungsense_wellness/lib/core/di/injection_container.dart) inside `initDependencies()`:

```dart
// 1. DataSources
sl.registerLazySingleton<ReportRemoteDataSource>(
  () => ReportRemoteDataSourceImpl(sl()),
);

// 2. Repositories
sl.registerLazySingleton<ReportRepository>(
  () => ReportRepositoryImpl(remoteDataSource: sl()),
);

// 3. Use Cases
sl.registerLazySingleton(() => FetchReportsUseCase(sl()));

// 4. Blocs (Factories, registered fresh per widget instantiation)
sl.registerFactory(() => ReportBloc(fetchReportsUseCase: sl()));
```

---

## 🛤️ 3. Registering New Routes

New pages are declared and configured in [app_router.dart](file:///c:/Users/naffi/OneDrive/Documents/DigiBiomics/Lungsense_wellness/lib/core/router/app_router.dart):

1. **Add Route Constant**:
   ```dart
   static const String reportPath = '/report';
   static const String reportName = 'report';
   ```

2. **Append to GoRouter routes list**:
   ```dart
   GoRoute(
     path: reportPath,
     name: reportName,
     builder: (context, state) => BlocProvider(
       create: (context) => sl<ReportBloc>(),
       child: const ReportPage(),
     ),
   ),
   ```

---

## 🔐 4. Supabase DB Schema & RLS Policies

When adding new tables to your Supabase backend, make sure to enable Row Level Security (RLS) policies to keep user data secure.

1. **Define Relationships**:
   Always link custom profile tables directly to `auth.users` via reference constraints:
   ```sql
   create table public.user_reports (
       id uuid primary key default gen_random_uuid(),
       user_id uuid not null references auth.users(id) on delete cascade,
       score integer not null,
       created_at timestamptz default now()
   );
   ```

2. **Apply Row Level Security (RLS)**:
   ```sql
   alter table user_reports enable row level security;

   create policy "Users can manage own reports"
   on user_reports
   for all
   using (auth.uid() = user_id);
   ```

---

## 🧪 5. Testing and Validation

- **Run all tests**:
  ```bash
  flutter test
  ```
- **Code formatting check**:
  ```bash
  flutter format lib/ test/
  ```
- **Linter check**:
  ```bash
  flutter analyze
  ```
