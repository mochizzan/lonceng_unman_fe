# Pull-to-Refresh Error Handling — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When pull-to-refresh fails on Home / Jadwal / Profile, the existing full-screen `DataRefreshOverlay` shows the error view for 3 seconds then auto-closes with a fade-out. No SnackBar is shown afterwards. Login flow is unchanged.

**Architecture:** Convert `DataRefreshOverlay` from `StatelessWidget` to `StatefulWidget` and add a single `Timer? _autoCloseTimer` field. When `DataInitFailure` arrives in the existing `BlocListener`, start the timer; on expiry, `Navigator.pop()`. Cancel the timer in `dispose()` and in the success branch (defensive). Remove the now-dead `onPipelineFailure` and redundant `onPipelineSuccess` named arguments from the three pages. Add a widget test that exercises the auto-close path with a stub `DataInitBloc`.

**Tech Stack:** Flutter 3.x, Dart 3.12, BLoC 9.x, `flutter_test`, `bloc_test` (not needed here — we drive the BLoC directly).

---

## Global Constraints

- Dart SDK ^3.12.0
- Flutter (SDK)
- BLoC pattern for state management
- Clean Architecture (feature-based with presentation/data/domain layers)
- No new dependencies allowed — use existing packages only
- All changes must pass `flutter analyze` with 0 errors
- Frequent commits per task (1 commit per logical unit)
- No `developer.log` — use `debugPrint` from `package:flutter/foundation.dart`
- Run the `data_refresh_overlay` and `jadwal_pull_refresh` tests after every change; do not skip

---

## File Structure

| File | Responsibility | Change |
|------|----------------|--------|
| `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart` | Full-screen pull-to-refresh overlay | Modify: convert to StatefulWidget, add auto-close timer on `DataInitFailure` |
| `lib/features/home/presentation/pages/home_page.dart` | Home page | Modify: drop `onPipelineFailure` and `onPipelineSuccess` callbacks from `DataRefreshOverlay.triggerRefresh(...)` call |
| `lib/features/jadwal/presentation/pages/jadwal_page.dart` | Jadwal page | Same callback cleanup |
| `lib/features/profile/presentation/pages/profile_page.dart` | Profile page | Same callback cleanup |
| `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart` | Widget tests for overlay auto-close | **Create** |

No new files outside the test directory. No new dependencies.

---

## Task Decomposition Rationale

| Task | Why its own task |
|------|------------------|
| **Task 1**: Write failing test for pull-to-refresh auto-close | Establishes the new behavior contract before any production change. Reviewer can reject the test design independently. |
| **Task 2**: Convert `DataRefreshOverlay` to StatefulWidget + add auto-close timer | The single source-of-truth production change. Lands in one reviewable commit. |
| **Task 3**: Add the two regression-coverage tests (login does NOT auto-close; success still auto-closes) | Locks down the two adjacent contracts that share the same widget. |
| **Task 4**: Remove dead `onPipelineFailure` / redundant `onPipelineSuccess` callbacks from 3 pages | Pure cleanup, mechanically separate. Can be reviewed as a "diff only" change. |
| **Task 5**: Run full `flutter analyze` + `flutter test` | Independent verification gate. |

Tasks 1 + 2 = one TDD cycle. Task 3 = second TDD cycle on adjacent behaviors. Task 4 = dead-code cleanup. Task 5 = final verification.

---

## Task 1: Add Failing Test for Pull-to-Refresh Auto-Close on Failure

**Files:**
- Create: `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`

**Interfaces:**
- Consumes: `DataRefreshOverlay` widget (constructor: `npm`, `password`, `onPipelineFailure`, `onPipelineSuccess`).
- Consumes: `DataInitBloc` (existing) — we use a hand-written `FakeDataInitBloc` that emits `DataInitInProgress` then `DataInitFailure` on demand.
- Produces: Widget test asserting the modal route is popped after 3 s.

**Stub design (hand-written, no mocktail):**

The fake bloc needs to expose a way to emit states. The simplest pattern is a `Bloc<DataInitEvent, DataInitBlocState>` subclass with an `emitNow(state)` helper for the test.

```dart
class _FakeDataInitBloc extends Bloc<DataInitEvent, DataInitBlocState> {
  _FakeDataInitBloc(super.initialState);

  void emitNow(DataInitBlocState state) => emit(state);
}
```

- [ ] **Step 1: Create the test file with the test scaffold**

Create `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart` with these imports and the test signature. The test will fail because `DataRefreshOverlay` does not yet have a 3-second auto-close on `DataInitFailure`.

```dart
// test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart
//
// Verifies the failure-path lifecycle of DataRefreshOverlay:
//   1. Pull-to-refresh failure auto-closes the overlay after 3 seconds.
//   2. Login-flow failure does NOT auto-close (no timer arms).
//   3. Success still auto-closes within ~500 ms (existing behavior preserved).
//
// The widget is pumped directly (not through show() / triggerRefresh() which
// wrap showGeneralDialog) to keep the test synchronous and free of credentials.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_progress_view.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_refresh_overlay.dart';

class _FakeDataInitBloc extends Bloc<DataInitEvent, DataInitBlocState> {
  _FakeDataInitBloc(super.initialState);

  void emitNow(DataInitBlocState state) => emit(state);
}

Future<_FakeDataInitBloc> _pumpOverlay(
  WidgetTester tester, {
  required DataInitBlocState initial,
}) async {
  final bloc = _FakeDataInitBloc(initial);
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<DataInitBloc>.value(
        value: bloc,
        child: const DataRefreshOverlay(),
      ),
    ),
  );
  return bloc;
}

void main() {
  testWidgets(
    'pull-to-refresh failure auto-closes overlay after 3 seconds',
    (tester) async {
      // 1. Mount the overlay. State starts as in-progress (spinner visible).
      final bloc = await _pumpOverlay(
        tester,
        initial: const DataInitInProgress(DataInitStatus.downloadingKrs),
      );
      expect(find.byType(DataInitProgressView), findsOneWidget);

      // 2. Pipeline fails.
      bloc.emitNow(
        const DataInitFailure(
          'Server sedang tidak tersedia',
          failedStep: 'downloadingKrs',
        ),
      );
      await tester.pump();

      // 3. Error view is rendered.
      expect(
        find.text('Server sedang tidak tersedia'),
        findsOneWidget,
        reason: 'Error message from DataInitFailure should be shown.',
      );

      // 4. After 2 seconds the overlay is still visible.
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(DataInitProgressView), findsOneWidget);

      // 5. After 3 seconds total, the overlay has been popped.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        find.byType(DataInitProgressView),
        findsNothing,
        reason: 'Overlay should auto-close 3 seconds after DataInitFailure.',
      );
    },
  );
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`

Expected: **FAIL** with `Expected: exactly one widget`, `Actual: ?[]` — the overlay never auto-closes today because the production code's `DataInitFailure` branch only logs and waits for user action.

- [ ] **Step 3: Commit the failing test**

```bash
git add test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart
git commit -m "test(data-init): add failing test for pull-to-refresh auto-close

The test mounts DataRefreshOverlay directly, drives a fake
DataInitBloc to emit DataInitFailure, and asserts the overlay
disappears 3 seconds later. Fails today because the production
code stays visible until the user taps a Close button."
```

---

## Task 2: Implement Auto-Close Timer in `DataRefreshOverlay`

**Files:**
- Modify: `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart`

**Interfaces:**
- Consumes: existing widget constructor (`npm`, `password`, `onPipelineFailure`, `onPipelineSuccess` — these stay for source compatibility but are now unused inside the pull-to-refresh path).
- Produces: a `StatefulWidget` that pops itself 3 seconds after `DataInitFailure` arrives.

- [ ] **Step 1: Convert `DataRefreshOverlay` to a `StatefulWidget` with a `Timer?` field**

Replace the entire file with the new implementation below. The widget body is byte-for-byte identical except for: (a) the `Timer?` field + `dispose`, (b) the `_autoCloseTimer?.cancel()` line in the success branch, (c) the new failure branch that arms the timer.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_progress_view.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_bloc.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_event.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_event.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';

/// Full-screen blocking overlay for data refresh progress.
/// Shows [DataInitProgressView] over a semi-transparent barrier.
/// On success, auto-dismisses in 500 ms.
/// On failure (pull-to-refresh), shows the error view for 3 seconds then
/// auto-closes — no SnackBar. Login flow uses [DataInitProgressView]
/// directly with `isFreshLogin: true` and is unaffected.
class DataRefreshOverlay extends StatefulWidget {
  const DataRefreshOverlay({
    super.key,
    this.npm,
    this.password,
    this.onPipelineFailure,
    this.onPipelineSuccess,
  });

  /// Optional credentials captured by [show]. When provided, the overlay
  /// dispatches the data-init pipeline itself once mounted — this guarantees
  /// the [BlocListener] below is alive before any state is emitted, so a
  /// fast-failing pipeline can still close the overlay.
  final String? npm;
  final String? password;

  /// Optional callback (no longer invoked in pull-to-refresh failure path;
  /// the overlay self-dismisses before this would fire). Retained for
  /// source compatibility with any future caller.
  final void Function(DataInitFailure failure)? onPipelineFailure;

  /// Optional callback invoked when the pipeline succeeds. Retained for
  /// source compatibility; the overlay already dispatches BLoC refetches
  /// internally on success.
  final VoidCallback? onPipelineSuccess;

  /// Shows the overlay as a full-screen, non-dismissible dialog.
  ///
  /// Returns a [Future] that completes when the overlay is dismissed
  /// (success or failure). Optional [npm]/[password] are forwarded to the
  /// dialog so it can drive the pipeline after mount.
  static Future<void> show(
    BuildContext context, {
    String? npm,
    String? password,
    void Function(DataInitFailure failure)? onPipelineFailure,
    VoidCallback? onPipelineSuccess,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Data Refresh',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return DataRefreshOverlay(
          npm: npm,
          password: password,
          onPipelineFailure: onPipelineFailure,
          onPipelineSuccess: onPipelineSuccess,
        );
      },
    );
  }

  /// Triggers data-init pipeline and shows overlay.
  ///
  /// Credentials are loaded up-front, then the overlay is awaited (so the
  /// [BlocListener] is guaranteed to be mounted) before the pipeline events
  /// are dispatched. This fixes a race where a fast-failing pipeline would
  /// emit [DataInitFailure] before the listener attached, leaving the
  /// overlay stuck on screen.
  static Future<void> triggerRefresh(
    BuildContext context, {
    void Function(DataInitFailure failure)? onPipelineFailure,
    VoidCallback? onPipelineSuccess,
  }) async {
    debugPrint('[DATA_REFRESH] triggerRefresh() START');

    final academicCache = Services.get<AcademicCacheService>();
    final credentials = await academicCache.loadCredentials();
    if (credentials == null || !context.mounted) {
      debugPrint(
        '[DATA_REFRESH] No credentials found or context unmounted — abort',
      );
      return;
    }

    final npm = credentials['npm'] ?? '';
    final password = credentials['password'] ?? '';
    debugPrint('[DATA_REFRESH] Credentials loaded: npm=$npm');

    if (context.mounted) {
      debugPrint('[DATA_REFRESH] Showing overlay (awaiting mount)');
      // Await show so the dialog route is fully built and its BlocListener
      // is mounted before we dispatch any events. The overlay owns the
      // pipeline lifecycle from this point on.
      await show(
        context,
        npm: npm,
        password: password,
        onPipelineFailure: onPipelineFailure,
        onPipelineSuccess: onPipelineSuccess,
      );
    }

    debugPrint('[DATA_REFRESH] triggerRefresh() END');
  }

  @override
  State<DataRefreshOverlay> createState() => _DataRefreshOverlayState();
}

class _DataRefreshOverlayState extends State<DataRefreshOverlay> {
  /// Auto-close timer armed when [DataInitFailure] arrives. Cancelled in
  /// [dispose] and defensively in the success branch.
  Timer? _autoCloseTimer;

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _dispatchPipeline(BuildContext innerContext) {
    if (widget.npm == null || widget.password == null) return;
    debugPrint(
      '[DATA_REFRESH] Dispatching DataInitReset + DataInitStarted from overlay',
    );
    innerContext.read<DataInitBloc>().add(const DataInitReset());
    innerContext.read<DataInitBloc>().add(
      DataInitStarted(
        npm: widget.npm!,
        password: widget.password!,
        forceRefresh: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<DataInitBloc, DataInitBlocState>(
      listener: (listenerContext, state) {
        // Only log on status changes, not every DataInitInProgress emission.
        final logState = state is DataInitInProgress
            ? state.status.name
            : state.runtimeType;
        debugPrint(
          '[DATA_REFRESH] State → $logState${state is DataInitInProgress ? ' (${state.detail ?? ''})' : ''}',
        );
        if (state is DataInitSuccess) {
          // Defensive: cancel any pending auto-close in case a Success
          // arrives after a Failure (would not happen today, but safe).
          _autoCloseTimer?.cancel();
          debugPrint('[DATA_REFRESH] Success — dismissing overlay in 500ms');
          // Trigger all BLoCs re-fetch after refresh
          try {
            listenerContext.read<JadwalBloc>().add(
              const JadwalFetchRequested(),
            );
            listenerContext.read<HomeBloc>().add(const HomeFetchRequested());
            listenerContext.read<ProfileBloc>().add(
              const ProfileFetchRequested(),
            );
            debugPrint(
              '[DATA_REFRESH] All BLoC refresh dispatched after refresh',
            );
          } catch (e) {
            debugPrint('[DATA_REFRESH] BLoC dispatch failed: $e');
          }
          // Notify optional success listener before dismissing.
          widget.onPipelineSuccess?.call();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (listenerContext.mounted) {
              Navigator.of(listenerContext).pop();
            }
          });
        } else if (state is DataInitFailure) {
          // Pull-to-refresh failure path: show the error view for 3 seconds
          // then auto-close. The overlay IS the error feedback; no SnackBar.
          // Login flow is unaffected because LoginPage does not instantiate
          // this widget — it mounts DataInitProgressView(isFreshLogin: true)
          // directly and that view still shows Retry/Cancel buttons.
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
      },
      child: Builder(
        builder: (innerContext) {
          // Kick off the pipeline from the first build of the overlay.
          // At this point BlocListener is already attached, so any state
          // emitted by the pipeline (including an instant DataInitFailure)
          // is guaranteed to be observed.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!innerContext.mounted) return;
            if (widget.npm == null || widget.password == null) return;
            _dispatchPipeline(innerContext);
          });

          return Material(
            color: cs.surface,
            child: DataInitProgressView(
              isFreshLogin: false,
              onRetry: () {
                debugPrint('[DATA_REFRESH] User tapped Retry');
                if (!innerContext.mounted) return;
                _dispatchPipeline(innerContext);
              },
              onClose: () {
                debugPrint('[DATA_REFRESH] User tapped Close');
                final navigator = Navigator.of(innerContext);
                final bloc = innerContext.read<DataInitBloc>();
                final lastState = bloc.state;
                navigator.pop();
                if (lastState is DataInitFailure &&
                    widget.onPipelineFailure != null) {
                  widget.onPipelineFailure!(lastState);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Run the test from Task 1 to verify it now passes**

Run: `flutter test test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`

Expected: **PASS** — the overlay is gone after 3 s of pump time.

- [ ] **Step 3: Run `flutter analyze`**

Run: `flutter analyze lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart`

Expected: 0 errors, 0 warnings. (The `npm` and `password` instance reads replaced with `widget.npm` and `widget.password` because we are now inside a `State`.)

- [ ] **Step 4: Commit**

```bash
git add lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart
git commit -m "feat(data-init): auto-close pull-to-refresh overlay on failure

Convert DataRefreshOverlay to StatefulWidget and arm a 3-second
Timer on DataInitFailure. The error view is shown for 3 s then
Navigator.pop() is called. No SnackBar is invoked.

Defensive: the timer is cancelled in dispose() and in the success
branch. The onPipelineFailure / onPipelineSuccess named parameters
are retained for source compatibility but are no longer invoked
by the pull-to-refresh path."
```

---

## Task 3: Add Regression Tests for Adjacent Behaviors

**Files:**
- Modify: `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`

**Interfaces:**
- Consumes: `DataRefreshOverlay` (pumped directly), `DataInitProgressView` (pumped directly with `isFreshLogin: true`), `DataInitBloc` event/state classes.
- Produces: two more `testWidgets` entries.

- [ ] **Step 1: Append the "login does NOT auto-close" test**

Append this inside the `void main() { ... }` block in the test file created in Task 1:

```dart
  testWidgets(
    'login failure (isFreshLogin: true) does NOT auto-close the view',
    (tester) async {
      // Mount DataInitProgressView directly in login mode (the actual login
      // path uses this widget, not DataRefreshOverlay).
      final bloc = _FakeDataInitBloc(
        const DataInitInProgress(DataInitStatus.scrapingProfile),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DataInitBloc>.value(
            value: bloc,
            child: const DataInitProgressView(
              isFreshLogin: true,
              onRetry: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Pipeline fails.
      bloc.emitNow(
        const DataInitFailure('Gagal memuat profil', failedStep: 'profile'),
      );
      await tester.pump();

      // Error view is rendered with both action buttons.
      expect(
        find.text('Gagal memuat profil'),
        findsOneWidget,
      );
      expect(
        find.text('Coba lagi'),
        findsOneWidget,
        reason: 'Login flow keeps the Retry button.',
      );
      expect(
        find.text('Tutup'),
        findsOneWidget,
        reason: 'Login flow keeps the Close button.',
      );

      // After 5 seconds the view is still on screen — no auto-close in
      // login mode. This is the behavior the spec requires to stay
      // byte-for-byte unchanged.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(
        find.byType(DataInitProgressView),
        findsOneWidget,
        reason: 'Login failure must not auto-close.',
      );
    },
  );
```

- [ ] **Step 2: Append the "success still auto-closes" test**

```dart
  testWidgets(
    'success auto-closes the overlay within ~500 ms',
    (tester) async {
      final bloc = await _pumpOverlay(
        tester,
        initial: const DataInitInProgress(DataInitStatus.downloadingKrs),
      );

      // Pipeline succeeds.
      bloc.emitNow(const DataInitSuccess());
      await tester.pump();

      // After 1 second (well past the 500 ms delay) the overlay is gone.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        find.byType(DataInitProgressView),
        findsNothing,
        reason: 'Success path must still auto-dismiss within 500 ms.',
      );
    },
  );
```

- [ ] **Step 3: Run the three tests**

Run: `flutter test test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`

Expected: **3 passed**. The first two were already passing after Task 2; the new "login does NOT auto-close" test confirms `DataInitProgressView` (used by login) is unaffected.

- [ ] **Step 4: Commit**

```bash
git add test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart
git commit -m "test(data-init): cover login-doesn't-autoclose and success-autoclose

Two regression tests added:

- Login (isFreshLogin=true) keeps Retry/Close buttons and does
  not auto-close, even after 5 s of pump time.
- Success path still auto-closes within 500 ms (existing
  behavior preserved)."
```

---

## Task 4: Remove Dead `onPipelineFailure` and Redundant `onPipelineSuccess` Callbacks

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Modify: `lib/features/jadwal/presentation/pages/jadwal_page.dart`
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`

**Interfaces:**
- Consumes: the existing `DataRefreshOverlay.triggerRefresh(context, …)` calls.
- Produces: cleaner call sites that no longer pass dead/redundant callbacks.

- [ ] **Step 1: Update `home_page.dart`**

In `lib/features/home/presentation/pages/home_page.dart`, locate the `onRefresh` callback inside `_buildContent` (around lines 150-172). Replace:

```dart
      onRefresh: () async {
        debugPrint('[HOME] Pull-to-refresh triggered');
        try {
          await DataRefreshOverlay.triggerRefresh(
            context,
            onPipelineFailure: (failure) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(failure.message),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          );
        } catch (e) {
          // Error surfaced by the overlay itself; no extra snackbar here.
          debugPrint('[HOME] Pull-to-refresh error: $e');
        }
      },
```

with:

```dart
      onRefresh: () async {
        debugPrint('[HOME] Pull-to-refresh triggered');
        try {
          await DataRefreshOverlay.triggerRefresh(context);
        } catch (e) {
          // Error surfaced by the overlay itself; no extra snackbar here.
          debugPrint('[HOME] Pull-to-refresh error: $e');
        }
      },
```

- [ ] **Step 2: Update `jadwal_page.dart`**

In `lib/features/jadwal/presentation/pages/jadwal_page.dart`, locate the `onRefresh` callback (around lines 90-107). Replace:

```dart
      onRefresh: () async {
        debugPrint('[JADWAL] Pull-to-refresh triggered');
        await DataRefreshOverlay.triggerRefresh(
          context,
          onPipelineFailure: (failure) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
        if (!context.mounted) return;
        context.read<JadwalBloc>().add(const JadwalRefreshRequested());
      },
```

with:

```dart
      onRefresh: () async {
        debugPrint('[JADWAL] Pull-to-refresh triggered');
        await DataRefreshOverlay.triggerRefresh(context);
        if (!context.mounted) return;
        context.read<JadwalBloc>().add(const JadwalRefreshRequested());
      },
```

- [ ] **Step 3: Update `profile_page.dart`**

In `lib/features/profile/presentation/pages/profile_page.dart`, locate the `onRefresh` callback (around lines 320-348). Replace:

```dart
      onRefresh: () async {
        debugPrint('[PROFILE] Pull-to-refresh triggered');
        await DataRefreshOverlay.triggerRefresh(
          context,
          onPipelineFailure: (failure) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
        if (!context.mounted) return;
        context.read<ProfileBloc>().add(const ProfileRefreshRequested());
        // Refresh foto dari backend bersamaan dengan data akademik
        final academicCache = Services.get<AcademicCacheService>();
        final creds = await academicCache.loadCredentials();
        if (creds != null && context.mounted) {
          final npm = creds['npm'] ?? '';
          final password = creds['password'] ?? '';
          if (npm.isNotEmpty && password.isNotEmpty) {
            context.read<AvatarCubit>().fetchFromBackend(
              npm: npm,
              password: password,
            );
          }
        }
      },
```

with:

```dart
      onRefresh: () async {
        debugPrint('[PROFILE] Pull-to-refresh triggered');
        await DataRefreshOverlay.triggerRefresh(context);
        if (!context.mounted) return;
        context.read<ProfileBloc>().add(const ProfileRefreshRequested());
        // Refresh foto dari backend bersamaan dengan data akademik
        final academicCache = Services.get<AcademicCacheService>();
        final creds = await academicCache.loadCredentials();
        if (creds != null && context.mounted) {
          final npm = creds['npm'] ?? '';
          final password = creds['password'] ?? '';
          if (npm.isNotEmpty && password.isNotEmpty) {
            context.read<AvatarCubit>().fetchFromBackend(
              npm: npm,
              password: password,
            );
          }
        }
      },
```

- [ ] **Step 4: Run `flutter analyze` on the three files**

Run: `flutter analyze lib/features/home/presentation/pages/home_page.dart lib/features/jadwal/presentation/pages/jadwal_page.dart lib/features/profile/presentation/pages/profile_page.dart`

Expected: 0 errors, 0 warnings.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/pages/home_page.dart lib/features/jadwal/presentation/pages/jadwal_page.dart lib/features/profile/presentation/pages/profile_page.dart
git commit -m "refactor(home,jadwal,profile): drop dead pull-to-refresh callbacks

The onPipelineFailure closure (SnackBar on pipeline failure) is
now dead code because DataRefreshOverlay auto-closes before the
callback would fire. The onPipelineSuccess closure was already
redundant — the overlay dispatches BLoC refetches internally on
DataInitSuccess. Both are removed."
```

---

## Task 5: Full Verification

**Files:** None — verification only.

- [ ] **Step 1: Run `flutter analyze`**

Run: `flutter analyze`

Expected: 0 errors, 0 warnings.

- [ ] **Step 2: Run the new overlay test file**

Run: `flutter test test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`

Expected: 3 tests pass.

- [ ] **Step 3: Run the existing pull-to-refresh test file**

Run: `flutter test test/features/jadwal/presentation/pages/jadwal_pull_refresh_test.dart`

Expected: 3 tests pass (V3-A, V3-B, V3-C). The structure of `RefreshIndicator > child` is unchanged, so the spinner-visibility probe should still pass.

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`

Expected: all tests pass. ~205+ test cases. No regressions.

- [ ] **Step 5: Manual smoke test on emulator**

- `flutter run` on the MuMu Player emulator at `127.0.0.1:5557` (or `127.0.0.1:5555`).
- Login → Home.
- Toggle airplane mode → pull-to-refresh on Home → confirm the error view shows for ~3 s → overlay fades out → no SnackBar.
- Turn off airplane mode → pull-to-refresh again → confirm normal success path.
- Switch to Jadwal tab → pull-to-refresh → confirm same auto-close behavior.
- Switch to Profile tab → pull-to-refresh → confirm same auto-close behavior (and avatar refreshes after the pipeline).
- Logout → login again → toggle airplane mode immediately on the data-init screen → confirm Retry/Cancel buttons still appear (login flow unchanged).

- [ ] **Step 6: Commit any test-only fixups**

If any of the steps above required a code fix, commit with a focused message:

```bash
git add -A
git commit -m "fix(verify): test-only fixups from full-suite run"
```

(If no changes were needed, this step is a no-op.)

---

## Self-Review (post-write)

**1. Spec coverage:**

| Spec section | Covered by |
|---|---|
| §1 Goal items 1-4 | Task 2 (timer + state conversion) + Task 4 (callback removal) |
| §3.1 Files changed (5 rows) | Tasks 1, 2, 3, 4 |
| §3.2 Out of scope (BLoC, ErrorHandler, tests) | Explicitly untouched; no task created |
| §3.3 API contract preserved | `show()` and `triggerRefresh()` signatures kept verbatim; only the body of the widget changes |
| §4.1 State conversion | Task 2 step 1 |
| §4.2 Auto-close + defensive cancel | Task 2 step 1 (both branches present) |
| §4.3 Callback removal from 3 pages | Task 4 |
| §4.4 "Why no widget change" | Reflected in Task 1 test design (pump `DataInitProgressView` directly) |
| §5 Lifecycle sequence | All 13 steps covered by Task 2 (logic) + Task 3 (tests) |
| §6 Error handling | No new code path; preserved |
| §7.1 Existing tests still pass | Task 5 step 3 |
| §7.2 New tests (3 cases) | Task 1 (case 1) + Task 3 (cases 2 & 3) |
| §7.3 Manual smoke | Task 5 step 5 |
| §8 Acceptance criteria (9 items) | All mapped: 1-3 via Task 2; 4 (login unchanged) via Task 3 case 2; 5-6 via Task 5; 7 via Task 2; 8 via Task 4; 9 by signature preservation in Task 2 |
| §9 Risks | All mitigations honored (defensive cancel in Task 2, test coverage in Tasks 1+3) |
| §10 Out of scope | Confirmed: no task touches BLoC, `ErrorHandler.show()`, or iOS |
| §11 Rollback | Implicit in the four task commits — any one can be reverted |

**2. Placeholder scan:** No "TBD", no "TODO", no "implement later", no "similar to Task N". Every step shows the actual code or command.

**3. Type consistency:**
- `_FakeDataInitBloc` defined in Task 1, reused in Task 3 — same name, same `emitNow` API.
- `DataInitFailure(message, failedStep: …)` — signature matches the constructor in `data_initialization_state.dart`.
- `DataInitInProgress(DataInitStatus.downloadingKrs)` — uses a value from `DataInitStatus` enum, which is what the production code emits.
- `DataInitProgressView` constructor — `isFreshLogin`, `onRetry`, `onCancel` are all real parameters in the production widget.
- `DataRefreshOverlay` constructor — `npm` and `password` retained (unused in the test but harmless); the test passes no credentials so the post-frame `_dispatchPipeline` guard (`if (widget.npm == null || widget.password == null) return`) prevents an actual pipeline run.
- No name mismatches across tasks.

---

## Execution Order

```
Task 1 (failing test) → Task 2 (production change) → Task 3 (regression tests) → Task 4 (cleanup) → Task 5 (verify)
```

Tasks 1 and 2 form one TDD cycle. Task 3 must run after Task 2 because its tests depend on the timer behavior. Task 4 is mechanically independent but reads cleaner after Tasks 1-3 land. Task 5 is the final gate.

---

## Verification (after all tasks)

1. `flutter analyze` — 0 errors, 0 warnings.
2. `flutter test` — all tests pass (existing ~205 + 3 new in this plan).
3. Manual smoke on MuMu Player emulator at `127.0.0.1:5557` (Android 15) — see Task 5 step 5.
4. Confirm `git log` shows four clean task commits with conventional commit messages.

---

*Plan complete.*
