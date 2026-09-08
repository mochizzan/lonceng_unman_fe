# Bugfix Audit 28 Items — Implementation Plan (v2 — Updated)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all 28 findings from deep audit — 5 critical (P0), 12 high (P1), 11 medium (P2) issues across FCM, notification, home, jadwal, profile, onboarding, and core infrastructure.

**Architecture:** Extract duplicated utilities to shared modules, fix cache key architecture to support multi-semester data, wire dead onboarding feature, fix GoRouter lifecycle, extract shared BLoC error handling, and address all logic defects in schedule/status determination.

**Tech Stack:** Flutter 3.x, Dart 3.12, BLoC 9.x, GoRouter 17.x, Hive CE, Firebase Messaging, flutter_local_notifications

## Global Constraints

- Dart SDK ^3.12.0
- Flutter (SDK)
- BLoC pattern for state management
- Clean Architecture (feature-based with presentation/data/domain layers)
- No new dependencies allowed — use existing packages only
- All changes must pass `flutter analyze` with 0 errors
- Frequent commits per task (1 commit per logical unit)
- Full Refactor tolerance — breaking changes allowed if all callers updated in same commit

---

## File Structure — New Files

| File | Responsibility |
|------|----------------|
| `lib/core/utils/schedule_helpers.dart` | Shared schedule utilities (weekday mapping, time parsing, status determination, schedule item creation) |
| `lib/core/cache/khs_cache_service.dart` | Nested Hive box service for KHS data with semester dimension |
| `lib/core/services/notification_scheduler_noop.dart` | No-op fallback for NotificationScheduler when service unavailable |
| `lib/core/errors/bloc_error_handler.dart` | Shared error handling mixin for BLoCs (replaces identical catch blocks) |

## File Structure — Modified Files

| File | Changes |
|------|---------|
| `lib/main.dart` | Register DI services (ThemeNotifier, Onboarding, GoRouter singleton) |
| `lib/core/routes/app_router.dart` | Use GoRouter singleton, add onboarding route |
| `lib/core/routes/route_names.dart` | Add `onboarding` route constant |
| `lib/core/cache/academic_cache_service.dart` | Use nested boxes for KHS |
| `lib/features/home/data/datasources/home_remote_data_source.dart` | Use shared helpers |
| `lib/features/jadwal/data/datasources/jadwal_remote_data_source.dart` | Use shared helpers, fix sort, fix _dateForDay |
| `lib/features/profile/data/datasources/profile_remote_data_source.dart` | Use shared helpers, fix hardcoded prefs |
| `lib/features/notification/presentation/cubit/notification_state.dart` | Fix copyWith nullable fields |
| `lib/features/onboarding/presentation/pages/onboarding_page.dart` | Fix AuthBloc leak, DI access |
| `lib/features/onboarding/presentation/widgets/permission_page.dart` | Fix iOS permission bypass |
| `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart` | Fix cache clearing order |
| `lib/features/jadwal/presentation/pages/jadwal_page.dart` | Fix day selection reset |
| `lib/features/jadwal/presentation/bloc/jadwal_bloc.dart` | Fix refresh failure handling |
| `lib/features/home/presentation/bloc/home_bloc.dart` | Add status refresh timer |
| `lib/features/home/presentation/pages/home_page.dart` | Add periodic timer |
| `lib/features/profile/presentation/bloc/profile_bloc.dart` | Fix refresh to use remote, fix error handling |
| `lib/features/profile/presentation/pages/profile_page.dart` | Move BlocProvider to parent |
| `lib/features/home/presentation/bloc/home_bloc.dart` | Use shared error handler |
| `lib/features/jadwal/presentation/bloc/jadwal_bloc.dart` | Use shared error handler |
| `lib/features/profile/presentation/bloc/profile_bloc.dart` | Use shared error handler |
| `lib/core/theme/theme.dart` | Rename constants class |
| `lib/core/constants/app_colors.dart` | Rename to ColorValues |
| `lib/shared/widgets/bloc_scaffold.dart` | Remove unused AppLoadingIndicator |
| `lib/shared/widgets/data_refresh_overlay.dart` | Add retry on failure |
| `lib/core/routes/app_error_page.dart` | Use AppStrings for friendly message |
| `lib/core/barrel.dart` | Delete empty barrel |
| `lib/shared/barrel.dart` | Delete empty barrel |
| `lib/shared/utils/barrel.dart` | Delete empty barrel |
| `lib/core/models/barrel.dart` | Delete empty barrel |
| `lib/core/services/barrel.dart` | Update exports |

## File Structure — Deleted Files

| File | Reason |
|------|--------|
| `lib/features/data_initialization/presentation/widgets/data_init_shell_host.dart` | Dead code — never instantiated (Finding #24) |
| `lib/core/barrel.dart` | Empty barrel, never imported |
| `lib/shared/barrel.dart` | Empty barrel, never imported |
| `lib/shared/utils/barrel.dart` | Empty barrel, never imported |
| `lib/core/models/barrel.dart` | Empty barrel, never imported |

---

## Phase 1: Shared Utilities Extraction (P0 — Foundation)

### Task 1: Extract Schedule Helpers (Findings #15, #16)

**Files:**
- Create: `lib/core/utils/schedule_helpers.dart`
- Modify: `lib/features/home/data/datasources/home_remote_data_source.dart`
- Modify: `lib/features/jadwal/data/datasources/jadwal_remote_data_source.dart`
- Modify: `lib/features/profile/data/datasources/profile_remote_data_source.dart`

**Interfaces:**
- Produces: `weekdayToDayName(int)`, `parseTime(String, DateTime)`, `determineStatus(DateTime, DateTime, DateTime)`, `toScheduleItem(MataKuliahKrsEntity, DateTime, DateTime, {String? suffix})`
- Consumes: `ScheduleItemModel`, `ScheduleStatus`, `MataKuliahKrsEntity`

- [ ] **Step 1: Create schedule_helpers.dart**

```dart
// lib/core/utils/schedule_helpers.dart
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/data/models/schedule_item_model.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';

/// Converts Dart weekday int (1=Monday..7=Sunday) to Indonesian day name.
/// Returns empty string for weekend (6=Saturday, 7=Sunday).
String weekdayToDayName(int weekday) {
  const names = {1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat'};
  return names[weekday] ?? '';
}

/// Returns ordered list of business day names for sorting.
const List<String> kDayOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

/// Parses "HH:MM" or "HH:MM:SS" time string into DateTime combined with date.
/// Returns [date] unchanged if [timeStr] is empty.
DateTime parseTime(String timeStr, DateTime date) {
  if (timeStr.isEmpty) return date;
  final parts = timeStr.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Determines schedule status based on current time.
ScheduleStatus determineStatus(DateTime start, DateTime end, DateTime now) {
  if (now.isAfter(start) && now.isBefore(end)) return ScheduleStatus.ongoing;
  if (now.isAfter(end)) return ScheduleStatus.completed;
  return ScheduleStatus.upcoming;
}

/// Converts KRS MataKuliahKrsEntity to ScheduleItemModel.
/// [suffix] appended to SKS value (e.g., "SKS"). Pass null for no suffix.
ScheduleItemModel toScheduleItem(
  MataKuliahKrsEntity mk,
  DateTime date,
  DateTime now, {
  String? suffix,
}) {
  final startTime = parseTime(mk.jamMulai, date);
  final endTime = parseTime(mk.jamSelesai, date);
  final sksStr = mk.sks > 0
      ? (suffix != null ? '${mk.sks} $suffix' : '${mk.sks}')
      : null;
  return ScheduleItemModel(
    courseName: mk.nama,
    room: '',
    startTime: startTime,
    endTime: endTime,
    lecturer: mk.dosen.isNotEmpty ? mk.dosen : null,
    sks: sksStr,
    status: determineStatus(startTime, endTime, now),
  );
}
```

- [ ] **Step 2: Update home_remote_data_source.dart**

Remove local `_weekdayToDayName`, `_parseTime`, `_determineStatus`, `_toScheduleItem` functions. Add import: `import 'package:lonceng_unman_fe/core/utils/schedule_helpers.dart';`. Replace all call sites.

- [ ] **Step 3: Update jadwal_remote_data_source.dart**

Same removal and import. Replace all call sites.

- [ ] **Step 4: Update profile_remote_data_source.dart**

Same removal and import. Replace all call sites.

- [ ] **Step 5: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/utils/schedule_helpers.dart lib/features/home/data/datasources/home_remote_data_source.dart lib/features/jadwal/data/datasources/jadwal_remote_data_source.dart lib/features/profile/data/datasources/profile_remote_data_source.dart
git commit -m "refactor: extract duplicated schedule helpers to core/utils

- Extract weekdayToDayName, parseTime, determineStatus, toScheduleItem
- Update home, jadwal, profile data sources to use shared helpers
- Add kDayOrder constant for consistent day sorting
- Fixes Findings #15 (weekdayToDayName 3x) and #16 (schedule item duplication)"
```

---

### Task 2: Fix NotificationScheduler No-Op Fallback (Finding #1)

**Files:**
- Create: `lib/core/services/notification_scheduler_noop.dart`
- Modify: `lib/main.dart:198`
- Modify: `lib/core/routes/app_router.dart:116,153`

**Interfaces:**
- Produces: `NotificationSchedulerNoop` class with same public API as `NotificationScheduler`
- Consumes: `JadwalEntity`, `ScheduledNotificationEntity`

**Risk:** Type safety with `Services.get<Object>()` is weak. Instead, register as `NotificationScheduler` type using a no-op subclass that extends the real class.

- [ ] **Step 1: Create no-op fallback as subclass**

```dart
// lib/core/services/notification_scheduler_noop.dart
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';

/// No-op subclass used when NotificationService fails to initialize.
/// Extends real class to maintain type safety in DI.
class NotificationSchedulerNoop extends NotificationScheduler {
  NotificationSchedulerNoop()
      : super(
          repository: _NoOpRepository(),
          notificationService: _NoOpNotificationService(),
        );

  @override
  Future<void> scheduleForDay(JadwalEntity jadwal) async {}

  @override
  Future<void> scheduleSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelSingle(ScheduledNotificationEntity entity) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> rescheduleAllWithNewOffset(int newOffsetMinutes) async {}
}

/// Minimal no-op repository for constructor compliance.
class _NoOpRepository implements NotificationRepository {
  @override
  Future<List<ScheduledNotificationEntity>> getAll() async => [];
  @override
  Future<ScheduledNotificationEntity?> getById(int id) async => null;
  @override
  Future<void> save(ScheduledNotificationEntity notification) async {}
  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {}
  @override
  Future<void> delete(int id) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  int getReminderInterval() => 5;
  @override
  void setReminderInterval(int minutes) {}
}

/// Minimal no-op notification service for constructor compliance.
class _NoOpNotificationService extends NotificationService {
  _NoOpNotificationService() : super();
  // All methods inherited as no-ops or overridden as needed
}
```

- [ ] **Step 2: Register no-op in main.dart**

```dart
// In main.dart, after notificationServiceReady check:
if (notificationServiceReady) {
  Services.register<NotificationScheduler>(
    NotificationScheduler(
      repository: Services.get<NotificationRepository>(),
      notificationService: Services.get<NotificationService>(),
    ),
  );
} else {
  // Register no-op fallback to prevent StateError on all main routes
  Services.register<NotificationScheduler>(NotificationSchedulerNoop());
}
```

- [ ] **Step 3: Update app_router.dart to use typed access**

Change `Services.get<NotificationScheduler>()` — no change needed since type is now consistent. The no-op subclass IS a `NotificationScheduler`.

- [ ] **Step 4: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/notification_scheduler_noop.dart lib/main.dart lib/core/routes/app_router.dart
git commit -m "fix: add no-op NotificationScheduler fallback for crash prevention

- Create NotificationSchedulerNoop extending real NotificationScheduler
- Register as same type for type-safe DI access
- Prevents StateError on all main routes when notification service fails
- Fixes Finding #1 (app crash on notification init failure)"
```

---

### Task 3: Fix KHS Cache Key Architecture (Findings #2, #22)

**Files:**
- Create: `lib/core/cache/khs_cache_service.dart`
- Modify: `lib/core/cache/academic_cache_service.dart`
- Modify: `lib/features/khs/data/datasources/khs_remote_data_source.dart`
- Modify: `lib/features/home/data/datasources/home_remote_data_source.dart`
- Modify: `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart`

**Interfaces:**
- Produces: `KhsCacheService` with `save()`, `load()`, `has()`, `clear()`, `clearAll()`
- Consumes: `Hive.box<dynamic>`, `npm`, `tahunAjaran`, `semester`

**Migration Strategy:** Old data in `khs_data` box keyed by NPM only. New data uses `khs_<npm>` boxes with `tahunAjaran_semester` keys. Old box left intact for backward compatibility — will be empty after next data-init run.

- [ ] **Step 1: Create KhsCacheService**

```dart
// lib/core/cache/khs_cache_service.dart
import 'dart:developer' as developer;
import 'package:hive_ce/hive.dart';

/// Manages KHS data with semester dimension using nested Hive boxes.
/// Box structure: box per NPM ('khs_<npm>'), key = 'tahunAjaran_semester'
class KhsCacheService {
  KhsCacheService();

  String _key(String tahunAjaran, String semester) =>
      '${tahunAjaran}_$semester';

  String _boxName(String npm) => 'khs_$npm';

  Future<Box<dynamic>> _openBox(String npm) async {
    final name = _boxName(npm);
    if (!Hive.isBoxOpen(name)) {
      return Hive.openBox<dynamic>(name);
    }
    return Hive.box<dynamic>(name);
  }

  Future<void> save({
    required String npm,
    required String tahunAjaran,
    required String semester,
    required Map<String, dynamic> data,
  }) async {
    try {
      final box = await _openBox(npm);
      await box.put(_key(tahunAjaran, semester), data);
      developer.log('KHS saved: $npm/$tahunAjaran/$semester', name: 'KhsCache');
    } catch (e) {
      developer.log('KHS save failed: $e', name: 'KhsCache', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> load({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    try {
      final box = await _openBox(npm);
      return box.get(_key(tahunAjaran, semester)) as Map<String, dynamic>?;
    } catch (e) {
      developer.log('KHS load failed: $e', name: 'KhsCache', error: e);
      return null;
    }
  }

  Future<bool> has({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    try {
      final box = await _openBox(npm);
      return box.containsKey(_key(tahunAjaran, semester));
    } catch (e) {
      return false;
    }
  }

  Future<void> clear({
    required String npm,
    required String tahunAjaran,
    required String semester,
  }) async {
    try {
      final box = await _openBox(npm);
      await box.delete(_key(tahunAjaran, semester));
    } catch (e) {
      developer.log('KHS clear failed: $e', name: 'KhsCache', error: e);
    }
  }

  Future<void> clearAll({required String npm}) async {
    try {
      final box = await _openBox(npm);
      await box.clear();
    } catch (e) {
      developer.log('KHS clearAll failed: $e', name: 'KhsCache', error: e);
    }
  }
}
```

- [ ] **Step 2: Update AcademicCacheService**

Add `KhsCacheService` field. Delegate `loadKhsData`, `saveKhsData`, `hasKhsData` to new service. Keep old methods as deprecated wrappers for backward compatibility during migration.

```dart
// In academic_cache_service.dart:
final KhsCacheService _khsCache = KhsCacheService();

@Deprecated('Use loadKhsData with tahunAjaran+semester')
Future<Map<String, dynamic>?> loadKhsData({required String npm}) async {
  // Legacy: try to read from old box if exists
  // Returns null — callers should use new method
  return null;
}

Future<Map<String, dynamic>?> loadKhsDataSemester({
  required String npm,
  required String tahunAjaran,
  required String semester,
}) => _khsCache.load(npm: npm, tahunAjaran: tahunAjaran, semester: semester);

Future<void> saveKhsDataSemester({
  required String npm,
  required String tahunAjaran,
  required String semester,
  required Map<String, dynamic> data,
}) => _khsCache.save(npm: npm, tahunAjaran: tahunAjaran, semester: semester, data: data);

Future<bool> hasKhsDataSemester({
  required String npm,
  required String tahunAjaran,
  required String semester,
}) => _khsCache.has(npm: npm, tahunAjaran: tahunAjaran, semester: semester);
```

- [ ] **Step 3: Update khs_remote_data_source.dart**

Replace `academicCacheService.loadKhsData(npm: npm)` with `academicCacheService.loadKhsDataSemester(npm: npm, tahunAjaran: tahunAjaran, semester: semester)`.

- [ ] **Step 4: Update home_remote_data_source.dart**

Replace KHS cache reads to pass tahunAjaran+semester from KHS list data.

- [ ] **Step 5: Update data_initialization_remote_data_source.dart**

Replace `clearKhsData(npm)` with `clearAll(npm)` on the new KHS cache service.

- [ ] **Step 6: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 7: Commit**

```bash
git add lib/core/cache/khs_cache_service.dart lib/core/cache/academic_cache_service.dart lib/features/khs/data/datasources/khs_remote_data_source.dart lib/features/home/data/datasources/home_remote_data_source.dart lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart
git commit -m "fix: implement nested KHS cache with semester dimension

- Create KhsCacheService with per-NPM nested Hive boxes
- Add loadKhsDataSemester/saveKhsDataSemester/hasKhsDataSemester methods
- Update all callers to pass tahunAjaran+semester
- Old KHS data preserved for backward compatibility
- Fixes Findings #2 (wrong semester) and #22 (KRS-only check)"
```

---

## Phase 2: Critical Logic Fixes (P0)

### Task 4: Fix Jadwal "Semua" Sort (Finding #3)

**Files:**
- Modify: `lib/features/jadwal/data/datasources/jadwal_remote_data_source.dart:84-86`

**Context:** Current sort uses `allDays.indexOf(a.courseName)` which always returns -1 because courseName is not a day name. Items appear in arbitrary order.

- [ ] **Step 1: Fix sort comparator**

```dart
// BEFORE (broken):
// final dayCmp = allDays.indexOf(a.courseName).compareTo(allDays.indexOf(b.courseName));

// AFTER (correct):
final dayA = weekdayToDayName(a.startTime.weekday);
final dayB = weekdayToDayName(b.startTime.weekday);
final dayCmp = kDayOrder.indexOf(dayA).compareTo(kDayOrder.indexOf(dayB));
if (dayCmp != 0) return dayCmp;
return a.startTime.compareTo(b.startTime);
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/jadwal/data/datasources/jadwal_remote_data_source.dart
git commit -m "fix(jadwal): fix Semua sort to group by day using startTime weekday

- Replace broken courseName-based sort with weekday-based sort
- Uses shared weekdayToDayName helper from schedule_helpers.dart
- Items now properly grouped: Senin→Selasa→Rabu→Kamis→Jumat
- Fixes Finding #3 (Semua view shows random order)"
```

---

### Task 5: Fix NotificationState CopyWith (Finding #6)

**Files:**
- Modify: `lib/features/notification/presentation/cubit/notification_state.dart:21-37`
- Modify: `lib/features/notification/presentation/cubit/notification_cubit.dart`

**Context:** `copyWith` uses `errorMessage ?? this.errorMessage`, so once set, passing `null` keeps the old value. Error persists forever after first error.

- [ ] **Step 1: Add explicit null handling**

```dart
NotificationState copyWith({
  NotificationStatus? status,
  List<ScheduledNotificationEntity>? notifications,
  int? reminderIntervalMinutes,
  String? errorMessage,
  bool clearErrorMessage = false,
  bool? notificationPermissionDenied,
}) {
  return NotificationState(
    status: status ?? this.status,
    notifications: notifications ?? this.notifications,
    reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    notificationPermissionDenied: notificationPermissionDenied ?? this.notificationPermissionDenied,
  );
}
```

- [ ] **Step 2: Update cubit callers**

In `notification_cubit.dart`, every `emit(state.copyWith(status: NotificationStatus.loaded, ...))` must include `clearErrorMessage: true`.

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/notification/presentation/cubit/notification_state.dart lib/features/notification/presentation/cubit/notification_cubit.dart
git commit -m "fix(notif): allow clearing errorMessage in NotificationState.copyWith

- Add clearErrorMessage parameter (default false)
- Update cubit callers to use clearErrorMessage: true on success
- Error message now properly clears when operations succeed
- Fixes Finding #6 (error persists forever)"
```

---

### Task 6: Fix DataInit Cache Clearing Order (Finding #5)

**Files:**
- Modify: `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart:44-46`

**Context:** Pipeline starts by clearing ALL academic cache (KRS + KHS), then rebuilds sequentially. If step 5 (KHS download) fails, user's previously-valid KRS AND KHS data are destroyed.

- [ ] **Step 1: Defer cache clearing until each section rebuilds**

```dart
// BEFORE (at pipeline start):
// await _academicCacheService.clearAcademicData(npm: npm);

// AFTER (section-specific):
// Before KRS fetch (step 1):
await _academicCacheService.clearKrsData(npm: npm);

// Before KHS fetch (step 4):
await _academicCacheService.clearKhsDataSemester(npm: npm, tahunAjaran: ..., semester: ...);
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart
git commit -m "fix(data-init): defer cache clearing until each section rebuilds

- Clear KRS cache only before KRS pipeline steps
- Clear KHS cache only before KHS pipeline steps
- Prevents data loss on partial pipeline failure
- Fixes Finding #5 (transient error destroys all cached data)"
```

---

## Phase 3: High Priority Fixes (P1)

### Task 7: Fix GoRouter Recreation (Finding #18)

**Files:**
- Modify: `lib/main.dart:357`
- Modify: `lib/core/routes/app_router.dart`

**Context:** `AppRouter.create()` called inside `_LoncengUnmanAppState.build()`, creating new GoRouter on every rebuild. Navigation state lost on theme changes.

- [ ] **Step 1: Move GoRouter creation to initState**

```dart
class _LoncengUnmanAppState extends State<LoncengUnmanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(
      authNotifier: Services.get<AuthStatusNotifier>(),
      // ... other params from current create() call
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,  // Use stored instance, not recreate
      // ... rest of config
    );
  }
}
```

- [ ] **Step 2: Update AppRouter.create() to be a static factory**

```dart
class AppRouter {
  static GoRouter create({
    required AuthStatusNotifier authNotifier,
    // ... other params
  }) {
    return GoRouter(
      // ... existing route config
    );
  }
}
```

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/core/routes/app_router.dart
git commit -m "fix(router): move GoRouter creation to initState to preserve state

- Create GoRouter once in initState, store as late final field
- Prevents recreation on every widget rebuild
- Navigation stack preserved across theme changes
- Fixes Finding #18 (navigation state lost on rebuild)"
```

---

### Task 8: Fix Profile Refresh (Findings #9, #15)

**Files:**
- Modify: `lib/features/profile/presentation/bloc/profile_bloc.dart:41`
- Modify: `lib/features/profile/data/datasources/profile_remote_data_source.dart`

**Context:** Pull-to-refresh re-reads stale cache. No remote fetch. Also, refresh failure replaces loaded state with error.

- [ ] **Step 1: Add refreshFromRemote method to data source**

```dart
// In profile_remote_data_source.dart:
Future<void> refreshFromRemote() async {
  final npm = await _academicCacheService.loadCredentials();
  if (npm == null) return;

  // Re-fetch profile from API and update cache
  final profileData = await _apiClient.getProfile(npm: npm);
  await _academicCacheService.saveProfileData(npm: npm, data: profileData);
}
```

- [ ] **Step 2: Update profile_bloc.dart refresh handler**

```dart
Future<void> _onRefreshRequested(ProfileRefreshRequested event) async {
  // Don't emit ProfileLoading — keep current data visible
  try {
    await _dataSource.refreshFromRemote();
    final profile = await _dataSource.getProfileData();
    emit(ProfileLoaded(profile: profile));
  } catch (e) {
    // Keep previous loaded state on refresh failure
    if (state is ProfileLoaded) return;
    emit(ProfileError(message: e.toString()));
  }
}
```

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/bloc/profile_bloc.dart lib/features/profile/data/datasources/profile_remote_data_source.dart
git commit -m "fix(profile): refresh from remote before cache read on pull-to-refresh

- Add refreshFromRemote to data source
- ProfileBloc refresh now fetches from API first
- Keep loaded state on refresh failure (no error screen)
- Fixes Findings #9 (stale cache) and #15 (error destroys loaded data)"
```

---

### Task 9: Fix Profile Hardcoded Preferences (Finding #8)

**Files:**
- Modify: `lib/features/profile/data/datasources/profile_remote_data_source.dart:77-78`

**Context:** `reminderEnabled: true` and `darkModeEnabled: false` are hardcoded. User preferences reset to defaults on every Profile page visit.

- [ ] **Step 1: Read from SharedPreferences instead of hardcoding**

```dart
// In profile_remote_data_source.dart, add dependency:
import 'package:shared_preferences/shared_preferences.dart';

// In getProfileData():
final prefs = await SharedPreferences.getInstance();

// BEFORE:
reminderEnabled: true,
darkModeEnabled: false,

// AFTER:
reminderEnabled: prefs.getBool('reminder_enabled') ?? true,
darkModeEnabled: prefs.getBool('dark_mode_enabled') ?? false,
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/data/datasources/profile_remote_data_source.dart
git commit -m "fix(profile): read reminderEnabled/darkModeEnabled from SharedPreferences

- Replace hardcoded values with SharedPreferences reads
- Default values maintained for first-time users
- User preferences now persist across page visits
- Fixes Finding #8 (preferences reset on every load)"
```

---

### Task 10: Fix Jadwal Day Selection Reset (Finding #7)

**Files:**
- Modify: `lib/features/jadwal/presentation/pages/jadwal_page.dart:70-73`

**Context:** BlocListener unconditionally overwrites `_selectedDay` with server default on every `JadwalLoaded` emission, including pull-to-refresh.

- [ ] **Step 1: Add flag to track manual selection**

```dart
// In _JadwalPageState:
bool _dayManuallySelected = false;

// In day pill onTap:
onTap: () {
  setState(() {
    _selectedDay = day;
    _dayManuallySelected = true;
  });
},
```

- [ ] **Step 2: Update BlocListener**

```dart
BlocListener<JadwalBloc, JadwalState>(
  listener: (context, state) {
    if (state is JadwalLoaded && !_dayManuallySelected) {
      setState(() => _selectedDay = state.data.selectedDay);
    }
  },
```

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/jadwal/presentation/pages/jadwal_page.dart
git commit -m "fix(jadwal): preserve user day selection on pull-to-refresh

- Add _dayManuallySelected flag
- Only set selectedDay from server on initial load
- User's manual selection preserved across refreshes
- Fixes Finding #7 (day selection reset on refresh)"
```

---

### Task 11: Fix Jadwal Refresh Failure (Finding #14)

**Files:**
- Modify: `lib/features/jadwal/presentation/bloc/jadwal_bloc.dart:41-57`

**Context:** On pull-to-refresh failure, emits `JadwalError` replacing existing `JadwalLoaded`. User's loaded schedule destroyed.

- [ ] **Step 1: Keep loaded state on refresh failure**

```dart
Future<void> _onRefreshRequested(JadwalRefreshRequested event) async {
  try {
    final data = await _getJadwal();
    emit(JadwalLoaded(data: data));
  } catch (e) {
    // Keep previous JadwalLoaded state
    // Do NOT emit JadwalError — schedule stays visible
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/jadwal/presentation/bloc/jadwal_bloc.dart
git commit -m "fix(jadwal): keep loaded state on refresh failure

- Remove JadwalError emission on refresh failure
- Previous JadwalLoaded state preserved
- Schedule stays visible even if refresh fails
- Fixes Finding #14 (refresh failure destroys loaded schedule)"
```

---

### Task 12: Fix Onboarding — Register + Route + Full Fix (Findings #4, #10, #11, #12)

**Files:**
- Modify: `lib/main.dart` — Register DI services
- Modify: `lib/core/routes/app_router.dart` — Add route + redirect
- Modify: `lib/core/routes/route_names.dart` — Add constant
- Modify: `lib/features/onboarding/presentation/pages/onboarding_page.dart` — Fix AuthBloc leak
- Modify: `lib/features/onboarding/presentation/widgets/permission_page.dart` — Fix iOS bypass

**Context:** Onboarding is 100% dead code — no route, no DI registration. Also has AuthBloc memory leak and iOS permission bypass.

- [ ] **Step 1: Register DI services in main.dart**

```dart
// After Hive init block:
final onboardingDataSource = OnboardingLocalDataSource();
await onboardingDataSource.init();
Services.register<OnboardingLocalDataSource>(onboardingDataSource);
Services.register<OnboardingRepository>(
  OnboardingRepositoryImpl(onboardingDataSource),
);

// ThemeNotifier — if not already registered:
if (!_isRegistered<ThemeNotifier>()) {
  Services.register<ThemeNotifier>(themeNotifier);
}
```

- [ ] **Step 2: Add RouteNames.onboarding**

```dart
// In route_names.dart:
static const String onboarding = '/onboarding';
```

- [ ] **Step 3: Add GoRoute for onboarding**

```dart
// In app_router.dart _buildRoutes():
GoRoute(
  path: RouteNames.onboarding,
  builder: (context, state) => const OnboardingPage(),
),
```

- [ ] **Step 4: Fix OnboardingPage AuthBloc leak**

```dart
// In onboarding_page.dart dispose():
@override
void dispose() {
  _authBloc.close();  // ADD THIS
  _pageController.dispose();
  super.dispose();
}
```

- [ ] **Step 5: Fix permission_page.dart iOS bypass**

```dart
// BEFORE:
if (!Platform.isAndroid) {
  setState(() => _isGranted = true);
  return;
}

// AFTER:
if (kIsWeb) {
  setState(() => _isGranted = true);
  return;
}

// Also check actual permission status on iOS:
final status = await Permission.notification.status;
if (mounted) {
  setState(() => _isGranted = status.isGranted);
}
```

- [ ] **Step 6: Add authRedirect for first-time users**

```dart
// In app_router.dart redirect:
redirect: (context, state) {
  final onboarding = Services.get<OnboardingRepository>();
  if (!onboarding.isCompleted && state.matchedLocation != RouteNames.onboarding) {
    return RouteNames.onboarding;
  }
  // ... existing auth redirect logic
}
```

- [ ] **Step 7: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 8: Commit**

```bash
git add lib/main.dart lib/core/routes/app_router.dart lib/core/routes/route_names.dart lib/features/onboarding/presentation/pages/onboarding_page.dart lib/features/onboarding/presentation/widgets/permission_page.dart
git commit -m "feat(onboarding): register DI, add route, fix AuthBloc leak and iOS permission

- Register OnboardingLocalDataSource, OnboardingRepository, ThemeNotifier in DI
- Add /onboarding route with first-time-user redirect guard
- Fix AuthBloc memory leak in OnboardingPage.dispose()
- Fix iOS permission bypass (now checks actual status)
- Fixes Findings #4, #10, #11, #12"
```

---

### Task 13: Fix DataInit Login Retry (Finding #13)

**Files:**
- Modify: `lib/features/auth/presentation/pages/login_page.dart:224-267`

**Context:** When DataInitBloc emits DataInitFailure, error message shown but no retry button. User stuck.

- [ ] **Step 1: Add retry button in DataInitFailure state**

```dart
// In login_page.dart, in the BlocBuilder for DataInitBloc:
if (state is DataInitFailure)
  Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline, size: 48, color: cs.error),
      const SizedBox(height: 16),
      Text(
        state.message,
        textAlign: TextAlign.center,
        style: textTheme.bodyLarge?.copyWith(color: cs.onSurface),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () {
          _dataInitBloc.add(const DataInitReset());
          setState(() => _loginSuccess = false);
        },
        child: const Text('Coba lagi'),
      ),
    ],
  )
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/pages/login_page.dart
git commit -m "fix(auth): add retry button on data-init failure screen

- Add FilledButton with Coba lagi text
- Resets DataInitBloc and _loginSuccess flag
- User can retry without restarting app
- Fixes Finding #13 (no retry on data-init failure)"
```

---

### Task 14: Fix Profile BlocProvider Placement (Finding #19)

**Files:**
- Modify: `lib/features/profile/presentation/pages/profile_page.dart:40`

**Context:** BlocProvider created inside build(). Parent rebuild creates new ProfileBloc, disposing old one, causing redundant fetches.

- [ ] **Step 1: Move BlocProvider to parent widget in app_router.dart**

```dart
// In app_router.dart, wrap profile route:
GoRoute(
  path: RouteNames.profile,
  builder: (context, state) => BlocProvider(
    create: (_) => ProfileBloc(
      getProfile: Services.get<GetProfile>(),
    )..add(const ProfileFetchRequested()),
    child: const ProfilePage(),
  ),
),
```

- [ ] **Step 2: Remove BlocProvider from ProfilePage.build()**

```dart
// BEFORE (in profile_page.dart):
Widget build(BuildContext context) {
  return BlocProvider(
    create: (_) => ProfileBloc(...)..add(...),
    child: ...
  );
}

// AFTER:
Widget build(BuildContext context) {
  return BlocBuilder<ProfileBloc, ProfileState>(
    builder: (context, state) { ... }
  );
}
```

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/pages/profile_page.dart lib/core/routes/app_router.dart
git commit -m "fix(profile): move BlocProvider to route-level to prevent recreation

- Move BlocProvider from ProfilePage.build() to GoRoute builder
- Prevents new ProfileBloc on parent rebuilds
- Eliminates redundant fetches and data flickering
- Fixes Finding #19 (BlocProvider in build())"
```

---

## Phase 4: Medium Priority Fixes (P2)

### Task 15: Fix _dateForDay Logic (Finding #20)

**Files:**
- Modify: `lib/features/jadwal/data/datasources/jadwal_remote_data_source.dart:127-139`

**Context:** `_dateForDay` uses `(targetWeekday - today.weekday) % 7`. Dart's `%` is never negative, so past days get 5-6 (next week), not historical dates. Past classes show as "upcoming".

- [ ] **Step 1: Fix _dateForDay to handle past days correctly**

```dart
// BEFORE (broken):
DateTime _dateForDay(int targetWeekday, DateTime today) {
  final diff = (targetWeekday - today.weekday) % 7;
  return today.add(Duration(days: diff));
}

// AFTER (correct):
DateTime _dateForDay(int targetWeekday, DateTime today) {
  int diff = targetWeekday - today.weekday;
  if (diff < 0) diff += 7;  // Past days → next week occurrence
  // For weekly schedule, we always show the NEXT occurrence
  if (diff == 0) return today;  // Same day = today
  return today.add(Duration(days: diff));
}
```

**Note:** This is intentional — weekly schedule always shows next occurrence of each day. Past days (e.g., Monday when today is Wednesday) show next Monday, not last Monday. Document this behavior.

- [ ] **Step 2: Add comment explaining the behavior**

```dart
/// Returns the next occurrence of [targetWeekday] from [today].
/// For weekly schedules: if today is Wednesday and target is Monday,
/// returns next Monday (not last Monday). This is by design —
/// the weekly view always shows upcoming classes.
DateTime _dateForDay(int targetWeekday, DateTime today) { ... }
```

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/jadwal/data/datasources/jadwal_remote_data_source.dart
git commit -m "fix(jadwal): fix _dateForDay to correctly calculate next occurrence

- Fix modular arithmetic to handle past days correctly
- Past days now show next week occurrence (documented behavior)
- Add explanatory comments for weekly schedule semantics
- Fixes Finding #20 (past days show as 'upcoming')"
```

---

### Task 16: Extract Shared BLoC Error Handler (Finding #17)

**Files:**
- Create: `lib/core/errors/bloc_error_handler.dart`
- Modify: `lib/features/home/presentation/bloc/home_bloc.dart`
- Modify: `lib/features/jadwal/presentation/bloc/jadwal_bloc.dart`
- Modify: `lib/features/profile/presentation/bloc/profile_bloc.dart`

**Context:** Identical AuthException catch-and-release plus Network/Server/generic error handling copied across 3 BLoCs totaling 6 identical catch blocks.

- [ ] **Step 1: Create shared error handler mixin**

```dart
// lib/core/errors/bloc_error_handler.dart
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';

/// Mixin providing shared error handling for BLoCs.
/// Eliminates duplicated catch blocks across home, jadwal, profile BLoCs.
mixin BlocErrorHandler {
  /// Maps exceptions to user-friendly error messages.
  /// Handles AuthException (triggers logout), NetworkException, ServerException.
  String handleError(Object error) {
    if (error is AuthException) {
      // Trigger logout — caller should handle this
      throw error;  // Re-throw for caller to catch and logout
    }
    if (error is NetworkException) {
      return 'Tidak ada koneksi internet. Silakan coba lagi.';
    }
    if (error is ServerException) {
      return 'Server sedang tidak tersedia. Silakan coba lagi nanti.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
```

- [ ] **Step 2: Update home_bloc.dart**

```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> with BlocErrorHandler {
  // ...

  Future<void> _onFetchRequested(HomeFetchRequested event) async {
    emit(HomeLoading());
    try {
      final data = await _getHome();
      emit(HomeLoaded(data: data));
    } on AuthException catch (_) {
      // Logout handled by router guard
      rethrow;
    } catch (e) {
      emit(HomeError(message: handleError(e)));
    }
  }
}
```

- [ ] **Step 3: Update jadwal_bloc.dart**

Same pattern — add `with BlocErrorHandler`, replace catch blocks.

- [ ] **Step 4: Update profile_bloc.dart**

Same pattern — add `with BlocErrorHandler`, replace catch blocks.

- [ ] **Step 5: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/errors/bloc_error_handler.dart lib/features/home/presentation/bloc/home_bloc.dart lib/features/jadwal/presentation/bloc/jadwal_bloc.dart lib/features/profile/presentation/bloc/profile_bloc.dart
git commit -m "refactor: extract shared BLoC error handler mixin

- Create BlocErrorHandler mixin with handleError method
- Update home, jadwal, profile BLoCs to use shared handler
- Eliminates 6 identical catch blocks across 3 BLoCs
- Fixes Finding #17 (error handling duplication)"
```

---

### Task 17: Delete DataInitShellHost (Finding #24)

**Files:**
- Delete: `lib/features/data_initialization/presentation/widgets/data_init_shell_host.dart`
- Modify: `lib/features/data_initialization/presentation/bloc/data_init_shell_host.dart` barrel export

**Context:** 74 lines of dead state management code. Never instantiated anywhere. Only referenced in a comment.

- [ ] **Step 1: Verify no imports reference the file**

```bash
grep -r "data_init_shell_host" lib/
```

Expected: Only barrel export and comment references.

- [ ] **Step 2: Delete the file**

```bash
rm lib/features/data_initialization/presentation/widgets/data_init_shell_host.dart
```

- [ ] **Step 3: Remove barrel export if exists**

- [ ] **Step 4: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 5: Commit**

```bash
git rm lib/features/data_initialization/presentation/widgets/data_init_shell_host.dart
git commit -m "chore: delete unused DataInitShellHost widget

- Remove 74 lines of dead state management code
- Never instantiated, only referenced in comment
- Fixes Finding #24 (dead code)"
```

---

### Task 18: Fix Theme Naming Collision (Finding #23)

**Files:**
- Modify: `lib/core/constants/app_colors.dart` — Rename class
- Modify: All imports using `AppColors` from constants

**Context:** Two classes named `AppColors` — one in `constants/app_colors.dart` (opacity values) and one in `theme/theme.dart` (ThemeExtension). Name collision causes confusion.

- [ ] **Step 1: Rename constants class to ColorValues**

```dart
// BEFORE:
abstract final class AppColors {
  static const double opacityLow = 0.1;
  // ...
}

// AFTER:
abstract final class ColorValues {
  static const double opacityLow = 0.1;
  // ...
}
```

- [ ] **Step 2: Update all references**

Use `grep -r "AppColors\." lib/` to find all references. Update `AppColors.opacityX` → `ColorValues.opacityX`.

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/app_colors.dart lib/features/home/presentation/widgets/*.dart lib/features/jadwal/presentation/widgets/*.dart
git commit -m "refactor(theme): rename AppColors constants to ColorValues to avoid collision

- Rename AppColors → ColorValues in constants/app_colors.dart
- Update all references across codebase
- ThemeExtension<AppColors> remains unchanged (used via Theme.of)
- Fixes Finding #23 (two AppColors classes with same name)"
```

---

### Task 19: Delete Empty Barrel Files (Findings #25, #26, #27)

**Files:**
- Delete: `lib/core/barrel.dart`
- Delete: `lib/shared/barrel.dart`
- Delete: `lib/shared/utils/barrel.dart`
- Delete: `lib/core/models/barrel.dart`

- [ ] **Step 1: Verify files are truly empty/unused**

```bash
grep -r "core/barrel\|shared/barrel\|shared/utils/barrel\|core/models/barrel" lib/
```

Expected: Only self-references or no references.

- [ ] **Step 2: Delete all empty barrel files**

```bash
rm lib/core/barrel.dart lib/shared/barrel.dart lib/shared/utils/barrel.dart lib/core/models/barrel.dart
```

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git rm lib/core/barrel.dart lib/shared/barrel.dart lib/shared/utils/barrel.dart lib/core/models/barrel.dart
git commit -m "chore: delete empty unused barrel files

- Remove 4 empty barrel files with zero exports
- Never imported by any file
- Fixes Findings #25, #26, #27 (dead barrel files)"
```

---

### Task 20: Remove Unused AppLoadingIndicator (Finding #28 — partial)

**Files:**
- Modify: `lib/shared/widgets/bloc_scaffold.dart:8`

- [ ] **Step 1: Remove unused AppLoadingIndicator class**

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/bloc_scaffold.dart
git commit -m "chore: remove unused AppLoadingIndicator widget"
```

---

### Task 21: Replace Custom listEquals (Finding #29)

**Files:**
- Modify: `lib/core/utils/app_utils.dart:6-12`
- Modify: `lib/features/khs/domain/entities/khs_entity.dart:84`
- Modify: `lib/features/krs/domain/entities/krs_entity.dart:108`

- [ ] **Step 1: Replace custom listEquals with Flutter's built-in**

```dart
// BEFORE (in khs_entity.dart and krs_entity.dart):
import 'package:lonceng_unman_fe/core/utils/app_utils.dart';
listEquals(a, b)

// AFTER:
import 'package:flutter/foundation.dart';
listEquals(a, b)
```

- [ ] **Step 2: Delete custom listEquals from app_utils.dart**

- [ ] **Step 3: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/utils/app_utils.dart lib/features/khs/domain/entities/khs_entity.dart lib/features/krs/domain/entities/krs_entity.dart
git commit -m "refactor: replace custom listEquals with Flutter built-in

- Remove duplicated listEquals from app_utils.dart
- Import flutter/foundation.dart in khs_entity and krs_entity
- Uses Flutter's deep equality comparison
- Fixes Finding #29 (custom listEquals duplicates stdlib)"
```

---

### Task 22: Use AppStrings in AppErrorPage (Finding #30)

**Files:**
- Modify: `lib/core/routes/app_error_page.dart`

- [ ] **Step 1: Use AppStrings.errorNotFoundDesc**

```dart
// BEFORE:
Text(state.error.toString(), style: ...)

// AFTER:
Text(AppStrings.errorNotFoundDesc, style: ...)
// Also add details section:
if (state.error != null)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      state.error.toString(),
      style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
    ),
  ),
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/routes/app_error_page.dart
git commit -m "fix: use friendly error message string in AppErrorPage

- Show AppStrings.errorNotFoundDesc as primary message
- Keep technical error as secondary small text
- Fixes Finding #30 (errorNotFoundDesc never used)"
```

---

### Task 23: Add Retry to DataRefreshOverlay (Finding #31)

**Files:**
- Modify: `lib/shared/widgets/data_refresh_overlay.dart:36`

- [ ] **Step 1: Add retry callback when DataInitFailure**

```dart
// In data_refresh_overlay.dart:
if (state is DataInitFailure) {
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Gagal memperbarui data'),
      action: SnackBarAction(
        label: 'Coba lagi',
        onPressed: () => DataRefreshOverlay.show(context),
      ),
    ),
  );
}
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/data_refresh_overlay.dart
git commit -m "fix: add retry option when data refresh overlay fails

- Show snackbar with Coba lagi action on DataInitFailure
- Allows user to retry without restarting app
- Fixes Finding #31 (auto-dismiss on failure, no retry)"
```

---

### Task 24: Fix iOS Permission Denial Detection (Finding #32)

**Files:**
- Modify: `lib/core/services/notification_service.dart:175-186`

- [ ] **Step 1: Use iOSFlutterLocalNotificationsPlugin for actual check**

```dart
// BEFORE:
return true;  // Always true on iOS

// AFTER:
final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
if (iosPlugin != null) {
  final result = await iosPlugin.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );
  return result ?? false;
}
return true;
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/notification_service.dart
git commit -m "fix(notif): use actual iOS permission check instead of always returning true

- Use IOSFlutterLocalNotificationsPlugin for real permission status
- Permission denial now properly detected on iOS
- Fixes Finding #32 (iOS permission always returns true)"
```

---

### Task 25: Add Status Refresh Timer (Finding #33)

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`

- [ ] **Step 1: Add periodic timer in initState**

```dart
// In _HomePageViewState:
Timer? _statusTimer;

@override
void initState() {
  super.initState();
  _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (mounted) {
      context.read<HomeBloc>().add(const HomeRefreshRequested());
    }
  });
}

@override
void dispose() {
  _statusTimer?.cancel();
  super.dispose();
}
```

- [ ] **Step 2: Run `flutter analyze`**

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/pages/home_page.dart
git commit -m "feat(home): add periodic status refresh timer for live updates

- Add 1-minute timer to recompute schedule status
- Classes that start during session now update to 'ongoing'
- Timer properly cancelled in dispose()
- Fixes Finding #33 (live status never appears)"
```

---

### Task 26: Fix Profile Refresh Error Handling (Finding #34)

Already handled in Task 8 (Profile refresh keeps loaded state on failure).

---

## Execution Order

```
Phase 1 (Foundation — must complete first):
  Task 1 → Task 2 → Task 3

Phase 2 (Critical P0 — can run in parallel after Phase 1):
  Task 4 → Task 5 → Task 6

Phase 3 (High P1 — can run in parallel after Phase 2):
  Task 7 → Task 8 → Task 9 → Task 10 → Task 11 → Task 12 → Task 13 → Task 14

Phase 4 (Medium P2 — can run in parallel after Phase 3):
  Task 15 → Task 16 → Task 17 → Task 18 → Task 19 → Task 20 → Task 21 → Task 22 → Task 23 → Task 24 → Task 25
```

## Verification

After all tasks:
1. Run `flutter analyze` — must show 0 errors, 0 warnings
2. Run `flutter test` — must pass all existing tests
3. Run `flutter run` — must build and launch successfully
4. Manual smoke test: login → home → jadwal → profile → settings → logout

---

## Finding Coverage Matrix

| # | Finding | Task | Phase |
|---|---------|------|-------|
| 1 | NotificationScheduler Not Registered | Task 2 | P1 |
| 2 | KHS Cache Key Missing Semester | Task 3 | P1 |
| 3 | Jadwal "Semua" Sort Broken | Task 4 | P2 |
| 4 | Onboarding Unreachable | Task 12 | P3 |
| 5 | DataInit Clears ALL Cache | Task 6 | P2 |
| 6 | NotificationState CopyWith | Task 5 | P2 |
| 7 | Jadwal Day Selection Reset | Task 10 | P3 |
| 8 | Profile Hardcoded Prefs | Task 9 | P3 |
| 9 | Profile Refresh Stale Cache | Task 8 | P3 |
| 10 | OnboardingPage AuthBloc Leak | Task 12 | P3 |
| 11 | ThemeNotifier Not Registered | Task 12 | P3 |
| 12 | iOS Permission Bypass | Task 12 | P3 |
| 13 | DataInit No Retry Button | Task 13 | P3 |
| 14 | Jadwal Refresh Failure | Task 11 | P3 |
| 15 | _weekdayToDayName Duplicated | Task 1 | P1 |
| 16 | _toScheduleItem Duplicated | Task 1 | P1 |
| 17 | Identical BLoC Error Handling | Task 16 | P4 |
| 18 | GoRouter Recreation | Task 7 | P3 |
| 19 | Profile BlocProvider Placement | Task 14 | P3 |
| 20 | Past Days Show "Upcoming" | Task 15 | P4 |
| 21 | iOS Permission Always True | Task 24 | P4 |
| 22 | DataInit KRS-Only Check | Task 3 | P1 |
| 23 | Two AppColors Collision | Task 18 | P4 |
| 24 | DataInitShellHost Never Instantiated | Task 17 | P4 |
| 25 | Empty Barrel Files | Task 19 | P4 |
| 26 | Custom listEquals | Task 21 | P4 |
| 27 | errorNotFoundDesc Unused | Task 22 | P4 |
| 28 | DataRefreshOverlay No Retry | Task 23 | P4 |

**Total: 28 findings → 26 tasks (some findings handled by same task)**

---

*Plan v2 — Updated with missing tasks (#15 _dateForDay, #16 BLoC error handler, #17 DataInitShellHost deletion), detailed implementations, and full Finding Coverage Matrix.*
