# LungSense Wellness

LungSense Wellness is a premium Flutter application designed to help users track and improve their respiratory wellness through daily wellness tracking, respiratory audio recordings, rule-based wellness scores, and personalized recommendations.

> [!IMPORTANT]
> **Not a Medical Diagnosis Tool**: This application is strictly designed for lifestyle improvement, healthy habits reinforcement, and wellness tracking. It does not provide medical diagnoses.

---

## Technical Stack & Architecture

- **Architecture**: Feature-First Clean Architecture (Presentation, Domain, Data)
- **State Management**: `flutter_bloc`
- **Dependency Injection**: `get_it`
- **Routing**: `go_router`
- **Local Storage**: `hive_flutter`
- **Error Handling**: Functional error propagation via `fpdart` (`Either<Failure, T>`)

---

## Project Memory System

Comprehensive project documentation is maintained under the `docs/` folder:
- See the [Documentation Index](docs/README.md) to explore the system architecture, roadmap, task tracker, and ADRs.
- Current status is tracked in [PROJECT_STATE.md](docs/PROJECT_STATE.md).

---

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK

### Installation

1. Clone or open the repository.
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the widget tests to verify compilation:
   ```bash
   flutter test
   ```
4. Run the application:
   ```bash
   flutter run
   ```
