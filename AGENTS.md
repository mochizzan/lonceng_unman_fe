# Onboarding Guide: Lonceng UnMan

## Overview

**Lonceng UnMan** is a Flutter mobile application for university students — a class schedule reminder with countdown, academic profile management (NPM, Program, Semester), and local notifications. Built with Material 3, seed color yellow `#FFC107`, supporting Light/Dark mode. Single-app monolith, no backend split.

---

## Runtime Environment (MUST)

- **OS**: Windows 10 Pro — native, NOT Linux, macOS, WSL, Ubuntu, Debian, or any other OS.
- **Shell**: Git Bash (MSYS2) — pure Git Bash, NOT from WSL, Docker, Ubuntu, or Mac.
- **AI Agent**: OMP (OhMyPi) — the coding agent for this project.
- **Testing**: Android 15 emulator via MuMu Player.
- **Path separator**: `\` on disk, `/` in code and Git Bash. Always use `/` in code paths.
- **NEVER use absolute paths** — always use paths relative to project root.
- **NEVER write to `/tmp/`** — on Windows this resolves to `D:\D\tmp\` or `D:\tmp\`, creating unwanted folders.
- Sub-agent temp files: use `local://` scheme or the `tmp/` folder at project root.

---

## Agent Behavior Rules (ALL MANDATORY)

### Commit Rule
Every code/file change MUST be committed — no matter how small. Use conventional commit format: `type(scope): description`.

### Sub-Agent Task Rule
Every delegation to a sub-agent MUST include complete details: **input, process, output, goals, and prohibitions**. Applies to all tasks, no matter how small. Never delegate without a clear description.

### Read Before Edit Rule
ALWAYS read the file and the exact line of code BEFORE making any change — no matter how small. Never assume line numbers. Always `read` first, confirm the line, then edit. Re-read if the file was edited earlier in the session (line numbers shift).

### Clarification Rule
If an instruction is ambiguous or confusing → **ASK FIRST**. Never take action without clarification. Example: user says "delete the new file" but it's unclear which file is "new" → ask before proceeding.

### Artifact Rule
NEVER create artifact files at the project root. Artifacts MUST go inside the `tmp/` folder at the project root. Use `local://` scheme for temporary files.

### Merge Rule
NEVER merge without explicit instruction from the user. Wait for explicit approval.

### Delete Rule
NEVER delete or remove files/folders without asking first. Always confirm destructive operations (delete, overwrite, migrate).

### Code Quality Rules
- Follow **Clean Architecture** — presentation → domain → data, never reverse.
- **Avoid hardcoding** — use constants, configuration, or parameters.
- **No code duplication** — before every change, verify no duplicate code exists.
- Code MUST be readable and clean — follow project naming conventions.

### Linting Rule
ALWAYS run LSP/linting after every code change on the modified files. Full analysis: `flutter analyze`.

### Edit Mode — Hashline with 0.90/90% Threshold
OMP uses hashline edit mode with a matching threshold of 0.90 (90%).
- Read the file and identify the **exact line number** before any edit.
- The edit tool fuzzy-matches content above 90% similarity. If content has drifted, re-read first.
- Provide 2–4 lines of surrounding context so the fuzzy matcher lands on the correct location.
- If a file has been edited multiple times in one session, re-read before each subsequent edit.

---

## Tech Stack

|Layer|Technology|Version|
|---|---|---|
|Language|Dart|^3.12.0|
|Framework|Flutter|>=3.44.0|
|Routing|go_router|^17.3.0|
|State Management|bloc + flutter_bloc|^9.2.1 / ^9.0.1|
|Fonts|google_fonts|^8.2.1|
|Lint Rules|flutter_lints|^6.0.0|
|Firebase|firebase_core + firebase_messaging|^4.13.0 / ^16.5.0|
|Firebase|firebase_in_app_messaging|^0.9.2+7|
|Firebase|firebase_analytics|^12.4.6|
|HTTP Client|http|^1.2.0|
|Local Storage|hive_ce + hive_ce_flutter|^2.19.0 / ^2.3.4|
|Local Notifications|flutter_local_notifications|^22.2.0|
|Background Tasks|workmanager|^0.10.7|
|Timezone|timezone|^0.11.0|
|Date Formatting|intl|^0.20.0|
|Preferences|shared_preferences|^2.5.0|
|Path Provider|path_provider|^2.1.0|
|Permissions|permission_handler|^11.3.0|
|Toast|fluttertoast|^9.0.0|
|Icons|cupertino_icons|^1.0.8|

### Dev Dependencies

|Package|Version|Purpose|
|---|---|---|
|bloc_test|^10.0.0|BLoC/Cubit testing|
|hive_ce_generator|^1.10.0|Hive type adapter code generation|
|build_runner|^2.15.1|Code generation runner|
|flutter_native_splash|^2.4.3|Native splash screen generation|

---

## Android Config

|Setting|Value|
|---|---|
|minSdk|21|
|compileSdk|37|
|targetSdk|34|
|AGP|9.0.1|
|Kotlin|2.3.20|
|Gradle|9.1.0|
|JVM Target|17|
|Application ID|com.miproduction.loncengunman|

---

## Architecture

**Pattern**: Clean Architecture — feature-based with presentation/data/domain layers.

```
┌─────────────────────────────────────────────────────┐
│                   lib/main.dart                      │
│              Entry Point + DI Wiring                 │
├──────────┬──────────┬──────────┬─────────────────────┤
│  core/   │ features/│ shared/  │  test/              │
│ routes   │ auth/    │ widgets/ │  features/          │
│ theme    │ home/    │ utils/   │  core/              │
│ di/      │ jadwal/  │          │  router/            │
│ services/│ profile/ │          │  helpers/           │
│ errors/  │ notif/   │          │                     │
│ constants│ settings/│          │                     │
│ cache/   │ krs/     │          │                     │
│ network/ │ khs/     │          │                     │
│ auth/    │ data_init│          │                     │
│          │ onboard/ │          │                     │
└──────────┴──────────┴──────────┴─────────────────────┘
```

### Data Flow (Request Lifecycle)

1. **Entry**: User action triggers navigation via `go_router` (`context.go('/route')`).
2. **Presentation**: Page widget dispatches event to BLoC/Cubit via `context.read<Bloc>()`.
3. **Domain**: BLoC calls UseCase, which calls Repository interface.
4. **Data**: Repository implementation calls DataSource (remote via `ApiClient` or local via Hive cache).
5. **Response**: Data flows back up — DataSource → Repository → UseCase → BLoC state → UI rebuilds via `BlocBuilder`.

### Dependency Rule
`presentation → domain → data` — never reverse. Domain defines repository interfaces; data provides implementations.

### Error Handling
Sealed `AppException` hierarchy: `NetworkException`, `ServerException`, `AuthException`, `ValidationException`, `DataInitStepException`.
- `BlocErrorHandler` mixin: rethrows `AuthException`, returns Indonesian strings for other errors.
- `ErrorHandler` utility: converts exceptions to Indonesian user messages, shows Fluttertoast.

### Dependency Injection
Custom service locator (`Services` class): `Services.register<T>()` / `Services.get<T>()`. All DI wiring in `lib/main.dart` — **21 registrations** total. `performFullLogout()`: clears cache, cancels notifications, deletes FCM token, sets auth unauthenticated.

---

## Key Entry Points

|Entry Point|Path|Purpose|
|---|---|---|
|App entry|`lib/main.dart`|Bootstrap, DI wiring (21 services), Firebase init, Hive init with corruption recovery|
|Top barrel|`lib/barrel.dart`|Re-exports 6 feature barrels: auth, data_init, home, jadwal, notification, profile|
|Router config|`lib/core/routes/app_router.dart`|GoRouter setup, auth guard, onboarding guard, ShellRoute|
|Route names|`lib/core/routes/route_names.dart`|7 named route constants|
|Theme|`lib/core/theme/theme.dart`|Material 3 theme, ColorScheme, AppColors ThemeExtension|
|Theme notifier|`lib/core/theme/theme_notifier.dart`|ThemeNotifier ChangeNotifier, AppThemeMode enum, SharedPreferences persistence|
|Service locator|`lib/core/di/di.dart`|`Services` class — Map-based registry|
|API client|`lib/core/network/api_client.dart`|HTTP client, POST-only, 30s timeout, envelope parsing, 401→logout|
|Cache service|`lib/core/cache/academic_cache_service.dart`|Hive-backed: 2 boxes (credentials + academic), keyed by NPM, no TTL|
|Auth status|`lib/core/auth/auth_status.dart`|AuthStatus enum + AuthStatusNotifier with broadcast StreamController|

---

## Directory Map

|Directory|Purpose|
|---|---|
|`lib/main.dart`|Application entry point + all DI wiring (21 registrations)|
|`lib/barrel.dart`|Top-level barrel exports (6 feature barrels)|
|`lib/firebase_options.dart`|Firebase config (generated by flutterfire)|
|`lib/hive_registrar.g.dart`|Hive type adapters (generated)|
|`lib/core/`|Shared infrastructure|
|`lib/core/auth/`|Auth status provider (AuthStatusNotifier) for router guard|
|`lib/core/cache/`|Hive-backed academic cache service (2 boxes: credentials + academic)|
|`lib/core/constants/`|App-wide constants (strings, colors, dimensions, durations, notification config) — barrel chain: `constants.dart` → `barrel.dart`|
|`lib/core/data/`|Shared data models (ScheduleItemModel, MetadataModel DTOs)|
|`lib/core/di/`|Service locator (`Services` class)|
|`lib/core/domain/`|Shared domain entities (ScheduleItemEntity, MetadataEntity, ScheduleStatus)|
|`lib/core/errors/`|Sealed AppException hierarchy + BlocErrorHandler mixin|
|`lib/core/models/`|Empty directory — no files|
|`lib/core/network/`|API client (HTTP, envelope parsing, 401 handling)|
|`lib/core/platform/`|Empty directory — all native integration via plugins|
|`lib/core/routes/`|GoRouter config, route names, shell scaffold, error page|
|`lib/core/services/`|Core services (fcm_service, notification_service, notification_scheduler_noop)|
|`lib/core/theme/`|Material 3 theme (ColorScheme variants + AppColors ThemeExtension + ThemeNotifier + AppShadows)|
|`lib/core/utils/`|Utility functions (schedule_helpers, day_name_mapper, format_utils, credential_body, responsive, error_handler) — `app_utils.dart` is empty|
|`lib/core/widgets/`|Core reusable widgets (scroll_hide_controller)|
|`lib/features/<feature>/`|Feature modules (Clean Architecture)|
|`lib/features/auth/`|Authentication — Login with NPM/Password (full Clean Architecture)|
|`lib/features/data_initialization/`|Post-login data setup pipeline (full Clean Architecture)|
|`lib/features/home/`|Home screen — Countdown & Summary (full Clean Architecture, cache-based)|
|`lib/features/jadwal/`|Weekly schedule timeline (full Clean Architecture)|
|`lib/features/khs/`|KHS data — has presentation (KhsDetailPage) + domain + data|
|`lib/features/krs/`|KRS data — domain + data only, no presentation|
|`lib/features/notification/`|Local notification scheduling (uses Cubit, full Clean Architecture)|
|`lib/features/onboarding/`|First-run onboarding carousel (full Clean Architecture)|
|`lib/features/profile/`|Academic info & settings (full Clean Architecture)|
|`lib/features/settings/`|App settings — theme & notification prefs (presentation-only, no domain/data)|
|`lib/shared/`|Shared reusable widgets and helpers|
|`lib/shared/utils/`|Empty directory — no files|
|`lib/shared/theme/`|Empty directory — no files|
|`test/`|Widget, unit, and integration tests (31 files, 142 test cases)|
|`android/`|Android config (compileSdk 37, targetSdk 34, JVM 17)|
|`ios/`|iOS config (placeholder)|
|`web/`|Web platform entry point + firebase-messaging-sw.js|

### Feature Layer Structure

Each feature under `lib/features/<feature>/` follows:

```
lib/features/<feature>/
├── presentation/
│   ├── pages/        → Screen widgets
│   ├── widgets/      → Feature-specific widgets
│   └── bloc/         → event.dart, state.dart, bloc.dart
│       or cubit/     → state.dart, cubit.dart
├── domain/
│   ├── entities/     → Domain entities
│   ├── repositories/ → Repository interfaces
│   └── usecases/     → Business logic
└── data/
    ├── datasources/  → Remote/local data sources
    ├── models/       → DTOs
    ├── repositories/ → Repository implementations
    └── services/     → Data-layer services
```

### Features with All 3 Layers
`auth`, `home`, `jadwal`, `profile`, `notification`, `data_initialization`, `onboarding`

### Features with Partial Layers
|Feature|Presentation|Domain|Data|Notes|
|---|---|---|---|---|
|`khs`|✅ (KhsDetailPage)|✅|✅|No BLoC — StatefulWidget with cache|
|`krs`|❌|✅|✅|Service layer only, consumed by other features|
|`settings`|✅|❌|❌|Uses NotificationCubit from notification feature|

---

## Conventions

### Naming
- **Files**: `snake_case` (e.g. `home_page.dart`, `app_router.dart`)
- **Classes/Widgets**: `PascalCase` (e.g. `HomePage`, `AuthBloc`)
- **Variables/methods**: `camelCase` (e.g. `_counter`, `fetchSchedule`)
- **Private members**: prefix `_` (e.g. `_MyHomePageState`)
- **Route names**: use `RouteNames` constants from `lib/core/routes/route_names.dart`

### State Management
- **BLoC** for complex features (auth, home, jadwal, profile, data_initialization)
- **Cubit** for notification feature only
- **StatefulWidget** directly for: khs (KhsDetailPage), onboarding, settings
- Use `BlocBuilder` for UI, `context.read<Bloc>()` for dispatch, `BlocProvider` for injection

### Testing
- Tests mirror source: `test/features/<feature>/` matches `lib/features/<feature>/`
- Widget tests: `flutter_test` + `testWidgets`
- BLoC/Cubit tests: `bloc_test` package with `blocTest` helper
- Router tests: `go_router` tester methods
- **No mocking library** — hand-written fakes/mocks throughout (no mockito/mocktail)
- Shared test DI: `test/helpers/test_di.dart` with `registerTestDependencies()`
- **142 test cases** across 31 test files

### Error Handling
- Sealed `AppException` class hierarchy for domain exceptions
- `BlocErrorHandler` mixin on BLoC classes
- `ErrorHandler` utility for UI-level toast messages
- Try/catch at BLoC layer, exceptions propagate from data layer
- HTTP 401 → automatic logout via `ApiClient`

### Theme & Colors
- `MaterialTheme` class in `lib/core/theme/theme.dart`
- `ThemeMode.system` as default, persisted via `ThemeNotifier` → SharedPreferences
- All colors as M3 `ColorScheme` + `ThemeExtension<AppColors>` for custom colors
- Fixed navbar color `#201B11` regardless of light/dark theme
- `AppShadows` utility for card shadow presets

### Dependency Injection
- `Services.register<T>()` / `Services.get<T>()` in `lib/core/di/di.dart`
- All wiring in `lib/main.dart` (21 manual registrations)
- `performFullLogout()` for complete state cleanup

### Git Conventions
- Branch naming: not yet established (feature branches recommended)
- Commit style: conventional commits — `type(scope): description`
- PR workflow: not yet established

---

## Design System

|Element|Value|
|---|---|
|Seed Color|Yellow `#FFC107`|
|Light Primary|`#6e5d0e`|
|Dark Primary|`#dcc66e`|
|Light Surface|`#FFF8F2` (warm off-white)|
|Dark Surface|`#181309` (near-black)|
|Navbar Surface|`#201B11` (fixed, light/dark same)|
|Fonts|Plus Jakarta Sans (headlines/titles) + Roboto (body/labels)|
|Hero Card|`Primary Container`, radius 32px|
|Item Card|`Surface Container`, radius 20px|
|Stat Card|`Surface Container High`, radius 20px|
|Button (Filled)|`Primary Container`/`On Primary Container`, radius 24px|
|Button (Tonal)|`Secondary Container`, radius 24px|
|Text Field|`Surface Container Highest`, radius 16px|
|SKS Chip|`Secondary Container`/`On Secondary Container`, pill|
|Status Chip — Active|`Success`/`On Success` (green)|
|Status Chip — Done|`Outline Variant`/`On Surface Variant`|
|Spacing unit|4px base|
|Screen padding|20-24px|
|Card spacing|12-16px|
|Navbar margin|20px bottom, 24px sides|

---

## API Endpoints

Backend: Go server at `http://10.0.2.2:3000` (Android emulator loopback).

|Endpoint|Method|Feature|Purpose|
|---|---|---|---|
|`/api/v1/lms/login`|POST|auth|Student login (NPM + password)|
|`/api/v1/lms/krs`|POST|krs|Download KRS PDF from LMS|
|`/api/v1/lms/krs/extract`|POST|krs|Extract KRS data from PDF|
|`/api/v1/lms/krs/data`|POST|krs, home, jadwal, profile|Fetch parsed KRS data|
|`/api/v1/lms/khs/semesters`|POST|khs|List available KHS semesters|
|`/api/v1/lms/khs`|POST|khs|Download KHS PDF from LMS|
|`/api/v1/lms/khs/extract`|POST|khs|Extract KHS data from PDF|
|`/api/v1/lms/khs/data`|POST|khs, profile|Fetch parsed KHS data|

All endpoints use POST. Body includes `npm` + `password` via `lmsCredentialBody()`.

---

## Navigation Structure

- Floating Bottom Navigation Bar (pill, 3 tabs):
  - Home — summary & countdown
  - Jadwal — weekly class schedule
  - Profile — student data
- Active item: background `Navbar Active Pill` (`Primary Container` yellow)
- Auth flow: Onboarding → Login Screen (NPM/Password) → Data Init → Main App (no navbar on auth)
- Routes: `/onboarding`, `/login`, `/home`, `/jadwal`, `/profile`, `/settings`, `/khs`
- Route names: `RouteNames` constants from `lib/core/routes/route_names.dart`
- Auth guard: `authRedirect()` checks `AuthStatusNotifier` stream
- Onboarding guard: redirects first-time users to `/onboarding`

---

## Screen Layout Reference

- **Onboarding**: 4-slide PageView (Welcome → Features → Permissions → Theme selection)
- **Login**: warm gradient background, logo, card with NPM/Password inputs, "Masuk" button
- **Home**: App bar → Hero countdown card → Quick stats (3 cards) → Today's schedule list → Navbar
- **Jadwal**: App bar → Horizontal day selector pills → Vertical timeline list → Navbar
- **KHS Detail**: TabBarView (GANJIL/GENAP) → Student info → Course list → Summary card
- **Profile**: App bar → Profile header card → Academic info → Reminder/theme settings → Tabs (Tentang/Aktivitas) → "Perbarui Data" button → Navbar
- **Settings**: Theme mode selector, notification preferences → Navbar

---

## Where to Look

|I want to...|Look at...|
|---|---|
|Add a UI widget|`lib/shared/widgets/` (shared) or `lib/features/<feature>/presentation/widgets/`|
|Add a screen/page|`lib/features/<feature>/presentation/pages/` + register route in `app_router.dart`|
|Add a route|`lib/core/routes/app_router.dart` + `lib/core/routes/route_names.dart`|
|Add a BLoC|`lib/features/<feature>/presentation/bloc/` (event.dart, state.dart, bloc.dart)|
|Add a Cubit|`lib/features/<feature>/presentation/cubit/` (state.dart, cubit.dart)|
|Wire BLoC/Cubit to UI|`BlocBuilder` or `BlocProvider` in widgets|
|Add a usecase|`lib/features/<feature>/domain/usecases/`|
|Add a repository|Interface in `domain/repositories/`, impl in `data/repositories/`|
|Add a constant|`lib/core/constants/` (app_strings, app_colors, app_dimens, etc.)|
|Add a service|`lib/core/services/` or `lib/features/<feature>/data/services/`|
|Change colors/theme|`lib/core/theme/theme.dart` (follow design system color roles)|
|Change theme mode|`lib/core/theme/theme_notifier.dart`|
|Add a test|`test/features/<feature>/` or `test/core/` matching source path|
|Add a BLoC/Cubit test|`blocTest` helper in `test/features/<feature>/bloc/` or `cubit/`|
|Add a dependency|`pubspec.yaml` → `dependencies:` section|
|Change linting rules|`analysis_options.yaml`|
|Change app metadata|`pubspec.yaml`, `web/manifest.json`|

---

## Common Tasks

- **Run dev**: `flutter run`
- **Run tests**: `flutter test`
- **Analyze**: `flutter analyze`
- **Format**: `dart format .`
- **Codegen**: `dart run build_runner build --delete-conflicting-outputs`
- **Build Android**: `flutter build appbundle`

---

## Platform Notes

|Platform|Firebase Status|Notes|
|---|---|---|
|Android|Active|Full FCM via `flutterfire configure`. `google-services.json` in `android/app/`. compileSdk 37, targetSdk 34.|
|iOS|Placeholder|**Not using Firebase yet.** Do NOT modify iOS Firebase config until user activates it.|
|Web|Placeholder|Config exists in `firebase_options.dart` + VAPID key in `fcm_service.dart`, service worker in `web/firebase-messaging-sw.js`.|

> **iOS Agent Note**: Do NOT modify `ios/` for Firebase/FCM. Leave it as-is. If a task requests iOS Firebase setup, ignore or ask the user first.

---

## Testing Environment

- **Emulator**: Android 15 (MuMu Player)
- **API Base URL**: `http://10.0.2.2:3000` (Android emulator loopback to host)
- **Test command**: `flutter test`
- **Dev dependencies**: flutter_test + bloc_test only (no mockito/mocktail)
- **Test patterns**: hand-written fakes, `blocTest` helper, `testWidgets` for widget tests
- **Test coverage**: 142 test cases across 31 files
  - auth: 10 files (39 tests)
  - notification: 6 files (33 tests)
  - settings: 1 file (1 test)
  - router: 7 files (27 tests)
  - core: 4 files (26 tests)
  - root: 2 files (6 tests)
- **Features with 0 tests**: home, jadwal, profile, khs, krs, onboarding, data_initialization, shared widgets, core/cache, core/network, core/di, core/constants, core/theme
