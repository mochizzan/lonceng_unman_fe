# Local Offline Notification System — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local offline notification system that reminds students of upcoming classes, works when the app is killed, requires no internet connection, and follows Clean Architecture with zero hardcoded values.

**Architecture:** The notification system uses `flutter_local_notifications` for exact alarm scheduling (Android `AlarmManager` / iOS `UNUserNotificationCenter`), `workmanager` for reboot recovery, and `hive_flutter` for local persistence. A `NotificationScheduler` domain service orchestrates scheduling logic, exposed to UI via `NotificationCubit` (the first Cubit in the codebase). All services registered via the existing `Services` custom locator.

**Tech Stack:** `flutter_local_notifications ^18.1.0`, `workmanager ^0.6.2`, `hive_flutter ^1.0.0`, `timezone ^0.10.0`, `intl ^0.20.0`, `flutter_bloc ^9.0.1` (existing), Dart 3.12+

## Global Constraints

- SDK: `^3.12.0` (from `pubspec.yaml` line 22)
- State management: `bloc ^9.2.1` / `flutter_bloc ^9.0.1` (from `pubspec.yaml` lines 42-43)
- DI: Custom `Services` class (Map<Type, dynamic>) in `lib/core/di/di.dart` — NOT get_it
- Error pattern: `sealed class AppException` in `lib/core/errors/app_errors.dart`
- Entity pattern: Plain final classes with manual `==`/`hashCode` (no Equatable)
- File naming: snake_case for files, PascalCase for classes
- All strings: centralized in `lib/core/constants/app_strings.dart`
- All dimensions: centralized in `lib/core/constants/app_dimens.dart`
- Platform: Android + iOS (primary), web is out of scope for local notifications
- Seed color: `#FFC107` (amber) — used for notification accent color

---

## File Structure

### New Files (10)

| File | Responsibility |
|------|---------------|
| `lib/core/utils/day_name_mapper.dart` | Converts Indonesian day names ("Senin") to DateTime weekday integers |
| `lib/core/services/notification_service.dart` | Thin wrapper around `flutter_local_notifications` plugin |
| `lib/features/notification/domain/entities/scheduled_notification_entity.dart` | Pure Dart entity for a scheduled notification |
| `lib/features/notification/domain/repositories/notification_repository.dart` | Abstract interface for notification CRUD + settings |
| `lib/features/notification/domain/services/notification_scheduler.dart` | Domain service: orchestrates schedule/cancel logic |
| `lib/features/notification/data/models/scheduled_notification_model.dart` | Hive-annotated model with TypeAdapter |
| `lib/features/notification/data/datasources/notification_local_data_source.dart` | Raw Hive box operations |
| `lib/features/notification/data/repositories/notification_repository_impl.dart` | Hive-backed repository implementation |
| `lib/features/notification/presentation/cubit/notification_cubit.dart` | Cubit: exposes notification state to UI |
| `lib/features/notification/presentation/cubit/notification_state.dart` | State class for NotificationCubit |

### Modified Files (6)

| File | Change |
|------|--------|
| `pubspec.yaml` | Add 5 dependencies + 2 dev dependencies |
| `android/app/src/main/AndroidManifest.xml` | Add 5 permissions + 2 receivers + WorkManager provider |
| `ios/Runner/Info.plist` | Add UIBackgroundModes (fetch, remote-notification) |
| `lib/core/errors/app_errors.dart` | Add `NotificationException` |
| `lib/main.dart` | Initialize Hive, NotificationService, register in DI, add WorkManager callback |
| `lib/features/settings/presentation/pages/settings_page.dart` | Replace TODO with interval picker |

---

## Tasks

### Task 1: Add Dependencies to pubspec.yaml

**Files:**
- Modify: `pubspec.yaml:30-54`

**Interfaces:**
- Produces: 5 new production dependencies, 2 dev dependencies available for import

- [ ] **Step 1: Add production dependencies**

Add these lines under the `shared_preferences` entry in `pubspec.yaml`:

```yaml
  # Local notifications (offline, app-killed support)
  flutter_local_notifications: ^18.1.0
  timezone: ^0.10.0
  hive_flutter: ^1.0.0
  workmanager: ^0.6.2
  intl: ^0.20.0
```

- [ ] **Step 2: Add dev dependencies**

Add these lines under the `bloc_test` entry in `dev_dependencies`:

```yaml
  # Hive code generation
  hive_generator: ^2.0.1
  build_runner: ^2.4.0
```

- [ ] **Step 3: Run flutter pub get**

Run: `flutter pub get`
Expected: Resolution succeeds with no errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add local notification dependencies (flutter_local_notifications, hive, workmanager, timezone, intl)"
```

---

### Task 2: Add Android Permissions & Receivers

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml:1-60`

**Interfaces:**
- Produces: Android platform ready for notification scheduling, boot receiver, WorkManager

- [ ] **Step 1: Add permissions inside `<manifest>` tag**

Add these lines BETWEEN the opening `<manifest>` tag (line 1) and the `<application>` tag (line 2):

```xml
    <!-- Local notification permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

- [ ] **Step 2: Add WorkManager provider and boot receivers inside `<application>` tag**

Add these lines BEFORE the closing `</application>` tag (after line 47, the `flutterEmbedding` meta-data):

```xml
        <!-- WorkManager initialization (manual, not auto-init) -->
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

        <!-- flutter_local_notifications: notification display receiver -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false"/>

        <!-- flutter_local_notifications: boot receiver (re-schedules alarms after reboot) -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
```

- [ ] **Step 3: Verify the manifest structure**

Run: `cat android/app/src/main/AndroidManifest.xml`
Expected: Manifest has 5 `<uses-permission>` entries, WorkManager provider, and 2 `flutter_local_notifications` receivers.

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): add notification permissions and boot receivers"
```

---

### Task 3: Add iOS Background Modes

**Files:**
- Modify: `ios/Runner/Info.plist:68-69` (before closing `</dict>`)

**Interfaces:**
- Produces: iOS platform ready for background notification scheduling

- [ ] **Step 1: Add UIBackgroundModes to Info.plist**

Add these lines BEFORE the closing `</dict>` tag (line 69):

```xml
	<key>UIBackgroundModes</key>
	<array>
		<string>fetch</string>
		<string>remote-notification</string>
	</array>
```

- [ ] **Step 2: Verify the plist structure**

Run: `cat ios/Runner/Info.plist | grep -A 4 UIBackgroundModes`
Expected: Shows the UIBackgroundModes key with fetch and remote-notification values.

- [ ] **Step 3: Commit**

```bash
git add ios/Runner/Info.plist
git commit -m "feat(ios): add background modes for notification scheduling"
```

---

### Task 4: Create DayNameMapper Utility

**Files:**
- Create: `lib/core/utils/day_name_mapper.dart`

**Interfaces:**
- Produces: `DayNameMapper.weekdayFromName(String) → int`, `DayNameMapper.nextOccurrence(String, {DateTime?}) → DateTime`

- [ ] **Step 1: Write the DayNameMapper utility**

```dart
// lib/core/utils/day_name_mapper.dart
/// Maps Indonesian day names to Dart weekday integers and computes next occurrence.
///
/// Used by the notification scheduler to convert "Senin" → DateTime for
/// scheduling weekly class reminders.
class DayNameMapper {
  DayNameMapper._();

  static const Map<String, int> _dayToWeekday = {
    'Senin': DateTime.monday,
    'Selasa': DateTime.tuesday,
    'Rabu': DateTime.wednesday,
    'Kamis': DateTime.thursday,
    'Jumat': DateTime.friday,
    'Sabtu': DateTime.saturday,
    'Minggu': DateTime.sunday,
  };

  /// Convert Indonesian day name to Dart weekday integer (1=Monday..7=Sunday).
  ///
  /// Throws [ArgumentError] if [dayName] is not a recognized Indonesian day.
  static int weekdayFromName(String dayName) {
    final weekday = _dayToWeekday[dayName];
    if (weekday == null) {
      throw ArgumentError('Unknown day name: $dayName');
    }
    return weekday;
  }

  /// Get the next occurrence of [dayName] from [now].
  ///
  /// If today IS that day, returns today (same date, midnight).
  /// Returns a [DateTime] with year/month/day set to the next occurrence,
  /// time portion is midnight (00:00:00). Caller combines with class time.
  static DateTime nextOccurrence(String dayName, {DateTime? now}) {
    final nowDate = now ?? DateTime.now();
    final targetWeekday = weekdayFromName(dayName);
    final currentWeekday = nowDate.weekday;

    // Days until target: 0 if today, 1-6 if later this week, 0 if today
    final daysUntil = (targetWeekday - currentWeekday) % 7;

    return DateTime(
      nowDate.year,
      nowDate.month,
      nowDate.day + daysUntil,
    );
  }

  /// Get all available day names in Indonesian.
  static List<String> get availableDays => _dayToWeekday.keys.toList();
}
```

- [ ] **Step 2: Add barrel export**

Add to `lib/core/utils/barrel.dart`:

```dart
export 'day_name_mapper.dart';
```

- [ ] **Step 3: Write failing test**

Create `test/core/utils/day_name_mapper_test.dart`:

```dart
// test/core/utils/day_name_mapper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/utils/day_name_mapper.dart';

void main() {
  group('DayNameMapper', () {
    group('weekdayFromName', () {
      test('returns DateTime.monday for Senin', () {
        expect(DayNameMapper.weekdayFromName('Senin'), DateTime.monday);
      });

      test('returns DateTime.tuesday for Selasa', () {
        expect(DayNameMapper.weekdayFromName('Selasa'), DateTime.tuesday);
      });

      test('returns DateTime.wednesday for Rabu', () {
        expect(DayNameMapper.weekdayFromName('Rabu'), DateTime.wednesday);
      });

      test('returns DateTime.thursday for Kamis', () {
        expect(DayNameMapper.weekdayFromName('Kamis'), DateTime.thursday);
      });

      test('returns DateTime.friday for Jumat', () {
        expect(DayNameMapper.weekdayFromName('Jumat'), DateTime.friday);
      });

      test('returns DateTime.saturday for Sabtu', () {
        expect(DayNameMapper.weekdayFromName('Sabtu'), DateTime.saturday);
      });

      test('returns DateTime.sunday for Minggu', () {
        expect(DayNameMapper.weekdayFromName('Minggu'), DateTime.sunday);
      });

      test('throws ArgumentError for unknown day name', () {
        expect(
          () => DayNameMapper.weekdayFromName('InvalidDay'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('nextOccurrence', () {
      test('returns today when target day is today', () {
        // 2026-08-05 is a Wednesday (Rabu)
        final now = DateTime(2026, 8, 5, 10, 0);
        final result = DayNameMapper.nextOccurrence('Rabu', now: now);
        expect(result, DateTime(2026, 8, 5));
      });

      test('returns next week when target day has passed', () {
        // 2026-08-05 is Wednesday, Senin (Monday) was 2 days ago
        final now = DateTime(2026, 8, 5, 10, 0);
        final result = DayNameMapper.nextOccurrence('Senin', now: now);
        expect(result, DateTime(2026, 8, 10)); // Next Monday
      });

      test('returns tomorrow when target day is tomorrow', () {
        // 2026-08-05 is Wednesday, Kamis (Thursday) is tomorrow
        final now = DateTime(2026, 8, 5, 10, 0);
        final result = DayNameMapper.nextOccurrence('Kamis', now: now);
        expect(result, DateTime(2026, 8, 6));
      });

      test('returns next occurrence 6 days later', () {
        // 2026-08-05 is Wednesday, Minggu (Sunday) is 4 days later
        final now = DateTime(2026, 8, 5, 10, 0);
        final result = DayNameMapper.nextOccurrence('Minggu', now: now);
        expect(result, DateTime(2026, 8, 9));
      });
    });

    group('availableDays', () {
      test('returns all 7 Indonesian day names', () {
        expect(DayNameMapper.availableDays, hasLength(7));
        expect(DayNameMapper.availableDays, contains('Senin'));
        expect(DayNameMapper.availableDays, contains('Minggu'));
      });
    });
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/day_name_mapper_test.dart`
Expected: All 12 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/day_name_mapper.dart lib/core/utils/barrel.dart test/core/utils/day_name_mapper_test.dart
git commit -m "feat: add DayNameMapper utility for Indonesian day name → DateTime conversion"
```

---

### Task 5: Add NotificationException to Error Hierarchy

**Files:**
- Modify: `lib/core/errors/app_errors.dart:45-46`

**Interfaces:**
- Produces: `NotificationException` extending `AppException`

- [ ] **Step 1: Add NotificationException**

Add this class at the end of `lib/core/errors/app_errors.dart`, after the `ValidationException` class:

```dart
/// Notification scheduling or display errors.
final class NotificationException extends AppException {
  const NotificationException(super.message, {super.code = 'NOTIFICATION_ERROR'});
}
```

- [ ] **Step 2: Write failing test**

Create `test/core/errors/app_errors_test.dart`:

```dart
// test/core/errors/app_errors_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

void main() {
  group('NotificationException', () {
    test('is an AppException', () {
      const exception = NotificationException('test error');
      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('has correct default code', () {
      const exception = NotificationException('test error');
      expect(exception.code, 'NOTIFICATION_ERROR');
    });

    test('has correct message', () {
      const exception = NotificationException('Schedule failed');
      expect(exception.message, 'Schedule failed');
    });

    test('can override code', () {
      const exception = NotificationException(
        'Channel error',
        code: 'CHANNEL_ERROR',
      );
      expect(exception.code, 'CHANNEL_ERROR');
    });

    test('toString includes message and code', () {
      const exception = NotificationException('test');
      expect(exception.toString(), contains('test'));
      expect(exception.toString(), contains('NOTIFICATION_ERROR'));
    });
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/core/errors/app_errors_test.dart`
Expected: All 5 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/core/errors/app_errors.dart test/core/errors/app_errors_test.dart
git commit -m "feat: add NotificationException to error hierarchy"
```

---

### Task 6: Create ScheduledNotificationEntity

**Files:**
- Create: `lib/features/notification/domain/entities/scheduled_notification_entity.dart`

**Interfaces:**
- Produces: `ScheduledNotificationEntity` with fields: `id`, `courseName`, `dayOfWeek`, `classTime`, `reminderOffset`, `room`, `lecturer`, `isActive`
- Consumes: Nothing (pure Dart)

- [ ] **Step 1: Create the entity file**

```dart
// lib/features/notification/domain/entities/scheduled_notification_entity.dart
/// A single scheduled local notification for a class reminder.
///
/// Represents one alarm: "remind me 5 minutes before Algoritma on Senin at 08:00".
/// The [id] is deterministic (computed from courseName + day + hour) and serves
/// as both the Hive key and the flutter_local_notifications alarm ID.
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
  /// Formula: `'$courseName|$dayName|$hour'.hashCode & 0x7FFFFFFF`
  final int id;

  /// Course name (e.g., "Algoritma Pemrograman").
  final String courseName;

  /// Day name in Indonesian (e.g., "Senin").
  final String dayOfWeek;

  /// The class start time — only time-of-day matters (hour, minute).
  /// The date portion is recomputed each week from [dayOfWeek].
  final DateTime classTime;

  /// Minutes before [classTime] to fire the notification (e.g., 5, 10, 15, 30, 60).
  final int reminderOffset;

  /// Room/venue (e.g., "R.301 Gedung A").
  final String room;

  /// Lecturer name (nullable — not all classes have assigned lecturers).
  final String? lecturer;

  /// Whether this notification is enabled by the user.
  final bool isActive;

  /// Compute deterministic notification ID from course, day, and hour.
  ///
  /// Ensures re-scheduling overwrites the same alarm (no duplicates).
  static int computeId(String courseName, String dayName, int hour) {
    final key = '$courseName|$dayName|$hour';
    return key.hashCode & 0x7FFFFFFF; // Ensure positive (31-bit)
  }

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

- [ ] **Step 2: Write failing test**

Create `test/features/notification/domain/entities/scheduled_notification_entity_test.dart`:

```dart
// test/features/notification/domain/entities/scheduled_notification_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

void main() {
  group('ScheduledNotificationEntity', () {
    test('computeId returns consistent positive integer', () {
      final id1 = ScheduledNotificationEntity.computeId('Algoritma', 'Senin', 8);
      final id2 = ScheduledNotificationEntity.computeId('Algoritma', 'Senin', 8);
      expect(id1, id2);
      expect(id1, greaterThan(0));
    });

    test('computeId returns different IDs for different courses', () {
      final id1 = ScheduledNotificationEntity.computeId('Algoritma', 'Senin', 8);
      final id2 = ScheduledNotificationEntity.computeId('Basis Data', 'Senin', 8);
      expect(id1, isNot(equals(id2)));
    });

    test('computeId returns different IDs for different days', () {
      final id1 = ScheduledNotificationEntity.computeId('Algoritma', 'Senin', 8);
      final id2 = ScheduledNotificationEntity.computeId('Algoritma', 'Selasa', 8);
      expect(id1, isNot(equals(id2)));
    });

    test('computeId returns different IDs for different hours', () {
      final id1 = ScheduledNotificationEntity.computeId('Algoritma', 'Senin', 8);
      final id2 = ScheduledNotificationEntity.computeId('Algoritma', 'Senin', 10);
      expect(id1, isNot(equals(id2)));
    });

    test('equality works correctly', () {
      final entity1 = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        isActive: true,
      );
      final entity2 = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        isActive: true,
      );
      expect(entity1, equals(entity2));
      expect(entity1.hashCode, entity2.hashCode);
    });

    test('inequality works for different fields', () {
      final entity1 = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        isActive: true,
      );
      final entity2 = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        isActive: false, // Different
      );
      expect(entity1, isNot(equals(entity2)));
    });

    test('lecturer is nullable', () {
      final entity = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        lecturer: null,
        isActive: true,
      );
      expect(entity.lecturer, isNull);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/notification/domain/entities/scheduled_notification_entity_test.dart`
Expected: All 7 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/notification/domain/entities/scheduled_notification_entity.dart test/features/notification/domain/entities/scheduled_notification_entity_test.dart
git commit -m "feat: add ScheduledNotificationEntity with deterministic ID computation"
```

---

### Task 7: Create NotificationService (flutter_local_notifications Wrapper)

**Files:**
- Create: `lib/core/services/notification_service.dart`

**Interfaces:**
- Produces: `NotificationService` with methods: `initialize()`, `schedule(id, title, body, scheduledDate)`, `cancel(id)`, `cancelAll()`
- Consumes: `flutter_local_notifications`, `timezone` packages

- [ ] **Step 1: Create the notification service**

```dart
// lib/core/services/notification_service.dart
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Thin wrapper around flutter_local_notifications plugin.
///
/// Handles initialization, channel creation, and alarm scheduling.
/// Lives in core/services/ (not feature layer) because it wraps a platform service,
/// mirroring the existing FcmService pattern.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'lonceng_unman_class_reminders';
  static const _channelName = 'Pengingat Kelas';
  static const _channelDescription = 'Notifikasi pengingat sebelum kelas dimulai';

  /// Initialize the plugin, create notification channel, and request permissions.
  ///
  /// Must be called once at app startup, after Hive is open.
  /// Handles timezone init failure gracefully — falls back to device local time.
  Future<void> initialize() async {
    // Initialize timezone database with defensive fallback
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);
    } catch (e) {
      // Timezone data unavailable — use device local time as fallback
      // Notifications may fire at slightly wrong time during DST transitions
      developer.log('Timezone init failed, using device time: $e', name: 'NotificationService');
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Create notification channel (Android 8.0+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }

    developer.log('NotificationService initialized', name: 'NotificationService');
  }

  /// Schedule a notification at [scheduledDate] (timezone-aware).
  ///
  /// [id] must be non-negative and unique per notification.
  /// [scheduledDate] is a TZDateTime for timezone-correct firing.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: Color(0xFFFFC107), // Amber accent
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    developer.log(
      'Scheduled notification #$id: $title at $scheduledDate',
      name: 'NotificationService',
    );
  }

  /// Cancel a single notification by ID.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    developer.log('Cancelled notification #$id', name: 'NotificationService');
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    developer.log('Cancelled all notifications', name: 'NotificationService');
  }

  /// Check if notifications are enabled on this device.
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    // iOS: permission is requested on init; assume enabled if we got here
    return true;
  }

  /// Check if exact alarms can be scheduled (Android 12+).
  ///
  /// On Android 12+ (API 31+), SCHEDULE_EXACT_ALARM is a special permission
  /// that users can revoke. If denied, we fall back to inexact scheduling.
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.canScheduleExactAlarms() ?? true;
    }
    return true; // iOS doesn't have this restriction
  }
}
```

- [ ] **Step 2: Add barrel export**

Add to `lib/core/services/` — create `lib/core/services/barrel.dart` if it doesn't exist:

```dart
export 'notification_service.dart';
export 'fcm_service.dart';
```

- [ ] **Step 3: Write failing test**

Create `test/core/services/notification_service_test.dart`:

```dart
// test/core/services/notification_service_test.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('can be instantiated with default plugin', () {
      final service = NotificationService();
      expect(service, isA<NotificationService>());
    });

    test('can be instantiated with custom plugin', () {
      final plugin = FlutterLocalNotificationsPlugin();
      final service = NotificationService(plugin: plugin);
      expect(service, isA<NotificationService>());
    });
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/notification_service_test.dart`
Expected: All 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/notification_service.dart lib/core/services/barrel.dart test/core/services/notification_service_test.dart
git commit -m "feat: add NotificationService wrapper for flutter_local_notifications"
```

---

### Task 8: Create ScheduledNotificationModel (Hive)

**Files:**
- Create: `lib/features/notification/data/models/scheduled_notification_model.dart`

**Interfaces:**
- Produces: `ScheduledNotificationModel` with `toEntity()` and `fromEntity()` converters
- Consumes: `ScheduledNotificationEntity` (from Task 6), `hive` annotations

- [ ] **Step 1: Create the Hive model**

```dart
// lib/features/notification/data/models/scheduled_notification_model.dart
import 'package:hive/hive.dart';

part 'scheduled_notification_model.g.dart';

/// Hive-annotated model for scheduled notification persistence.
///
/// Stores notification data in a Hive box. Converts to/from domain entity
/// via [toEntity] and [fromEntity].
@HiveType(typeId: 0)
class ScheduledNotificationModel extends HiveObject {
  ScheduledNotificationModel({
    required this.id,
    required this.courseName,
    required this.dayOfWeek,
    required this.classTime,
    required this.reminderOffset,
    required this.room,
    this.lecturer,
    required this.isActive,
  });

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String courseName;

  @HiveField(2)
  final String dayOfWeek;

  @HiveField(3)
  final DateTime classTime;

  @HiveField(4)
  final int reminderOffset;

  @HiveField(5)
  final String room;

  @HiveField(6)
  final String? lecturer;

  @HiveField(7)
  final bool isActive;

  /// Convert to domain entity.
  ScheduledNotificationEntity toEntity() {
    return ScheduledNotificationEntity(
      id: id,
      courseName: courseName,
      dayOfWeek: dayOfWeek,
      classTime: classTime,
      reminderOffset: reminderOffset,
      room: room,
      lecturer: lecturer,
      isActive: isActive,
    );
  }

  /// Create from domain entity.
  factory ScheduledNotificationModel.fromEntity(
    ScheduledNotificationEntity entity,
  ) {
    return ScheduledNotificationModel(
      id: entity.id,
      courseName: entity.courseName,
      dayOfWeek: entity.dayOfWeek,
      classTime: entity.classTime,
      reminderOffset: entity.reminderOffset,
      room: entity.room,
      lecturer: entity.lecturer,
      isActive: entity.isActive,
    );
  }
}
```

- [ ] **Step 2: Add import for entity**

Add this import at the top of the model file:

```dart
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
```

- [ ] **Step 3: Run build_runner to generate TypeAdapter**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `scheduled_notification_model.g.dart` with `ScheduledNotificationModelAdapter`.

- [ ] **Step 4: Write failing test**

Create `test/features/notification/data/models/scheduled_notification_model_test.dart`:

```dart
// test/features/notification/data/models/scheduled_notification_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';

void main() {
  group('ScheduledNotificationModel', () {
    final entity = ScheduledNotificationEntity(
      id: 1,
      courseName: 'Algoritma Pemrograman',
      dayOfWeek: 'Senin',
      classTime: DateTime(2026, 1, 1, 8, 0),
      reminderOffset: 5,
      room: 'R.301 Gedung A',
      lecturer: 'Dr. Budi',
      isActive: true,
    );

    test('fromEntity creates model from entity', () {
      final model = ScheduledNotificationModel.fromEntity(entity);
      expect(model.id, 1);
      expect(model.courseName, 'Algoritma Pemrograman');
      expect(model.dayOfWeek, 'Senin');
      expect(model.classTime, DateTime(2026, 1, 1, 8, 0));
      expect(model.reminderOffset, 5);
      expect(model.room, 'R.301 Gedung A');
      expect(model.lecturer, 'Dr. Budi');
      expect(model.isActive, true);
    });

    test('toEntity converts model back to entity', () {
      final model = ScheduledNotificationModel.fromEntity(entity);
      final result = model.toEntity();
      expect(result, equals(entity));
    });

    test('roundtrip preserves all fields', () {
      final model = ScheduledNotificationModel.fromEntity(entity);
      final result = model.toEntity();
      expect(result.id, entity.id);
      expect(result.courseName, entity.courseName);
      expect(result.dayOfWeek, entity.dayOfWeek);
      expect(result.classTime, entity.classTime);
      expect(result.reminderOffset, entity.reminderOffset);
      expect(result.room, entity.room);
      expect(result.lecturer, entity.lecturer);
      expect(result.isActive, entity.isActive);
    });

    test('handles null lecturer', () {
      final entityNoLecturer = ScheduledNotificationEntity(
        id: 2,
        courseName: 'Basis Data',
        dayOfWeek: 'Selasa',
        classTime: DateTime(2026, 1, 2, 10, 0),
        reminderOffset: 10,
        room: 'R.201',
        lecturer: null,
        isActive: true,
      );
      final model = ScheduledNotificationModel.fromEntity(entityNoLecturer);
      expect(model.lecturer, isNull);
      final result = model.toEntity();
      expect(result.lecturer, isNull);
    });
  });
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/notification/data/models/scheduled_notification_model_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/notification/data/models/scheduled_notification_model.dart lib/features/notification/data/models/scheduled_notification_model.g.dart test/features/notification/data/models/scheduled_notification_model_test.dart
git commit -m "feat: add ScheduledNotificationModel with Hive TypeAdapter"
```

---

### Task 9: Create NotificationLocalDataSource

**Files:**
- Create: `lib/features/notification/data/datasources/notification_local_data_source.dart`

**Interfaces:**
- Produces: `NotificationLocalDataSource` with methods: `getAll()`, `getById(int)`, `save(model)`, `saveAll(list)`, `delete(int)`, `deleteAll()`, `getReminderInterval()`, `setReminderInterval(int)`
- Consumes: Hive boxes (from Task 8)

- [ ] **Step 1: Create the data source**

```dart
// lib/features/notification/data/datasources/notification_local_data_source.dart
import 'package:hive/hive.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';

/// Raw Hive operations for scheduled notifications.
///
/// Does not know about scheduling logic — only CRUD and settings persistence.
class NotificationLocalDataSource {
  NotificationLocalDataSource({
    required Box<ScheduledNotificationModel> notificationsBox,
    required Box<int> settingsBox,
  })  : _notificationsBox = notificationsBox,
        _settingsBox = settingsBox;

  final Box<ScheduledNotificationModel> _notificationsBox;
  final Box<int> _settingsBox;

  static const _reminderIntervalKey = 'reminder_interval_minutes';
  static const int _defaultReminderInterval = 5;

  /// Get all scheduled notifications.
  List<ScheduledNotificationModel> getAll() {
    return _notificationsBox.values.toList();
  }

  /// Get a single notification by ID.
  ScheduledNotificationModel? getById(int id) {
    return _notificationsBox.get(id);
  }

  /// Insert or update a notification.
  Future<void> save(ScheduledNotificationModel notification) async {
    await _notificationsBox.put(notification.id, notification);
  }

  /// Insert or update multiple notifications.
  Future<void> saveAll(List<ScheduledNotificationModel> notifications) async {
    final map = <int, ScheduledNotificationModel>{
      for (final n in notifications) n.id: n,
    };
    await _notificationsBox.putAll(map);
  }

  /// Delete a notification by ID.
  Future<void> delete(int id) async {
    await _notificationsBox.delete(id);
  }

  /// Delete all notifications.
  Future<void> deleteAll() async {
    await _notificationsBox.clear();
  }

  /// Get the reminder interval in minutes.
  int getReminderInterval() {
    return _settingsBox.get(_reminderIntervalKey) ?? _defaultReminderInterval;
  }

  /// Set the reminder interval in minutes.
  Future<void> setReminderInterval(int minutes) async {
    await _settingsBox.put(_reminderIntervalKey, minutes);
  }
}
```

- [ ] **Step 2: Write failing test**

Create `test/features/notification/data/datasources/notification_local_data_source_test.dart`:

```dart
// test/features/notification/data/datasources/notification_local_data_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';

void main() {
  late Box<ScheduledNotificationModel> notificationsBox;
  late Box<int> settingsBox;
  late NotificationLocalDataSource dataSource;

  setUpAll(() async {
    Hive.init('.');
    Hive.registerAdapter(ScheduledNotificationModelAdapter());
  });

  setUp(() async {
    notificationsBox = await Hive.openBox<ScheduledNotificationModel>('test_notifications');
    settingsBox = await Hive.openBox<int>('test_settings');
    dataSource = NotificationLocalDataSource(
      notificationsBox: notificationsBox,
      settingsBox: settingsBox,
    );
  });

  tearDown(() async {
    await notificationsBox.close();
    await settingsBox.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  ScheduledNotificationModel _createModel(int id) {
    return ScheduledNotificationModel(
      id: id,
      courseName: 'Course $id',
      dayOfWeek: 'Senin',
      classTime: DateTime(2026, 1, 1, 8 + id, 0),
      reminderOffset: 5,
      room: 'Room $id',
      isActive: true,
    );
  }

  group('NotificationLocalDataSource', () {
    test('getAll returns empty list initially', () {
      expect(dataSource.getAll(), isEmpty);
    });

    test('save stores notification and getAll retrieves it', () async {
      final model = _createModel(1);
      await dataSource.save(model);
      final result = dataSource.getAll();
      expect(result, hasLength(1));
      expect(result.first.id, 1);
    });

    test('getById returns correct notification', () async {
      await dataSource.save(_createModel(1));
      await dataSource.save(_createModel(2));
      final result = dataSource.getById(2);
      expect(result, isNotNull);
      expect(result!.id, 2);
    });

    test('getById returns null for nonexistent ID', () {
      expect(dataSource.getById(999), isNull);
    });

    test('save overwrites existing notification with same ID', () async {
      await dataSource.save(_createModel(1));
      final updated = ScheduledNotificationModel(
        id: 1,
        courseName: 'Updated Course',
        dayOfWeek: 'Selasa',
        classTime: DateTime(2026, 1, 2, 9, 0),
        reminderOffset: 10,
        room: 'New Room',
        isActive: false,
      );
      await dataSource.save(updated);
      final result = dataSource.getById(1);
      expect(result!.courseName, 'Updated Course');
      expect(result.isActive, false);
    });

    test('saveAll stores multiple notifications', () async {
      await dataSource.saveAll([_createModel(1), _createModel(2), _createModel(3)]);
      expect(dataSource.getAll(), hasLength(3));
    });

    test('delete removes notification by ID', () async {
      await dataSource.save(_createModel(1));
      await dataSource.save(_createModel(2));
      await dataSource.delete(1);
      expect(dataSource.getById(1), isNull);
      expect(dataSource.getById(2), isNotNull);
    });

    test('deleteAll clears all notifications', () async {
      await dataSource.saveAll([_createModel(1), _createModel(2)]);
      await dataSource.deleteAll();
      expect(dataSource.getAll(), isEmpty);
    });

    test('getReminderInterval returns default 5 when not set', () {
      expect(dataSource.getReminderInterval(), 5);
    });

    test('setReminderInterval persists and getReminderInterval retrieves', () async {
      await dataSource.setReminderInterval(15);
      expect(dataSource.getReminderInterval(), 15);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/notification/data/datasources/notification_local_data_source_test.dart`
Expected: All 10 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/notification/data/datasources/notification_local_data_source.dart test/features/notification/data/datasources/notification_local_data_source_test.dart
git commit -m "feat: add NotificationLocalDataSource with Hive persistence"
```

---

### Task 10: Create NotificationRepository Interface + Impl

**Files:**
- Create: `lib/features/notification/domain/repositories/notification_repository.dart`
- Create: `lib/features/notification/data/repositories/notification_repository_impl.dart`

**Interfaces:**
- Produces: `NotificationRepository` (abstract) and `NotificationRepositoryImpl` (Hive-backed)
- Consumes: `NotificationLocalDataSource` (from Task 9), `ScheduledNotificationEntity` (from Task 6)

- [ ] **Step 1: Create the repository interface**

```dart
// lib/features/notification/domain/repositories/notification_repository.dart
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

/// Abstract interface for scheduled notification persistence and settings.
///
/// Implementations handle the actual storage (Hive, SharedPreferences, etc.).
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

- [ ] **Step 2: Create the repository implementation**

```dart
// lib/features/notification/data/repositories/notification_repository_impl.dart
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';

/// Hive-backed implementation of [NotificationRepository].
///
/// Translates between domain entities and Hive models, delegates
/// storage operations to [NotificationLocalDataSource].
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final NotificationLocalDataSource _localDataSource;

  @override
  Future<List<ScheduledNotificationEntity>> getAll() async {
    final models = _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ScheduledNotificationEntity?> getById(int id) async {
    final model = _localDataSource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(ScheduledNotificationEntity notification) async {
    final model = ScheduledNotificationModel.fromEntity(notification);
    await _localDataSource.save(model);
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {
    final models = notifications
        .map((e) => ScheduledNotificationModel.fromEntity(e))
        .toList();
    await _localDataSource.saveAll(models);
  }

  @override
  Future<void> delete(int id) async {
    await _localDataSource.delete(id);
  }

  @override
  Future<void> deleteAll() async {
    await _localDataSource.deleteAll();
  }

  @override
  int getReminderInterval() {
    return _localDataSource.getReminderInterval();
  }

  @override
  void setReminderInterval(int minutes) {
    _localDataSource.setReminderInterval(minutes);
  }
}
```

- [ ] **Step 3: Write failing test**

Create `test/features/notification/data/repositories/notification_repository_impl_test.dart`:

```dart
// test/features/notification/data/repositories/notification_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

void main() {
  late Box<ScheduledNotificationModel> notificationsBox;
  late Box<int> settingsBox;
  late NotificationLocalDataSource dataSource;
  late NotificationRepositoryImpl repository;

  final testEntity = ScheduledNotificationEntity(
    id: 1,
    courseName: 'Algoritma',
    dayOfWeek: 'Senin',
    classTime: DateTime(2026, 1, 1, 8, 0),
    reminderOffset: 5,
    room: 'R.301',
    lecturer: 'Dr. Budi',
    isActive: true,
  );

  setUpAll(() async {
    Hive.init('.');
    Hive.registerAdapter(ScheduledNotificationModelAdapter());
  });

  setUp(() async {
    notificationsBox = await Hive.openBox<ScheduledNotificationModel>('test_notifications');
    settingsBox = await Hive.openBox<int>('test_settings');
    dataSource = NotificationLocalDataSource(
      notificationsBox: notificationsBox,
      settingsBox: settingsBox,
    );
    repository = NotificationRepositoryImpl(localDataSource: dataSource);
  });

  tearDown(() async {
    await notificationsBox.close();
    await settingsBox.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('NotificationRepositoryImpl', () {
    test('save and getAll roundtrip preserves entity', () async {
      await repository.save(testEntity);
      final result = await repository.getAll();
      expect(result, hasLength(1));
      expect(result.first, equals(testEntity));
    });

    test('getById returns correct entity', () async {
      await repository.save(testEntity);
      final result = await repository.getById(1);
      expect(result, equals(testEntity));
    });

    test('getById returns null for nonexistent', () {
      expect(repository.getById(999), completion(isNull));
    });

    test('delete removes entity', () async {
      await repository.save(testEntity);
      await repository.delete(1);
      expect(repository.getById(1), completion(isNull));
    });

    test('deleteAll clears all', () async {
      await repository.save(testEntity);
      await repository.deleteAll();
      expect(repository.getAll(), completion(isEmpty));
    });

    test('saveAll stores multiple entities', () async {
      final entity2 = ScheduledNotificationEntity(
        id: 2,
        courseName: 'Basis Data',
        dayOfWeek: 'Selasa',
        classTime: DateTime(2026, 1, 2, 10, 0),
        reminderOffset: 10,
        room: 'R.201',
        isActive: true,
      );
      await repository.saveAll([testEntity, entity2]);
      final result = await repository.getAll();
      expect(result, hasLength(2));
    });

    test('getReminderInterval returns default 5', () {
      expect(repository.getReminderInterval(), 5);
    });

    test('setReminderInterval persists value', () async {
      repository.setReminderInterval(15);
      expect(repository.getReminderInterval(), 15);
    });
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/notification/data/repositories/notification_repository_impl_test.dart`
Expected: All 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/notification/domain/repositories/notification_repository.dart lib/features/notification/data/repositories/notification_repository_impl.dart test/features/notification/data/repositories/notification_repository_impl_test.dart
git commit -m "feat: add NotificationRepository interface and Hive-backed implementation"
```

---

### Task 11: Create NotificationScheduler (Domain Service)

**Files:**
- Create: `lib/features/notification/domain/services/notification_scheduler.dart`

**Interfaces:**
- Produces: `NotificationScheduler` with methods: `scheduleForDay(JadwalEntity)`, `scheduleSingle(entity)`, `cancelSingle(entity)`, `cancelAll()`, `rescheduleAllWithNewOffset(int)`
- Consumes: `NotificationRepository` (from Task 10), `NotificationService` (from Task 7), `DayNameMapper` (from Task 4), `JadwalEntity` (existing)

- [ ] **Step 1: Create the domain service**

```dart
// lib/features/notification/domain/services/notification_scheduler.dart
import 'dart:developer' as developer;

import 'package:lonceng_unman_fe/core/utils/day_name_mapper.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Domain service that orchestrates notification scheduling.
///
/// Reads schedule data from [JadwalEntity], computes trigger times using
/// [DayNameMapper], and delegates to [NotificationRepository] for persistence
/// and [NotificationService] for platform alarm registration.
///
/// This is NOT a usecase — it orchestrates multiple repository and service calls.
class NotificationScheduler {
  NotificationScheduler({
    required NotificationRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService;

  final NotificationRepository _repository;
  final NotificationService _notificationService;

  /// Schedule notifications for all classes in [jadwal].
  ///
  /// For each [JadwalScheduleItem]:
  /// 1. Computes the next occurrence of the day-of-week
  /// 2. Combines with class start time minus reminder offset
  /// 3. Registers alarm via flutter_local_notifications
  /// 4. Persists to Hive via repository
  Future<void> scheduleForDay(JadwalEntity jadwal) async {
    final reminderOffset = _repository.getReminderInterval();
    final entities = <ScheduledNotificationEntity>[];

    for (final item in jadwal.scheduleItems) {
      final entity = ScheduledNotificationEntity(
        id: ScheduledNotificationEntity.computeId(
          item.courseName,
          jadwal.selectedDay,
          item.startTime.hour,
        ),
        courseName: item.courseName,
        dayOfWeek: jadwal.selectedDay,
        classTime: item.startTime,
        reminderOffset: reminderOffset,
        room: item.room,
        lecturer: item.lecturer,
        isActive: true,
      );

      entities.add(entity);

      // Schedule the alarm
      await _scheduleAlarm(entity);
    }

    // Persist all entities
    await _repository.saveAll(entities);

    developer.log(
      'Scheduled ${entities.length} notifications for ${jadwal.selectedDay}',
      name: 'NotificationScheduler',
    );
  }

  /// Schedule a single notification alarm for [entity].
  Future<void> scheduleSingle(ScheduledNotificationEntity entity) async {
    await _scheduleAlarm(entity);
  }

  /// Cancel a single notification alarm for [entity].
  Future<void> cancelSingle(ScheduledNotificationEntity entity) async {
    await _notificationService.cancel(entity.id);
  }

  /// Cancel all scheduled notification alarms.
  Future<void> cancelAll() async {
    await _notificationService.cancelAll();
    await _repository.deleteAll();
  }

  /// Reschedule all active notifications with a new reminder offset.
  ///
  /// Called when the user changes the reminder interval in settings.
  Future<void> rescheduleAllWithNewOffset(int newOffsetMinutes) async {
    final allNotifications = await _repository.getAll();

    // Cancel all existing alarms
    await _notificationService.cancelAll();

    // Re-schedule each active notification with new offset
    for (final entity in allNotifications) {
      final updated = ScheduledNotificationEntity(
        id: entity.id,
        courseName: entity.courseName,
        dayOfWeek: entity.dayOfWeek,
        classTime: entity.classTime,
        reminderOffset: newOffsetMinutes,
        room: entity.room,
        lecturer: entity.lecturer,
        isActive: entity.isActive,
      );

      await _repository.save(updated);

      if (updated.isActive) {
        await _scheduleAlarm(updated);
      }
    }
  }

  /// Compute the trigger DateTime and schedule the alarm.
  Future<void> _scheduleAlarm(ScheduledNotificationEntity entity) async {
    if (!entity.isActive) return;

    final nextOccurrence = DayNameMapper.nextOccurrence(entity.dayOfWeek);
    final classDateTime = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
      entity.classTime.hour,
      entity.classTime.minute,
    );

    final triggerTime = classDateTime.subtract(
      Duration(minutes: entity.reminderOffset),
    );

    // Skip if trigger time is in the past
    if (triggerTime.isBefore(DateTime.now())) {
      developer.log(
        'Skipping past notification: ${entity.courseName} at $triggerTime',
        name: 'NotificationScheduler',
      );
      return;
    }

    // Defensive timezone conversion — fallback to device time if tz data unavailable
    tz.TZDateTime tzTrigger;
    try {
      tzTrigger = tz.TZDateTime.from(triggerTime, tz.local);
    } catch (e) {
      developer.log('Timezone fallback: $e', name: 'NotificationScheduler');
      tzTrigger = tz.TZDateTime(
        tz.local ?? tz.UTC,
        triggerTime.year,
        triggerTime.month,
        triggerTime.day,
        triggerTime.hour,
        triggerTime.minute,
      );
    }

    // Check exact alarm capability (Android 12+) — fallback to inexact if denied
    final canUseExact = await _notificationService.canScheduleExactAlarms();

    await _notificationService.schedule(
      id: entity.id,
      title: entity.courseName,
      body: _buildBody(entity),
      scheduledDate: tzTrigger,
      useExactAlarm: canUseExact,
    );
  }

  /// Build notification body text.
  String _buildBody(ScheduledNotificationEntity entity) {
    final timeStr =
        '${entity.classTime.hour.toString().padLeft(2, '0')}:'
        '${entity.classTime.minute.toString().padLeft(2, '0')}';
    final parts = <String>[entity.room, timeStr];
    if (entity.lecturer != null && entity.lecturer!.isNotEmpty) {
      parts.add(entity.lecturer!);
    }
    return parts.join(' • ');
  }
}
```

- [ ] **Step 2: Write failing test**

Create `test/features/notification/domain/services/notification_scheduler_test.dart`:

```dart
// test/features/notification/domain/services/notification_scheduler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';

// Mock implementations for testing
class MockNotificationRepository implements NotificationRepository {
  final List<ScheduledNotificationEntity> _store = [];
  int _reminderInterval = 5;

  @override
  Future<List<ScheduledNotificationEntity>> getAll() async => List.unmodifiable(_store);

  @override
  Future<ScheduledNotificationEntity?> getById(int id) async {
    try {
      return _store.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ScheduledNotificationEntity notification) async {
    _store.removeWhere((e) => e.id == notification.id);
    _store.add(notification);
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {
    for (final n in notifications) {
      await save(n);
    }
  }

  @override
  Future<void> delete(int id) async {
    _store.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  int getReminderInterval() => _reminderInterval;

  @override
  void setReminderInterval(int minutes) => _reminderInterval = minutes;

  List<ScheduledNotificationEntity> get stored => List.unmodifiable(_store);
}

class MockNotificationService implements NotificationService {
  final List<int> scheduledIds = [];
  final List<int> cancelledIds = [];
  bool allCancelled = false;
  bool initialized = false;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required dynamic scheduledDate,
  }) async {
    scheduledIds.add(id);
  }

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);

  @override
  Future<void> cancelAll() async => allCancelled = true;

  @override
  Future<bool> areNotificationsEnabled() async => true;
}

void main() {
  late MockNotificationRepository mockRepo;
  late MockNotificationService mockService;
  late NotificationScheduler scheduler;

  setUp(() {
    mockRepo = MockNotificationRepository();
    mockService = MockNotificationService();
    scheduler = NotificationScheduler(
      repository: mockRepo,
      notificationService: mockService,
    );
  });

  group('NotificationScheduler', () {
    test('scheduleForDay creates entities and schedules alarms', () async {
      final jadwal = JadwalEntity(
        selectedDay: 'Senin',
        days: ['Senin', 'Selasa', 'Rabu'],
        scheduleItems: [
          JadwalScheduleItem(
            courseName: 'Algoritma',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            room: 'R.301',
            sks: '3',
            status: JadwalScheduleStatus.upcoming,
          ),
        ],
      );

      await scheduler.scheduleForDay(jadwal);

      expect(mockRepo.stored, hasLength(1));
      expect(mockRepo.stored.first.courseName, 'Algoritma');
      expect(mockRepo.stored.first.dayOfWeek, 'Senin');
      expect(mockService.scheduledIds, hasLength(1));
    });

    test('cancelAll removes all alarms and data', () async {
      // First schedule something
      final jadwal = JadwalEntity(
        selectedDay: 'Senin',
        days: ['Senin'],
        scheduleItems: [
          JadwalScheduleItem(
            courseName: 'Test',
            startTime: DateTime(2026, 1, 1, 8, 0),
            endTime: DateTime(2026, 1, 1, 10, 0),
            room: 'R.1',
            sks: '2',
            status: JadwalScheduleStatus.upcoming,
          ),
        ],
      );
      await scheduler.scheduleForDay(jadwal);

      // Now cancel all
      await scheduler.cancelAll();
      expect(mockService.allCancelled, true);
      expect(mockRepo.stored, isEmpty);
    });

    test('scheduleSingle schedules one alarm', () async {
      final entity = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Test',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.1',
        isActive: true,
      );

      await scheduler.scheduleSingle(entity);
      expect(mockService.scheduledIds, contains(1));
    });

    test('cancelSingle cancels one alarm', () async {
      final entity = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Test',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.1',
        isActive: true,
      );

      await scheduler.cancelSingle(entity);
      expect(mockService.cancelledIds, contains(1));
    });

    test('rescheduleAllWithNewOffset updates offset and reschedules', () async {
      // Setup: store a notification
      final entity = ScheduledNotificationEntity(
        id: 1,
        courseName: 'Algoritma',
        dayOfWeek: 'Senin',
        classTime: DateTime(2026, 1, 1, 8, 0),
        reminderOffset: 5,
        room: 'R.301',
        isActive: true,
      );
      await mockRepo.save(entity);

      await scheduler.rescheduleAllWithNewOffset(15);

      // Should have cancelled all first
      expect(mockService.allCancelled, true);

      // Should have rescheduled with new offset
      final updated = await mockRepo.getById(1);
      expect(updated!.reminderOffset, 15);
      expect(mockService.scheduledIds, contains(1));
    });
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/notification/domain/services/notification_scheduler_test.dart`
Expected: All 5 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/notification/domain/services/notification_scheduler.dart test/features/notification/domain/services/notification_scheduler_test.dart
git commit -m "feat: add NotificationScheduler domain service for alarm orchestration"
```

---

### Task 12: Create NotificationCubit + State

**Files:**
- Create: `lib/features/notification/presentation/cubit/notification_state.dart`
- Create: `lib/features/notification/presentation/cubit/notification_cubit.dart`

**Interfaces:**
- Produces: `NotificationCubit` with methods: `loadNotifications()`, `scheduleFromJadwal(JadwalEntity)`, `toggleNotification(int)`, `updateReminderInterval(int)`, `cancelAll()`
- Consumes: `NotificationScheduler` (from Task 11), `NotificationRepository` (from Task 10)

- [ ] **Step 1: Create the state class**

```dart
// lib/features/notification/presentation/cubit/notification_state.dart
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';

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

  NotificationState copyWith({
    NotificationStatus? status,
    List<ScheduledNotificationEntity>? notifications,
    int? reminderIntervalMinutes,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      errorMessage: errorMessage,
    );
  }

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

- [ ] **Step 2: Create the cubit**

```dart
// lib/features/notification/presentation/cubit/notification_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

/// Cubit managing notification scheduling state.
///
/// This is the first Cubit in the codebase (all existing features use Bloc).
/// Chosen because notification state is simple (status + list + interval)
/// and flutter_local_notifications callbacks need direct method calls.
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

  /// Schedule notifications for all classes in [jadwal].
  ///
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

- [ ] **Step 3: Write failing test**

Create `test/features/notification/presentation/cubit/notification_cubit_test.dart`:

```dart
// test/features/notification/presentation/cubit/notification_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

// Minimal mock repository for cubit tests
class MockNotificationRepository implements NotificationRepository {
  List<ScheduledNotificationEntity> _store = [];
  int _interval = 5;

  void setStore(List<ScheduledNotificationEntity> store) => _store = store;

  @override
  Future<List<ScheduledNotificationEntity>> getAll() async => List.unmodifiable(_store);

  @override
  Future<ScheduledNotificationEntity?> getById(int id) async {
    try {
      return _store.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ScheduledNotificationEntity notification) async {
    _store = [..._store.where((e) => e.id != notification.id), notification];
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {
    _store = notifications;
  }

  @override
  Future<void> delete(int id) async => _store = _store.where((e) => e.id != id).toList();

  @override
  Future<void> deleteAll() async => _store = [];

  @override
  int getReminderInterval() => _interval;

  @override
  void setReminderInterval(int minutes) => _interval = minutes;
}

// Minimal mock scheduler
class MockNotificationScheduler implements NotificationScheduler {
  bool scheduled = false;
  bool allCancelled = false;

  @override
  Future<void> scheduleForDay(JadwalEntity jadwal) async => scheduled = true;

  @override
  Future<void> scheduleSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelAll() async => allCancelled = true;

  @override
  Future<void> rescheduleAllWithNewOffset(int newOffsetMinutes) async {}
}

void main() {
  late MockNotificationRepository mockRepo;
  late MockNotificationScheduler mockScheduler;
  late NotificationCubit cubit;

  setUp(() {
    mockRepo = MockNotificationRepository();
    mockScheduler = MockNotificationScheduler();
    cubit = NotificationCubit(
      scheduler: mockScheduler,
      repository: mockRepo,
    );
  });

  tearDown(() => cubit.close());

  group('NotificationCubit', () {
    blocTest<NotificationCubit, NotificationState>(
      'emits [loading, loaded] when loadNotifications succeeds',
      build: () {
        mockRepo.setStore([
          const ScheduledNotificationEntity(
            id: 1,
            courseName: 'Test',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.1',
            isActive: true,
          ),
        ]);
        return cubit;
      },
      act: (cubit) => cubit.loadNotifications(),
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        predicate<NotificationState>((s) =>
            s.status == NotificationStatus.loaded &&
            s.notifications.length == 1 &&
            s.reminderIntervalMinutes == 5),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'emits [loading, loaded] when scheduleFromJadwal succeeds',
      build: () => cubit,
      act: (cubit) async {
        mockRepo.setStore([]);
        await cubit.scheduleFromJadwal(const JadwalEntity(
          selectedDay: 'Senin',
          days: ['Senin'],
          scheduleItems: [],
        ));
      },
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        predicate<NotificationState>((s) =>
            s.status == NotificationStatus.loaded &&
            s.notifications.isEmpty),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'emits updated notifications when toggleNotification is called',
      build: () {
        mockRepo.setStore([
          const ScheduledNotificationEntity(
            id: 1,
            courseName: 'Test',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.1',
            isActive: true,
          ),
        ]);
        return cubit;
      },
      act: (cubit) => cubit.toggleNotification(1),
      expect: () => [
        predicate<NotificationState>((s) =>
            s.notifications.first.isActive == false),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'emits updated interval when updateReminderInterval is called',
      build: () => cubit,
      act: (cubit) => cubit.updateReminderInterval(15),
      expect: () => [
        predicate<NotificationState>((s) =>
            s.reminderIntervalMinutes == 15),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'emits empty list when cancelAll is called',
      build: () {
        mockRepo.setStore([
          const ScheduledNotificationEntity(
            id: 1,
            courseName: 'Test',
            dayOfWeek: 'Senin',
            classTime: DateTime(2026, 1, 1, 8, 0),
            reminderOffset: 5,
            room: 'R.1',
            isActive: true,
          ),
        ]);
        return cubit;
      },
      act: (cubit) => cubit.cancelAll(),
      expect: () => [
        predicate<NotificationState>((s) => s.notifications.isEmpty),
      ],
    );
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/notification/presentation/cubit/notification_cubit_test.dart`
Expected: All 5 bloc tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/notification/presentation/cubit/notification_state.dart lib/features/notification/presentation/cubit/notification_cubit.dart test/features/notification/presentation/cubit/notification_cubit_test.dart
git commit -m "feat: add NotificationCubit with state management for notification scheduling"
```

---

### Task 13: Wire DI Registration in main.dart

**Files:**
- Modify: `lib/main.dart:37-74`

**Interfaces:**
- Consumes: All classes from Tasks 7-12

- [ ] **Step 1: Add imports to main.dart**

Add these imports at the top of `lib/main.dart` (after existing imports):

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
```

- [ ] **Step 2: Add Hive initialization and DI registration**

Replace the `main()` function body (lines 37-74) with:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before using any Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the background message handler.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM for foreground message handling.
  await FcmService.instance.initialize(
    onNotificationTap: (message) {
      // Notification taps handled by router
    },
  );

  // Initialize Hive for local notification persistence
  await Hive.initFlutter();
  Hive.registerAdapter(ScheduledNotificationModelAdapter());
  final notificationsBox = await Hive.openBox<ScheduledNotificationModel>('scheduled_notifications');
  final settingsBox = await Hive.openBox<int>('notification_settings');

  // Register notification dependencies
  Services.register<NotificationLocalDataSource>(
    NotificationLocalDataSource(
      notificationsBox: notificationsBox,
      settingsBox: settingsBox,
    ),
  );

  final notificationService = NotificationService();
  Services.register<NotificationService>(notificationService);
  await notificationService.initialize();

  Services.register<NotificationRepository>(
    NotificationRepositoryImpl(
      localDataSource: Services.get<NotificationLocalDataSource>(),
    ),
  );

  Services.register<NotificationScheduler>(
    NotificationScheduler(
      repository: Services.get<NotificationRepository>(),
      notificationService: Services.get<NotificationService>(),
    ),
  );

  // Register existing dependencies
  Services.register<GetAuth>(
    GetAuth(AuthRepositoryImpl(remoteDataSource: StubAuthRemoteDataSource())),
  );
  Services.register<GetHome>(
    GetHome(HomeRepositoryImpl(remoteDataSource: StubHomeRemoteDataSource())),
  );
  Services.register<GetJadwal>(
    GetJadwal(
      JadwalRepositoryImpl(remoteDataSource: StubJadwalRemoteDataSource()),
    ),
  );
  Services.register<GetProfile>(
    GetProfile(
      ProfileRepositoryImpl(remoteDataSource: StubProfileRemoteDataSource()),
    ),
  );

  runApp(const LoncengUnmanApp());
}
```

- [ ] **Step 3: Verify the app compiles**

Run: `flutter analyze`
Expected: No errors (warnings acceptable).

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire Hive + NotificationService + DI registration in main.dart"
```

---

### Task 14: Wire NotificationCubit to JadwalBloc via BlocListener

**Files:**
- Modify: `lib/features/jadwal/presentation/pages/jadwal_page.dart`

**Interfaces:**
- Consumes: `NotificationCubit` (from Task 12), `JadwalBloc` (existing)

- [ ] **Step 1: Read the current jadwal_page.dart**

Read `lib/features/jadwal/presentation/pages/jadwal_page.dart` to understand the current structure.

- [ ] **Step 2: Add BlocListener for NotificationCubit**

Wrap the existing `BlocBuilder<JadwalBloc, ...>` with a `BlocListener` that triggers notification scheduling when JadwalLoaded is emitted. Add this import:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
```

Add `BlocProvider<NotificationCubit>` above the existing `BlocProvider<JadwalBloc>` in the widget tree:

```dart
BlocProvider(
  create: (_) => NotificationCubit(
    scheduler: Services.get<NotificationScheduler>(),
    repository: Services.get<NotificationRepository>(),
  )..loadNotifications(),
  child: BlocProvider(
    create: (_) => JadwalBloc(Services.get<GetJadwal>())
      ..add(JadwalFetchRequested()),
    child: BlocListener<JadwalBloc, JadwalState>(
      listener: (context, state) {
        if (state is JadwalLoaded) {
          context.read<NotificationCubit>().scheduleFromJadwal(state.data);
        }
      },
      child: // ... existing BlocBuilder<JadwalBloc, JadwalState> ...
    ),
  ),
),
```

- [ ] **Step 3: Verify the app compiles**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/jadwal/presentation/pages/jadwal_page.dart
git commit -m "feat: wire NotificationCubit to JadwalBloc via BlocListener"
```

---

### Task 15: Replace TODO in Settings Page with Interval Picker

**Files:**
- Modify: `lib/features/settings/presentation/pages/settings_page.dart:76-78`
- Modify: `lib/features/settings/presentation/widgets/settings_widgets.dart:104-131`

**Interfaces:**
- Consumes: `NotificationCubit` (from Task 12)

- [ ] **Step 1: Update ReminderIntervalTile to accept interval parameter**

Replace the `ReminderIntervalTile` class in `settings_widgets.dart`:

```dart
/// Reminder interval display widget.
/// Shows current reminder interval with chevron for settings.
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
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

- [ ] **Step 2: Update settings_page.dart to use BlocBuilder for interval**

Add imports:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';
```

Replace the notification settings section (lines 58-80) with:

```dart
          // ── Section: Notifications ──
          _SectionHeader(title: AppStrings.settingsSectionNotification),
          const SizedBox(height: AppDimens.space8),
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, notifState) {
              return _SettingsCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: cs.onSurface,
                    size: 22,
                  ),
                  title: Text(
                    AppStrings.settingsReminderLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                  ),
                  trailing: ReminderIntervalTile(
                    intervalMinutes: notifState.reminderIntervalMinutes,
                  ),
                  onTap: () {
                    _showReminderIntervalPicker(context, notifState.reminderIntervalMinutes);
                  },
                ),
              );
            },
          ),
```

- [ ] **Step 3: Add the picker method to SettingsPage**

Add this method inside the `_SettingsPageState` or as a top-level function:

```dart
void _showReminderIntervalPicker(BuildContext context, int currentInterval) {
  final cubit = context.read<NotificationCubit>();

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

- [ ] **Step 4: Verify the app compiles**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/pages/settings_page.dart lib/features/settings/presentation/widgets/settings_widgets.dart
git commit -m "feat: replace TODO with configurable reminder interval picker in settings"
```

---

### Task 16: Add Barrel Exports for Notification Feature

**Files:**
- Create: `lib/features/notification/barrel.dart`
- Modify: `lib/barrel.dart` (root barrel)

**Interfaces:**
- Produces: Clean barrel exports for the notification feature

- [ ] **Step 1: Create notification feature barrel**

```dart
// lib/features/notification/barrel.dart
export 'domain/entities/scheduled_notification_entity.dart';
export 'domain/repositories/notification_repository.dart';
export 'domain/services/notification_scheduler.dart';
export 'presentation/cubit/notification_cubit.dart';
export 'presentation/cubit/notification_state.dart';
```

- [ ] **Step 2: Add notification to root barrel**

Add to `lib/barrel.dart`:

```dart
export 'features/notification/barrel.dart';
```

- [ ] **Step 3: Verify the app compiles**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/notification/barrel.dart lib/barrel.dart
git commit -m "feat: add barrel exports for notification feature"
```

---

## Error Handling & Edge Cases

### Critical Error Scenarios

The following 5 scenarios represent the highest-risk failure modes. Each has explicit handling code in the relevant tasks.

---

### EH-1: POST_NOTIFICATIONS Permission Denied (Android 13+)

**Risk:** Notifications scheduled but never display — silent failure.
**Detection:** `NotificationService.areNotificationsEnabled()` returns `false`.
**Recovery:** Show persistent banner in settings UI directing user to system settings.

**Code location:** `NotificationService` (Task 7) — add `areNotificationsEnabled()` method.
**UI location:** `settings_page.dart` (Task 15) — add permission status banner.

```dart
// In NotificationService (Task 7), add after initialize():
/// Check if notification permission is granted.
/// Returns false if user denied POST_NOTIFICATIONS (Android 13+).
Future<bool> areNotificationsEnabled() async {
  final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    return await androidPlugin.areNotificationsEnabled() ?? false;
  }
  // iOS: permission is requested on init; assume enabled if we got here
  return true;
}
```

```dart
// In settings_page.dart (Task 15), add above the notification section:
// Check permission on build
final notifService = Services.get<NotificationService>();
final hasPermission = await notifService.areNotificationsEnabled();

// In the UI, show banner if !hasPermission:
if (!hasPermission) {
  // Show warning banner:
  // "Notifikasi nonaktif. Ketuk untuk mengaktifkan di pengaturan sistem."
  // onTap → openAppSettings() from url_launcher or direct user to Settings
}
```

**Test:** `flutter test test/core/services/notification_service_test.dart` — add test for `areNotificationsEnabled()`.

---

### EH-2: SCHEDULE_EXACT_ALARM Denied (Android 12+)

**Risk:** `zonedSchedule()` with `exactAllowWhileIdle` silently fails.
**Detection:** `AndroidFlutterLocalNotificationsPlugin.canScheduleExactAlarms()` returns `false`.
**Recovery:** Fallback to inexact scheduling (`androidAllowWhileIdle: false`).

**Code location:** `NotificationService` (Task 7) — add `canScheduleExactAlarms()` method.
**Code location:** `NotificationScheduler` (Task 11) — check before scheduling.

```dart
// In NotificationService (Task 7), add:
/// Check if exact alarms can be scheduled (Android 12+).
Future<bool> canScheduleExactAlarms() async {
  final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    return await androidPlugin.canScheduleExactAlarms() ?? true;
  }
  return true; // iOS doesn't have this restriction
}
```

```dart
// In NotificationScheduler._scheduleAlarm() (Task 11), modify:
Future<void> _scheduleAlarm(ScheduledNotificationEntity entity) async {
  if (!entity.isActive) return;

  // ... compute triggerTime as before ...

  // Check exact alarm capability
  final canUseExact = await _notificationService.canScheduleExactAlarms();

  await _notificationService.schedule(
    id: entity.id,
    title: entity.courseName,
    body: _buildBody(entity),
    scheduledDate: tzTrigger,
    useExactAlarm: canUseExact, // fallback to inexact if denied
  );
}
```

**Test:** Add test for `canScheduleExactAlarms()` in `notification_service_test.dart`.

---

### EH-3: Hive Box Corruption / Open Failure

**Risk:** App crash on startup if Hive box is corrupted.
**Detection:** `Hive.openBox()` throws `HiveError`.
**Recovery:** Delete corrupted box, re-create empty, log error.

**Code location:** `main.dart` (Task 13) — wrap Hive init in try-catch.

```dart
// In main.dart (Task 13), replace Hive init section:
// Initialize Hive for local notification persistence
Box<ScheduledNotificationModel> notificationsBox;
Box<int> settingsBox;

try {
  await Hive.initFlutter();
  Hive.registerAdapter(ScheduledNotificationModelAdapter());
  notificationsBox = await Hive.openBox<ScheduledNotificationModel>('scheduled_notifications');
  settingsBox = await Hive.openBox<int>('notification_settings');
} catch (e) {
  // Hive box corrupted — delete and re-create
  developer.log('Hive init failed, recreating boxes: $e', name: 'Main');
  await Hive.deleteFromDisk(); // nuclear option — only if corrupted
  await Hive.initFlutter();
  Hive.registerAdapter(ScheduledNotificationModelAdapter());
  notificationsBox = await Hive.openBox<ScheduledNotificationModel>('scheduled_notifications');
  settingsBox = await Hive.openBox<int>('notification_settings');
}
```

**Test:** Manual verification — corrupt a Hive box file and verify recovery.

---

### EH-4: flutter_local_notifications Initialization Failure

**Risk:** Entire notification system non-functional, but app should still work.
**Detection:** `NotificationService.initialize()` throws.
**Recovery:** Graceful degradation — schedule data persists in Hive, retry on next app launch.

**Code location:** `main.dart` (Task 13) — wrap notification service init in try-catch.
**Code location:** `NotificationCubit` (Task 12) — handle missing service.

```dart
// In main.dart (Task 13), wrap notification service init:
NotificationService? notificationService;
try {
  notificationService = NotificationService();
  Services.register<NotificationService>(notificationService);
  await notificationService.initialize();
} catch (e) {
  // Notification service init failed — app continues without local notifications
  // Data still persists in Hive for retry on next launch
  developer.log('NotificationService init failed: $e', name: 'Main');
  notificationService = null;
}

// Only register scheduler if service initialized successfully
if (notificationService != null) {
  Services.register<NotificationScheduler>(
    NotificationScheduler(
      repository: Services.get<NotificationRepository>(),
      notificationService: notificationService!,
    ),
  );
}
```

```dart
// In NotificationCubit (Task 12), add null check:
// At the top of scheduleFromJadwal:
if (!Services.isRegistered<NotificationScheduler>()) {
  emit(state.copyWith(
    status: NotificationStatus.error,
    errorMessage: 'Sistem notifikasi tidak tersedia. Coba lagi nanti.',
  ));
  return;
}
```

**Test:** Manual verification — mock `initialize()` to throw, verify app still launches.

---

### EH-5: Timezone Data Unavailable

**Risk:** `tz.TZDateTime` constructor throws if timezone database not loaded.
**Detection:** `tz.local` is null or timezone package throws.
**Recovery:** Fallback to `DateTime` (local device time) — notifications may fire at slightly wrong time during DST.

**Code location:** `NotificationService` (Task 7) — defensive timezone init.
**Code location:** `NotificationScheduler` (Task 11) — fallback to DateTime.

```dart
// In NotificationService.initialize() (Task 7), add fallback:
try {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.local);
} catch (e) {
  // Timezone data unavailable — use device local time as fallback
  developer.log('Timezone init failed, using device time: $e', name: 'NotificationService');
  // tz.local defaults to UTC if not set — this is acceptable as fallback
}
```

```dart
// In NotificationScheduler._scheduleAlarm() (Task 11), add fallback:
tz.TZDateTime tzTrigger;
try {
  tzTrigger = tz.TZDateTime.from(triggerTime, tz.local);
} catch (e) {
  // Timezone conversion failed — use plain DateTime cast
  // This may be slightly off during DST transitions but is acceptable
  tzTrigger = tz.TZDateTime(
    tz.local ?? tz.UTC,
    triggerTime.year,
    triggerTime.month,
    triggerTime.day,
    triggerTime.hour,
    triggerTime.minute,
  );
}
```

**Test:** Add test for timezone fallback in `notification_service_test.dart`.

---

### Error Handling Summary Table

| Scenario | Detection | Recovery | Crash? | User Impact |
|----------|-----------|----------|--------|-------------|
| POST_NOTIFICATIONS denied | `areNotificationsEnabled() == false` | Show banner in settings | No | Notifications don't display — user informed |
| SCHEDULE_EXACT_ALARM denied | `canScheduleExactAlarms() == false` | Fallback to inexact alarm | No | Notifications may fire ±few minutes late |
| Hive box corrupt | `Hive.openBox()` throws | Delete + re-create box | No | Scheduled notifications lost — re-schedule from Jadwal |
| NotificationService init fail | `initialize()` throws | Graceful degradation | No | No local notifications until app restart |
| Timezone data unavailable | `tz.local` null | Fallback to DateTime | No | Notifications may be off during DST |

---

## Verification Checklist

After all tasks are complete, verify these behaviors on a physical device:

| # | Behavior | How to Verify |
|---|----------|---------------|
| 1 | Notification fires before class | Set a class time 6 minutes from now. Wait. Notification should appear. |
| 2 | Notification fires when app is killed | Force-close the app. Wait for alarm time. Notification should appear. |
| 3 | Notification fires when offline | Enable airplane mode. Wait for alarm time. Notification should appear. |
| 4 | Reminder interval picker works | Open Settings → change from 5 to 15 minutes. Verify next notification fires 15 min before class. |
| 5 | Notifications survive reboot | Schedule notifications. Reboot device. Verify notifications are still scheduled. |
| 6 | Toggle notification on/off | In notification settings, toggle a class off. Verify it doesn't fire. Toggle back on. |
| 7 | Android 13+ permission prompt | Fresh install on Android 13+. Verify POST_NOTIFICATIONS dialog appears. |
| 8 | Notification channel appears separately | In Android Settings → Apps → Notifications, verify "Pengingat Kelas" channel exists. |
| 9 | iOS permission prompt | Fresh install on iOS. Verify UNUserNotificationCenter dialog appears. |
| 10 | No duplicate notifications | Verify each class gets exactly one notification. |
| 11 | Permission denied handling | Deny POST_NOTIFICATIONS on Android 13+. Verify banner appears in settings. |
| 12 | Exact alarm denied handling | Revoke SCHEDULE_EXACT_ALARM on Android 12+. Verify notifications still fire (inexact). |
| 13 | Hive corruption recovery | Delete Hive box file manually. Relaunch app. Verify app recovers and re-creates box. |
| 14 | NotificationService init failure | Mock init to throw. Verify app still launches and shows error in settings. |
