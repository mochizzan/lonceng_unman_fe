# Final Recommendations — Local Offline Notification System

> Decisive document. Every choice is FINAL with rationale grounded in source code.
> Inputs: audit-clarified.md, audit-filtered.md, audit-consolidated.md, verified against live codebase.

---

## A. TECHNOLOGY STACK

### A1. Notification Display & Scheduling: `flutter_local_notifications`

| Attribute | Value |
|-----------|-------|
| **Package** | `flutter_local_notifications` |
| **Version** | `^18.1.0` (latest 18.x stable, Oct 2024) |
| **Platforms** | Android + iOS (both targets) |
| **Rationale** | De facto standard — 99% of Flutter notification tutorials, largest community. Supports `zonedSchedule()` with timezone-aware triggers. Uses `AlarmManager` internally on Android (system-level, survives app kill) and `UNUserNotificationCenter` on iOS (native scheduling). |

**Why NOT `awesome_notifications`:** Heavier monolithic package bundles its own scheduling engine. Two focused packages (`flutter_local_notifications` + `workmanager`) gives finer control and smaller blast radius. The audit explicitly recommends this combo.

**Why NOT `android_alarm_manager_plus` alone:** Android-only. The app targets iOS too. Not suitable as the primary solution.

### A2. Background Re-scheduling: `workmanager`

| Attribute | Value |
|-----------|-------|
| **Package** | `workmanager` |
| **Version** | `^0.6.2` (latest 0.6.x stable) |
| **Rationale** | Handles the one case `flutter_local_notifications` alone cannot: **re-scheduling after device reboot**. `AlarmManager` alarms do not survive reboot. When the device reboots, `RECEIVE_BOOT_COMPLETED` fires, `workmanager`'s `BackgroundTaskHandler` runs, re-reads Hive, and re-registers all alarms via `zonedSchedule()`. |

**Critical constraint:** `workmanager` is NOT used for primary scheduling — its minimum periodic interval is 15 minutes, far too imprecise for class reminders. It exists solely for the reboot recovery path and as a periodic schedule refresh fallback.

### A3. Local Storage: `hive_flutter`

| Attribute | Value |
|-----------|-------|
| **Package** | `hive_flutter` |
| **Version** | `^1.0.0` (stable, includes `hive` ^2.5.0 transitively) |
| **Rationale** | Notification data is flat and simple (≤20 rows: one per class per week × 7 days). Hive stores typed objects natively with no JSON boilerplate. Synchronous after open — `box.get(id)` returns immediately, critical for time-sensitive `flutter_local_notifications` callbacks. Minimal setup for a project with no existing database. |

**Why NOT `sqflite`:** Overkill — no complex queries, no joins, no migrations expected. The notification table has at most ~20 rows. Schema management overhead is not justified.

**Why NOT `SharedPreferences` alone:** Cannot store structured `ScheduledNotification` objects without manual `jsonEncode`/`jsonDecode` boilerplate. Loses type safety. Already used for theme preference — overloading it for structured data creates confusion.

**Hive box structure:**
- Box 1: `'scheduled_notifications'` — Key: notification ID (int), Value: `ScheduledNotification` model
- Box 2: `'notification_settings'` — Key: `'reminder_interval_minutes'`, Value: `int`

### A4. Timezone Handling: `timezone`

| Attribute | Value |
|-----------|-------|
| **Package** | `timezone` |
| **Version** | `^0.10.0` (latest 0.10.x stable) |
| **Rationale** | `flutter_local_notifications`' `zonedSchedule()` requires `TZDateTime` objects. The `timezone` package provides timezone-aware scheduling that handles DST transitions correctly. Without it, notifications scheduled during DST transitions fire at the wrong wall-clock time. |

**Required initialization in `main()`:**
```dart
tz.initializeTimeZones();
tz.setLocalLocation(tz.local); // Uses device timezone
```

**Why NOT `intl` for day-name mapping:** The `intl` package's `DateFormat` can parse day names but requires locale initialization and is heavier than a simple static map. Day names are always Indonesian — a `Map<String, int>` is zero-dependency, faster, and less error-prone. `intl` is still recommended for the rest of the app (replacing the 3 duplicated `_formatTime()` functions) but the `DayNameMapper` utility does not depend on it.

### A5. State Management: Cubit (from `flutter_bloc: ^9.0.1`)

| Attribute | Value |
|-----------|-------|
| **Package** | `flutter_bloc` (already present, `^9.0.1`) |
| **Pattern** | `Cubit` (first Cubit in the codebase — all existing BLoCs are Bloc pattern) |
| **Rationale** | Notification state is simple: `enum NotificationStatus` + `List<ScheduledNotificationEntity>` + `int reminderIntervalMinutes`. No complex event chain needed. `flutter_local_notifications` callbacks happen outside BLoC lifecycle — calling `cubit.method()` is simpler than dispatching `Event`. Cubit's `emit()` is directly callable from plugin callbacks. The audit explicitly recommends Cubit for this use case. |

**Pattern conformance:** State class follows existing convention — plain final class with manual `==`/`hashCode` (no Equatable, matching `AuthBloc`/`HomeBloc` pattern). State naming: `NotificationState` (matches `AuthState`, `HomeState`).

### A6. Date Formatting: `intl`

| Attribute | Value |
|-----------|-------|
| **Package** | `intl` |
| **Version** | `^0.20.0` (latest 0.20.x stable) |
| **Rationale** | `_formatTime()` is duplicated in 3 files. `DateFormat.Hm()` replaces all three with locale-aware formatting. Also used for day-name display if needed. Low risk — widely used, stable API. |

### Summary: Packages to Add to `pubspec.yaml`

```yaml
dependencies:
  # Notification system
  flutter_local_notifications: ^18.1.0
  workmanager: ^0.6.2
  hive_flutter: ^1.0.0
  timezone: ^0.10.0
  intl: ^0.20.0

dev_dependencies:
  hive_generator: ^2.0.1    # Code generation for Hive TypeAdapters
  build_runner: ^2.4.0       # Required by hive_generator
```

---

## B. ARCHITECTURE BLUEPRINT

### B1. Feature Module Structure (Exact Files)

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
│   │   └── scheduled_notification_model.g.dart   # Generated by hive_generator
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

lib/core/errors/
└── app_errors.dart                                # Add NotificationException (existing file)
```

**Total new files: 10. Modified files: 4** (`app_errors.dart`, `app_strings.dart`, `main.dart`, `settings_page.dart`)

### B2. Layer Responsibilities

| Layer | Class | Responsibility | Does NOT |
|-------|-------|---------------|----------|
| **Domain entity** | `ScheduledNotificationEntity` | Pure data class. No framework deps. Defines what a scheduled notification IS. | Know about Hive or flutter_local_notifications |
| **Domain repository** | `NotificationRepository` (abstract) | Interface for CRUD of scheduled notifications + reminder interval. Contracts only. | Know about implementation details |
| **Domain service** | `NotificationScheduler` | Orchestrates: reads schedule data, computes which notifications to schedule/cancel, delegates to repository and platform service. | Touch UI, know about Hive or plugin internals |
| **Data model** | `ScheduledNotificationModel` | Hive-annotated version of entity. Has `TypeAdapter` for serialization. | Contain business logic |
| **Data source** | `NotificationLocalDataSource` | Raw Hive operations: `box.get()`, `box.put()`, `box.delete()`, `box.values`. | Know about scheduling logic |
| **Repository impl** | `NotificationRepositoryImpl` | Translates between domain entities and Hive models. Delegates to data source. | Compute trigger times |
| **Platform service** | `NotificationService` | Thin wrapper around `flutter_local_notifications`. Handles initialization, channel creation, `zonedSchedule()`, `cancel()`, `cancelAll()`. | Compute trigger times, persist data |
| **Cubit** | `NotificationCubit` | Exposes state to UI. Delegates to `NotificationScheduler`. | Directly call flutter_local_notifications or Hive |

### B3. Entity Design (Complete)

```dart
// lib/features/notification/domain/entities/scheduled_notification_entity.dart

/// A single scheduled local notification for a class reminder.
class ScheduledNotificationEntity {
  const ScheduledNotificationEntity({
    required this.id,
    required this.courseName,
    required this.dayOfWeek,
    required this.classTime,
    required this.reminderOffset,
    required this.room,
    this.lecturer,
    required this.isActive,
  });

  /// Unique notification ID — computed from courseName + day + hour.
  /// Used as both Hive key and flutter_local_notifications ID.
  /// Formula: `'$courseName|$dayName|$hour'.hashCode & 0x7FFFFFFF`
  final int id;

  /// Course name (e.g., "Algoritma Pemrograman").
  final String courseName;

  /// Day name in Indonesian (e.g., "Senin").
  final String dayOfWeek;

  /// The class start time — only time-of-day matters (hour, minute).
  /// The date portion is recomputed each week from dayOfWeek.
  final DateTime classTime;

  /// Minutes before classTime to fire the notification (e.g., 5, 10, 15, 30, 60).
  final int reminderOffset;

  /// Room/venue (e.g., "R.301 Gedung A").
  final String room;

  /// Lecturer name (nullable — not all classes have assigned lecturers).
  final String? lecturer;

  /// Whether this notification is enabled by the user.
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledNotificationEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courseName == other.courseName &&
          dayOfWeek == other.dayOfWeek &&
          classTime == other.classTime &&
          reminderOffset == other.reminderOffset &&
          room == other.room &&
          lecturer == other.lecturer &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        id,
        courseName,
        dayOfWeek,
        classTime,
        reminderOffset,
        room,
        lecturer,
        isActive,
      );
}
```

**Why `classTime` is a `DateTime` but only time-of-day matters:** `JadwalScheduleItem.startTime` is a `DateTime` (from `DateTime.parse(json['startTime'])`). The entity stores it as-is for compatibility, but the scheduler extracts only `hour` and `minute` when computing the trigger `DateTime` from `dayOfWeek`.

### B4. Repository Interface (Complete)

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
  /// Returns 5 (default) if not yet set.
  int getReminderInterval();

  /// Set the reminder interval in minutes.
  void setReminderInterval(int minutes);
}
```

**Why `getReminderInterval`/`setReminderInterval` are synchronous:** Hive is synchronous after open. These methods read/write a single key-value pair in the `'notification_settings'` box — no async needed. This avoids unnecessary `await` chains in the Cubit.

**Why these live in `NotificationRepository` not a separate settings repository:** The reminder interval is notification-specific state. A separate `NotificationSettingsRepository` adds a class and DI registration for one getter/one setter. The repository already owns notification-related persistence — storing the interval in a separate Hive box (different key space) is simpler and avoids cross-repository coordination.

### B5. Service Interface (Complete)

```dart
// lib/core/services/notification_service.dart

/// Thin wrapper around flutter_local_notifications plugin.
/// Handles initialization, channel creation, and alarm scheduling.
class NotificationService {
  /// Initialize the plugin, create notification channel.
  /// Must be called once at app startup, after Hive is open.
  Future<void> initialize();

  /// Schedule a notification at [scheduledDate] (timezone-aware).
  /// [id] must be non-negative and unique per notification.
  /// [scheduledDate] is a TZDateTime for timezone-correct firing.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required TZDateTime scheduledDate,
  });

  /// Cancel a single notification by ID.
  Future<void> cancel(int id);

  /// Cancel all scheduled notifications.
  Future<void> cancelAll();
}
```

**Why this is in `core/services/`, not in the feature:** `flutter_local_notifications` is a platform service, not domain logic. It mirrors `FcmService` (also in `core/services/`). The feature's `NotificationScheduler` depends on this service but does not own it.

### B6. Cubit Design (Complete)

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          notifications == other.notifications &&
          reminderIntervalMinutes == other.reminderIntervalMinutes &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        notifications,
        reminderIntervalMinutes,
        errorMessage,
      );
}
```

```dart
// lib/features/notification/presentation/cubit/notification_cubit.dart

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required NotificationScheduler scheduler,
    required NotificationRepository repository,
  })  : _scheduler = scheduler,
        _repository = repository,
        super(const NotificationState());

  final NotificationScheduler _scheduler;
  final NotificationRepository _repository;

  /// Load all scheduled notifications and current reminder interval.
  Future<void> loadNotifications() async {
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final notifications = await _repository.getAll();
      final interval = _repository.getReminderInterval();
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifications,
        reminderIntervalMinutes: interval,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Schedule notifications for all classes on the current day.
  /// Called when JadwalBloc emits JadwalLoaded.
  Future<void> scheduleFromJadwal(JadwalEntity jadwal) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      await _scheduler.scheduleForDay(jadwal);
      final notifications = await _repository.getAll();
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Toggle a specific notification on/off.
  Future<void> toggleNotification(int id) async {
    try {
      final existing = await _repository.getById(id);
      if (existing == null) return;
      final toggled = ScheduledNotificationEntity(
        id: existing.id,
        courseName: existing.courseName,
        dayOfWeek: existing.dayOfWeek,
        classTime: existing.classTime,
        reminderOffset: existing.reminderOffset,
        room: existing.room,
        lecturer: existing.lecturer,
        isActive: !existing.isActive,
      );
      await _repository.save(toggled);
      if (toggled.isActive) {
        await _scheduler.scheduleSingle(toggled);
      } else {
        await _scheduler.cancelSingle(toggled);
      }
      final notifications = await _repository.getAll();
      emit(state.copyWith(notifications: notifications));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Update reminder interval and reschedule all active notifications.
  Future<void> updateReminderInterval(int minutes) async {
    try {
      _repository.setReminderInterval(minutes);
      await _scheduler.rescheduleAllWithNewOffset(minutes);
      final notifications = await _repository.getAll();
      emit(state.copyWith(
        reminderIntervalMinutes: minutes,
        notifications: notifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    try {
      await _scheduler.cancelAll();
      emit(state.copyWith(notifications: []));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
```

**Why Cubit, not Bloc (reconfirmed from source):**
1. Zero complex event chains — `loadNotifications()`, `scheduleFromJadwal()`, `toggleNotification()` are direct methods.
2. `flutter_local_notifications` callbacks happen outside BLoC lifecycle — calling `cubit.onNotificationDelivered(id)` is simpler than dispatching `NotificationDeliveredEvent`.
3. State class follows existing convention: plain final class with manual `==`/`hashCode` (matching `AuthBloc`/`HomeBloc` pattern — see `jadwal_entity.dart:39-53`).
4. Cubit is created per-widget via `BlocProvider` (matching how `AuthBloc`, `HomeBloc`, etc. are created in pages).

### B7. DI Registration Pattern

Follows the exact pattern from `lib/core/di/di.dart` (custom `Map<Type, dynamic>` locator — NOT get_it).

```dart
// In lib/main.dart, after existing Services.register calls:

// 1. Initialize timezone (before any TZDateTime usage)
tz.initializeTimeZones();
tz.setLocalLocation(tz.local);

// 2. Open Hive boxes (async, before Services.register)
final notificationsBox = await Hive.openBox<Map>('scheduled_notifications');
final settingsBox = await Hive.openBox('notification_settings');

// 3. Register data layer
Services.register<NotificationLocalDataSource>(
  NotificationLocalDataSource(
    notificationsBox: notificationsBox,
    settingsBox: settingsBox,
  ),
);

// 4. Register repository
Services.register<NotificationRepository>(
  NotificationRepositoryImpl(
    localDataSource: Services.get<NotificationLocalDataSource>(),
  ),
);

// 5. Register platform service (flutter_local_notifications wrapper)
Services.register<NotificationService>(
  NotificationService(),
);

// 6. Initialize platform service (async — creates channel, requests permissions)
await Services.get<NotificationService>().initialize();

// 7. Register domain service (orchestrator)
Services.register<NotificationScheduler>(
  NotificationScheduler(
    repository: Services.get<NotificationRepository>(),
    notificationService: Services.get<NotificationService>(),
  ),
);

// 8. NotificationCubit is NOT registered in Services.
//    Created per-widget via BlocProvider (matching existing pattern):
//    BlocProvider(
//      create: (_) => NotificationCubit(
//        scheduler: Services.get<NotificationScheduler>(),
//        repository: Services.get<NotificationRepository>(),
//      ),
//    )
```

**Why `NotificationCubit` is NOT in `Services`:** Cubits are created per-widget-tree via `BlocProvider` (matching how `AuthBloc`, `HomeBloc`, etc. are created). `Services` holds long-lived singletons (repositories, data sources, services). Cubits are scoped to their widget subtree and disposed when the subtree is removed.

**Why Hive boxes are opened in `main()` not in `NotificationLocalDataSource`:** `Services` is sync (`register` is `void`). Hive's `openBox()` is async. Boxes must be opened before the sync `Services.register()` call.

### B8. Error Handling Integration

Add to existing `lib/core/errors/app_errors.dart`:

```dart
/// Notification scheduling/display errors.
final class NotificationException extends AppException {
  const NotificationException(
    super.message, {
    super.code = 'NOTIFICATION_ERROR',
    this.notificationId,
  });

  /// The notification ID that caused the error, if applicable.
  final int? notificationId;
}
```

**Rationale:** Fits the existing `sealed class AppException` hierarchy (see `app_errors.dart:6`). Every other feature uses this pattern (`NetworkException`, `ServerException`, etc.). The `NotificationException` carries an optional `notificationId` for debugging which specific alarm failed.

**Usage in `NotificationScheduler`:**
```dart
try {
  await _notificationService.schedule(...);
} catch (e) {
  throw NotificationException(
    'Failed to schedule notification for $courseName: $e',
    notificationId: id,
  );
}
```

**Usage in `NotificationCubit`:**
```dart
try {
  await _scheduler.scheduleForDay(jadwal);
} on NotificationException catch (e) {
  emit(state.copyWith(
    status: NotificationStatus.error,
    errorMessage: 'Gagal menjadwalkan notifikasi: ${e.message}',
  ));
}
```

---

## C. PLATFORM CONFIGURATION

### C1. Android — `android/app/src/main/AndroidManifest.xml`

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

**Add inside `<application>` tag (after existing `<meta-data>` entries, before `</application>`):**

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

**Existing config to reuse (verified in `AndroidManifest.xml:28-41`):**
- FCM channel ID: `lonceng_unman_notifications` (line 30-31)
- FCM icon: `@drawable/ic_notification` (line 35) — reuse for local notifications
- Accent color: `#FFC107` (line 40) — reuse for notification accent
- The notification feature creates a **separate channel** (`lonceng_unman_class_reminders`) to allow independent volume/mute control vs FCM push

**Notification Channel Configuration:**

```dart
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

**Why a separate channel from FCM:** The existing FCM channel handles push notifications from the server. Class reminders are local, scheduled notifications. Separate channels let the user: (1) Mute FCM push without losing class reminders, (2) Mute class reminders without losing FCM push, (3) Configure vibration/sound independently.

**Why `ScheduledNotificationBootReceiver` is critical:** Without this receiver, all `AlarmManager` alarms are lost after device reboot. The receiver receives `BOOT_COMPLETED`, initializes Hive in a background isolate, reads all `ScheduledNotificationEntity` records, recomputes trigger times using `DayNameMapper.nextOccurrence()` with today's date, and re-registers all alarms via `zonedSchedule()`.

### C2. iOS — `ios/Runner/Info.plist`

**Add inside `<dict>`:**

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

**iOS permission flow:** `flutter_local_notifications` calls `UNUserNotificationCenter.requestAuthorization()` automatically on first `initialize()` call. No manual plist entry needed for the permission itself. The user sees the system permission dialog on first notification attempt.

**iOS notification category (optional but recommended):** Register a `CLASS_REMINDER` category in `initialize()` so users can take action (e.g., "Dismiss" or "Snooze 5 min") from the notification.

### C3. Web (Optional Scope + Limitations)

| Aspect | Status |
|--------|--------|
| **Feasibility** | Web has Service Worker + Notification API — technically possible |
| **Limitation** | No `AlarmManager` equivalent. No `workmanager` support. Notifications only work when the browser tab is open OR the user has granted persistent notification permission (Chrome: "Push" only for PWA-installed apps) |
| **Recommendation** | **DO NOT implement for web in this phase.** The app's primary use case is mobile (class reminders for students). Web would require a fundamentally different architecture (Service Worker + periodic polling). |
| **Future path** | If web support is needed later, implement via `firebase_messaging` foreground-only notifications + a periodic `Timer` while the tab is open. Not the same as the mobile alarm-based system. |

---

## D. DATA FLOW

### D1. Jadwal Data → Notification Scheduling (Step by Step)

```
1. User opens JadwalPage
   → BlocProvider<JadwalBloc> created
   → JadwalFetchRequested event dispatched

2. JadwalBloc → GetJadwal → JadwalRepositoryImpl → StubJadwalRemoteDataSource
   → Returns JadwalEntity with selectedDay="Senin", scheduleItems=[...]

3. JadwalPage contains BlocListener<JadwalBloc>
   → On JadwalLoaded state:
     → Calls context.read<NotificationCubit>().scheduleFromJadwal(jadwal)

4. NotificationCubit.scheduleFromJadwal(jadwal):
   → Emits state with status=loading
   → Delegates to NotificationScheduler.scheduleForDay(jadwal)

5. NotificationScheduler.scheduleForDay(jadwal):
   → Reads current reminderInterval from NotificationRepository
   → For each JadwalScheduleItem in jadwal.scheduleItems:
     a. Extract dayName = jadwal.selectedDay ("Senin")
     b. Extract hour:minute from item.startTime
     c. Compute nextOccurrence = DayNameMapper.nextOccurrence(dayName)
        → Returns next Monday as DateTime (e.g., 2025-01-06 00:00:00)
     d. Compute triggerTime = nextOccurrence
        + TimeOfDay(hour: startTime.hour, minute: startTime.minute)
        - Duration(minutes: reminderInterval)
        → E.g., next Monday 08:00 - 5 min = next Monday 07:55
     e. Compute notificationId = _computeNotificationId(item.courseName, dayName, item.startTime.hour)
        → Deterministic hash: 'Algoritma|Senin|8'.hashCode & 0x7FFFFFFF
     f. Build ScheduledNotificationEntity with computed fields
     g. Save to Hive via NotificationRepository.save(entity)
     h. Call NotificationService.schedule(
          id: notificationId,
          title: item.courseName,
          body: '${item.room} • ${formatTime(item.startTime)}',
          scheduledDate: TZDateTime(local, triggerTime.year, triggerTime.month, triggerTime.day, triggerTime.hour, triggerTime.minute),
        )
   → Returns to Cubit
   → Cubit emits state with status=loaded, notifications=[...]

6. flutter_local_notifications → Android AlarmManager.setExactAndAllowWhileIdle()
   → System-level alarm registered
   → Fires at triggerTime even if app is killed
```

### D2. Day-Name → DateTime Conversion

```dart
// DayNameMapper.nextOccurrence("Senin", now: 2025-01-03 [Friday])

// targetWeekday = DateTime.monday = 1
// currentWeekday = DateTime.friday = 5
// daysUntil = (1 - 5) % 7 = (-4) % 7 = 3
// Result: 2025-01-03 + 3 days = 2025-01-06 (next Monday)
```

**Edge case — today IS the target day:**
```dart
// DayNameMapper.nextOccurrence("Senin", now: 2025-01-06 [Monday])
// daysUntil = (1 - 1) % 7 = 0
// Result: 2025-01-06 (today — fires today's reminder)
```

**Edge case — Sunday (weekday=7):**
```dart
// DayNameMapper.nextOccurrence("Minggu", now: 2025-01-06 [Monday])
// daysUntil = (7 - 1) % 7 = 6
// Result: 2025-01-06 + 6 days = 2025-01-12 (next Sunday)
```

### D3. Recurring Weekly Notifications → Individual Alarms

**Input:** `JadwalEntity` with `selectedDay = "Senin"` and 3 schedule items:
```
Algoritma:   startTime = 08:00, room = R.301
Basis Data:  startTime = 10:00, room = R.201
Jaringan:    startTime = 13:00, room = R.105
```

**Output:** 3 separate `zonedSchedule` calls:
```
ID: hash("Algoritma|Senin|8")  → trigger: next Monday 07:55
ID: hash("Basis Data|Senin|10") → trigger: next Monday 09:55
ID: hash("Jaringan|Senin|13")  → trigger: next Monday 12:55
```

**Why one alarm per class per week (not a single weekly alarm):** Each class has a different time. A single weekly alarm cannot represent "08:00 Senin AND 10:00 Senin AND 13:00 Rabu". Each must be a separate `zonedSchedule` call with a unique ID.

**Why `reminderOffset` is subtracted from trigger time:** The user sets "Ingatkan Sebelum Kelas: 5 menit" (remind 5 minutes before class). If class starts at 08:00, the notification fires at 07:55. The offset is configurable (5, 10, 15, 30, 60 minutes) and stored in Hive.

### D4. Notification Fires When App Is Killed

```
1. User force-closes the app
2. AlarmManager alarm fires at triggerTime (system-level, no app needed)
3. flutter_local_notifications' BroadcastReceiver receives the alarm
4. BroadcastReceiver creates notification using the persisted notification data
   (title, body, channel ID are stored in the AlarmManager's PendingIntent)
5. System notification appears in status bar
6. User taps notification → app launches
7. flutter_local_notifications' tap handler fires → routes to JadwalPage
```

**Key:** `flutter_local_notifications` stores notification content in the `AlarmManager` `PendingIntent` as an extras bundle. The app does not need to be running for the notification to display.

### D5. Notification Fires When Offline

```
1. Class reminder scheduled for Monday 07:55
2. User's phone has no internet connection on Monday morning
3. AlarmManager fires at 07:55 (local system clock — no internet needed)
4. flutter_local_notifications displays notification (all data is local)
5. Notification appears normally
```

**Key:** Local notifications are entirely local. No network connection required. The scheduling, storage, and display all happen on-device. This is the fundamental difference from FCM push notifications (which require internet).

---

## E. SETTINGS INTEGRATION

### E1. Reminder Interval: Hardcoded → Configurable

**Current state (verified in source):**
- `lib/core/constants/app_strings.dart:65`: `static const String settingsReminderValue = '5 menit';` — hardcoded display string
- `lib/features/settings/presentation/pages/settings_page.dart:77`: `// TODO: Implement reminder interval picker` — empty handler
- `lib/features/settings/presentation/widgets/settings_widgets.dart:121`: `AppStrings.settingsReminderValue` — renders hardcoded string

**Target state:**
- `settingsReminderValue` constant is **kept** as the default fallback but no longer the source of truth
- `ReminderIntervalTile` reads from `NotificationCubit.state.reminderIntervalMinutes`
- `onTap` opens a bottom sheet picker
- Selected value saves to Hive and triggers reschedule

### E2. SharedPreferences Key Naming (Hive, not SharedPreferences)

| Key | Box | Type | Default | Purpose |
|-----|-----|------|---------|---------|
| `reminder_interval_minutes` | `notification_settings` | `int` | `5` | Minutes before class to fire notification |

**Why Hive, not SharedPreferences:** The reminder interval lives alongside notification records in a Hive box. Using SharedPreferences would split notification-related state across two storage systems. Hive's synchronous API is also better for the notification system's time-critical callbacks.

### E3. Settings UI Changes Needed

**File: `lib/features/settings/presentation/widgets/settings_widgets.dart`**

Modify `ReminderIntervalTile` to accept the current interval as a parameter:

```dart
class ReminderIntervalTile extends StatelessWidget {
  const ReminderIntervalTile({super.key, required this.intervalMinutes});

  /// Current reminder interval in minutes (from NotificationCubit state).
  final int intervalMinutes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatInterval(intervalMinutes),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  String _formatInterval(int minutes) {
    if (minutes >= 60) return '${minutes ~/ 60} jam';
    return '$minutes menit';
  }
}
```

**File: `lib/features/settings/presentation/pages/settings_page.dart`**

Modify the `onTap` handler at line 76-78 to open a bottom sheet picker:

```dart
onTap: () {
  _showReminderIntervalPicker(context);
},
```

**Add `_showReminderIntervalPicker` method:**

```dart
void _showReminderIntervalPicker(BuildContext context) {
  final cubit = context.read<NotificationCubit>();
  final currentInterval = cubit.state.reminderIntervalMinutes;

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.settingsReminderLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // Options: 5, 10, 15, 30, 60 minutes
            for (final minutes in [5, 10, 15, 30, 60])
              ListTile(
                title: Text(minutes >= 60 ? '1 jam' : '$minutes menit'),
                trailing: minutes == currentInterval
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  cubit.updateReminderInterval(minutes);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      );
    },
  );
}
```

**File: `lib/core/constants/app_strings.dart`**

Add reminder interval display strings:

```dart
// ─── Reminder Intervals ──────────────────────────────
static const String reminderInterval5 = '5 menit';
static const String reminderInterval10 = '10 menit';
static const String reminderInterval15 = '15 menit';
static const String reminderInterval30 = '30 menit';
static const String reminderInterval60 = '1 jam';
```

**Keep `settingsReminderValue`** as-is for backward compatibility (it's used as the default display before Cubit loads). The Cubit state takes precedence once loaded.

---

## F. RISK REGISTER

### F1. Top 5 Risks

| # | Risk | Severity | Likelihood | Impact | Mitigation |
|---|------|----------|------------|--------|------------|
| 1 | **SCHEDULE_EXACT_ALARM denied by user on Android 12+** | HIGH | MEDIUM | Notifications scheduled but never fire — silent failure | On Android 12+ (`canScheduleExactAlarms()` returns false), show a dialog explaining why exact alarms are needed and direct user to Settings. Fall back to inexact alarms (`zonedSchedule` with `androidAllowWhileIdle: false`). |
| 2 | **POST_NOTIFICATIONS denied on Android 13+** | HIGH | LOW | Notifications scheduled but cannot display — no error shown to user | After `initialize()`, check `areNotificationsEnabled()`. If false, show a persistent banner in the notification settings section explaining that notifications are disabled. Direct user to system settings. |
| 3 | **Boot receiver fails to re-schedule** | MEDIUM | LOW | All alarms lost after reboot, user never notified | Test on physical devices (not just emulators). Use `flutter_local_notifications`' built-in `ScheduledNotificationBootReceiver` (proven, battle-tested). Log re-schedule attempts. Add a periodic `workmanager` task (every 24 hours) as a secondary safety net. |
| 4 | **Hive box corruption** | LOW | VERY LOW | Scheduled notifications lost | Hive is append-only with CRC checks. If corruption detected, catch the exception, delete the corrupted box, re-create it, and re-schedule from JadwalBloc data. The JadwalBloc data is the source of truth — Hive is a cache. |
| 5 | **Timezone DST transition breaks alarms** | LOW | LOW | Notifications fire at wrong time during DST transitions | `timezone` package + `TZDateTime.local()` handles DST correctly. The scheduler recomputes trigger times on reboot and on app launch — stale DST-adjusted times are replaced with current-correct times. |

### F2. Platform-Specific Gotchas

| Platform | Gotcha | Detail |
|----------|--------|--------|
| **Android 12+** | `SCHEDULE_EXACT_ALARM` requires user opt-in | On Android 12 (API 31+), `SCHEDULE_EXACT_ALARM` is a special permission. Users can revoke it in Settings → Apps → Special access → Alarms. The app must check `canScheduleExactAlarms()` before scheduling. |
| **Android 13+** | `POST_NOTIFICATIONS` is a runtime permission | Must be requested at runtime, not just declared in manifest. `flutter_local_notifications` handles this in `initialize()` but the user may deny it. |
| **Android** | Doze mode blocks alarms | `setExactAndAllowWhileIdle()` bypasses Doze — `flutter_local_notifications` uses this internally. No action needed. |
| **Android** | Battery optimization kills background work | Some OEMs (Xiaomi, Huawei, Samsung) aggressively kill background processes. Add app to "Battery optimization whitelist" prompt on first launch. |
| **iOS** | Background fetch is not guaranteed | iOS decides when to run background fetch. The scheduler must handle the case where a notification's trigger time has already passed by the time the background task runs. |
| **iOS** | Notification permission is one-time prompt | If user denies, the app cannot re-prompt. Must direct user to Settings. `flutter_local_notifications` provides `checkPermissions()`. |
| **Both** | Notification channel changes require re-install | On Android, notification channel properties (name, importance) cannot be changed after creation. Only new installs get updated channel config. For existing users, changes require app reinstall. |

### F3. Battery Optimization Considerations

| Concern | Approach |
|---------|----------|
| **AlarmManager wake-ups** | Each `zonedSchedule` call creates one wake-up per class per week. For a student with 5 classes/day × 5 days = 25 alarms/week. This is negligible battery impact — AlarmManager is optimized for this. |
| **WorkManager periodic task** | If used as a safety net, schedule at 24-hour intervals. One wake-up per day is within Android's battery budget. |
| **Hive reads on alarm** | `box.get(id)` is sub-millisecond. No battery concern. |
| **UI rebuilds** | Cubit state updates are lightweight (no heavy computation). `BlocProvider` scopes rebuilds to the notification-relevant widgets. |

**OEM-specific mitigation:** If the app detects it's on Xiaomi/Huawei/Samsung, show a first-launch dialog guiding the user to disable battery optimization for the app. This is a known issue for all alarm-based apps on these devices.

---

## G. IMPLEMENTATION ORDER

### G1. Dependency Graph

```
Task 1: Add packages to pubspec.yaml ──────────┐
Task 2: flutter pub get + build_runner ─────────┤
Task 3: Add Android permissions ────────────────┤
Task 4: Add iOS background modes ───────────────┤
Task 5: Create DayNameMapper utility ───────────┤
                                                ↓
Task 6: Create ScheduledNotificationEntity + Model (Hive) ──┐
Task 7: Create NotificationService (flutter_local_notifications wrapper) ──┤
Task 8: Create NotificationLocalDataSource ──────────────────────────────┤
                                                                         ↓
Task 9: Create NotificationRepository + Impl ───────────────────────────┐
Task 10: Create NotificationScheduler (domain service) ────────────────┤
Task 11: Create NotificationCubit + State ─────────────────────────────┤
                                                                       ↓
Task 12: Wire DI in main.dart ─────────────────────────────────────────┐
Task 13: Add NotificationException to app_errors.dart ─────────────────┤
Task 14: Wire NotificationCubit to JadwalBloc via BlocListener ───────┤
Task 15: Replace TODO in settings_page.dart with interval picker ─────┤
Task 16: Add reminder interval strings to AppStrings ─────────────────┘
```

### G2. Parallelizable Tasks

| Wave | Tasks | Can Run In Parallel | Reason |
|------|-------|---------------------|--------|
| **Wave 1** | Task 1 (pubspec), Task 3 (Android), Task 4 (iOS), Task 5 (DayNameMapper) | **YES** | No code dependencies. pubspec adds packages; Android/iOS are config files; DayNameMapper is a standalone utility. |
| **Wave 2** | Task 2 (pub get + build_runner), Task 6 (Entity + Model), Task 7 (NotificationService) | **YES** (Task 2 must complete before Task 6's code gen) | Task 2 is `flutter pub get`. Task 6 and 7 depend on packages from Task 1 but can be written in parallel with Task 2 running. |
| **Wave 3** | Task 8 (DataSource), Task 9 (Repository) | **YES** | DataSource depends on Model (Task 6). Repository depends on DataSource + Entity. Can write both once Wave 2 completes. |
| **Wave 4** | Task 10 (Scheduler), Task 11 (Cubit + State) | **YES** | Scheduler depends on Repository + NotificationService. Cubit depends on Scheduler. But Cubit's structure can be written first, then wired after Scheduler. |
| **Wave 5** | Task 12 (DI wiring), Task 13 (Error class), Task 14 (BlocListener wiring), Task 15 (Settings picker), Task 16 (AppStrings) | **YES** | All integration/wiring tasks. Depend on all previous waves completing. |

### G3. Sequential Dependencies (Must Run In Order)

| From | To | Why |
|------|----|-----|
| Task 1 (pubspec) | Task 2 (pub get) | Must add packages before resolving them |
| Task 6 (Model) | Task 8 (DataSource) | DataSource operates on Model types |
| Task 8 (DataSource) | Task 9 (Repository) | Repository delegates to DataSource |
| Task 7 (NotificationService) | Task 10 (Scheduler) | Scheduler calls NotificationService |
| Task 9 (Repository) | Task 10 (Scheduler) | Scheduler calls Repository |
| Task 10 (Scheduler) | Task 11 (Cubit) | Cubit delegates to Scheduler |
| Task 11 (Cubit) | Task 14 (BlocListener) | BlocListener calls Cubit methods |
| Task 11 (Cubit) | Task 15 (Settings picker) | Picker calls Cubit.updateReminderInterval() |

### G4. Task Descriptions

| # | Task | Files | Effort |
|---|------|-------|--------|
| 1 | Add packages to `pubspec.yaml` | `pubspec.yaml` | Small |
| 2 | `flutter pub get` + `dart run build_runner build` | Terminal | Small |
| 3 | Add Android permissions to manifest | `android/app/src/main/AndroidManifest.xml` | Small |
| 4 | Add iOS background modes to Info.plist | `ios/Runner/Info.plist` | Small |
| 5 | Create `DayNameMapper` utility | `lib/core/utils/day_name_mapper.dart` | Small |
| 6 | Create `ScheduledNotificationEntity` + `ScheduledNotificationModel` (Hive) | `lib/features/notification/domain/entities/scheduled_notification_entity.dart`, `lib/features/notification/data/models/scheduled_notification_model.dart` | Medium |
| 7 | Create `NotificationService` (flutter_local_notifications wrapper) | `lib/core/services/notification_service.dart` | Medium |
| 8 | Create `NotificationLocalDataSource` | `lib/features/notification/data/datasources/notification_local_data_source.dart` | Small |
| 9 | Create `NotificationRepository` interface + `NotificationRepositoryImpl` | `lib/features/notification/domain/repositories/notification_repository.dart`, `lib/features/notification/data/repositories/notification_repository_impl.dart` | Medium |
| 10 | Create `NotificationScheduler` (domain service) | `lib/features/notification/domain/services/notification_scheduler.dart` | Large |
| 11 | Create `NotificationCubit` + `NotificationState` | `lib/features/notification/presentation/cubit/notification_cubit.dart`, `lib/features/notification/presentation/cubit/notification_state.dart` | Medium |
| 12 | Wire DI in `main.dart` | `lib/main.dart` | Medium |
| 13 | Add `NotificationException` to `app_errors.dart` | `lib/core/errors/app_errors.dart` | Small |
| 14 | Wire `NotificationCubit` to `JadwalBloc` via `BlocListener` | `lib/features/jadwal/presentation/pages/jadwal_page.dart` (or appropriate page) | Medium |
| 15 | Replace TODO in `settings_page.dart` with interval picker | `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/settings/presentation/widgets/settings_widgets.dart` | Medium |
| 16 | Add reminder interval strings to `AppStrings` | `lib/core/constants/app_strings.dart` | Small |

---

## H. ANTI-PATTERNS TO AVOID

| Anti-Pattern | Where Found in Codebase | Notification System Prevention |
|-------------|------------------------|-------------------------------|
| Dispatch in `build()` | `home_page.dart:79`, `profile_page.dart:53` | `NotificationCubit.scheduleFromJadwal()` called from `BlocListener<JadwalBloc>`, never from `build()` |
| Bloc created in `build()` | `home_page.dart` creates `HomeBloc` in `build` | `NotificationCubit` created in `BlocProvider.create` (runs once, like `initState`) |
| Duplicated `_formatTime()` | 3 files (jadwal, home, hero_countdown) | Use `intl` package's `DateFormat.Hm()` everywhere |
| Hardcoded strings | `AppStrings.settingsReminderValue = '5 menit'` | Read from Hive via `NotificationCubit.state.reminderIntervalMinutes`, display dynamically |
| Ephemeral data | All schedule data lost on restart | Hive persists all notification records |

---

## I. VERIFICATION CHECKLIST

After implementation, verify these behaviors on a physical device:

| # | Behavior | How to Verify |
|---|----------|---------------|
| 1 | Notification fires 5 minutes before class | Set a class time 6 minutes from now. Wait. Notification should appear. |
| 2 | Notification fires when app is killed | Force-close the app. Wait for alarm time. Notification should appear. |
| 3 | Notification fires when offline | Enable airplane mode. Wait for alarm time. Notification should appear. |
| 4 | Reminder interval picker works | Open Settings → change from 5 to 15 minutes. Verify next notification fires 15 min before class. |
| 5 | Notifications survive reboot | Schedule notifications. Reopen device. Verify notifications are still scheduled. |
| 6 | Toggle notification on/off | In notification settings, toggle a class off. Verify it doesn't fire. Toggle back on. Verify it fires. |
| 7 | Android 13+ permission prompt | Fresh install on Android 13+. Verify POST_NOTIFICATIONS dialog appears. |
| 8 | Notification channel appears separately | In Android Settings → Apps → Notifications, verify "Pengingat Kelas" channel exists separately from FCM channel. |
| 9 | iOS permission prompt | Fresh install on iOS. Verify UNUserNotificationCenter dialog appears. |
| 10 | No duplicate notifications | Verify each class gets exactly one notification, not two. |
