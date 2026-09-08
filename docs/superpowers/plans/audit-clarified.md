# Clarified Audit — Local Offline Notification System

> Resolved ambiguities, contradictions, and gaps from the filtered audit. Every decision is grounded in source code verification. Zero TBDs.

---

## A. Contradiction Resolution

### A1. DI Pattern: get_it vs Custom Map

| Source | Claim |
|--------|-------|
| AGENTS.md | "Uses get_it for DI" |
| AuditArch finding | "Custom lightweight Map<Type, dynamic> service locator (not get_it as AGENTS.md says)" |
| Actual code (`lib/core/di/di.dart`) | **Custom `Map<Type, dynamic>` locator.** Class `Services` with `register<T>()`, `get<T>()`, `unregister<T>()`, `clear()`. No get_it dependency. |

**Truth:** The codebase uses a custom `Services` class — a static `Map<Type, dynamic>`. No get_it, no riverpod, no provider for DI. AGENTS.md is wrong. All feature wiring in `main.dart` confirms this: `Services.register<GetAuth>(GetAuth(...))`, `Services.register<GetJadwal>(...)`, etc.

**Implication for notifications:** Must register all notification services via `Services.register<T>()`. Cannot use get_it `GetIt.instance.registerLazySingleton()`.

### A2. Package Versions (Verified from `pubspec.yaml`)

| Package | Declared | Audit Claim | Verified |
|---------|----------|-------------|----------|
| `flutter_bloc` | `^9.0.1` | "9.x" | ✅ Confirmed |
| `bloc` | `^9.2.1` | "9.x" | ✅ Confirmed |
| `shared_preferences` | `^2.5.0` | "2.5.0" | ✅ Confirmed |
| `firebase_core` | `^4.13.0` | (not listed) | ✅ Confirmed |
| `firebase_messaging` | `^16.5.0` | "16.5.0" | ✅ Confirmed |
| SDK constraint | `^3.12.0` | (not listed) | ✅ Confirmed — Dart 3.12+ |
| `get_it` | **NOT present** | AGENTS.md says present | ❌ AGENTS.md wrong |

### A3. Bloc vs Cubit Naming

The audit says "Zero Cubits exist" (AuditBloc). Verified: `AuthBloc`, `HomeBloc`, `JadwalBloc`, `ProfileBloc` — all Bloc pattern. No Cubits anywhere. The notification feature will be the **first Cubit** in the codebase.

### A4. `settingsReminderValue` Confusion

| Location | Value | Status |
|----------|-------|--------|
| `app_strings.dart:65` | `'5 menit'` (String constant) | Hardcoded display string |
| `settings_page.dart:77` | `// TODO: Implement reminder interval picker` | Empty handler |
| `settings_widgets.dart:121` | `AppStrings.settingsReminderValue` | Renders hardcoded string |

**Truth:** The reminder interval is a hardcoded display string, not a stored preference. No SharedPreferences key exists for it. No picker exists. The `ReminderIntervalTile` renders a static "5 menit" label with a chevron that does nothing on tap.

### A5. Android SDK Versions

From `android/app/build.gradle.kts`:
- `compileSdk` = `flutter.compileSdkVersion` (dynamic, resolves to Flutter SDK's bundled value)
- `minSdk` = `flutter.minSdkVersion` (dynamic)
- `targetSdk` = `flutter.targetSdkVersion` (dynamic)
- Java/Kotlin: JVM 17

These resolve at build time. Current Flutter SDK 3.x defaults: compileSdk=35, minSdk=21, targetSdk=35. The `SCHEDULE_EXACT_ALARM` permission (API 31+) and `POST_NOTIFICATIONS` (API 33) are relevant because targetSdk=35.

---

## B. Package Selection Decisions

### B1. Notification Display & Scheduling Package

| Package | Offline Capable | App-Killed Support | Platform | Maintenance | API Complexity |
|---------|----------------|--------------------|----------|-------------|---------------|
| `flutter_local_notifications` | ✅ Yes (local) | ⚠️ Via callback only (needs background handler) | Android + iOS + macOS + Linux | Active (18.x, Oct 2024) | Medium — requires channel setup, timezone init |
| `awesome_notifications` | ✅ Yes | ✅ Yes (built-in background isolates) | Android + iOS | Active | High — many features, steeper learning curve |
| `flutter_local_notifications` + `workmanager` | ✅ Yes | ✅ Yes (WorkManager reschedules) | Android + iOS | Both active | Medium — two packages but well-documented combo |
| `android_alarm_manager_plus` | ✅ Yes | ✅ Yes (AlarmManager fires) | Android only | Active | Low — simple API, but Android-only |

**Decision: `flutter_local_notifications` + `workmanager`**

**Rationale:**
1. `flutter_local_notifications` is the de facto standard — 99% of Flutter notification tutorials use it, it has the largest community, and it supports both platforms this app targets.
2. `workmanager` handles the app-killed gap that `flutter_local_notifications` alone cannot fill: when the app is terminated, WorkManager's `BackgroundTaskHandler` fires and can re-schedule notifications.
3. `awesome_notifications` is capable but heavier — it bundles its own scheduling engine, which overlaps with `workmanager`. Using two focused packages is simpler than one monolithic one.
4. `android_alarm_manager_plus` is Android-only; the app targets iOS too. Not suitable as the primary solution.
5. The filtered audit already recommends this exact combo.

### B2. Background Scheduling Strategy

| Strategy | Reliability (Android) | Battery Impact | Exact Timing | App-Killed Behavior |
|----------|----------------------|---------------|--------------|---------------------|
| `AlarmManager` (via `android_alarm_manager_plus`) | ✅ High — system-level alarms survive Doze (with `setExactAndAllowWhileIdle`) | Medium — wakes CPU | ✅ Exact to the second | ✅ Fires even when app killed |
| `WorkManager` | ⚠️ Approximate — `PeriodicWorkRequest` minimum interval is 15 min, `OneTimeWorkRequest` can be expedited but not exact | Low — battery-friendly | ❌ Not exact — can defer by minutes | ✅ Survives app kill, survives reboot (with `ExistingPeriodicWorkPolicy`) |
| Periodic `Timer` in Dart | ❌ Dies with app process | High (keeps isolate alive) | ✅ Exact while running | ❌ Does not survive app kill |

**Decision: `flutter_local_notifications` for exact alarm scheduling + `workmanager` for re-scheduling on reboot/app-kill**

**Rationale:**
1. The notification use case is **class reminders at specific times** (e.g., "5 minutes before Senin 08:00"). This requires exact timing.
2. `flutter_local_notifications` uses Android's `AlarmManager` internally via its `zonedSchedule()` method. This provides exact-to-the-second scheduling with timezone support.
3. When the app is killed, `AlarmManager`-based alarms **still fire** on Android (they are system-level). `flutter_local_notifications` handles this automatically.
4. `workmanager` is needed only for **re-scheduling after device reboot** (AlarmManager alarms do not survive reboot) and as a fallback for periodic schedule refresh.
5. `workmanager` is NOT used for the primary scheduling — it is too imprecise (15-min minimum). It is used only for the `RECEIVE_BOOT_COMPLETED` flow: when the device reboots, a WorkManager task fires and re-registers all alarms.
6. On iOS, `flutter_local_notifications` uses `UNUserNotificationCenter` with `UNCalendarNotificationTrigger`, which handles exact timing natively.

**Scheduling architecture:**
```
Schedule all notifications for the week:
  flutter_local_notifications.zonedSchedule(id, title, body, nextOccurrence, ...)
  → One alarm per class per week (e.g., Senin 08:00, Senin 10:00, Rabu 13:00)
  → Each alarm has a unique ID (hash of courseName + day + startTime)

On reboot:
  workmanager → BootRescheduleTask → re-read Hive → re-call zonedSchedule for all

On app-kill:
  AlarmManager fires the scheduled notification (system-level, no app needed)
  → flutter_local_notifications displays it via its BroadcastReceiver
```

### B3. Local Storage Decision

| Package | Fit for Notification Data | Query Capability | Complexity |
|---------|--------------------------|-----------------|------------|
| `SharedPreferences` | ❌ Key-value only — cannot store lists of structured objects without manual JSON serialization | No queries — get by key only | Low |
| `Hive` | ✅ Type-adapted boxes — store `ScheduledNotification` objects directly | Basic: `.values`, `get(key)`, `box.values.where(...)` | Low-Medium — requires code generation or manual TypeAdapter |
| `SQLite` (via `sqflite`) | ✅ Full relational model | Full SQL: JOINs, WHERE, ORDER BY | Medium-High — schema management, migrations |

**Decision: `Hive` (via `hive_flutter`)**

**Rationale:**
1. The notification data model is **flat and simple**: notification ID, course name, day, time, reminder offset, delivery status. No relational joins needed.
2. Hive stores typed objects natively — no JSON serialization boilerplate. A `ScheduledNotification` class with a `TypeAdapter` (or `@HiveType` annotation) is clean.
3. Hive is synchronous after open — `box.get(id)` returns immediately, no `await`. This matters because `flutter_local_notifications` callbacks are time-critical.
4. `sqflite` is overkill — there are no complex queries, no joins, no migrations expected. The notification table has at most ~20 rows (one per class per week × 7 days).
5. `SharedPreferences` cannot store structured notification records without manual `jsonEncode`/`jsonDecode` and loses type safety.
6. The filtered audit recommends Hive, and the project has no existing DB — Hive's minimal setup fits the "no existing infrastructure" state.

**Hive box structure:**
- Box name: `'scheduled_notifications'`
- Key: notification ID (int — computed from `courseName.hashCode ^ dayOfWeek ^ startTime.hour`)
- Value: `ScheduledNotification` model (Hive-annotated)
- Secondary box: `'notification_settings'` for reminder interval preference

---

## C. Architecture Specification

### C1. Feature Directory Structure

```
lib/features/notification/
├── domain/
│   ├── entities/
│   │   └── scheduled_notification_entity.dart    # Pure Dart entity
│   ├── repositories/
│   │   └── notification_repository.dart          # Abstract interface
│   └── services/
│       └── notification_scheduler.dart           # Domain service (orchestration)
├── data/
│   ├── models/
│   │   └── scheduled_notification_model.dart     # Hive-serializable model
│   ├── datasources/
│   │   └── notification_local_data_source.dart   # Hive box operations
│   └── repositories/
│       └── notification_repository_impl.dart     # Hive-backed implementation
└── presentation/
    ├── cubit/
    │   ├── notification_cubit.dart
    │   └── notification_state.dart
    └── widgets/
        └── notification_settings_section.dart    # Settings UI integration

lib/core/services/
├── notification_service.dart                      # flutter_local_notifications wrapper
└── fcm_service.dart                               # (existing, untouched)

lib/core/utils/
└── day_name_mapper.dart                           # "Senin" → DateTime conversion
```

**Why `services/` in domain, not `usecases/`?**
The audit lists usecases (`schedule_class_notification.dart`, etc.), but `NotificationScheduler` is not a usecase — it is a domain service that orchestrates multiple repository calls and notification platform interactions. The jadwal feature uses usecases (`GetJadwal`) because they are single-responsibility query wrappers. Notification scheduling is a multi-step orchestration (query existing → compute diff → schedule new → cancel stale → update state). This is a service, not a usecase.

### C2. Entity Design

```dart
// lib/features/notification/domain/entities/scheduled_notification_entity.dart

/// A single scheduled local notification for a class reminder.
class ScheduledNotificationEntity {
  const ScheduledNotificationEntity({
    required this.id,
    required this.courseName,
    required this.dayOfWeek,       // "Senin", "Selasa", etc.
    required this.classTime,       // The class startTime (e.g., 08:00)
    required this.reminderOffset,  // Minutes before class (e.g., 5)
    required this.room,
    required this.lecturer,
    required this.isActive,        // User can toggle per-notification
  });

  /// Unique notification ID — computed from courseName + day + hour.
  /// Used as both Hive key and flutter_local_notifications ID.
  final int id;

  /// Course name (e.g., "Algoritma Pemrograman").
  final String courseName;

  /// Day name in Indonesian (e.g., "Senin").
  final String dayOfWeek;

  /// The class start time — only time-of-day matters (hour, minute).
  /// The date portion is recomputed each week from dayOfWeek.
  final DateTime classTime;

  /// Minutes before classTime to fire the notification.
  final int reminderOffset;

  /// Room/venue (e.g., "R.301 Gedung A").
  final String room;

  /// Lecturer name (nullable — not all classes have assigned lecturers).
  final String? lecturer;

  /// Whether this notification is enabled by the user.
  final bool isActive;
}
```

**Why `classTime` is a `DateTime` but only time-of-day matters:**
`JadwalScheduleItem.startTime` is a `DateTime` (from `DateTime.parse(json['startTime'])`). The entity stores it as-is for compatibility, but the scheduler extracts only `hour` and `minute` when computing the trigger `DateTime` from `dayOfWeek`.

### C3. Repository Interface

```dart
// lib/features/notification/domain/repositories/notification_repository.dart

abstract class NotificationRepository {
  /// Get all scheduled notifications.
  Future<List<ScheduledNotificationEntity>> getAll();

  /// Get a single notification by ID.
  Future<ScheduledNotificationEntity?> getById(int id);

  /// Insert or update a notification.
  Future<void> save(ScheduledNotificationEntity notification);

  /// Insert or update multiple notifications.
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications);

  /// Delete a notification by ID.
  Future<void> delete(int id);

  /// Delete all notifications.
  Future<void> deleteAll();

  /// Get the reminder interval in minutes (from settings).
  Future<int> getReminderInterval();

  /// Set the reminder interval in minutes.
  Future<void> setReminderInterval(int minutes);
}
```

**Why `getReminderInterval`/`setReminderInterval` live in `NotificationRepository` rather than a separate settings repository:**
The reminder interval is notification-specific state. A separate `NotificationSettingsRepository` adds a class and DI registration for one getter/one setter. The `NotificationRepository` already owns notification-related persistence — storing the interval in the same Hive box (different key) is simpler and avoids cross-repository coordination.

### C4. Service Layer Responsibilities

| Layer | Class | Responsibility | Does NOT |
|-------|-------|---------------|----------|
| **Domain service** | `NotificationScheduler` | Orchestrates: reads schedule data, computes which notifications to schedule/cancel, delegates to `NotificationRepository` and `NotificationService` | Does not touch UI, does not know about Hive or flutter_local_notifications internals |
| **Data service** | `NotificationService` | Thin wrapper around `flutter_local_notifications` plugin. Handles initialization, channel creation, `zonedSchedule()`, `cancel()`, `cancelAll()` | Does not compute trigger times, does not persist data |
| **Data source** | `NotificationLocalDataSource` | Raw Hive operations: `box.get()`, `box.put()`, `box.delete()`, `box.values` | Does not know about notification scheduling logic |
| **Repository impl** | `NotificationRepositoryImpl` | Translates between domain entities and Hive models, delegates to data source and data service | Does not compute trigger times |
| **Cubit** | `NotificationCubit` | Exposes state to UI, delegates to `NotificationScheduler` | Does not directly call flutter_local_notifications or Hive |

### C5. Cubit Design

```dart
// lib/features/notification/presentation/cubit/notification_state.dart

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.reminderIntervalMinutes = 5,
    this.errorMessage,
  });

  final NotificationStatus status;
  final List<ScheduledNotificationEntity> notifications;
  final int reminderIntervalMinutes;
  final String? errorMessage;
}
```

```dart
// lib/features/notification/presentation/cubit/notification_cubit.dart

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required NotificationScheduler scheduler,
    required NotificationRepository repository,
  }) : _scheduler = scheduler,
       _repository = repository,
       super(const NotificationState());

  final NotificationScheduler _scheduler;
  final NotificationRepository _repository;

  /// Load all scheduled notifications and reminder interval.
  Future<void> loadNotifications() async { ... }

  /// Schedule notifications for all classes on a given day.
  /// Called when JadwalBloc emits JadwalLoaded.
  Future<void> scheduleFromJadwal(JadwalEntity jadwal) async { ... }

  /// Toggle a specific notification on/off.
  Future<void> toggleNotification(int id) async { ... }

  /// Update reminder interval and reschedule all active notifications.
  Future<void> updateReminderInterval(int minutes) async { ... }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async { ... }
}
```

**Why Cubit, not Bloc (reconfirmed):**
1. No complex event chain — `loadNotifications()`, `scheduleFromJadwal()`, `toggleNotification()` are direct methods, not events that need transformation.
2. `flutter_local_notifications` callbacks happen outside BLoC lifecycle — calling `cubit.onNotificationDelivered(id)` is simpler than dispatching `NotificationDeliveredEvent`.
3. The audit explicitly recommends Cubit for this use case.
4. State class follows existing convention: plain final class with manual `==`/`hashCode` (no Equatable, matching `AuthBloc`/`HomeBloc` pattern).

### C6. DI Wiring

```dart
// In lib/main.dart, after existing Services.register calls:

// 1. Open Hive boxes (async, before Services.register)
final notificationsBox = await Hive.openBox<Map>('scheduled_notifications');
final settingsBox = await Hive.openBox('notification_settings');

// 2. Register data layer
Services.register<NotificationLocalDataSource>(
  NotificationLocalDataSource(
    notificationsBox: notificationsBox,
    settingsBox: settingsBox,
  ),
);

// 3. Register repository
Services.register<NotificationRepository>(
  NotificationRepositoryImpl(
    localDataSource: Services.get<NotificationLocalDataSource>(),
  ),
);

// 4. Register platform service (flutter_local_notifications wrapper)
Services.register<NotificationService>(
  NotificationService(),
);

// 5. Initialize platform service (async)
await Services.get<NotificationService>().initialize();

// 6. Register domain service (orchestrator)
Services.register<NotificationScheduler>(
  NotificationScheduler(
    repository: Services.get<NotificationRepository>(),
    notificationService: Services.get<NotificationService>(),
  ),
);

// 7. Register Cubit (created per-widget via BlocProvider, not in Services)
//    NotificationCubit is NOT a singleton — each widget tree section
//    creates its own via:
//    BlocProvider(
//      create: (_) => NotificationCubit(
//        scheduler: Services.get<NotificationScheduler>(),
//        repository: Services.get<NotificationRepository>(),
//      ),
//    )
```

**Why NotificationCubit is NOT registered in Services:**
Cubits are created per-widget-tree via `BlocProvider` (matching how `AuthBloc`, `HomeBloc`, etc. are created). Services holds long-lived singletons (repositories, data sources, services). Cubits are scoped to their widget subtree and disposed when the subtree is removed.

---

## D. Platform Setup — Exact Specifications

### D1. Android Permissions — `android/app/src/main/AndroidManifest.xml`

**Add inside `<manifest>` tag (before `<application>`):**

```xml
<!-- Android 13+ (API 33): runtime permission for posting notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Android 12+ (API 31): schedule exact alarms via AlarmManager -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<!-- Receive alarms after device reboot (re-schedules all notifications) -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Keep CPU alive during alarm delivery -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- Foreground service for background notification scheduling (WorkManager) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

**Add inside `<application>` tag (after existing `<meta-data>` entries):**

```xml
<!-- Disable default WorkManager auto-init (we initialize manually) -->
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

<!-- Boot receiver: re-schedules all notifications after device reboot -->
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
    android:exported="false"/>
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

**Why these exact receivers:**
`flutter_local_notifications` bundles `ScheduledNotificationBootReceiver` which re-registers all persisted alarms on boot. Without this, alarms are lost after reboot. The `ScheduledNotificationReceiver` handles the actual notification display when `AlarmManager` fires.

**Existing config to reuse:**
- FCM channel ID `lonceng_unman_notifications` (line 30-31) — notification feature creates a **separate channel** (`lonceng_unman_class_reminders`) to allow independent volume/mute control
- FCM icon `@drawable/ic_notification` (line 35) — reuse for local notifications
- Accent color `#FFC107` (line 40) — reuse for notification accent

### D2. iOS Setup

**Add to `ios/Runner/Info.plist` (inside `<dict>`):**

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>
```

**Why these background modes:**
- `fetch` — allows periodic background app refresh (workmanager's iOS equivalent)
- `remote-notification` — required for FCM (already needed for existing push infrastructure)
- `processing` — allows background processing tasks (workmanager uses `BGProcessingTask` for rescheduling)

**iOS permission flow:**
`flutter_local_notifications` calls `UNUserNotificationCenter.requestAuthorization()` automatically on first `initialize()` call. No manual plist entry needed for the permission itself. The user sees the system permission dialog on first notification attempt.

**iOS notification category (optional but recommended):**
Register a `CLASS_REMINDER` category in `initialize()` so users can take action (e.g., "Dismiss" or "Snooze 5 min") from the notification.

### D3. Notification Channel Configuration

```dart
// In NotificationService.initialize():
const AndroidNotificationChannel classReminderChannel = AndroidNotificationChannel(
  'lonceng_unman_class_reminders',  // Channel ID
  'Pengingat Kelas',                // Channel name (Indonesian)
  description: 'Notifikasi pengingat sebelum kelas dimulai',
  importance: Importance.high,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFFFFC107),      // Amber accent
);
```

**Why a separate channel from FCM:**
The existing FCM channel (`lonceng_unman_notifications`) handles push notifications from the server. Class reminders are local, scheduled notifications. Separate channels let the user:
- Mute FCM push without losing class reminders
- Mute class reminders without losing FCM push
- Configure vibration/sound independently

---

## E. Data Model Clarification

### E1. Day Name → DateTime Conversion

**The problem:** `JadwalEntity.selectedDay` is `"Senin"` (Monday). Schedule items have `startTime` as a `DateTime` (e.g., `2025-01-06 08:00:00`). To schedule a recurring weekly notification, you need the **next** occurrence of that weekday.

**The solution — `DayNameMapper` utility:**

```dart
// lib/core/utils/day_name_mapper.dart

/// Maps Indonesian day names to Dart weekday integers and vice versa.
class DayNameMapper {
  DayNameMapper._();

  static const Map<String, int> _dayToWeekday = {
    'Senin': DateTime.monday,    // 1
    'Selasa': DateTime.tuesday,  // 2
    'Rabu': DateTime.wednesday,  // 3
    'Kamis': DateTime.thursday,  // 4
    'Jumat': DateTime.friday,    // 5
    'Sabtu': DateTime.saturday,  // 6
    'Minggu': DateTime.sunday,   // 7
  };

  /// Convert "Senin" → DateTime.monday (1).
  static int weekdayFromName(String dayName) {
    final weekday = _dayToWeekday[dayName];
    if (weekday == null) {
      throw ArgumentError('Unknown day name: $dayName');
    }
    return weekday;
  }

  /// Get the next occurrence of [dayName] from [now].
  /// If today IS that day, returns today.
  static DateTime nextOccurrence(String dayName, {DateTime? now}) {
    final now_ = now ?? DateTime.now();
    final targetWeekday = weekdayFromName(dayName);
    final currentWeekday = now_.weekday;

    // Days until the target day (0 if today, 7 if next week)
    final daysUntil = (targetWeekday - currentWeekday) % 7;

    return DateTime(
      now_.year,
      now_.month,
      now_.day + daysUntil,
    );
  }
}
```

**Why a static mapping instead of `intl` parsing:**
The day names are always in Indonesian (`"Senin"` through `"Minggu"`). The `intl` package's `DateFormat` can parse day names, but it requires locale initialization and is heavier than a simple map. The static mapping is:
- Zero-dependency (no `intl` needed for this specific function)
- Faster (no locale lookup)
- Less error-prone (no locale string mismatches)

**Note:** The `intl` package is still recommended for the rest of the app (replacing the 3 duplicated `_formatTime()` functions), but the day-name mapper does not depend on it.

### E2. Weekly Schedule → Individual Alarm Mapping

**Input:** A `JadwalEntity` with `selectedDay = "Senin"` and `scheduleItems` containing items like:
```
courseName: "Algoritma", startTime: 2025-01-06 08:00, room: "R.301"
courseName: "Basis Data", startTime: 2025-01-06 10:00, room: "R.201"
```

**Output:** Two `flutter_local_notifications` alarms:
1. ID: `hash("Algoritma" ^ "Senin" ^ 8)`, trigger: next Monday 07:55 (5 min before)
2. ID: `hash("Basis Data" ^ "Senin" ^ 10)`, trigger: next Monday 09:55 (5 min before)

**Mapping algorithm (in `NotificationScheduler`):**

```
For each JadwalScheduleItem in scheduleItems:
  1. Extract dayName from JadwalEntity.selectedDay
  2. Extract hour:minute from item.startTime
  3. Compute nextOccurrence = DayNameMapper.nextOccurrence(dayName)
  4. Compute triggerTime = nextOccurrence + TimeOfDay(hour: startTime.hour, minute: startTime.minute) - Duration(minutes: reminderInterval)
  5. Compute notificationId = _computeId(item.courseName, dayName, item.startTime.hour)
  6. Call notificationService.schedule(
       id: notificationId,
       title: item.courseName,
       body: '${item.room} • ${formatTime(item.startTime)}',
       scheduledDate: TZDateTime.local(triggerTime.year, triggerTime.month, triggerTime.day, triggerTime.hour, triggerTime.minute),
     )
```

**Why one alarm per class per week (not a single weekly alarm):**
Each class has a different time. A single weekly alarm cannot represent "08:00 Senin AND 10:00 Senin AND 13:00 Rabu". Each must be a separate `zonedSchedule` call with a unique ID.

**Why `reminderOffset` is subtracted from trigger time:**
The user sets "Ingatkan Sebelum Kelas: 5 menit" (remind 5 minutes before class). If class starts at 08:00, the notification fires at 07:55. The offset is configurable (5, 10, 15, 30 minutes) and stored in Hive via `NotificationRepository.getReminderInterval()`.

### E3. Notification ID Computation

```dart
/// Deterministic ID from course + day + hour.
/// Ensures re-scheduling overwrites the same alarm (no duplicates).
static int _computeNotificationId(String courseName, String dayName, int hour) {
  final key = '$courseName|$dayName|$hour';
  return key.hashCode & 0x7FFFFFFF;  // Ensure positive (31-bit)
}
```

**Why `hashCode & 0x7FFFFFFF`:**
`String.hashCode` can return negative values. `flutter_local_notifications` requires non-negative IDs. The `& 0x7FFFFFFF` masks the sign bit.

**Why not use `DateTime.hashCode`:**
`DateTime` includes microseconds, so two calls at different microseconds produce different hashes. The deterministic key uses only the semantically meaningful parts (course + day + hour).

### E4. Reminder Interval Options

| Display String | Internal Value (minutes) | ID |
|---------------|-------------------------|----|
| `'5 menit'` | `5` | 5 |
| `'10 menit'` | `10` | 10 |
| `'15 menit'` | `15` | 15 |
| `'30 menit'` | `30` | 30 |
| `'1 jam'` | `60` | 60 |

**Storage:** Hive box `'notification_settings'`, key `'reminder_interval_minutes'`, value `int`.

**UI:** Replace the TODO at `settings_page.dart:77` with a bottom sheet picker showing these options. The selected value updates `NotificationCubit.updateReminderInterval(minutes)`, which:
1. Saves to Hive via `NotificationRepository.setReminderInterval(minutes)`
2. Cancels all existing notifications
3. Re-schedules all with the new offset

### E5. Notification Re-scheduling on Reboot

**Flow:**
1. Device reboots → Android sends `BOOT_COMPLETED` intent
2. `ScheduledNotificationBootReceiver` (from `flutter_local_notifications`) receives it
3. Calls top-level `@pragma('vm:entry-point')` handler registered in the notification service
4. Handler initializes Hive, reads all `ScheduledNotificationEntity` from box
5. Re-computes trigger times using `DayNameMapper.nextOccurrence()` with **today's date**
6. Calls `zonedSchedule()` for each active notification

**Why trigger times must be recomputed (not stored):**
Stored trigger times become stale after reboot. A notification scheduled for "next Monday 07:55" has a specific `DateTime`. After reboot on Wednesday, "next Monday" is different. The entity stores the **day-of-week + time-of-day pattern**, not the absolute `DateTime`. The scheduler always computes the next occurrence from "now".

---

## F. Implementation Prerequisites (Revised)

| # | Prerequisite | Depends On | Blocks |
|---|-------------|-----------|--------|
| 1 | Add packages to `pubspec.yaml`: `flutter_local_notifications`, `timezone`, `hive_flutter`, `workmanager` | Nothing | Everything |
| 2 | `flutter pub get` + `dart run build_runner build` (Hive type adapters) | #1 | Hive models |
| 3 | Add Android permissions to `AndroidManifest.xml` | #1 | Background scheduling |
| 4 | Add iOS background modes to `Info.plist` | #1 | Background scheduling on iOS |
| 5 | Create `DayNameMapper` utility | Nothing | Date conversion |
| 6 | Create `ScheduledNotificationEntity` + `ScheduledNotificationModel` (Hive) | #1 | Data layer |
| 7 | Create `NotificationLocalDataSource` (Hive box ops) | #6 | Repository |
| 8 | Create `NotificationRepository` interface + `NotificationRepositoryImpl` | #7 | Scheduler |
| 9 | Create `NotificationService` (flutter_local_notifications wrapper) | #1 | Scheduler |
| 10 | Initialize Hive + notification service in `main()` | #1, #7, #9 | DI registration |
| 11 | Register all services in DI (`Services.register`) | #7, #9, #10 | Cubit |
| 12 | Create `NotificationScheduler` (domain service) | #8, #9 | Cubit |
| 13 | Create `NotificationCubit` + `NotificationState` | #12 | UI wiring |
| 14 | Wire `NotificationCubit` to `JadwalBloc` via `BlocListener` | #13 | Live scheduling |
| 15 | Replace TODO in `settings_page.dart:77` with interval picker | #13 | User config |

---

## G. Anti-Patterns to Avoid

| Anti-Pattern | Where Found | Notification System Prevention |
|-------------|-------------|-------------------------------|
| Dispatch in `build()` | `home_page.dart:79`, `profile_page.dart:53` | `NotificationCubit.scheduleFromJadwal()` called from `BlocListener<JadwalBloc>`, never from `build()` |
| Bloc created in `build()` | `home_page.dart` creates `HomeBloc` in `build` | `NotificationCubit` created in `BlocProvider.create` (which runs once, like `initState`) |
| Duplicated `_formatTime()` | 3 files | Use `intl` package's `DateFormat.Hm()` everywhere |
| Hardcoded strings | `AppStrings.settingsReminderValue = '5 menit'` | Read from Hive, display dynamically |
| Ephemeral data | All schedule data lost on restart | Hive persists all notification records |
