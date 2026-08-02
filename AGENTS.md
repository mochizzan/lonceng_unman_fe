# Project Instructions

## Project Overview
**Lonceng UnMan** adalah aplikasi Flutter untuk mahasiswa — pengingat jadwal kuliah dengan countdown, manajemen profil akademik (NPM, Prodi, Semester). Desain Material 3 penuh dengan seed color kuning `#FFC107`, mendukung Light/Dark mode.

## Tech Stack
| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Dart | ^3.12.0 |
| Framework | Flutter | (SDK) |
| Routing | go_router | ^17.3.0 |
| State Management | bloc + flutter_bloc | ^9.2.1 / ^9.1.1 |
| Fonts | google_fonts | ^8.2.1 |
| Lint Rules | flutter_lints | ^6.0.0 |

## Code Style
- PascalCase for widget/class names (e.g. `MyHomePage`)
- camelCase for variables and methods (e.g. `_incrementCounter`)
- snake_case for file names (e.g. `main.dart`, `app_router.dart`)
- Private members prefixed with underscore (e.g. `_counter`, `_MyHomePageState`)
- StatelessWidget for stateless widgets, StatefulWidget for stateful ones
- `const` constructors preferred for widgets that don't depend on runtime state
- BLoC pattern: separate `event.dart`, `state.dart`, `bloc.dart` files per feature
- Events extend `Equatable` for value equality (recommended pattern)

## Testing
- Run tests: `flutter test`
- Test pattern: `*.dart` in `test/`
- Widget tests use `flutter_test` + `testWidgets`
- BLoC tests use `bloc_test` package with `blocTest` helper
- Router tests use `go_router`: `GoRouterTester` or `tester.push()`/`tester.pop()`
- Example test: `test/widget_test.dart`

## Build & Run
- Dev: `flutter run` (then press `r` for hot reload, `R` for hot restart)
- Build (Android): `flutter build appbundle`
- Build (iOS): `flutter build ios`
- Build (Web): `flutter build web`
- Analyze: `flutter analyze`
- Format: `dart format .`

## Project Structure
| Path | Purpose |
|------|---------|
| `lib/main.dart` | Application entry point |
| `lib/core/` | Shared infrastructure (constants, utils, errors, network, di, routes, theme) |
| `lib/core/routes/app_router.dart` | GoRouter configuration and route definitions |
| `lib/core/theme/app_theme.dart` | Material 3 color schemes, ThemeData, AppColors (ThemeExtension) |
| `lib/core/di/di.dart` | Dependency injection setup (get_it) |
| `lib/core/network/` | API client and network layer |
| `lib/core/errors/` | Custom exception/error classes |
| `lib/features/<feature>/` | Feature-based modules following Clean Architecture |
| `lib/features/auth/` | Authentication (Login with NPM/Password) |
| `lib/features/data_initialization/` | Post-login data setup |
| `lib/features/home/` | Home screen (Countdown & Summary) |
| `lib/features/jadwal/` | Weekly schedule timeline |
| `lib/features/profile/` | Academic info & settings |
| `lib/shared/` | Shared reusable widgets and helpers |
| `test/` | Widget, unit, and integration tests |
| `web/` | Web platform entry point and assets |
| `android/` | Android platform configuration and native code |
| `ios/` | iOS platform configuration and native code |
| `pubspec.yaml` | Package manifest and dependencies |
| `analysis_options.yaml` | Dart analyzer and lint rules config |
| `DESIGN.md` | Full design system specification (Material 3) |

## Architecture
- **Pattern**: Clean Architecture (feature-based with presentation/data/domain layers)
- **Navigation**: Declarative routing via `go_router` — routes in `lib/core/routes/app_router.dart`
- **State Management**: BLoC pattern (bloc + flutter_bloc) — one bloc per feature
- **Theming**: Material 3 with HCT algorithm (Fidelity variant) — `lib/core/theme/app_theme.dart`
- **Dependency Injection**: `get_it` pattern in `lib/core/di/di.dart` (placeholder)
- Architecture: Monolith (single Flutter app, no backend split)
- Network layer: Placeholder API client in `lib/core/network/api_client.dart`

## Feature Layer Structure (Clean Architecture)
Each feature under `lib/features/<feature>/` follows:
- **presentation/** — pages/, widgets/, bloc/ (UI + state)
- **domain/** — entities/, repositories/ (interfaces), usecases/ (business logic)
- **data/** — datasources/, models/ (DTOs), repositories/ (implementation), services/

Dependency rule: presentation → domain → data (never reverse)

## Design System (from DESIGN.md)
- **Seed Color**: Yellow `#FFC107` — primary container fixed across light/dark modes
- **Color Variants**: Light mode uses warm off-white surface (`#FFF8F2`), dark mode near-black (`#181309`)
- **Fonts**: Plus Jakarta Sans (headlines/titles) + Roboto (body/labels) via `google_fonts`
- **Shapes**: Extra Large (32px) for hero cards, Large (20-24px) for item cards, Full pill for chips/navbar
- **Elevation**: M3 tonal elevation (0-3 levels) + subtle drop shadows (0.06 opacity for cards, 0.25 for navbar)
- **Fixed Navbar**: `Navbar Surface` = `#201B11` (neutral tone 10) — does NOT change between light/dark modes
- **Custom Colors**: `Success` (green for "sedang berlangsung" status) via `ThemeExtension<AppColors>`

## UI Components (from DESIGN.md)
- Filled Button: `Primary Container`/`On Primary Container`, radius 24px
- Tonal Button: `Secondary Container`, radius 24px
- Outlined Button: border `Outline`, text `Primary`
- Text Field: fill `Surface Container Highest`, radius 16px
- SKS Chip: `Secondary Container`/`On Secondary Container`, pill
- Status Chip — Berlangsung: `Success`/`On Success`
- Status Chip — Selesai: `Outline Variant`/`On Surface Variant`
- Card — Hero: `Primary Container`, radius 32px
- Card — Item: `Surface Container`, radius 20px
- Stat Card: `Surface Container High`, radius 20px
- Countdown Widget: `On Primary Container`, big Display Large text

## Navigation Structure (from DESIGN.md)
- Floating Bottom Navigation Bar (pill, 3 tabs):
  - 🏠 **Home** — ringkasan & countdown
  - 📅 **Jadwal** — jadwal kuliah mingguan
  - 👤 **Profile** — data diri mahasiswa
- Item aktif: background `Navbar Active Pill` (`Primary Container` kuning)
- Auth flow: Login Screen (NPM/Password) → Main App (no navbar on auth)
- Routes: `/login`, `/main/home`, `/main/jadwal`, `/main/profile`

## Screen Layout Reference (from DESIGN.md)
- **Login**: warm gradient bg, logo, card with NPM/Password inputs, "Masuk" button
- **Home**: App bar → Hero countdown card → Quick stats (3 cards) → Today's schedule list → Navbar
- **Jadwal**: App bar → Horizontal day selector pills → Vertical timeline list → Navbar
- **Profile**: App bar → Profile header card → Academic info → Reminder/theme settings → Tabs (Tentang/Aktivitas) → "Perbarui Data" button → Navbar

## Spacing (from DESIGN.md)
- Base spacing unit: 8px
- Screen padding: 20-24px (left/right)
- Card spacing: 12-16px
- Navbar margin: 20px from bottom, 24px from sides

## Conventions
- No git history available (shallow clone) — cannot detect branch naming or commit style conventions
- Clean Architecture: feature-based modules with presentation/data/domain layers
- Routing via `go_router`: `context.go('/route')` for navigation, `ShellRoute` for bottom navbar
- State management via BLoC: `BlocBuilder` for UI, `context.read<Bloc>()` for dispatch, `BlocProvider` for injection
- Theme follows DESIGN.md — `buildTheme()` function in `lib/core/theme/app_theme.dart`, `ThemeMode.system` default
- All colors defined as `ColorScheme` (Material 3) + `ThemeExtension<AppColors>` for custom colors
- Fixed navbar color (`#201B11`) used regardless of light/dark theme

## Where to Look
| I want to... | Look at... |
|--------------|-----------|
| Add a UI widget | `lib/shared/widgets/` (shared) or `lib/features/<feature>/presentation/widgets/` |
| Add a screen/page | `lib/features/<feature>/presentation/pages/` + register route in `lib/core/routes/app_router.dart` |
| Add a route | `lib/core/routes/app_router.dart` (GoRouter config) |
| Add a state feature | `lib/features/<feature>/presentation/bloc/` (event.dart, state.dart, bloc.dart) |
| Wire a BLoC to UI | Use `BlocBuilder` or `BlocProvider` in widgets |
| Add a usecase | `lib/features/<feature>/domain/usecases/` |
| Add a repository | Define interface in `domain/repositories/`, implement in `data/repositories/` |
| Change colors/theme | `lib/core/theme/app_theme.dart` (follow DESIGN.md color roles) |
| Add a test | `test/` matching the source path |
| Add a BLoC test | Use `blocTest` helper in `test/features/<feature>/bloc/` |
| Add a dependency | `pubspec.yaml` → `dependencies:` section |
| Change linting rules | `analysis_options.yaml` |
| Change app metadata | `pubspec.yaml`, `web/manifest.json` |
| Reference design system | `DESIGN.md` (read before adding styling) |
