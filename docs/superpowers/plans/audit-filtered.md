# Filtered Audit — Local Offline Notification System

> Refined from consolidated findings (5 parallel audits). Only notification-system-relevant data retained. Every finding is grounded in source code.

---

## A. Packages to Add

### Required

| Package | Latest Stable | Purpose | Rationale |
|---------|--------------|---------|-----------|
| `flutter_local_notifications` | `18.x` | Local notification display & scheduling | No local notification capability exists today; `FcmService` is push-only |
| `timezone` | `0.10.x` | TZ-aware scheduling (handles DST, recurring weekly alarms) | Weekday-based schedules ("Senin") require timezone-correct `DateTime` conversion |
| `intl` | `0.20.x` | Date/time formatting, locale-aware day names | `_formatTime()` is currently duplicated in 3 files; `intl` replaces all of them |
| `hive_flutter` | `2.x` | Local persistence for scheduled notifications, settings | No local DB exists; `shared_preferences` is insufficient for structured notification data |
| `workmanager` | `0.6.x` | Background task scheduling (Android WorkManager / iOS BGTaskScheduler) | Required for notifications when app is killed; no background scheduling exists |

### Optional / Consider

| Package | Purpose | When Needed |
|---------|---------|-------------|
| `android_alarm_manager_plus` | Android-only exact alarms via AlarmManager | If `workmanager` precision is insufficient for exact alarm timing on Android 12+ |
| `permission_handler` | Runtime permission requests for POST_NOTIFICATIONS (Android 13+) | If `flutter_local_notifications` doesn't cover all permission flows |

### Already Present (usable as-is)

| Package | Version | Reuse For |
|---------|---------|-----------|
| `flutter_bloc` / `bloc` | `9.x` | NotificationCubit/Bloc state management |
| `shared_preferences` | `2.5.0` | User reminder interval preference storage |
| `firebase_messaging` | `16.5.0` | Existing push infrastructure (NOT replaced, augmented) |

---

## B. Platform Permissions & Capabilities

### Android — `android/app/src/main/AndroidManifest.xml`

Current state: **No notification-related permissions at all.** Only FCM channel metadata exists (line 28-41).

**Must add inside `<manifest>` tag:**

```xml
<!-- Android 13+ (API 33): runtime permission for posting notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Android 12+ (API 31): schedule exact alarms -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<!-- Receive alarms after device reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Keep CPU alive during alarm delivery -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- Foreground service for background notification scheduling -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

**Must add inside `<application>` tag (for WorkManager):**

```xml
<!-- WorkManager initialization -->
<provider
    android:name="androidx.start.InitializationProvider"
    android:authorities="${applicationId}.androidx-startup"
    android:exported="false"
    tools:node="merge">
    <meta-data
        android:name="androidx.work.WorkManagerInitializer"
        android:value="androidx.startup"
        tools:node="remove"/>
</provider>
```

**Existing Android config that can be reused:**
- FCM channel ID: `lonceng_unman_notifications` (line 30-31) — notification feature can share or create a separate channel
- FCM icon: `@drawable/ic_notification` (line 35) — monochrome icon for status bar
- Accent color: `#FFC107` (amber) — matches design system seed color

### iOS — `ios/Runner/Info.plist`

Current state: **No background mode or notification entitlement configured.** Info.plist contains only standard Flutter keys.

**Must add to Info.plist:**

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

**Must add to `ios/Runner.xcodeproj/project.pbxproj`:**
- Enable Push Notifications capability (Xcode → Signing & Capabilities → + Capability → Push Notifications)
- Enable Background Modes (fetch, remote-notification)

**iOS runtime permission:** `flutter_local_notifications` handles `UNUserNotificationCenter.requestAuthorization()` automatically on first notification attempt. No manual plist entry needed for the permission itself.

---

## C. Data Model Fields Available for Scheduling

### JadwalScheduleItem (Primary source) — `lib/features/jadwal/domain/entities/jadwal_entity.dart`

| Field | Type | Notification Use |
|-------|------|-----------------|
| `courseName` | `String` | Notification title |
| `startTime` | `DateTime` | Notification trigger time (with reminder offset) |
| `endTime` | `DateTime` | Context only (end of class) |
| `lecturer` | `String?` | Notification body detail |
| `room` | `String` | Notification body detail |
| `sks` | `String` | Notification body detail |
| `status` | `JadwalScheduleStatus` | Filter: only schedule for `upcoming` items |

### JadwalEntity (Aggregate)

| Field | Type | Notification Use |
|-------|------|-----------------|
| `selectedDay` | `String` | Day name ("Senin", "Selasa", etc.) — **needs DateTime conversion** |
| `days` | `List<String>` | Available weekdays for weekly scheduling |
| `scheduleItems` | `List<JadwalScheduleItem>` | Items to schedule notifications for |

### NextClassEntity (Secondary, home feature)

| Field | Type | Notification Use |
|-------|------|-----------------|
| `courseName` | `String` | Same data, different shape |
| `startTime` | `DateTime` | `timeRemaining(now)` method — useful for countdown logic |
| `location` | `String` | Same as `room` in JadwalScheduleItem |

### ScheduleItemEntity (Home feature, duplicate model)

Has `group` field but **not used for scheduling** — JadwalScheduleItem is the canonical source.

---

## D. Data Gaps

### 1. Day-Name → DateTime Conversion (CRITICAL)

**Current state:** `JadwalEntity.selectedDay` is a `String` like `"Senin"` (Monday). Schedule items have `startTime`/`endTime` as `DateTime` — but these represent the mock data's absolute dates, not the day-of-week pattern.

**Problem:** To schedule recurring weekly notifications, you need to convert `"Senin"` to the next occurrence of Monday as a `DateTime`. No such conversion exists in the codebase.

**Required utility:** A `DayNameToDateTime` mapper that:
- Takes a day name string ("Senin"-"Minggu")
- Returns the next `DateTime` falling on that weekday
- Uses `intl` package's locale-aware day parsing or a static mapping

### 2. Local Persistence for Scheduled Notifications (CRITICAL)

**Current state:** All data is ephemeral. `SharedPreferences` holds only theme mode. No database exists.

**Needed:** A local store (Hive) to persist:
- Scheduled notification records (notification ID, trigger time, class details)
- User's reminder interval preference (currently hardcoded to `"5 menit"`)
- Notification delivery state (to avoid duplicate notifications)

### 3. Reminder Interval (Hardcoded) (CRITICAL)

**Current state in `lib/core/constants/app_strings.dart`:**
```dart
static const String settingsReminderValue = '5 menit';
```

**Current state in `lib/features/settings/presentation/widgets/settings_widgets.dart`:**
`ReminderIntervalTile` displays this hardcoded string. The `onTap` handler in `settings_page.dart:77` is:
```dart
// TODO: Implement reminder interval picker
```

**Gap:** No mechanism to store or read a user-selected reminder interval. The value is baked into the constants file, not wired to any storage.

---

## E. Existing Code to Reuse vs Must Build

### Reuse As-Is

| Component | Location | Why Reusable |
|-----------|----------|-------------|
| `Services` (DI container) | `lib/core/di/di.dart` | Lightweight `Map<Type, dynamic>` locator; register `NotificationScheduler` here |
| `AppException` hierarchy | `lib/core/errors/app_errors.dart` | Add `NotificationException` extending `AppException` |
| `FcmService` | `lib/core/services/fcm_service.dart` | Coexists with local notifications; FCM is for push, local is for scheduled |
| `JadwalScheduleItem` entity | `lib/features/jadwal/domain/entities/jadwal_entity.dart` | Primary data source for scheduling |
| `JadwalBloc` data flow | `lib/features/jadwal/` | Pattern for how feature data flows (repository → usecase → bloc) |
| `ThemeSegmentedControl` | `lib/features/settings/presentation/widgets/` | Pattern for how settings widgets are built |

### Must Build

| Component | Location | Notes |
|-----------|----------|-------|
| `notification/` feature | `lib/features/notification/` | New feature directory following existing structure |
| `NotificationCubit` | `lib/features/notification/presentation/bloc/` | State for notification list, scheduling status |
| `NotificationScheduler` | `lib/features/notification/domain/services/` | Core scheduling logic (not a BLoC) |
| `NotificationService` | `lib/features/notification/data/services/` | `flutter_local_notifications` wrapper |
| `ScheduledNotification` model | `lib/features/notification/data/models/` | Persistence model (Hive-serializable) |
| `NotificationRepository` | `lib/features/notification/domain/repositories/` | Interface for CRUD of scheduled notifications |
| `NotificationRepositoryImpl` | `lib/features/notification/data/repositories/` | Hive-backed implementation |
| `NotificationLocalDataSource` | `lib/features/notification/data/datasources/` | Hive box operations |
| `DayNameToDateTime` utility | `lib/core/utils/` | Converts "Senin" → next Monday DateTime |
| Reminder interval picker | `lib/features/settings/presentation/widgets/` | Replace TODO at `settings_page.dart:77` |
| `NotificationSettingsRepository` | `lib/features/notification/domain/repositories/` | Read/write reminder interval to SharedPreferences |
| Android receiver | `android/.../BootCompletedReceiver.kt` | Re-schedule alarms on device boot |

---

## F. Architecture Decisions

### 1. Cubit vs Bloc

**Recommendation: Cubit**

**Rationale (grounded in audit):**
- Zero Cubits exist in the codebase today (AuditBloc: "Cubit vs Bloc: Zero Cubits — all use Bloc pattern")
- Notification state is simple: `enum NotificationStatus { initial, loading, loaded, error }` + `List<ScheduledNotification>` + `int reminderIntervalMinutes`
- No complex event chain needed: no multi-step async workflows like AuthBloc's `NpmChanged → Submitted → Authenticated`
- `flutter_local_notifications` callbacks happen outside BLoC lifecycle — a Cubit's `emit()` is simpler to call from plugin callbacks
- The audit itself recommends Cubit: "Use Cubit (not Bloc) for notifications — simpler API fits notification state"

**Pattern to follow:** Match the naming convention (`NotificationCubit`, not `NotificationBloc`) but use the same state class pattern as existing blocs (plain final class with `status` field, manual `==`/`hashCode`).

### 2. Feature Location in Clean Architecture

```
lib/features/notification/
├── domain/
│   ├── entities/
│   │   └── scheduled_notification_entity.dart
│   ├── repositories/
│   │   └── notification_repository.dart          (abstract interface)
│   └── usecases/
│       ├── schedule_class_notification.dart
│       ├── cancel_notification.dart
│       └── get_scheduled_notifications.dart
├── data/
│   ├── models/
│   │   └── scheduled_notification_model.dart     (Hive-serializable)
│   ├── datasources/
│   │   └── notification_local_data_source.dart   (Hive box)
│   └── repositories/
│       └── notification_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── notification_cubit.dart
    │   └── notification_state.dart
    └── widgets/
        └── notification_settings_section.dart     (optional UI)
```

This mirrors the exact structure of `jadwal/`, `auth/`, `home/`, and `profile/` features (AuditArch: "Feature-based with presentation/data/domain layers ✅").

### 3. DI Wiring (Custom Service Locator)

**Current DI pattern** (`lib/core/di/di.dart`):
```dart
Services.register<GetJadwal>(
  GetJadwal(JadwalRepositoryImpl(remoteDataSource: StubJadwalRemoteDataSource())),
);
```

**Notification DI wiring should follow the same pattern:**
```dart
// Register data sources and repositories
Services.register<NotificationLocalDataSource>(
  NotificationLocalDataSource(),
);
Services.register<NotificationRepository>(
  NotificationRepositoryImpl(
    localDataSource: Services.get<NotificationLocalDataSource>(),
  ),
);
Services.register<NotificationScheduler>(
  NotificationScheduler(
    repository: Services.get<NotificationRepository>(),
  ),
);
```

**Note:** `Services` is a singleton map (`static final Map<Type, dynamic>`). It has no async initialization (`register` is sync). If Hive needs async open, do it in `main()` before `Services.register()`:
```dart
final hiveBox = await Hive.openBox<ScheduledNotification>('notifications');
Services.register<NotificationLocalDataSource>(
  NotificationLocalDataSource(box: hiveBox),
);
```

### 4. Notification Scheduling Interaction with BLoC Patterns

**Key audit finding (AuditBloc):** "Events dispatched in `build()`" is a known anti-pattern in the codebase (home_page.dart:79, profile_page.dart:53). The notification system should avoid this.

**Scheduling flow:**
1. `JadwalBloc` loads schedule data → `JadwalLoaded` state contains `scheduleItems`
2. `NotificationCubit` listens to `JadwalBloc` state changes (via `BlocListener` in the widget tree)
3. On `JadwalLoaded`, `NotificationCubit.scheduleAll(items, reminderMinutes)` is called
4. `NotificationCubit` delegates to `NotificationScheduler` (domain service, not BLoC)
5. `NotificationScheduler` queries `NotificationRepository` for existing schedules, computes diff, schedules/cancels via `flutter_local_notifications`
6. UI shows notification status from `NotificationCubit` state

**Avoid:** Dispatching notification scheduling from `build()`. Use `BlocListener<JadwalBloc>` in a parent widget that triggers `NotificationCubit` only on state transitions.

---

## G. Low-Priority Context (Nice to Know)

These findings are irrelevant to the notification system but provide context:

| Finding | Source | Why Low Priority |
|---------|--------|-----------------|
| Responsive utils exist (`scale()`, `sp()`) | AuditServices | Only needed if notification UI has custom layouts |
| `ThemeNotifier` uses `WidgetsBindingObserver` | AuditPlatform | Pattern for lifecycle awareness, but `flutter_local_notifications` handles its own callbacks |
| Unused contrast themes (~280 lines dead code) | AuditPlatform | Dead code, not blocking |
| Empty barrel exports (`shared/theme/barrel.dart`, `shared/utils/helpers.dart`) | AuditArch | Dead code, not blocking |
| `data_initialization/` feature is dead code | AuditArch | Dead code, not blocking |
| `ApiClient` is a placeholder (throws `NetworkException`) | AuditServices | Notification system is local-only, no network needed |
| Only AuthBloc has tests | AuditBloc | Not blocking, but NotificationCubit should have tests from the start |

---

## Summary: Implementation Prerequisites Checklist

| # | Prerequisite | Status | Blocks |
|---|-------------|--------|--------|
| 1 | Add 5 packages to `pubspec.yaml` | ❌ Not done | Everything |
| 2 | Add Android permissions to manifest | ❌ Not done | Background scheduling, boot receiver |
| 3 | Add iOS background modes to Info.plist | ❌ Not done | Background scheduling on iOS |
| 4 | Implement `DayNameToDateTime` utility | ❌ Not done | Converting schedule data to schedulable DateTimes |
| 5 | Initialize Hive in `main()` | ❌ Not done | Local notification persistence |
| 6 | Register notification services in DI | ❌ Not done | All feature wiring |
| 7 | Wire reminder interval to SharedPreferences | ❌ Not done | User-configurable reminder timing |
| 8 | Create `notification/` feature scaffold | ❌ Not done | All notification code |
