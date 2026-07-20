# LungSense Wellness

LungSense Wellness is a premium, feature-rich Flutter application designed to track and improve respiratory wellness through daily symptom logging, local audio recording, AI acoustic signature analysis simulation, and profile management synced with Supabase.

> [!IMPORTANT]
> **Not a Medical Diagnosis Tool**: This application is strictly designed for lifestyle improvement, healthy habits reinforcement, and wellness tracking. It does not provide medical diagnoses or replace professional healthcare consultations.

---

## 🚀 Key Features

- **Auth Portal**: Supabase Email & Password registration, login, verification screen, and Google Sign-in flow.
- **Onboarding (Profile Setup)**: Dynamic multi-step onboarding collecting basic profile info, lifestyle indicators (sleep, water), respiratory indicators, and medical history with real-time BMI calculations.
- **Interactive Dashboard**: Health indicator metrics grid (Cough status, lifestyle rating, trend), daily respiratory tips card, quick action buttons, recent activity logs, and a bottom navigation menu.
- **Symptom Tracker (Daily Log)**: Inputs for Cough severity, Breathlessness, Fever, Wheezing, Chest pain, Smoking status, exercise, hydration (+/- buttons), and sleep metrics.
- **Respiratory Recorder**: Clean UI matching ref mockups to record cough or breathing logs, play back recordings, delete audio, or simulate device file uploads.
- **Acoustic Reports**: Radial progress metrics dial (Lungs Health Score), sound wave energy timelines, and AI wellness tips.

---

## 🛠️ Technical Stack & Architecture

- **Engine**: Flutter SDK (`^3.11.0`)
- **Pattern**: Feature-First Clean Architecture (Presentation, Domain, Data layers)
- **State Management**: `flutter_bloc` (BLoC pattern)
- **Dependency Injection**: Service Locator pattern using `get_it`
- **Routing**: Declarative navigation using `go_router`
- **Backend Services**: Supabase Authentication & Database client
- **Offline Caching**: Key-Value offline storage using `hive_flutter`
- **Error Handling**: Functional error propagation via `fpdart` (`Either<Failure, T>`)

---

## 📦 System Architecture Diagram

```
                 +-----------------------------------+
                 |           Presentation            |
                 |      (Widgets, Blocs, Pages)      |
                 +-----------------+-----------------+
                                   |
                                   | Invokes
                                   v
                 +-----------------+-----------------+
                 |              Domain               |
                 |      (Entities, Use Cases,        |
                 |       Repository Contracts)       |
                 +-----------------+-----------------+
                                   |
                                   | Implements
                                   v
                 +-----------------+-----------------+
                 |              Data                 |
                 |     (Models, Repositories Impl,   |
                 |      Local & Remote DataSources)  |
                 +-----------------+-----------------+
                                   |
                                   +-------+
                                   |       |
                                   v       v
                              [Supabase] [Hive]
```

---

## 🏁 Getting Started

### 📋 Prerequisites

Ensure you have the following installed on your machine:
- **Flutter SDK**: `^3.11.0` (stable channel)
- **Dart SDK**: Compatible with Flutter SDK
- **Git** version control tool
- **Android Studio** (for Android emulator/builds)
- **Xcode** (for iOS simulator/builds, macOS only)
- **VS Code** (recommended IDE with Dart/Flutter plugins)

---

### 💻 Setup and Installation

Follow these steps to run the application locally:

#### 1. Clone the Repository
Clone the repository to your local directory:
```bash
git clone <repository-url>
cd Lungsense_wellness
```

#### 2. Configure Environment Secrets
Create a secrets file inside the core module: `lib/core/secrets/supabase_secrets.dart`. This file stores anonymous keys and url endpoint strings, preventing hardcoded credentials:
```dart
// lib/core/secrets/supabase_secrets.dart
abstract class SupabaseSecrets {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
}
```
*Note: This file is excluded from git version tracking by our `.gitignore` to maintain security.*

#### 3. Fetch Dependencies
Install package dependencies from the pub registry:
```bash
flutter pub get
```

#### 4. Run Code Generators
Trigger build runner to execute model serialization and Hive adapter code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 5. Launch the Application
Start the development server or build on target emulator/device:
```bash
flutter run
```

---

## 🧪 Verification and Testing

To execute the test suites and verify that everything compiles and runs correctly:

Run all unit and widget tests:
```bash
flutter test
```

Unit tests cover:
- Redirection workflows (Splash transitions, unverified email checks, profile completeness checks).
- Calculations (reactive BMI adjustments inside the Onboarding BLoC).
- Authentication transitions (Login, Google Sign-in state updates).

---

## 📂 Project Documentation Index

Detailed architectural specs, guides, and decisions are stored under the `docs/` folder:
- **[Documentation Index](docs/README.md)**: Main catalog.
- **[System Architecture details](docs/ARCHITECTURE.md)**: Layer rules and dependencies constraints.
- **[Folder Structure](docs/FOLDER_STRUCTURE.md)**: Complete map of code directories.
- **[Maintenance Guide](docs/MAINTENANCE_GUIDE.md)**: Instructions on extending features, routing, and database tables.
- **[Latest Decisions (ADR)](docs/DECISIONS.md)**: Architectural choices registry.
- **[Roadmap](docs/ROADMAP.md)** & **[Tasks](docs/TASKS.md)**: Development milestone checklists.
