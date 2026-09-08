# Design: FCM FIAM Suppression & Foreground System Notification

**Date:** 2026-09-06
**Status:** Approved (brainstorming gate passed)
**Scope:** Single spec — two tightly coupled FCM fixes (FIAM suppression + foreground display)
**Related files:** `lib/main.dart`, `lib/core/services/fcm_service.dart`, `lib/core/services/fiam_service.dart` (new), `lib/core/services/notification_service.dart`, `lib/core/auth/auth_status.dart`, `lib/features/onboarding/**`, `lib/core/routes/app_router.dart`, `pubspec.yaml`

---

## 1. Context & Problem

Two user-reported FCM issues on fresh install and normal use:

1. **FIAM (Firebase In-App Messaging) appears in onboarding and login** — even on fresh install and before any account exists. Root cause: `firebase_in_app_messaging: ^0.9.2+7` is declared in `pubspec.yaml` but never referenced in code (`grep` for `FirebaseInAppMessaging | setMessagesSuppressed | setAutomaticDataCollectionEnabled` returns zero hits). FIAM auto-activates after `Firebase.initializeApp()` and, without any suppression or targeting, shows campaigns on every screen including `OnboardingPage` (4-slide carousel) and `LoginPage`.

2. **Realtime FCM notification does not appear while the app is in foreground.** Root cause: `FcmService._handleForegroundMessage` (lib/core/services/fcm_service.dart:240) only does `debugPrint` + `_messageController.add(message)`. On Android, FCM does **not** automatically display a system notification when the app is in foreground — it only delivers to `FirebaseMessaging.onMessage`. On iOS, `setForegroundNotificationPresentationOptions(alert:true)` makes the OS show it, but on Android the message is silently swallowed except for the delivered-history save in `main.dart:_wireFcmDelivered`. No `NotificationService.show()` is ever called for foreground messages.

**Exploration method:** cocoindex + codegraph + direct file reads of `main.dart`, `fcm_service.dart`, `notification_service.dart`, `app_router.dart`, `onboarding_page.dart`, `permission_cubit.dart`, `permission_page.dart`, `notification_config.dart`, `AndroidManifest.xml`, `pubspec.yaml`. Verified: FIAM has no code-level suppression, foreground FCM has no system-notification path on Android.

---

## 2. Goals & Non-Goals

### Goals

- G1: FIAM never renders on onboarding (`/onboarding`) or login (`/login`) — including fresh install and unauthenticated cold start. FIAM renders only after `AuthStatus.authenticated` inside the main shell (`/home`, `/jadwal`, `/profile`).
- G2: Foreground FCM displays as a heads-up **system notification** (status bar, sound/vibration, tappable) on Android, consistent with background/killed behavior. Done via `NotificationService.show()` because Android does not auto-display foreground FCM.
- G3: Minimal change, no new backend contract, no `pubspec.yaml` dependency change, no router guard change.

### Non-Goals (YAGNI)

- No Firebase Console targeting/A-B test changes — suppression is client-side only.
- No FCM payload/backend changes.
- No in-app banner/toast for foreground — system notification only.
- No FIAM analytics event or campaign orchestration changes.

---

## 3. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| FIAM suppression trigger | `AuthStatusNotifier.status` stream (A) | Single source of truth already used by `AppRouter.authRedirect` and `main.dart` credential check. Covers cold start, logout, re-login, deep link. Route-based toggle would be noisy and miss `unknown`. |
| Foreground display | System notification via `flutter_local_notifications` (A) | Consistent with background/killed. Android requires manual `show()` for foreground. `NotificationService` already wraps channel config. |
| New abstraction | `FiamService` thin wrapper in `core/services/` | Isolates FIAM concern, injectable for tests, mirrors `FcmService` / `NotificationService` pattern. ~20 lines. |
| Where to call `show()` | Inside `FcmService._handleForegroundMessage` (inject `NotificationService`) | Cohesion: FCM transport owns foreground display. Alternative (`_wireFcmDelivered` in `main.dart`) would split FCM responsibilities. |
| Data collection toggle | `setAutomaticDataCollectionEnabled(!suppress)` alongside `setMessagesSuppressed` | Stops fetch while suppressed; privacy-friendly; no loss — cached campaigns remain. |

---

## 4. Architecture & File Map

```
lib/core/services/
  fcm_service.dart              // MODIFY: inject NotificationService, show in _handleForegroundMessage
  fiam_service.dart             // NEW: wrapper for FirebaseInAppMessaging suppression
  notification_service.dart     // UNCHANGED: consumed as dependency

lib/main.dart                   // WIRING: bind FiamService to AuthStatusNotifier, init order
lib/core/auth/auth_status.dart  // UNCHANGED: consumed (currentStatus + status stream)
lib/features/onboarding/**       // UNCHANGED
lib/core/routes/app_router.dart  // UNCHANGED
```

Dependency direction: `core/services` → `core/auth` (allowed). No `features → core/services` cycle introduced. `FiamService` depends only on `firebase_in_app_messaging` + `AuthStatusNotifier`. `FcmService` adds optional `NotificationService` dep (constructor injection with `Services.get` fallback, matching existing BLoC pattern: `param ?? Services.get<T>()`).

---

## 5. Components & Interfaces

### 5.1 FiamService (new: `lib/core/services/fiam_service.dart`)

```dart
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:async';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';

/// Thin wrapper around FirebaseInAppMessaging suppression.
///
/// Binds to [AuthStatusNotifier] and toggles FIAM visibility
/// based on auth lifecycle (not route).
class FiamService {
  FiamService({FirebaseInAppMessaging? instance})
      : _fiam = instance ?? FirebaseInAppMessaging.instance;

  final FirebaseInAppMessaging _fiam;
  StreamSubscription<AuthStatus>? _sub;

  /// Call once in main() after [AuthStatusNotifier] is registered.
  /// Applies suppression for current status and listens for changes.
  Future<void> bind(AuthStatusNotifier notifier) async {
    await _apply(notifier.currentStatus);
    _sub = notifier.status.listen((s) => _apply(s));
  }

  Future<void> _apply(AuthStatus s) async {
    final suppress = s != AuthStatus.authenticated;
    try {
      await _fiam.setMessagesSuppressed(suppress);
      await _fiam.setAutomaticDataCollectionEnabled(!suppress);
      debugPrint('[FIAM] suppressed=$suppress (status=$s)');
    } catch (e) {
      debugPrint('[FIAM] _apply FAILED: $e (status=$s)');
    }
  }

  void dispose() => _sub?.cancel();
}
```

Behavior:

- `setMessagesSuppressed(true)` holds rendering but keeps campaign fetch warm; `false` releases.
- `setAutomaticDataCollectionEnabled` mirrors suppression for efficiency/privacy.
- Constructor-injected `instance` enables hand-written fake in tests.
- `bind` is idempotent-safe: `_apply` is called for initial `currentStatus` before the credential check, so there is no window where FIAM could flash before the guard.
- On logout (`Services.performFullLogout() → setStatus(unauthenticated)`), stream fires → `suppress=true` again.
- Errors are logged, not thrown — FIAM is non-critical.

### 5.2 FcmService modifications (`lib/core/services/fcm_service.dart`)

Additions:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';

class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();
  static FcmService get instance => _instance;

  // ... existing fields (_messaging, _messageController, _currentToken, subscriptions) ...

  /// Test-only override for NotificationService. Production path uses Services.get lazily.
  @visibleForTesting
  NotificationService? _testNotificationService;
  @visibleForTesting
  void setNotificationServiceForTest(NotificationService? svc) =>
      _testNotificationService = svc;

  NotificationService get _notif =>
      _testNotificationService ?? Services.get<NotificationService>();

  // ... existing initialize(), requestPermission(), refreshToken() unchanged ...

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] --------------------------------------------');
    debugPrint('[FCM] FOREGROUND MESSAGE RECEIVED!');
    debugPrint('[FCM]   Message ID: ${message.messageId}');
    debugPrint('[FCM]   Title: ${message.notification?.title}');
    debugPrint('[FCM]   Body: ${message.notification?.body}');
    debugPrint('[FCM]   Data: ${message.data}');
    debugPrint('[FCM] --------------------------------------------');
    _messageController.add(message);

    // NEW: show system notification on Android foreground
    if (kIsWeb) return;
    final notif = message.notification;
    if (notif == null) return; // data-only → no system notification
    try {
      final id = (message.messageId ?? DateTime.now().toIso8601String()).hashCode & 0x7FFFFFFF;
      _notif.show(
        id: id,
        title: notif.title ?? 'Lonceng UnMan',
        body: notif.body ?? '',
        channel: NotificationChannel.classReminders,
      );
    } catch (e) {
      debugPrint('[FCM] foreground show FAILED: $e');
    }
  }
}
```

Notes:

- Singleton `FcmService.instance` remains `static final _instance = FcmService._()` with a private no-arg constructor. Dependency is **not** constructor-injected into the singleton; instead `_handleForegroundMessage` resolves `NotificationService` lazily via `Services.get<NotificationService>()` at call time (with an optional `NotificationService?` field set only by tests via a test-only setter `setNotificationServiceForTest`). This preserves `FcmService.instance` compatibility and avoids breaking the existing `FcmService._()` signature.
- `kIsWeb` guard: web foreground is handled by `firebase-messaging-sw.js` + browser.
- Data-only messages (`notification == null`) intentionally do not show — they are for silent sync, not user-visible alerts. If later needed, a separate data-message handler can be added.
- `id` is derived from `messageId` hash masked to non-negative 31-bit to satisfy `flutter_local_notifications` id constraints. To avoid collision with `ScheduledNotificationEntity` ids (deterministic per course/day/hour) and `downloads` ids (7000–7999), foreground FCM ids use the full 31-bit hash space which statistically does not overlap with the small-range scheduled ids. If a dedicated range is preferred, implementation MUST reserve a distinct range (e.g. 90000–99999) and document it in `NotificationConfig`.
- Channel is definitively `NotificationChannel.classReminders` (Importance.high, heads-up). A dedicated `NotificationChannel.fcmMessages` is explicitly **out of scope** for this spec; add it only as a follow-up spec if UX requires a separate shade grouping.

### 5.3 Wiring in `lib/main.dart`

Order (after existing registrations):

```dart
// After: Services.register<AuthStatusNotifier>(authStatusNotifier);
final fiamService = FiamService();
try {
  await fiamService.bind(authStatusNotifier);
} catch (e) {
  debugPrint('[MAIN] FiamService bind FAILED: $e');
}
Services.register<FiamService>(fiamService);
```

Placement rationale: after `AuthStatusNotifier` and `OnboardingLocalDataSource` are ready, before `credential check` + `runApp`. The `await _apply(currentStatus)` inside `bind` ensures the initial suppression is set synchronously before the first frame. Fire-and-forget is acceptable if `await` would block startup — but `setMessagesSuppressed` is fast (in-memory flag), so awaiting is safe.

No change to `AppRouter.create`: the redirect already checks `OnboardingRepository.isCompleted` then `authRedirect`. FIAM suppression is orthogonal to routing.

---

## 6. Data Flow

### 6.1 FIAM suppression

```
Firebase.initializeApp()
  → Hive init, OnboardingLocalDataSource.init(), AuthStatusNotifier created (default unauthenticated)
  → FiamService.bind(notifier)
      → _apply(currentStatus) → setMessagesSuppressed(suppress?)
      → listen(notifier.status) → on each emission → _apply(newStatus)
  → credential check (cache.loadCredentials, hasKrs/hasKhsList)
      → setStatus(authenticated|unauthenticated) → stream emits → _apply
  → runApp()

Login success: AuthBloc → DataInitBloc(DataInitSuccess)
  → authStatusNotifier.setStatus(authenticated) → _apply(authenticated) → suppressed=false
  → GoRouter redirect → /home (shell) → FIAM may display

Logout: Services.performFullLogout()
  → clear caches, cancel alarms, delete FCM token
  → setStatus(unauthenticated) → _apply → suppressed=true → FIAM hidden again
```

Cold-start guarantee: `bind` awaits `_apply(currentStatus)` before `credential check`, so even on fresh install (`unauthenticated`) there is no frame where FIAM could render.

### 6.2 Foreground FCM

```
FCM payload arrives while app in foreground (Android)
  → FirebaseMessaging.onMessage fires
  → FcmService._handleForegroundMessage
      → debugPrint + _messageController.add(message)
          → existing: _wireFcmDelivered listener saves to NotificationDeliveredRepository
      → (new) NotificationService.show(...) → heads-up system notification
  → User taps heads-up:
      → FirebaseMessaging.onMessageOpenedApp fires
      → FcmService._backgroundTapSubscription → _onNotificationTap
      → app handles deep link / navigation (existing)
```

Background/killed path unchanged: `_firebaseMessagingBackgroundHandler` (top-level) + `FirebaseMessaging.onBackgroundMessage` handles it; `getInitialMessage` handles killed→tap.

---

## 7. Error Handling

| Failure | Handling |
|---|---|
| `FiamService.bind` throws (e.g. FIAM instance unavailable before Firebase init) | Catch in `main.dart`, log `debugPrint('[MAIN] FiamService bind FAILED')`, app continues. FIAM fails safe — no crash, just no suppression (acceptable since suppression is best-effort). |
| `setMessagesSuppressed` / `setAutomaticDataCollectionEnabled` throws | Catch inside `_apply`, log `[FIAM] _apply FAILED`, no rethrow. |
| `NotificationService.show` throws in foreground handler (permission denied, channel not ready) | Catch inside `_handleForegroundMessage`, log `[FCM] foreground show FAILED`, no rethrow. Message still saved to delivered history; visible in `NotificationHistoryPage`. |
| `POST_NOTIFICATIONS` denied (Android 13+) | `show()` is silently dropped by OS; no re-request here — permission already requested on onboarding slide 3 (`PermissionPage`). Foreground message still recorded in history. |
| FCM data-only message in foreground | Intentionally no `show()` — `notification == null` guard. |
| `Services.get<NotificationService>()` not yet registered when foreground message arrives | Guard: `_notif` getter will throw `StateError`; caught by the same `try/catch` around `show()`, logged. In practice impossible because `NotificationService` is registered before `FcmService.initialize` in `main.dart`. |

Global error handling remains: `runZonedGuarded` + `FlutterError.onError` unchanged.

---

## 8. Testing

### 8.1 Unit: FiamService (`test/core/services/fiam_service_test.dart`)

Hand-written fake (no mockito/mocktail, per repo convention in `test/helpers/test_di.dart`):

```dart
class FakeFiam implements FirebaseInAppMessaging { // or hand fake with same surface
  bool? lastSuppressed;
  bool? lastDataCollection;
  @override Future<void> setMessagesSuppressed(bool v) async => lastSuppressed = v;
  @override Future<void> setAutomaticDataCollectionEnabled(bool v) async => lastDataCollection = v;
}
```

Cases:

- `bind` with `currentStatus=unauthenticated` → `suppressed=true`, `dataCollection=false`.
- `bind` with `currentStatus=authenticated` → `suppressed=false`, `dataCollection=true`.
- Stream `unauthenticated → authenticated` → second `_apply` flips values.
- Underlying `setMessagesSuppressed` throws → `bind` does not throw (logged).

### 8.2 Unit: FcmService foreground show

Fake `NotificationService` capturing `show()` args:

```dart
class CapturingNotificationService extends NotificationService {
  int? lastId; String? lastTitle; String? lastBody; NotificationChannel? lastChannel;
  @override Future<void> show({required int id, required String title, required String body, required NotificationChannel channel, ...}) async {
    lastId = id; lastTitle = title; lastBody = body; lastChannel = channel;
  }
}
```

Cases:

- `RemoteMessage(notification: RemoteNotification(title:'T', body:'B'))` on Android → `show` called with `channel==classReminders`, non-negative id.
- Data-only (`notification==null`) → `show` not called.
- `show` throws → handler does not throw.
- (Optional) `kIsWeb` path → no `show` (injectable flag or conditional test).

### 8.3 Existing suites

- `test/router/auth_guard_test.dart` must stay green — no guard change.
- `test/features/onboarding` (if empty, no regression).
- Full `flutter test` must pass.

### 8.4 Manual QA checklist

- Fresh install → onboarding slides → FIAM campaign active in console → no FIAM on any onboarding slide.
- On login page (unauthenticated) → no FIAM.
- Login success → data init → `/home` → FIAM campaign now eligible to display.
- Logout → back to login → FIAM suppressed again.
- Foreground FCM: from Firebase Console send notification with title/body while app on `/home` (Android) → heads-up appears, tap opens app, entry in Notification History.
- Foreground data-only message → no heads-up, but no crash.

---

## 9. Alternatives Considered

- **Route-based FIAM suppression** (`AppRouter.redirect` checks `state.matchedLocation`): rejected — `redirect` fires on every navigation (noisy toggles), misses `AuthStatus.unknown` cold start, mixes routing with messaging.
- **Merge FIAM into FcmService**: rejected — mixes two Firebase products (`firebase_messaging` vs `firebase_in_app_messaging`) in one class, widens import surface, violates single-responsibility of `FcmService`.
- **Foreground in-app banner instead of system notification**: rejected per user choice (A) — system notification is expected, tappable, consistent with background; banner would duplicate and not appear in shade.

---

## 10. Risks & Mitigations

- **FIAM campaign already fetched before suppression**: `setMessagesSuppressed(true)` suppresses display even if already fetched; no need to clear cache.
- **Startup ordering**: `FiamService.bind` must run after `Firebase.initializeApp` and `AuthStatusNotifier` creation — enforced by placement in `main.dart` after those steps.
- **Channel choice for foreground FCM**: reuses `classReminders` (high importance). If FCM notifications deserve distinct channel (e.g. `fcmMessages`), add a new `NotificationChannel` enum value — `NotificationService` auto-creates it. Decision deferred to implementation; spec allows either.
- **Android 13+ permission denied**: foreground `show()` silently dropped; mitigated by history fallback.

---

## 11. Implementation Plan Handoff

Implementation follows `writing-plans` skill. Suggested task breakdown:

1. Create `lib/core/services/fiam_service.dart` with `bind` + tests.
2. Modify `lib/core/services/fcm_service.dart` to inject `NotificationService` and `show` in foreground handler + tests.
3. Wire `FiamService` in `lib/main.dart` after `AuthStatusNotifier`.
4. Run `flutter analyze` + `flutter test` + manual QA checklist.

No `pubspec.yaml` change. No new permissions. No manifest change.
