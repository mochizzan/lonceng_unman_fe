# Lonceng UnMan

A Flutter mobile application for university students — lecture schedule reminder with countdown, academic profile management (NPM, Program Studi, Semester), and weekly schedule tracking.

## Features

- **Lecture schedule reminder** with live countdown to next class
- **Academic profile management** — NPM, Program Studi, Semester
- **Weekly schedule timeline** for all courses
- **Material 3 design** with yellow seed color (`#FFC107`)
- **Light/Dark mode** support with adaptive theming

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (latest stable)
- Android SDK / Xcode (for device testing)
- VS Code or Android Studio

### Installation

```bash
# Clone the repository
git clone https://github.com/mochizzan/lonceng_unman_fe.git
cd lonceng_unman_fe

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Building

```bash
# Android
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web
```

## Development

- **Dev mode**: `flutter run` (hot reload: `r`, hot restart: `R`)
- **Analyze**: `flutter analyze`
- **Format**: `dart format .`
- **Test**: `flutter test`

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Dart |
| Framework | Flutter |
| Routing | [go_router](https://pub.dev/packages/go_router) |
| State Management | [flutter_bloc](https://pub.dev/packages/flutter_bloc) |
| Fonts | [google_fonts](https://pub.dev/packages/google_fonts) |
| Linting | flutter_lints |

## Project Structure

```
lib/
├── main.dart              # Application entry point
├── core/                  # Shared infrastructure
│   ├── routes/            # GoRouter configuration
│   ├── theme/             # Material 3 color schemes
│   ├── di/                # Dependency injection (get_it)
│   ├── network/           # API client and network layer
│   └── errors/            # Custom exception/error classes
├── features/              # Feature-based modules
│   ├── auth/              # Authentication (Login)
│   ├── home/              # Home screen (Countdown & Summary)
│   ├── jadwal/            # Weekly schedule timeline
│   └── profile/           # Academic info & settings
└── shared/                # Shared reusable widgets
```

## Architecture

This project follows **Clean Architecture** with feature-based modules:

- **presentation/** — pages, widgets, bloc (UI + state)
- **domain/** — entities, repositories (interfaces), usecases (business logic)
- **data/** — datasources, models (DTOs), repositories (implementation)

Dependency rule: `presentation → domain → data` (never reverse)

## Design System

- **Seed Color**: Yellow `#FFC107`
- **Fonts**: Plus Jakarta Sans (headlines) + Roboto (body)
- **Shapes**: Extra Large cards (32px), Large item cards (20-24px)
- **Navbar**: Fixed bottom navigation with 3 tabs (Home, Jadwal, Profile)

See [DESIGN.md](DESIGN.md) for the complete design specification.

## License

This project is developed for academic purposes at Universitas Negeri Malang.