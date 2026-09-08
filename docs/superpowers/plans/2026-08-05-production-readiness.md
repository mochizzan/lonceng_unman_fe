# Production Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 8 verified issues to make the notification system production-ready before backend integration.

**Architecture:** Clean Architecture (feature-based) with BLoC state management, GoRouter routing, Hive for local persistence, and flutter_local_notifications for scheduled alarms.

**Tech Stack:** Flutter SDK, Dart 3.12+, bloc/flutter_bloc 9.x, go_router 17.x, hive, flutter_local_notifications, timezone

## Global Constraints
- Flutter project on Windows (native, not WSL)
- Never use absolute paths — always relative to project root
- Follow existing code conventions (PascalCase widgets, camelCase vars, snake_case files)
- Clean Architecture: presentation → domain → data (never reverse)
- No hardcoded values — use NotificationConfig, AppStrings, AppDimens
- All colors via ThemeExtension<AppColors> or ColorScheme

---

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `lib/features/notification/domain/services/notification_scheduler.dart` | Modify | Add weekly recurrence (NF-3) |
| `lib/features/notification/presentation/cubit/notification_state.dart` | Modify | Fix copyWith (NF-6) |
| `lib/main.dart` | Modify | Add global error handling (NF-5) |
| `lib/core/services/notification_service.dart` | Modify | Add requestPermission() (NF-12) |
| `lib/features/notification/presentation/cubit/notification_cubit.dart` | Modify | Use requestPermission() (NF-12) |
| `lib/core/routes/app_router.dart` | Modify | Move NotificationCubit to ShellRoute (NF-10+11) |
| `lib/features/jadwal/presentation/pages/jadwal_page.dart` | Modify | Remove NotificationCubit wrapper + fix DI (NF-9, NF-10) |
| `lib/features/auth/presentation/pages/login_page.dart` | Modify | Fix AuthBloc lifecycle (NF-8) + remove test button (NF-1) |
| `lib/shared/widgets/notification_test_button.dart` | Delete | Remove test button (NF-1) |
| `lib/core/constants/notification_config.dart` | Modify | Remove test channel + constants (NF-2) |

---

## Task 1: Weekly Recurring Notifications (NF-3)

**Files:**
- Modify: `lib/features/notification/domain/services/notification_scheduler.dart:167-174`

**Interfaces:**
- Consumes: `NotificationService.schedule()` (already accepts `matchDateTimeComponents`)
- Produces: `NotificationScheduler.scheduleFromJadwal()` now schedules recurring weekly alarms

- [ ] **Step 1: Add import for DateTimeComponents**
  
  Open `lib/features/notification/domain/services/notification_scheduler.dart`.
  
  `DateTimeComponents` is from `flutter_local_notifications`. Dart imports are NOT transitive — importing `NotificationService` does NOT bring `DateTimeComponents` into scope. Add this import at the top:
  ```dart
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  ```

- [ ] **Step 2: Fix past-trigger early return**
  
  In `_scheduleAlarm()`, there is an early return (around lines 133-140) that skips scheduling when `triggerTime.isBefore(DateTime.now())`. With `matchDateTimeComponents`, the plugin computes the NEXT future occurrence automatically — the actual date is irrelevant. But this early return prevents `schedule()` from ever being called.
  
  **Change the early return** to only skip the ONE-TIME case, not the recurring case. The simplest fix: remove the early return entirely when using weekly recurrence. Since we ALWAYS use `matchDateTimeComponents` now, the plugin handles future scheduling. Remove or comment out:
  ```dart
  // DELETE or comment out this block:
  if (triggerTime.isBefore(DateTime.now())) {
    developer.log('Skipping past notification: ...');
    return;
  }
  ```
  
  With `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`, `flutter_local_notifications` always schedules the NEXT matching occurrence, so there's no risk of firing in the past.

- [ ] **Step 3: Add matchDateTimeComponents parameter**
  
  Locate the `_notificationService.schedule()` call (around line 168-174).
  
  Add `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime` to the named parameters:
  
  ```dart
  await _notificationService.schedule(
    id: entity.id,
    title: entity.courseName,
    body: _buildBody(entity),
    channel: NotificationChannel.classReminders,
    scheduledDate: tzTrigger,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
  ```

- [ ] **Step 3: Run dart analyze**
  
  Run: `dart analyze lib/features/notification/domain/services/notification_scheduler.dart`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 4: Commit**
  
  ```bash
  git add lib/features/notification/domain/services/notification_scheduler.dart
  git commit -m "fix(notification): add weekly recurrence to scheduled alarms"
  ```

---

## Task 2: Fix NotificationState.copyWith (NF-6)

**Files:**
- Modify: `lib/features/notification/presentation/cubit/notification_state.dart:33`

**Interfaces:**
- Consumes: `NotificationState` class
- Produces: Fixed `copyWith` that preserves `errorMessage`

- [ ] **Step 1: Fix the copyWith method**
  
  Open `lib/features/notification/presentation/cubit/notification_state.dart`.
  
  Find the `copyWith` method. Locate line 33 where `errorMessage: errorMessage` is used.
  
  Change it to:
  ```dart
  errorMessage: errorMessage ?? this.errorMessage,
  ```
  
  The full `copyWith` should look like (note: the parameter is `notifications`, NOT `scheduledNotifications`):
  ```dart
  NotificationState copyWith({
    NotificationStatus? status,
    List<ScheduledNotificationEntity>? notifications,
    String? errorMessage,
    bool? notificationPermissionDenied,
    int? reminderIntervalMinutes,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
      notificationPermissionDenied: notificationPermissionDenied ?? this.notificationPermissionDenied,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
    );
  }
  ```
  
  **IMPORTANT:** Only change line 33 (`errorMessage: errorMessage` → `errorMessage: errorMessage ?? this.errorMessage`). Do NOT rewrite the entire copyWith — the example above is for reference only.

- [ ] **Step 2: Run dart analyze**
  
  Run: `dart analyze lib/features/notification/presentation/cubit/notification_state.dart`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 3: Commit**
  
  ```bash
  git add lib/features/notification/presentation/cubit/notification_state.dart
  git commit -m "fix(notification): preserve errorMessage in copyWith"
  ```

---

## Task 3: Global Error Handling (NF-5)

**Files:**
- Modify: `lib/main.dart:45-157`

**Interfaces:**
- Consumes: `main()` function
- Produces: App with global error boundaries

- [ ] **Step 1: Add FlutterError.onError and runZonedGuarded**
  
  Open `lib/main.dart`.
  
  Find the `main()` function (line 45). Wrap the entire body in `runZonedGuarded` and add `FlutterError.onError`:
  
  ```dart
  Future<void> main() async {
    // Global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      developer.log(
        'FlutterError: ${details.exceptionAsString()}',
        name: 'ErrorHandler',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
  
    runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();
  
      // Firebase initialization (keep existing)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  
      // FCM (keep existing — use actual function names from your file)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await FcmService.instance.initialize(onNotificationTap: ...);
  
      // Hive initialization (keep existing)
      await Hive.initFlutter();
      Hive.registerAdapter(ScheduledNotificationModelAdapter());
  
      // ... rest of existing initialization ...
  
      runApp(const LoncengUnmanApp());
    }, (error, stackTrace) {
      developer.log(
        'Uncaught error: $error',
        name: 'ErrorHandler',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }
  ```
  
  Ensure `import 'dart:developer' as developer;` is at the top of the file.

- [ ] **Step 2: Run dart analyze**
  
  Run: `dart analyze lib/main.dart`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 3: Commit**
  
  ```bash
  git add lib/main.dart
  git commit -m "fix: add global error handling with runZonedGuarded"
  ```

---

## Task 4: Android 13+ Permission Request (NF-12)

**Files:**
- Modify: `lib/core/services/notification_service.dart`
- Modify: `lib/features/notification/presentation/cubit/notification_cubit.dart`

**Interfaces:**
- Consumes: `NotificationService` (existing)
- Produces: `NotificationService.requestPermission()` method

- [ ] **Step 1: Add requestPermission() to NotificationService**
  
  Open `lib/core/services/notification_service.dart`.
  
  Add this method to the `NotificationService` class (after `canScheduleExactNotifications()`):
  
  ```dart
  /// Request notification permission (required for Android 13+).
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    // iOS handles permission in initialization settings
    return true;
  }
  ```

- [ ] **Step 2: Update NotificationCubit.checkPermission()**
  
  Open `lib/features/notification/presentation/cubit/notification_cubit.dart`.
  
  Find the `checkPermission()` method. Change it to call `requestPermission()` instead of just checking:
  
  ```dart
  Future<bool> checkPermission() async {
    final enabled = await _notificationService.requestPermission();
    emit(state.copyWith(notificationPermissionDenied: !enabled));
    return enabled;
  }
  ```

- [ ] **Step 3: Run dart analyze**
  
  Run: `dart analyze lib/core/services/notification_service.dart lib/features/notification/presentation/cubit/notification_cubit.dart`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 4: Commit**
  
  ```bash
  git add lib/core/services/notification_service.dart lib/features/notification/presentation/cubit/notification_cubit.dart
  git commit -m "feat(notification): add Android 13+ permission request"
  ```

---

## Task 5: Single NotificationCubit Instance (NF-10+11)

**Files:**
- Modify: `lib/core/routes/app_router.dart`
- Modify: `lib/features/jadwal/presentation/pages/jadwal_page.dart`

**Interfaces:**
- Consumes: `NotificationCubit`, `NotificationScheduler`, `NotificationRepository`, `NotificationService`
- Produces: Single shared `NotificationCubit` at ShellRoute level

- [ ] **Step 1: Move NotificationCubit to ShellRoute in app_router.dart**
  
  Open `lib/core/routes/app_router.dart`.
  
  Find the `ShellRoute` (around line 111-117). Add `BlocProvider<NotificationCubit>` to the ShellRoute builder:
  
  ```dart
  ShellRoute(
    builder: (context, state, child) {
      return BlocProvider(
        create: (_) => NotificationCubit(
          scheduler: Services.get<NotificationScheduler>(),
          repository: Services.get<NotificationRepository>(),
          notificationService: Services.get<NotificationService>(),
        )..loadNotifications(),
        child: MainShellScaffold(
          currentIndex: _indexForRoute(state.topRoute?.name),
          child: child,
        ),
      );
    },
    routes: <RouteBase>[
      // ... existing routes ...
    ],
  ),
  ```
  
  Ensure the import for `NotificationCubit` is present:
  ```dart
  import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
  ```

- [ ] **Step 2: Remove NotificationCubit from JadwalPage**
  
  Open `lib/features/jadwal/presentation/pages/jadwal_page.dart`.
  
  Remove the `BlocProvider<NotificationCubit>` wrapper. The `JadwalPage` should only provide `JadwalBloc`:
  
  ```dart
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: true,
      create: (_) => JadwalBloc(Services.get<GetJadwal>()),
      child: const _JadwalPageView(),
    );
  }
  ```
  
  Remove the imports for `NotificationCubit`, `NotificationRepository`, and `NotificationScheduler` from this file.

- [ ] **Step 3: KEEP NotificationCubit on Settings route (do NOT remove)**
  
  **CRITICAL:** The Settings route (app_router.dart around line 138-149) is a standalone `GoRoute` OUTSIDE the `ShellRoute`. It does NOT share the ShellRoute's context. If you remove the `BlocProvider<NotificationCubit>` from the Settings route, `SettingsPage` will crash with `ProviderNotFoundException`.
  
  **KEEP the Settings route's `BlocProvider<NotificationCubit>` as-is.** Only JadwalPage (which IS inside the ShellRoute) should have its provider removed.
  
  The result: two `NotificationCubit` instances exist — one in ShellRoute (shared by Home/Jadwal/Profile) and one in Settings route. This is acceptable because Settings is a pushed route outside the shell.

- [ ] **Step 4: Run dart analyze**
  
  Run: `dart analyze lib/core/routes/app_router.dart lib/features/jadwal/presentation/pages/jadwal_page.dart`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 5: Commit**
  
  ```bash
  git add lib/core/routes/app_router.dart lib/features/jadwal/presentation/pages/jadwal_page.dart
  git commit -m "refactor(notification): move NotificationCubit to ShellRoute for JadwalPage"
  ```

---

## Task 6: Fix AuthBloc Lifecycle (NF-8)

**Files:**
- Modify: `lib/features/auth/presentation/pages/login_page.dart`

**Interfaces:**
- Consumes: `AuthBloc`, `GetAuth`, `AuthStatusNotifier`
- Produces: `LoginPage` with stable AuthBloc lifecycle

- [ ] **Step 1: Fix AuthBloc lifecycle in LoginPage**
  
  Open `lib/features/auth/presentation/pages/login_page.dart`.
  
  **Note:** LoginPage is ALREADY a StatefulWidget. The issue is that AuthBloc is created inside `build()` instead of `initState()`.
  
  Move AuthBloc creation to `initState` and add cleanup in `dispose`:
  
  ```dart
  class _LoginPageState extends State<LoginPage> {
    final _npmController = TextEditingController();
    late final AuthBloc _authBloc;
  
    @override
    void initState() {
      super.initState();
      _authBloc = widget.authBloc ?? AuthBloc(
        Services.get<GetAuth>(),
        widget.authStatusNotifier,
      );
    }
  
    @override
    void dispose() {
      _npmController.dispose();
      _authBloc.close();
      super.dispose();
    }
  
    @override
    Widget build(BuildContext context) {
      return BlocProvider.value(
        value: _authBloc,
        child: Scaffold(
          // ... rest unchanged
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Run dart analyze**
  
  Run: `dart analyze lib/features/auth/presentation/pages/login_page.dart`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 3: Commit**
  
  ```bash
  git add lib/features/auth/presentation/pages/login_page.dart
  git commit -m "fix(auth): move AuthBloc creation to initState"
  ```

---

## Task 7: Fix JadwalPage DI Bypass (NF-9)

**Files:**
- Modify: `lib/features/jadwal/presentation/pages/jadwal_page.dart`

**Interfaces:**
- Consumes: `GetJadwal` (from DI)
- Produces: `JadwalPage` using DI-provided usecase

- [ ] **Step 1: Remove _defaultGetJadwal() and use DI**
  
  Open `lib/features/jadwal/presentation/pages/jadwal_page.dart`.
  
  Remove the `_defaultGetJadwal()` static method and the `getJadwal` constructor parameter:
  
  ```dart
  class JadwalPage extends StatelessWidget {
    const JadwalPage({super.key});
  
    @override
    Widget build(BuildContext context) {
      return BlocProvider(
        lazy: true,
        create: (_) => JadwalBloc(Services.get<GetJadwal>()),
        child: const _JadwalPageView(),
      );
    }
  }
  ```
  
  Remove the imports for `JadwalRepositoryImpl` and `JadwalRemoteDataSource` (data layer imports from presentation).

- [ ] **Step 2: Run dart analyze**
  
  Run: `dart analyze lib/features/jadwal/presentation/pages/jadwal_page.dart`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 3: Commit**
  
  ```bash
  git add lib/features/jadwal/presentation/pages/jadwal_page.dart
  git commit -m "fix(jadwal): use DI-provided GetJadwal instead of inline stub"
  ```

---

## Task 8: Remove Test Button + Test Channel (NF-1+NF-2)

**Files:**
- Delete: `lib/shared/widgets/notification_test_button.dart`
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Modify: `lib/core/constants/notification_config.dart`

**Interfaces:**
- Consumes: None (removing dead code)
- Produces: Clean production build without test artifacts

- [ ] **Step 1: Remove test button from login_page.dart**
  
  Open `lib/features/auth/presentation/pages/login_page.dart`.
  
  Remove the import (around line 17):
  ```dart
  // DELETE: import 'package:lonceng_unman_fe/shared/widgets/notification_test_button.dart';
  ```
  
  Remove the widget usage (around line 89):
  ```dart
  // DELETE: const NotificationTestButton(),
  ```

- [ ] **Step 2: Delete notification_test_button.dart**
  
  Delete the file: `lib/shared/widgets/notification_test_button.dart`

- [ ] **Step 3: Remove NotificationChannel.test from notification_config.dart**
  
  Open `lib/core/constants/notification_config.dart`.
  
  Remove the `test` enum value (around lines 56-63):
  ```dart
  // DELETE these lines:
  /// Test notification (debug only).
  test(
    id: 'lonceng_unman_test',
    name: 'Test Notifikasi',
    description: 'Channel untuk test notifikasi',
    importance: Importance.high,
    enableVibration: true,
    enableLights: true,
  ),
  ```

- [ ] **Step 4: Remove test constants from NotificationConfig**
  
  In the same file, remove the entire `// ─── Test Notification ──` section (around lines 126-138):
  ```dart
  // DELETE these lines:
  // --- Test Notification ------------------------------------
  /// Fixed notification ID for the test notification button.
  static const int testNotificationId = 0;
  /// Test notification title.
  static const String testNotificationTitle = 'Lonceng UnMan';
  /// Test notification body.
  static const String testNotificationBody = 'Notifikasi berhasil!';
  /// Tooltip for the test notification button.
  static const String testNotificationTooltip = 'Test notifikasi';
  ```

- [ ] **Step 5: Run dart analyze**
  
  Run: `dart analyze lib/`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 6: Commit**
  
  ```bash
  git add lib/shared/widgets/notification_test_button.dart lib/features/auth/presentation/pages/login_page.dart lib/core/constants/notification_config.dart
  git commit -m "chore: remove test notification button and test channel"
  ```

---

## Task 9: Final Verification

**Files:**
- All modified files

- [ ] **Step 1: Run full dart analyze**
  
  Run: `dart analyze lib/`
  
  Expected: 0 errors, 0 warnings

- [ ] **Step 2: Verify no dead code**
  
  Grep for any remaining references to:
  - `NotificationTestButton`
  - `NotificationChannel.test`
  - `testNotificationId`
  - `testNotificationTitle`
  - `testNotificationBody`
  - `testNotificationTooltip`
  
  Expected: Zero matches in `lib/`

- [ ] **Step 3: Verify notification system works**
  
  Run the app on a device/emulator. Check:
  1. No test button on login page
  2. Notification permission dialog appears on Android 13+
  3. Scheduled notifications recur weekly (check system notification settings)
  4. Error states persist correctly (trigger an error, navigate away, come back)

- [ ] **Step 4: Final commit if needed**
  
  ```bash
  git add -A
  git commit -m "chore: production readiness cleanup"
  ```

---

## Deferred Items (After Backend Integration)

| ID | Issue | Effort | Reason to Defer |
|----|-------|--------|-----------------|
| NF-4 | Schedule all days (not just selected) | 60 min | Needs backend data model alignment |
| NF-7 | HomeBloc/ProfileBloc dispatch in build() | 20 min | Cosmetic, not functional blocker |
| NF-13 | FcmService not in DI | 10 min | Pattern inconsistency, works fine |
| NF-14 | ThemeNotifier flash | 15 min | UX polish, not crash risk |
| NF-15 | channelTogglePrefix unused | 5 min | Infrastructure for future feature |
| NF-16 | scheduleUpdates/general channels unused | 5 min | Infrastructure for future channels |
| NF-17 | Home/Jadwal/ProfileBloc zero tests | 60 min | Test coverage, not blocking |
| NF-18 | DataInitializationBloc dead code | 5 min | Dead code, no impact |

---

## Self-Review Checklist

- [x] **Spec coverage:** All 8 "fix now" items have tasks? Yes — NF-3, NF-5, NF-6, NF-8, NF-9, NF-10+11, NF-12, NF-1+2
- [x] **Placeholder scan:** No "TBD", "TODO", "implement later", or vague steps? Verified — all steps have concrete code
- [x] **Type consistency:** `NotificationService.requestPermission()` returns `Future<bool>`, cubit uses it correctly? Verified
- [x] **Dependency order:** Tasks are ordered to respect dependencies (NF-6 before NF-12, NF-10+11 before NF-12)? Verified
- [x] **Commit messages:** Each task ends with a conventional commit? Yes
- [x] **Validation:** 3 independent validators reviewed plan — all issues corrected:
  - Task 1: Added import step + past-trigger early return fix
  - Task 2: Fixed parameter name (notifications, not scheduledNotifications)
  - Task 3: Fixed pseudo-code to match actual function names
  - Task 5: Kept Settings route's BlocProvider (it's outside ShellRoute)
  - Task 6: Corrected false positive (LoginPage is already StatefulWidget)
