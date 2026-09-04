# Pull-Refresh Debounce 1 per 2 Minutes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rolling 2-RPM throttle on `DataInitializationRemoteDataSource.initialize()` with a resettable 2-minute debounce, and remove the `onRetry`/`onClose` buttons from the pull-refresh error view.

**Architecture:** Single in-memory `PullRefreshDebounce` tracker (1 timestamp per NPM, 2-min window) replaces the list-based `PullRefreshThrottle`. The `_initializeHeavy`/`_initializeLight` split from commit `7cef42a` stays intact; only the tracker is swapped. `DataRefreshOverlay` stops forwarding `onRetry`/`onClose` callbacks to `DataInitProgressView`. Login flow is untouched.

**Tech Stack:** Flutter (Dart), Hive cache (read-only — credentials), GoRouter, BLoC, custom service locator (`Services` in `lib/core/di/di.dart`).

**Spec:** `docs/superpowers/specs/2026-09-05-pull-refresh-debounce-design.md` (commit `5092755`).

## Global Constraints

- FE-only — never modify `lonceng_unman_be`.
- Per-NPM keyed; in-memory; restart = reset.
- Login flow (`isPullRefresh: false`) is NEVER consulted by the debounce.
- Use `debugPrint` from `package:flutter/foundation.dart` (NOT `developer.log`).
- Hand-written fakes only (no mockito/mocktail).
- `flutter analyze` clean; targeted `flutter test` runs (scope = `test/features/data_initialization/**`, `test/features/auth/presentation/pages/login_page_test.dart`, `test/router/**`, `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart`).
- API base URL unchanged: production default, `--dart-define=API_BASE_URL=…` for local dev.
- No new dependencies; no `pubspec.yaml` change.
- No Hive/SharedPreferences persistence for the debounce.

## File Map

Created:
- `lib/features/data_initialization/data/services/pull_refresh_debounce.dart` — `PullRefreshDebounce` class.
- `test/features/data_initialization/data/services/pull_refresh_debounce_test.dart` — debounce unit tests.

Modified:
- `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart` — swap `_throttle` for `_debounce`, rename `shouldThrottle` call site to `shouldUseLight`. The rest of the file stays byte-identical to commit `7cef42a`.
- `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart` — pass `onRetry: null, onClose: null` to `DataInitProgressView` (line 220-228 area).
- `lib/main.dart` — register `PullRefreshDebounce` instead of `PullRefreshThrottle`; pass to datasource via the constructor-fallback already present.
- `test/features/data_initialization/data/datasources/data_initialization_remote_data_source_light_branch_test.dart` — replace `_FakeThrottle` with `_FakeDebounce` matching the new method name `shouldUseLight`.

Deleted:
- `lib/features/data_initialization/data/services/pull_refresh_throttle.dart`
- `test/features/data_initialization/data/services/pull_refresh_throttle_test.dart`

---

## Task 1: Add `PullRefreshDebounce` tracker + failing tests

**Files:**
- Create: `lib/features/data_initialization/data/services/pull_refresh_debounce.dart`
- Create: `test/features/data_initialization/data/services/pull_refresh_debounce_test.dart`

**Interfaces:**
- Produces: `class PullRefreshDebounce` with `PullRefreshDebounce({DateTime Function()? clock})`, `static const window = Duration(minutes: 2)`, `bool shouldUseLight(String npm, [DateTime? now])`, `void recordHeavy(String npm, [DateTime? now])`. Pure Dart; only `DateTime`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/data_initialization/data/services/pull_refresh_debounce_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/services/pull_refresh_debounce.dart';

void main() {
  late DateTime now;
  late PullRefreshDebounce debounce;

  setUp(() {
    now = DateTime(2026, 9, 5, 12, 0, 0);
    debounce = PullRefreshDebounce(clock: () => now);
  });

  group('PullRefreshDebounce', () {
    test('hit pertama (belum ada catatan) → shouldUseLight == false', () {
      expect(debounce.shouldUseLight('npm1'), isFalse);
    });

    test('recordHeavy lalu cek dalam 120s → shouldUseLight == true', () {
      debounce.recordHeavy('npm1', now);
      now = now.add(const Duration(seconds: 30));
      expect(debounce.shouldUseLight('npm1'), isTrue);
    });

    test('tepat 119s → true; tepat 120s → false (boundary)', () {
      debounce.recordHeavy('npm1', now);
      now = now.add(const Duration(seconds: 119));
      expect(debounce.shouldUseLight('npm1'), isTrue,
          reason: '< window (120s) → light');
      now = now.add(const Duration(seconds: 1));
      expect(debounce.shouldUseLight('npm1'), isFalse,
          reason: '>= window → boleh berat');
    });

    test('recordHeavy kedua dalam window → reset timestamp', () {
      debounce.recordHeavy('npm1', now);
      now = now.add(const Duration(seconds: 30));
      expect(debounce.shouldUseLight('npm1'), isTrue);
      debounce.recordHeavy('npm1', now);
      now = now.add(const Duration(seconds: 40));
      expect(debounce.shouldUseLight('npm1'), isTrue,
          reason: '70s dari reset t=30, masih < 120s');
      now = now.add(const Duration(seconds: 80));
      expect(debounce.shouldUseLight('npm1'), isFalse,
          reason: '150s dari reset t=30, >= 120s');
    });

    test('NPM berbeda terisolasi', () {
      debounce.recordHeavy('npm1', now);
      now = now.add(const Duration(seconds: 10));
      expect(debounce.shouldUseLight('npm1'), isTrue);
      expect(debounce.shouldUseLight('npm2'), isFalse,
          reason: 'npm2 belum pernah trigger');
    });

    test('recordHeavy setelah lewat window → boleh berat (false)', () {
      debounce.recordHeavy('npm1', now);
      now = now.add(const Duration(minutes: 2));
      expect(debounce.shouldUseLight('npm1'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails (file does not exist yet)**

Run: `flutter test test/features/data_initialization/data/services/pull_refresh_debounce_test.dart`
Expected: compile error — `Target of URI doesn't exist: 'package:lonceng_unman_fe/features/data_initialization/data/services/pull_refresh_debounce.dart'`.

- [ ] **Step 3: Write the implementation**

Create `lib/features/data_initialization/data/services/pull_refresh_debounce.dart`:

```dart
/// Pelacak debounce pull-refresh: 1 jalur berat per 2 menit per NPM.
///
/// - [shouldUseLight] true bila ada catatan jalur berat dalam 120 detik
///   terakhir. NULL (belum pernah trigger) = tidak throttled.
/// - [recordHeavy] dipanggil saat jalur berat DIMULAI; update timestamp
///   ke waktu trigger itu (debounce reset).
/// - In-memory saja; restart app = reset.
/// - Jam via parameter opsional agar unit-test deterministik.
class PullRefreshDebounce {
  PullRefreshDebounce({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, DateTime> _lastHeavyHit = {};

  static const window = Duration(minutes: 2);

  bool shouldUseLight(String npm, [DateTime? now]) {
    final t = now ?? _clock();
    final last = _lastHeavyHit[npm];
    if (last == null) return false;
    return t.difference(last) < window;
  }

  void recordHeavy(String npm, [DateTime? now]) {
    _lastHeavyHit[npm] = now ?? _clock();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/data_initialization/data/services/pull_refresh_debounce_test.dart`
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/data_initialization/data/services/pull_refresh_debounce.dart \
        test/features/data_initialization/data/services/pull_refresh_debounce_test.dart
git commit -m "feat(data-init): add PullRefreshDebounce tracker (1 per 2 min)"
```

---

## Task 2: Delete old `PullRefreshThrottle` files

**Files:**
- Delete: `lib/features/data_initialization/data/services/pull_refresh_throttle.dart`
- Delete: `test/features/data_initialization/data/services/pull_refresh_throttle_test.dart`

- [ ] **Step 1: Remove files**

```bash
git rm lib/features/data_initialization/data/services/pull_refresh_throttle.dart
git rm test/features/data_initialization/data/services/pull_refresh_throttle_test.dart
```

- [ ] **Step 2: Verify compile still works (other files still import the old class)**

Run: `flutter analyze lib/features/data_initialization lib/main.dart 2>&1 | tail -n 20`
Expected: errors referencing `PullRefreshThrottle` in `data_initialization_remote_data_source.dart` and `main.dart`. These are expected — Task 3 fixes them.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(data-init): remove old PullRefreshThrottle (replaced by debounce)"
```

---

## Task 3: Wire `PullRefreshDebounce` into the datasource

**Files:**
- Modify: `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart`
- Modify: `lib/main.dart`

**Interfaces (consumed from Task 1):**
- `PullRefreshDebounce({DateTime Function()? clock})` — singleton registered in DI.
- `bool shouldUseLight(String npm, [DateTime? now])`
- `void recordHeavy(String npm, [DateTime? now])`

- [ ] **Step 1: Replace throttle field with debounce**

In `lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart`:

- Find the import block at the top. Replace
  `import '.../pull_refresh_throttle.dart';`
  with
  `import '.../pull_refresh_debounce.dart';`
  (Use the actual file name; the ellipsis above is for clarity only.)

- Find the constructor. Replace the field assignment
  `final PullRefreshThrottle _throttle;` → `final PullRefreshDebounce _debounce;`
  and the constructor parameter
  `PullRefreshThrottle? throttle` → `PullRefreshDebounce? debounce`,
  and the initializer
  `throttle ?? Services.get<PullRefreshThrottle>()` →
  `debounce ?? Services.get<PullRefreshDebounce>()`.

- [ ] **Step 2: Update dispatcher call sites**

In the same file, find `initialize({...})` and `_initializeLight`/`_initializeHeavy` and rename:

- `_throttle.shouldThrottle(npm)` → `_debounce.shouldUseLight(npm)`
- `_throttle.recordHeavy(npm)` → `_debounce.recordHeavy(npm)`

Update the inline doc comment near the dispatcher to read
`// debounce.shouldUseLight(npm)?` (no functional change; just matches the spec).

- [ ] **Step 3: Update `main.dart` registration**

In `lib/main.dart`, find the `Services.register<PullRefreshThrottle>(PullRefreshThrottle())`
call (added in commit `7cef42a`).

- Replace the type name with `PullRefreshDebounce` and the constructor call with `PullRefreshDebounce()`. The import at the top of `main.dart` must be updated to point to `pull_refresh_debounce.dart` instead of `pull_refresh_throttle.dart`.
- The `DataInitializationRemoteDataSource` constructor call passes a named parameter; if it was named `throttle:`, rename it to `debounce:`. The value can be `Services.get<PullRefreshDebounce>()` or omitted (the constructor-fallback already handles it).

- [ ] **Step 4: Run analyze on touched files**

Run: `flutter analyze lib/features/data_initialization lib/main.dart 2>&1 | tail -n 20`
Expected: no errors, no new warnings related to the rename.

- [ ] **Step 5: Run targeted datasource tests to confirm no regression**

Run: `flutter test test/features/data_initialization/data/datasources/data_initialization_remote_data_source_light_branch_test.dart --timeout 60s 2>&1 | tail -n 10`
Expected: COMPILE ERROR — the test still references `_FakeThrottle extends PullRefreshThrottle`. This is expected; Task 4 fixes it.

- [ ] **Step 6: Commit**

```bash
git add lib/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart \
        lib/main.dart
git commit -m "refactor(data-init): swap throttle for debounce in datasource + DI"
```

---

## Task 4: Update datasource light-branch test to use `_FakeDebounce`

**Files:**
- Modify: `test/features/data_initialization/data/datasources/data_initialization_remote_data_source_light_branch_test.dart`

**Interfaces (consumed from Task 1):**
- `PullRefreshDebounce.shouldUseLight(npm, [now])` — overridable in the fake.
- `PullRefreshDebounce.recordHeavy(npm, [now])` — recordable in the fake.

- [ ] **Step 1: Replace `_FakeThrottle` with `_FakeDebounce`**

In the test file, find the class `_FakeThrottle extends PullRefreshThrottle` (around line 110, from commit `7cef42a`).

Replace the import `pull_refresh_throttle.dart` with `pull_refresh_debounce.dart`.

Replace the class:

```dart
class _FakeDebounce extends PullRefreshDebounce {
  _FakeDebounce();

  bool useLight = false;
  int recordHeavyCalls = 0;
  int shouldUseLightCalls = 0;
  DateTime? _fakeNow;

  @override
  bool shouldUseLight(String npm, [DateTime? now]) {
    shouldUseLightCalls++;
    return useLight;
  }

  @override
  void recordHeavy(String npm, [DateTime? now]) {
    recordHeavyCalls++;
  }
}
```

- [ ] **Step 2: Update existing tests to use `_FakeDebounce` and assert new method name**

In each test, replace
- `final debounce = _FakeThrottle();` → `final debounce = _FakeDebounce();`
- `debounce.useLight` and `debounce.recordHeavyCalls` (already named the same)
- `debounce.shouldThrottleCalls` → `debounce.shouldUseLightCalls`
- `DataInitializationRemoteDataSource(throttle: debounce)` →
  `DataInitializationRemoteDataSource(debounce: debounce)`

Verify that all existing assertions still hold: heavy method call counts are zero on the light branch, `recordHeavyCalls` is 1 on the unthrottled heavy branch, `shouldUseLightCalls` is 0 on the login path.

- [ ] **Step 3: Add a debounce-specific assertion test**

Add a new test to the same file's `main()` block:

```dart
test('recordHeavy hanya dipanggil untuk pull-refresh, tidak untuk login', () async {
  final debounce = _FakeDebounce();
  final ds = _buildDataSource(debounce: debounce);
  // Login path: isPullRefresh false.
  await ds.initialize(
    npm: 'n', password: 'p', forceRefresh: true, isPullRefresh: false,
  ).toList();
  expect(debounce.shouldUseLightCalls, 0, reason: 'login tidak boleh dicek');
  expect(debounce.recordHeavyCalls, 0, reason: 'login tidak boleh catat');

  // Pull-refresh path (heavy): catat 1.
  debounce.useLight = false;
  await ds.initialize(
    npm: 'n', password: 'p', forceRefresh: true, isPullRefresh: true,
  ).toList();
  expect(debounce.recordHeavyCalls, 1);

  // Pull-refresh path (light): tidak catat.
  debounce.recordHeavyCalls = 0;
  debounce.useLight = true;
  await ds.initialize(
    npm: 'n', password: 'p', forceRefresh: true, isPullRefresh: true,
  ).toList();
  expect(debounce.recordHeavyCalls, 0);
});
```

(The `_buildDataSource` helper is whatever helper the existing test file uses to construct the datasource with all fakes. If the file does not have a single helper, construct it inline as the other tests do.)

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/data_initialization/data/datasources/data_initialization_remote_data_source_light_branch_test.dart --timeout 60s 2>&1 | tail -n 10`
Expected: All tests pass (8 existing + 1 new = 9 total).

- [ ] **Step 5: Commit**

```bash
git add test/features/data_initialization/data/datasources/data_initialization_remote_data_source_light_branch_test.dart
git commit -m "test(data-init): use FakeDebounce + assert login never consults debounce"
```

---

## Task 5: Remove Retry/Close buttons from pull-refresh overlay

**Files:**
- Modify: `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart` (line 220-228 area)

- [ ] **Step 1: Read the current overlay's `DataInitProgressView` instantiation**

Confirm the call (around line 220 of `data_refresh_overlay.dart`) passes `onRetry:` and `onClose:` callbacks. Both currently dispatch `_dispatchPipeline` / pop the navigator and call `onPipelineFailure`.

- [ ] **Step 2: Pass `null` for both callbacks**

Replace the `DataInitProgressView` constructor call with:

```dart
DataInitProgressView(
  isFreshLogin: false,
  onRetry: null,
  onClose: null,
),
```

Delete the now-unused inline closures if they are not referenced anywhere else in the file. (Check the `Builder` body — the closures may still be reachable; if so, leave them dead but the widget itself no longer takes them.)

- [ ] **Step 3: Verify analyze is clean**

Run: `flutter analyze lib/features/data_initialization 2>&1 | tail -n 10`
Expected: no new warnings about unused closures (the closures were inlined callbacks; deleting them is the correct cleanup, not "leave them as dead code").

- [ ] **Step 4: Add a widget test that asserts no buttons appear**

If a test file `test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart` exists, extend it. If not, create it:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_refresh_overlay.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_bloc.dart';

// Hand-rolled stubs: provide non-null values for the refetch BLoCs the
// overlay reaches on success; supply a GetDataInitialization that immediately
// emits DataInitFailure.

void main() {
  testWidgets('DataRefreshOverlay error view: TIDAK ada tombol apapun', (tester) async {
    final bloc = _FailingBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<DataInitBloc>.value(value: bloc),
            BlocProvider<HomeBloc>.value(value: _NoopHomeBloc()),
            BlocProvider<JadwalBloc>.value(value: _NoopJadwalBloc()),
            BlocProvider<ProfileBloc>.value(value: _NoopProfileBloc()),
          ],
          child: const DataRefreshOverlay(
            npm: '2211700006',
            password: 'Izzan027',
          ),
        ),
      ),
    );

    // Pump for post-frame + first stream emission.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    // Failure emitted → error view rendered.
    expect(bloc.state, isA<DataInitFailure>());
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    // Bukti: TIDAK ada tombol.
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Coba Lagi'), findsNothing);
    expect(find.text('Tutup'), findsNothing);
  });
}
```

Provide minimal stub BLoCs and a `DataInitBloc` that immediately fails. The exact shape of those stubs is whatever the existing test scaffolding in the repo uses (e.g. a `FakeDataInitRepository` that yields `DataInitProgress.failed` first). If the existing `data_refresh_overlay_test.dart` already has a `FakeDataInitRepository` (likely added in commit `7cef42a`), reuse it.

- [ ] **Step 5: Run the new widget test**

Run: `flutter test test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart --timeout 60s 2>&1 | tail -n 10`
Expected: PASS.

- [ ] **Step 6: Run the full throttle-scope suite to confirm no regression**

Run: `flutter test test/features/data_initialization test/features/auth/presentation/pages/login_page_test.dart test/router --timeout 90s 2>&1 | tail -n 5`
Expected: all tests pass (count varies; previously 144/144; expect 144 ± the new debounce tests + the new overlay test, minus the deleted throttle tests).

- [ ] **Step 7: Commit**

```bash
git add lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart \
        test/features/data_initialization/presentation/widgets/data_refresh_overlay_test.dart
git commit -m "feat(overlay): remove Retry/Close buttons from pull-refresh error view"
```

---

## Task 6: Final gate — analyze + full throttle-scope test sweep

**Files:** none (verification only).

- [ ] **Step 1: Run `flutter analyze` on the whole project**

Run: `flutter analyze 2>&1 | tail -n 20`
Expected: 0 errors; pre-existing 3 info notes on `data_initialization_remote_data_source.dart` are unchanged.

- [ ] **Step 2: Run the full throttle-scope test sweep**

Run: `flutter test test/features/data_initialization test/features/auth test/features/notification test/router --timeout 90s 2>&1 | tail -n 5`
Expected: `All tests passed!` with the line `+N` showing the new test count.

- [ ] **Step 3: Verify no orphan files**

Run: `git status --short -- lib/ test/`
Expected: only the files modified by Tasks 1-5 appear; the two deleted files from Task 2 are gone.

- [ ] **Step 4: Verify final commit history**

Run: `git log --oneline -8`
Expected: Tasks 1-5 commits plus the spec commit `5092755` at the top of the older range; the head commit is the latest task commit (Task 5's commit message).

- [ ] **Step 5: Done**

No further code changes. The work ends here. Subsequent E2E verification (Patrol) is out of scope for this plan per the spec.
