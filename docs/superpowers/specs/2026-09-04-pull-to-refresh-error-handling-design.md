# Pull-to-Refresh Error Handling — Design

> **Status:** Approved (brainstorming complete, awaiting user review of this written spec)
> **Date:** 2026-09-04
> **Author:** Brainstorming session with user
> **Related docs:**
> - `docs/superpowers/plans/2026-08-08-bugfix-audit-28items.md` (Task 23 / Finding #31 — original proposal for retry SnackBar; superseded by this spec)

---

## 1. Goal

Change the failure path of pull-to-refresh on the three main tabs (Home, Jadwal, Profile) so that:

1. When the data-init pipeline fails, the existing full-screen overlay shows the error view (icon + message + failed step + hint) for **exactly 3 seconds**, then **auto-closes with a fade-out animation**.
2. **No SnackBar** is shown after the overlay closes.
3. The user cannot manually close the overlay faster — there are no Retry/Close buttons in this mode.
4. The login flow is **unaffected**: it does not use `DataRefreshOverlay` at all — `LoginPage` directly mounts `DataInitProgressView(isFreshLogin: true, …)` (`login_page.dart:118`) and keeps its existing Retry/Cancel behavior. `DataRefreshOverlay` itself is **only** instantiated for pull-to-refresh.

The pull-to-refresh `onRefresh` callbacks on the three pages are also cleaned up: the `onPipelineFailure` and `onPipelineSuccess` named arguments to `DataRefreshOverlay.triggerRefresh(...)` are removed because `onPipelineFailure` becomes dead code (overlay auto-dismisses before the callback would fire) and `onPipelineSuccess` was already redundant (the overlay dispatches BLoC refetches internally on `DataInitSuccess` at `data_refresh_overlay.dart:147-153`).

---

## 2. Background & Current Behavior (verified)

| Aspect | File:Line | Current state |
|---|---|---|
| Overlay trigger | `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart:82-117` | `triggerRefresh` shows modal, dispatches pipeline |
| Pipeline states | `lib/features/data_initialization/presentation/bloc/data_initialization_state.dart` | `DataInitInProgress` / `DataInitSuccess` / `DataInitFailure(message, failedStep)` |
| Success auto-dismiss | `data_refresh_overlay.dart:162-166` | `Future.delayed(500ms)` then `Navigator.pop()` |
| Failure behavior (login) | `data_init_progress_view.dart:_buildErrorView` | Shows Retry + Close buttons; user must act |
| Failure callback (refresh) | `home_page.dart:155-164`, `jadwal_page.dart:94-100`, `profile_page.dart:325-331` | After user taps Close, parent receives `onPipelineFailure` and shows `ScaffoldMessenger.showSnackBar(SnackBar(content: Text(failure.message), duration: 3s))` — copy-pasted 3× |
| `isFreshLogin` flag | `data_init_progress_view.dart:18`, `data_refresh_overlay.dart:191` | Boolean distinguishing login-time vs. pull-to-refresh pipeline runs |
| BLoC refresh handlers (silent) | `home_bloc.dart:36-50`, `jadwal_bloc.dart:43-49`, `profile_bloc.dart:57-72` | All swallow errors to keep prior `Loaded` state; **not in scope for this spec** |
| Pull-to-refresh test | `test/features/jadwal/presentation/pages/jadwal_pull_refresh_test.dart` | 3 tests V3-A/B/C — probe spinner visibility only, not error UI |

**Key finding:** the BLoC refresh handlers (the second `try/catch` path after the overlay) already swallow errors silently. They are not in scope; this spec only changes the overlay's failure behavior.

---

## 3. Architecture & Changes

### 3.1 Files changed

| File | Change |
|---|---|
| `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart` | Convert `StatelessWidget` → `StatefulWidget`; add `Timer? _autoCloseTimer`; start 3-second timer in `BlocListener` when `state is DataInitFailure && !isFreshLogin`; cancel timer in `dispose`; cancel timer in success branch (defensive). |
| `lib/features/home/presentation/pages/home_page.dart` | Remove `onPipelineFailure: (failure) { … showSnackBar … }` closure inside `DataRefreshOverlay.triggerRefresh(...)` call (lines 155-164). |
| `lib/features/jadwal/presentation/pages/jadwal_page.dart` | Remove `onPipelineFailure` closure (lines 94-100). |
| `lib/features/profile/presentation/pages/profile_page.dart` | Remove `onPipelineFailure` closure (lines 325-331). |
| `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart` | **New file.** Widget test that pumps the overlay with a stub `DataInitBloc` and asserts the auto-close behavior in both modes. |

### 3.2 Files NOT changed (out of scope)

- `lib/features/data_initialization/presentation/widgets/data_init_progress_view.dart` — error view rendering stays identical. The "no buttons" requirement is enforced by the overlay's auto-pop, not by view changes.
- `lib/features/home/presentation/bloc/home_bloc.dart`, `jadwal_bloc.dart`, `profile_bloc.dart` — silent error swallowing is intentional and not affected.
- `lib/core/errors/bloc_error_handler.dart` — unchanged.
- All test files in `test/features/{auth,notification,profile,home}/` — unaffected.
- Patrol E2E tests — not modified; manual smoke is sufficient for this lifecycle tweak.

### 3.3 API contract preserved

`DataRefreshOverlay.show()` and `DataRefreshOverlay.triggerRefresh()` keep their existing signatures. The `onPipelineFailure` and `onPipelineSuccess` named parameters remain for source compatibility but `onPipelineFailure` will no longer be invoked in pull-to-refresh mode (it can still be invoked by future callers, if any). The `// ignore: unused_element` style is unnecessary because the parameters are still part of the public API.

---

## 4. Implementation Detail

### 4.1 `DataRefreshOverlay` state conversion

Convert the existing `StatelessWidget DataRefreshOverlay` (lines 20-215) to a `StatefulWidget` with a single state class. The new state holds one field:

```dart
Timer? _autoCloseTimer;
```

`dispose()` cancels it. `initState()` does nothing beyond the super call.

### 4.2 Auto-close logic in the existing BlocListener

Inside the existing `BlocListener<DataInitBloc, DataInitBlocState>` (around `data_refresh_overlay.dart:134-176`), extend the failure branch:

```dart
} else if (state is DataInitFailure) {
  if (widget.isFreshLogin) {
    // Login flow: keep current behavior — stay visible, show Retry/Close.
    return;
  }
  // Pull-to-refresh flow: show the error view briefly, then auto-close.
  // No SnackBar is shown to the user — the overlay IS the error feedback.
  debugPrint(
    '[DATA_REFRESH] Failure (pull-to-refresh): ${state.message} '
    'step=${state.failedStep} — auto-closing in 3s',
  );
  _autoCloseTimer?.cancel();
  _autoCloseTimer = Timer(const Duration(seconds: 3), () {
    if (!mounted) return;
    Navigator.of(context).pop();
  });
}
```

The existing success branch (lines 143-166) must also cancel the timer defensively, in case a Success emission lands while an earlier failure had already armed the timer (this can happen if a future change retries internally). Add one line:

```dart
if (state is DataInitSuccess) {
  _autoCloseTimer?.cancel();  // defensive: cancel any pending auto-close
  // … existing success body …
}
```

### 4.3 Removal of `onPipelineFailure` callbacks

In each of the three pages, the `DataRefreshOverlay.triggerRefresh(context, onPipelineFailure: …)` call is reduced to `DataRefreshOverlay.triggerRefresh(context)`. The `onPipelineSuccess` callback is also removed because the overlay already dispatches the BLoC refetches internally (`data_refresh_overlay.dart:147-153`) — the page-level success callback was redundant and is being deleted as part of the cleanup.

### 4.4 Why no widget change is needed

The existing `DataInitProgressView` (lines 130-200) renders the failure UI identically regardless of mode. The overlay's "no buttons" UX is achieved by the overlay closing before the user could act, not by suppressing the buttons inside the view. The login flow passes `isFreshLogin: true` and the view still shows buttons because the overlay never auto-closes for that flow.

---

## 5. Lifecycle Sequence (Pull-to-Refresh Failure)

```
1. User pull-to-refresh on Home / Jadwal / Profile.
2. onRefresh() calls DataRefreshOverlay.triggerRefresh(context).
3. triggerRefresh loads credentials from AcademicCacheService.
4. triggerRefresh awaits show() — full-screen modal opens.
5. DataRefreshOverlay mounts → postFrame callback dispatches
   DataInitReset + DataInitStarted(forceRefresh: true).
6. DataInitBloc emits DataInitInProgress(downloadingKrs, …) — spinner visible.
7. Pipeline fails → DataInitBloc emits DataInitFailure(message, failedStep).
8. DataRefreshOverlay BlocListener sees DataInitFailure:
   - isFreshLogin == false → start 3-second Timer, return.
9. User sees error view (icon + title + step badge + message + hint) for 3s.
10. Timer fires → mounted check → Navigator.of(context).pop().
11. Overlay dismisses with the showGeneralDialog's default 200ms fade-out.
12. No SnackBar. No callback invocation. Page state unchanged (Loaded).
13. User can pull-to-refresh again at any time.
```

**Edge cases handled:**
- `dispose()` cancels the timer if the widget is unmounted before the 3 s elapse (e.g., user navigates away).
- `mounted` check inside the timer callback guards against post-dispose pop attempts.
- `Success` after a `Failure` (impossible today, defensive): success branch cancels the pending timer.
- Login flow: `isFreshLogin == true` keeps the existing Retry/Close UX untouched.

---

## 6. Error Handling

No new error path is introduced. Failure messages still flow through:

- `DataInitBloc._onStarted` (data_initialization_bloc.dart:64-99) catches `DataInitStepException`, `TimeoutException`, and other errors; maps them through `ErrorHandler.toHumanReadable()`; emits `DataInitFailure(friendlyMessage, failedStep: step)`.
- The overlay reads `state.message` and `state.failedStep` for display.
- `AppErrorDisplay`, `BlocErrorHandler` mixin, `ErrorHandler.show()` — all unchanged and orthogonal to this spec.

---

## 7. Testing

### 7.1 Existing tests — must continue to pass

| Test file | Why it stays green |
|---|---|
| `test/features/jadwal/presentation/pages/jadwal_pull_refresh_test.dart` (V3-A/B/C) | Probes `RefreshProgressIndicator` visibility during gestur. Structure of `RefreshIndicator > child` is unchanged — the overlay lifecycle change does not affect scrollable geometry or AlwaysScrollable behavior. |
| `test/features/auth/...`, `test/features/notification/...`, etc. | No dependency on the changed files. |

### 7.2 New tests (one file, three cases)

`test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart` (new) covers:

1. **Pull-to-refresh failure auto-closes after 3 s** — instantiate `DataRefreshOverlay` directly (no `show()` / `triggerRefresh()` indirection — those are static helpers around `showGeneralDialog`), wrap it in a `BlocProvider<DataInitBloc>.value` with a stub `DataInitBloc` that emits `DataInitInProgress(downloadingKrs)` then `DataInitFailure('Server down', failedStep: 'downloadingKrs')`. Advance time by 3 s, assert `find.byType(DataInitProgressView)` is gone and the modal route is popped.

2. **Login failure does NOT auto-close** — pump `DataInitProgressView(isFreshLogin: true, …)` directly inside the test (bypassing `DataRefreshOverlay`) with a stub `DataInitBloc` that emits `DataInitFailure`. Advance time by 5 s, assert the `DataInitProgressView` is still on screen with Retry/Close buttons rendered. This guards the `isFreshLogin: true` branch inside `DataInitProgressView` and confirms that the auto-close logic is **specific to `DataRefreshOverlay`**, not to `DataInitProgressView`.

3. **Success still auto-closes within 500 ms** — emit `DataInitInProgress` then `DataInitSuccess`. Advance time by 1 s, assert the modal route is popped.

A hand-written `FakeDataInitBloc` is acceptable; no mocktail/mockito needed (matches the project's existing test conventions, see `test/helpers/test_di.dart`).

### 7.3 Manual smoke

- Run `flutter run` (or on MuMu emulator at `127.0.0.1:5557`).
- Login → Home.
- Toggle airplane mode → pull-to-refresh → confirm error view shows for 3 s → overlay fades out → no SnackBar.
- Turn off airplane mode → pull-to-refresh again → confirm normal success path.
- Logout → login again → toggle airplane mode immediately on the data-init screen → confirm Retry/Close buttons still appear (login flow unchanged).

---

## 8. Acceptance Criteria

1. ✅ Pull-to-refresh on Home / Jadwal / Profile, when the pipeline fails, shows the error view inside the overlay for **exactly 3 seconds**, then auto-closes with the existing fade-out transition.
2. ✅ No `ScaffoldMessenger.showSnackBar` is invoked anywhere along the pull-to-refresh failure path.
3. ✅ The overlay provides no Retry / Close buttons in pull-to-refresh mode (they remain visible in login mode).
4. ✅ Login flow (`isFreshLogin: true`) is **byte-for-byte unchanged** in failure handling: stays visible with Retry/Close buttons.
5. ✅ `flutter analyze` reports 0 errors.
6. ✅ `flutter test` reports all tests passing (existing + new).
7. ✅ `data_refresh_overlay.dart` becomes a `StatefulWidget` with a single `Timer? _autoCloseTimer` field; `dispose` cancels the timer.
8. ✅ `home_page.dart`, `jadwal_page.dart`, `profile_page.dart` no longer pass `onPipelineFailure` to `DataRefreshOverlay.triggerRefresh` (the callback is now dead code and removed).
9. ✅ `DataRefreshOverlay.show()` and `DataRefreshOverlay.triggerRefresh()` signatures remain backward-compatible.

---

## 9. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Timer leak if widget unmounts before 3 s | Low | Low (debug-only leak) | `dispose` cancels the timer. |
| `Success` arrives after a `Failure` somehow | Very low | Medium (overlay would not close) | Defensive `_autoCloseTimer?.cancel()` in success branch. |
| User cannot retry without re-pulling | By design | Low | Hint text in the error view already says "Coba lagi nanti"; user re-pulls. |
| Existing pull-to-refresh test breaks | Low | Medium (regression) | Tests will be run after the change. If they fail, root-cause and adjust test or implementation. |
| BLoC refresh still silently swallows errors | Out of scope | None (intentional, pre-existing) | Documented as not in scope; future spec may revisit. |

---

## 10. Out of Scope (Explicit Non-Goals)

- BLoC-level refresh-error UI (`JadwalBloc` / `HomeBloc` / `ProfileBloc` swallow errors). Kept silent intentionally.
- `ErrorHandler.show()` (Toast) integration into the refresh path.
- Replacing `DataRefreshOverlay` with a different widget family.
- Retry SnackBar pattern (proposed in bugfix audit Task 23 / Finding #31). Superseded by this spec.
- iOS-specific overlay behavior (only Android is tested on this project).

---

## 11. Rollback Plan

If the new behavior causes user confusion in production, revert the single commit that converts `DataRefreshOverlay` to `StatefulWidget` and removes the three `onPipelineFailure` closures. Net result: returns to the current "stay visible + Retry/Close + SnackBar after Close" behavior. No data loss risk; no migration required.
