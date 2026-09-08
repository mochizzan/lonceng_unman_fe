# Consolidated Audit Report — Lonceng UnMan Codebase

> Raw findings from 5 parallel audit agents. Used as input for filtering, polishing, and recommendation selection.

---

## Audit 1: Architecture & Feature Structure (AuditArch)

### Complete lib/ File Tree

```
lib/
├── main.dart                          │ App entry: Firebase init, FCM setup, DI registration, runApp()
├── firebase_options.dart              │ Auto-generated Firebase config
├── barrel.dart                        │ Root barrel: re-exports core/ and all features/
│
├── core/                              │ ═══ Core Infrastructure ═══
│   ├── auth/auth_status.dart          │ AuthStatus enum + stream-based provider
│   ├── constants/                     │ app_strings, app_colors, app_dimens, app_durations, app_constants (empty)
│   ├── di/di.dart                     │ Custom lightweight service locator (Map<Type, dynamic>)
│   ├── errors/app_errors.dart         │ Sealed AppException: Network, Server, Cache, Auth, Validation
│   ├── models/base_model.dart         │ EMPTY placeholder
│   ├── network/api_client.dart        │ PLACEHOLDER ApiClient — get/post throw NetworkException
│   ├── routes/                        │ app_router.dart (go_router), route_names, main_shell_scaffold, error_page
│   ├── services/fcm_service.dart      │ FCM singleton: permission, token, foreground/background listeners
│   ├── theme/                         │ theme.dart (MaterialTheme, AppColors), theme_notifier.dart
│   ├── utils/                         │ responsive.dart (scale/sp), app_utils.dart (empty)
│   └── widgets/                       │ scroll_hide_controller.dart
│
├── features/
│   ├── auth/                          │ AuthEntity, AuthRepository, GetAuth, AuthBloc, LoginPage
│   ├── home/                          │ HomeEntity, HomeRepository, GetHome, HomeBloc, HomePage
│   ├── jadwal/                        │ JadwalEntity, JadwalRepository, GetJadwal, JadwalBloc, JadwalPage
│   ├── profile/                       │ ProfileEntity, ProfileRepository, GetProfile, ProfileBloc, ProfilePage
│   ├── data_initialization/           │ EMPTY stub (dead code)
│   └── settings/                      │ SettingsPage (uses ThemeNotifier, not Bloc)
│
└── shared/
    ├── widgets/                       │ BellLogo, AppTextField, AppButton, AuthBackground
    ├── theme/barrel.dart              │ Empty barrel (actual theme in core/)
    └── utils/helpers.dart             │ Empty placeholder
```

### Architecture Assessment
- **Clean Architecture**: Feature-based with presentation/data/domain layers ✅
- **Dependency Rule**: presentation → domain → data ✅ (compliance verified)
- **DI**: Custom lightweight Map<Type, dynamic> service locator (not get_it as AGENTS.md says)
- **All data sources are stubs** — entire backend is mocked
- **barrel.dart pattern**: Consistent barrel exports across all modules ✅
- **Key gap**: No `lib/features/notification/` exists yet — notification system needs to be built from scratch

---

## Audit 2: BLoC Pattern & State Management (AuditBloc)

### Inventory: ALL BLoCs/Cubits

| BLoC | Events | States | Type |
|------|--------|--------|------|
| AuthBloc | AuthNpmChanged, AuthSubmitted, AuthLogoutRequested | AuthInitial, AuthLoading, AuthAuthenticated, AuthError | Bloc |
| HomeBloc | HomeFetchRequested | HomeInitial, HomeLoading, HomeLoaded, HomeError | Bloc |
| JadwalBloc | JadwalFetchRequested, JadwalDayChanged | JadwalInitial, JadwalLoading, JadwalLoaded, JadwalError | Bloc |
| ProfileBloc | ProfileFetchRequested | ProfileInitial, ProfileLoading, ProfileLoaded, ProfileError | Bloc |
| DataInitializationBloc | (empty) | (empty) | Stub (dead code) |

### Pattern Assessment
- **Equatable**: NOT used — manual `==`/`hashCode` in all event/state classes ✅ (bug-free)
- **Sealed classes**: NOT used for states — plain final classes with status fields
- **Cubit vs Bloc**: Zero Cubits — all use Bloc pattern
- **Error handling**: `sealed class AppException` hierarchy in `app_errors.dart`
- **Testing**: Only AuthBloc has tests (6 `bloc_test` cases); others have zero

### Critical Issues
1. **Events dispatched in `build()`** (home_page.dart:79, profile_page.dart:53) — re-triggers on every rebuild
2. **AuthBloc created in `build()` not `initState()`** — lifecycle misuse
3. **DataInitializationBloc is dead code** — empty stub files
4. **Only AuthBloc has tests**

### NotificationBloc Recommendation
Use **Cubit** (not Bloc) for notifications — simpler API fits notification state. Place at `lib/features/notification/` following existing structure.

---

## Audit 3: Scheduling & Date/Time Handling (AuditSchedule)

### JadwalScheduleItem Data Model (Domain Entity)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `courseName` | `String` | ✅ | Course name |
| `startTime` | `DateTime` | ✅ | Class start time |
| `endTime` | `DateTime` | ✅ | Class end time |
| `lecturer` | `String?` | ❌ | Lecturer name |
| `room` | `String` | ✅ | Room/venue |
| `sks` | `String` | ✅ | Credit hours (e.g., "3 SKS") |
| `status` | `JadwalScheduleStatus` | ✅ | `ongoing` / `upcoming` / `completed` |

### JadwalEntity (Aggregate)
- `selectedDay` (String): Currently selected day ("Senin")
- `days` (List<String>): Available day names
- `scheduleItems` (List<JadwalScheduleItem>): Items for selected day

### Parallel Models (Home Feature)
- **ScheduleItemEntity** — has `group` but no `sks`
- **NextClassEntity** — has `sks`, `location`; provides `timeRemaining(DateTime)` method

### Data Flow
```
JadwalPage → BlocProvider<JadwalBloc> → JadwalFetchRequested
  → JadwalBloc → GetJadwal → JadwalRepositoryImpl → StubJadwalRemoteDataSource
  → JadwalModel (mock) → JadwalLoaded → UI
```

### Time Handling
- `DateTime.parse(json['startTime'])` — ISO 8601 deserialization
- Manual `_formatTime()` → `HH:MM` duplicated in 3 files
- `formatCountdown()` → `HH:MM:SS` in hero_countdown_card.dart
- `NextClassEntity.timeRemaining(now)` → `startTime.difference(now)`
- **No timezone handling** — all times device-local
- **No `intl` package**

### Countdown Timer
- `HeroCountdownCard` uses `Timer.periodic(Duration(seconds: 1))`
- Timer lifecycle: `initState` → create, `dispose` → cancel
- **No BLoC involvement** — timer is purely in widget state

### Scheduling Dependencies
**Present**: `firebase_messaging: ^16.5.0`, `firebase_core: ^4.13.0`, `shared_preferences: ^2.5.0`
**MISSING**: `flutter_local_notifications`, `timezone`, `intl`, `workmanager`/`android_alarm_manager_plus`, `hive`/`sqflite`

### Existing Notification Infrastructure
- **FcmService** (singleton) — Push-only, receives from Firebase server
- **Android manifest** — FCM channel configured, but NO `SCHEDULE_EXACT_ALARM` or `RECEIVE_BOOT_COMPLETED`
- **Settings UI** — "Ingatkan Sebelum Kelas" section exists but is `TODO: Implement reminder interval picker`
- **ReminderIntervalTile** — Shows hardcoded "5 menit", not wired to SharedPreferences

### Key Gaps for Notification Scheduler
1. No `flutter_local_notifications` package
2. No `timezone` package
3. No background scheduling (alarm manager/workmanager)
4. No local schedule persistence (data is ephemeral)
5. No `RECEIVE_BOOT_COMPLETED` permission on Android
6. No `SCHEDULE_EXACT_ALARM` permission on Android 12+
7. Reminder interval hardcoded, not wired to settings
8. No day-name → DateTime conversion ("Senin" string doesn't map to next Monday)

---

## Audit 4: Existing Services & Shared Widgets (AuditServices)

### Shared Widgets (4)
- `BellLogo` — School toga icon, responsive sizing
- `AppTextField` — Outlined field with leading icon
- `AppButton` — Filled button, PrimaryContainer colors
- `AuthBackground` — Gradient background for login

### Core Widgets
- `ScrollHideController` — Animation for navbar show/hide on scroll

### Utils
- `responsive.dart` — `scale()`, `sp()`, `responsiveFontSize()` (baseline 375px)
- `helpers.dart` — Empty placeholder
- `app_utils.dart` — Empty placeholder

### Network Layer
- `ApiClient` — PLACEHOLDER that throws NetworkException
- **No HTTP library** (no dio, no http package)
- All features use Stub*RemoteDataSource with hardcoded mock data

### Error Handling
- `sealed class AppException` hierarchy:
  - `NetworkException` (NETWORK_ERROR)
  - `ServerException` (SERVER_ERROR, has statusCode)
  - `CacheException` (CACHE_ERROR)
  - `AuthException` (AUTH_ERROR)
  - `ValidationException` (VALIDATION_ERROR)

### Complete Dependencies
**Production**: flutter, cupertino_icons ^1.0.8, go_router ^17.3.0, bloc ^9.2.1, flutter_bloc ^9.0.1, google_fonts ^8.2.1, firebase_core ^4.13.0, firebase_messaging ^16.5.0, shared_preferences ^2.5.0
**Dev**: flutter_test, bloc_test ^10.0.0, flutter_lints ^6.0.0

### Key Absences for Notification System
- `flutter_local_notifications` — Required
- `timezone` — Required
- `workmanager` — Required for background tasks
- `android_alarm_manager_plus` — Alternative for Android
- `hive`/`sqflite` — Required for local persistence
- `dio`/`http` — No real HTTP client

---

## Audit 5: Theme System & Platform Integration (AuditPlatform)

### Theme System
- `MaterialTheme` class: Full 36-slot ColorScheme for light/dark × 3 contrast levels (432 color tokens)
- `AppColors` ThemeExtension with custom semantic tokens (success, navbar)
- `ThemeNotifier` extends ChangeNotifier — persists Light/Dark/System via SharedPreferences
- `useMaterial3: true` ✅
- Seed color: `#6E5D0E` (dark gold)
- **Unused contrast themes**: ~280 lines of dead code
- **No Typography config** — relies on default M3

### Android Platform Config
- Application ID: `com.miproduction.loncengunman`
- compileSdk: dynamic (flutter.compileSdkVersion)
- FCM channel: `lonceng_unman_notifications`
- FCM icon: `@drawable/ic_notification`
- FCM accent: `#FFC107` (amber/seed color)
- **MISSING Permissions**:
  - `POST_NOTIFICATIONS` (Android 13+/API 33)
  - `SCHEDULE_EXACT_ALARM` (Android 12+)
  - `RECEIVE_BOOT_COMPLETED`
  - `WAKE_LOCK`
  - `FOREGROUND_SERVICE`
- MainActivity.kt: Bare FlutterActivity() — no platform channels

### iOS Platform Config
- Bundle ID: `com.miproduction.loncengunman`
- Deployment target: Not explicitly set (uses Flutter default)

### App Lifecycle
- `ThemeNotifier` uses `WidgetsBindingObserver` for lifecycle awareness
- No other lifecycle management

### Platform Capabilities for Notifications
- **Android**: AlarmManager/WorkManager available (needs permissions + packages)
- **iOS**: UNUserNotificationCenter available (needs permission request)
- **Web**: Service Worker + Notification API available (different implementation)
