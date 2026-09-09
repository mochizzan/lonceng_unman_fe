# Remove "Selamat datang kembali" Resume SnackBar — Design

> **Status:** Approved (brainstorming complete, awaiting user review of this written spec)
> **Date:** 2026-09-09
> **Author:** Brainstorming session with user
> **Related docs:**
> - `lib/features/home/presentation/pages/home_page.dart:70-78` (sole occurrence of the string)
> - `docs/superpowers/specs/2026-09-04-pull-to-refresh-error-handling-design.md` (prior "no SnackBar on resume/auto-close" precedent)

---

## 1. Goal

Remove the `"Selamat datang kembali"` SnackBar that appears every time the app resumes from background, so that returning to the app is silent. Clean up the now-dead `WidgetsBindingObserver` plumbing that exists only to drive that SnackBar.

User decision (brainstorming session 2026-09-09): **Option A — Hapus total** + **Pendekatan 1 — Surgical removal**.

---

## 2. Background & Current Behavior (verified)

| Aspect | File:Line | Current state |
|---|---|---|
| SnackBar string | `lib/features/home/presentation/pages/home_page.dart:74` | `const SnackBar(content: Text('Selamat datang kembali'), duration: 2s)` |
| Trigger | `home_page.dart:70-78` | `didChangeAppLifecycleState` → `if (resumed && mounted) showSnackBar(...)` |
| Observer mixin | `home_page.dart:43` | `class _HomePageViewState extends State<_HomePageView> with WidgetsBindingObserver` |
| Registration | `home_page.dart:50` | `WidgetsBinding.instance.addObserver(this)` in `initState` |
| Unregistration | `home_page.dart:59` | `WidgetsBinding.instance.removeObserver(this)` in `dispose` |
| Introduced in | `e8a8ebb fix(home): non-destructive cache + KHS error logging + app return/refresh snackbars` (2026-08-08) | Part of a broader commit that also added non-destructive cache and KHS logging |
| Other SnackBars (out of scope) | `profile_page.dart:86`, `edit_bio_bottom_sheet.dart:93`, `profile_avatar.dart:189` | Error/validation SnackBars — must stay |
| Grep result | `grep "selamat datang"` | Exactly 1 hit (the target line) — no other occurrence in `lib/` or `test/` |
| Grep result | `grep "SnackBar\|showSnackBar\|ScaffoldMessenger"` | 5 hits total; 1 is the target, 4 are legitimate error SnackBars |
| Grep result | `grep "didChangeAppLifecycleState\|WidgetsBindingObserver"` | 1 hit each — both in `home_page.dart` |
| `_statusTimer` | `home_page.dart:44,52-55,58` | `Timer.periodic(1m)` → `HomeRefreshRequested` — independent of the observer, must stay |

**Key finding:** the only reason `_HomePageViewState` mixes in `WidgetsBindingObserver` and registers with `WidgetsBinding` is this SnackBar. Removing the SnackBar makes the entire observer contract dead code.

---

## 3. Approaches Considered

| # | Approach | Description | Trade-off | Verdict |
|---|---|---|---|---|
| 1 | **Surgical removal** | Delete `with WidgetsBindingObserver`, `addObserver`/`removeObserver`, and `didChangeAppLifecycleState` entirely. State becomes a plain `StatefulWidget` with only `_statusTimer`. | Pro: zero dead code, smallest diff (~10 lines deleted, 0 added), no idle observer cost, cleanest for future readers. Con: re-adding resume handling later costs ~6 lines. | **Selected** |
| 2 | Soft-disable | Empty the body of `didChangeAppLifecycleState`, keep mixin + registration. | Pro: 1-line revert to restore. Con: dead code, observer still fires on every resume for no reason, violates YAGNI and the user's "hapuskan" intent. | Rejected |
| 3 | Replace with silent refresh | Keep observer, replace SnackBar with `HomeRefreshRequested` dispatch. | Pro: resume would refresh data. Con: new behavior outside the requested scope, adds network/cache side-effects and needs throttling. | Rejected |

Rationale for #1: it is the most faithful execution of "hapuskan" — no behavior is added, no dead plumbing is left behind, and it aligns with the prior team decision to make resume/auto-close paths silent (see pull-to-refresh error handling spec: "No SnackBar").

---

## 4. Architecture & Changes

### 4.1 Files changed

| File | Change |
|---|---|
| `lib/features/home/presentation/pages/home_page.dart` | Surgical removal only. |

### 4.2 Exact diff (normative)

```diff
-class _HomePageViewState extends State<_HomePageView>
-    with WidgetsBindingObserver {
+class _HomePageViewState extends State<_HomePageView> {
   var _fetchDispatched = false;
   Timer? _statusTimer;

   @override
   void initState() {
     super.initState();
-    WidgetsBinding.instance.addObserver(this);
     _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
       if (mounted) {
         context.read<HomeBloc>().add(const HomeRefreshRequested());
       }
     });
   }

   @override
   void dispose() {
     _statusTimer?.cancel();
-    WidgetsBinding.instance.removeObserver(this);
     super.dispose();
   }

-  @override
-  void didChangeAppLifecycleState(AppLifecycleState state) {
-    if (state == AppLifecycleState.resumed && mounted) {
-      ScaffoldMessenger.of(context).showSnackBar(
-        const SnackBar(
-          content: Text('Selamat datang kembali'),
-          duration: Duration(seconds: 2),
-        ),
-      );
-    }
-  }
-
   String _getDateText() {
```

Net: ~10 lines deleted, 0 lines added (aside from the shortened class header). No new imports, no new dependencies.

### 4.3 Files NOT changed (out of scope — explicitly)

- `lib/features/profile/presentation/pages/profile_page.dart` — error SnackBar stays.
- `lib/features/profile/presentation/widgets/edit_bio_bottom_sheet.dart` — validation SnackBar stays.
- `lib/features/profile/presentation/widgets/profile_avatar.dart` — `AvatarFailure` SnackBar stays.
- `lib/features/data_initialization/presentation/widgets/data_refresh_overlay.dart` — unrelated overlay, no SnackBar on its path.
- `lib/core/errors/*`, `lib/core/services/*` — no error-handling change.
- All files under `test/` — no test asserts this SnackBar today; no test file needs editing.
- No route, DI, cache, or BLoC contract changes.

### 4.4 API contract

No public API changes. `_HomePageViewState` is private. `HomePage` widget signature unchanged. No barrel re-export affected.

---

## 5. Data Flow & Lifecycle

### Before

```
OS resume event
  → WidgetsBinding → _HomePageViewState.didChangeAppLifecycleState(resumed)
    → ScaffoldMessenger.of(context).showSnackBar("Selamat datang kembali", 2s)
```

Plus: `_statusTimer` independently fires `HomeRefreshRequested` every 60s (unchanged).

### After

```
OS resume event
  → (no observer registered) → no-op
  → _statusTimer continues to fire HomeRefreshRequested every 60s (unchanged)
```

Returning from background becomes silent. No network call, no cache read, no BLoC event is added on resume.

---

## 6. Error Handling

No new error path. Removing the callback eliminates one class of risk:

- **Stale `BuildContext`**: `ScaffoldMessenger.of(context)` inside a lifecycle callback can reference a context whose Scaffold is no longer mounted (e.g., during navigation). Deleting the callback removes that risk entirely.
- No `mounted` guard is needed after the deletion — the only remaining `mounted` check is inside `_statusTimer`'s callback, which is correct and retained.
- All other error paths (`HomeBloc`, `DataInitBloc`, `AvatarCubit`, global `ErrorHandler`) are untouched.

---

## 7. Testing

### 7.1 Existing tests — must continue to pass

| Suite | Why it stays green |
|---|---|
| `flutter analyze` | Deleting an override and a mixin cannot introduce new diagnostics; unused-import check will still pass (no new imports). |
| `flutter test` (all 37 suites, ~205 cases) | No existing test asserts the resume SnackBar. Verified by `grep -r "selamat datang\|didChangeAppLifecycleState\|WidgetsBindingObserver" test/` → 0 hits. `home_header_avatar_test.dart` and other home tests pump `HomePage` without exercising lifecycle. |
| Patrol E2E (`patrol_test/login_e2e_test.dart`) | Exercises login → home, not background→foreground resume. Unaffected. |

No new test is added. This is a pure deletion of UX noise; the surviving behavior (no SnackBar on resume) is the absence of something, which is adequately verified by manual smoke and by the fact that the string no longer exists in the codebase.

### 7.2 Manual smoke (required before merge)

1. `flutter run` (or MuMu `127.0.0.1:5557`) → login → Home.
2. Press Home button → return to app → **confirm no SnackBar appears** (repeat 2–3×).
3. Keep app foregrounded 2 minutes → confirm `_statusTimer` still refreshes schedule status (no regression).
4. `grep -r "Selamat datang kembali" lib/` → 0 hits.

---

## 8. Acceptance Criteria

1. ✅ `lib/features/home/presentation/pages/home_page.dart` no longer contains the string `"Selamat datang kembali"`.
2. ✅ `grep -rn "didChangeAppLifecycleState\|WidgetsBindingObserver" lib/` returns 0 hits.
3. ✅ `grep -rn "ScaffoldMessenger.*Selamat\|Selamat.*SnackBar" lib/` returns 0 hits (redundant guard over AC1).
4. ✅ `class _HomePageViewState` no longer mixes in `WidgetsBindingObserver`; `initState`/`dispose` no longer call `addObserver`/`removeObserver`.
5. ✅ `_statusTimer` (periodic `HomeRefreshRequested`) is preserved and still cancelled in `dispose`.
6. ✅ No other SnackBar (profile error, bio validation, avatar failure) is modified.
7. ✅ `flutter analyze` reports 0 errors, 0 new warnings.
8. ✅ `flutter test` passes with no test file modified.
9. ✅ Manual smoke: background → foreground shows no SnackBar over 3 consecutive resumes.

---

## 9. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Future need for resume handling | Low | Low | Re-adding `with WidgetsBindingObserver` + 3 lifecycle lines is trivial; git history (`e8a8ebb`) preserves the exact snippet. |
| Test that implicitly relied on observer registration | Very low | Low | Grep over `test/` shows no such test; `flutter test` will catch it. |
| Reviewer expects a "silent refresh" on resume | Low | Low | Explicitly out of scope per user decision A+1; a separate spec can add it if desired. |

---

## 10. Out of Scope (Explicit Non-Goals)

- Adding any new behavior on `AppLifecycleState.resumed` (e.g., silent `HomeRefreshRequested`, cache invalidation, or analytics event).
- Changing any other SnackBar, Toast, or overlay behavior.
- Modifying `_statusTimer` cadence or adding debounce/throttle.
- Refactoring `HomePage` into smaller widgets or extracting the timer into a service.
- Codegen (`build_runner`) — no Hive model change.

---

## 11. Rollback Plan

Revert the single commit. `git revert <commit>` restores `with WidgetsBindingObserver`, `addObserver`/`removeObserver`, and `didChangeAppLifecycleState` with the SnackBar. No migration, no data loss.

---

## 12. Implementation Checklist (for writing-plans)

- [ ] Edit `lib/features/home/presentation/pages/home_page.dart` — apply the diff in §4.2.
- [ ] Run `flutter analyze` — expect 0 errors.
- [ ] Run `flutter test` — expect all green, 0 files edited in `test/`.
- [ ] Manual smoke on emulator — background→foreground 3×, no SnackBar.
- [ ] `grep -r "Selamat datang kembali" lib/` — confirm 0 hits before committing.
