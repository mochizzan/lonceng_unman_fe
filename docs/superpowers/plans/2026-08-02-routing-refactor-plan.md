# Routing Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor Lonceng UnMan's go_router routing to be professional, industry-standard, and secure — adding a Settings route (5 minimum), named routes, auth guard, error handling, and testability, while resolving all stale documentation and path inconsistencies.

**Architecture:** Single-module Flutter + go_router 17.3.0 refactor. The router transitions from a non-injectable singleton to a factory function (`AppRouter.create`) that accepts dependencies. Named routes via a `RouteNames` constant class. Auth guard uses an adapter pattern (`AuthStatusProvider`) that is inert with stubs but active when real auth is wired. Settings is a standalone route outside the ShellRoute.

**Tech Stack:** GoRouter ^17.3.0, Flutter 3.29+, Dart ^3.12.0, Material 3, flutter_test, flutter_lints ^6.0.0.

## Global Constraints

- go_router version: ^17.3.0 (resolved 17.3.0 per pubspec.lock)
- Dart SDK: ^3.12.0
- Bottom navigation MUST have exactly 3 items: Home, Jadwal, Profile (DESIGN.md §4)
- MUST include minimum 5 routes: /login, /home, /jadwal, /profile, /settings
- Path renaming allowed but all 5 routes must remain
- Settings MUST be a standalone route outside the ShellRoute (not in bottom nav)
- All routes MUST have a `name` (required for `matchedRoute` in auth guard)
- Test framework: flutter_test with testWidgets
- Code style: PascalCase widgets, camelCase methods, snake_case files (AGENTS.md)

---

## File Inventory

### Created
| File | Responsibility |
|---|---|
| `lib/core/routes/route_names.dart` | Named route constants class — single source of truth for all route names |
| `lib/core/auth/auth_status.dart` | AuthStatus enum + AuthStatusProvider interface + StubAuthStatusProvider |
| `lib/core/auth/barrel.dart` | Barrel export for auth module |
| `lib/core/routes/app_error_page.dart` | Material 3 404/unknown-route error page widget |
| `lib/core/routes/main_shell_scaffold.dart` | Stateless shell scaffold + FloatingNavBar |
| `lib/features/settings/presentation/pages/settings_page.dart` | Settings page (theme & reminder controls from DESIGN.md §5.4) |
| `lib/features/settings/presentation/widgets/settings_widgets.dart` | ThemeSegmentedControl placeholder widget |
| `test/router/route_names_test.dart` | Test RouteNames covers all 5 required routes |
| `test/router/auth_status_test.dart` | Test AuthStatus enum + StubAuthStatusProvider |
| `test/router/auth_guard_test.dart` | Test authRedirect pure function (7 scenarios) |
| `test/router/app_error_page_test.dart` | Test error page renders + back-to-home navigation |
| `test/router/main_shell_scaffold_test.dart` | Test shell scaffold renders child + FloatingNavBar |
| `test/router/app_router_test.dart` | Test AppRouter.create() structure + auth guard integration |
| `test/router/exports_test.dart` | Test barrel exports resolve |
| `test/features/settings/presentation/pages/settings_page_test.dart` | Test SettingsPage renders |
| `test/main_test.dart` | Test main.dart uses AppRouter.create |

### Modified
| File | Change |
|---|---|
| `lib/core/routes/app_router.dart` | Complete rewrite: factory function, named routes, auth guard, error handling, no /main/ prefix |
| `lib/core/routes/barrel.dart` | Export new route files |
| `lib/core/barrel.dart` | Export auth barrel |
| `lib/main.dart` | Use AppRouter.create() with StubAuthStatusProvider |
| `test/widget_test.dart` | Add routerConfig assertion |

### Not Changed
- `lib/features/data_initialization/presentation/pages/data_initialization_page.dart` — kept as-is, not wired as a route
- `lib/features/auth/` — all stubs left untouched; auth guard uses AuthStatusProvider adapter abstraction

---

## Task Structure & Dependencies

```
Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6 → Task 7 → Task 8 → Task 9 → Task 10 → Task 11
  │        │        │        │        │        │        │        │        │        │        └─ Full suite verify
  │        │        │        │        │        │        │        │        │        └─ Widget test update
  │        │        │        │        │        │        │        │        └─ main.dart bootstrap
  │        │        │        │        │        │        │        └─ AppRouter.create factory
  │        │        │        │        │        │        └─ Barrel exports
  │        │        │        │        │        └─ Auth guard redirect logic
  │        │        │        │        └─ Settings page
  │        │        │        └─ MainShellScaffold extraction
  │        │        └─ Error page widget
  │        └─ AuthStatus abstraction
  └─ RouteNames constants
```

---

### Task 1: RouteNames Constant Class

**Files:**
- Create: `lib/core/routes/route_names.dart`
- Test: `test/router/route_names_test.dart`

**Interfaces:**
- Consumes: none
- Produces: `class RouteNames` with static const `String` fields

- [ ] **Step 1: Write the failing test**

```dart
// test/router/route_names_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

void main() {
  test('RouteNames contains all 5 required routes', () {
    expect(RouteNames.login, 'login');
    expect(RouteNames.home, 'home');
    expect(RouteNames.jadwal, 'jadwal');
    expect(RouteNames.profile, 'profile');
    expect(RouteNames.settings, 'settings');
  });

  test('RouteNames does not contain slashes', () {
    for (final name in [
      RouteNames.login,
      RouteNames.home,
      RouteNames.jadwal,
      RouteNames.profile,
      RouteNames.settings,
      RouteNames.setup,
      RouteNames.error,
    ]) {
      expect(name.contains('/'), isFalse, reason: '$name contains a slash');
    }
  });

  test('RouteNames cannot be instantiated', () {
    expect(() => RouteNames._(), isA<TypeError>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd D:/TUGAS-AKHIR/app/v2/lonceng_unman_fe
flutter test test/router/route_names_test.dart -v
```

Expected: `Error: Method not found: 'RouteNames'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/routes/route_names.dart
/// Named route constants — single source of truth for all route names.
/// Replaces hardcoded string paths in context.go() calls.
class RouteNames {
  RouteNames._();

  static const login = 'login';
  static const home = 'home';
  static const jadwal = 'jadwal';
  static const profile = 'profile';
  static const settings = 'settings';
  static const setup = 'setup';
  static const error = 'error';
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/router/route_names_test.dart -v
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add test/router/route_names_test.dart lib/core/routes/route_names.dart
git commit -m "feat(routes): add RouteNames constant class with 7 named routes"
```

---

### Task 2: AuthStatus Abstraction

**Files:**
- Create: `lib/core/auth/auth_status.dart`
- Test: `test/router/auth_status_test.dart`

**Interfaces:**
- Consumes: none
- Produces: `enum AuthStatus`, `abstract class AuthStatusProvider`, `class StubAuthStatusProvider`

- [ ] **Step 1: Write the failing test**

```dart
// test/router/auth_status_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';

void main() {
  test('AuthStatus enum has 3 states', () {
    expect(AuthStatus.values.length, 3);
    expect(AuthStatus.unknown, isNotNull);
    expect(AuthStatus.authenticated, isNotNull);
    expect(AuthStatus.unauthenticated, isNotNull);
  });

  test('StubAuthStatusProvider always returns authenticated', () {
    final provider = StubAuthStatusProvider();
    expect(provider.currentStatus, AuthStatus.authenticated);
  });

  test('StubAuthStatusProvider status stream is empty', () {
    final provider = StubAuthStatusProvider();
    expect(provider.status.isEmpty, isTrue);
  });

  test('AuthStatusProvider is abstract and cannot be instantiated', () {
    expect(() => AuthStatusProvider(), isA<TypeError>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/router/auth_status_test.dart -v
```

Expected: `Error: Method not found: 'AuthStatus'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/auth/auth_status.dart
import 'package:flutter/foundation.dart';

/// Auth state for the router's auth guard.
enum AuthStatus {
  /// Auth state is being resolved (e.g. checking token on app start).
  unknown,

  /// User is authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,
}

/// Abstraction the router depends on. Decouples the router from the
/// concrete auth BLoC/data layer. Provides a stub now; swap in a real
/// implementation when auth is implemented.
abstract class AuthStatusProvider {
  /// Current auth status — read synchronously at redirect time.
  AuthStatus get currentStatus;

  /// Stream that emits when auth status changes.
  /// Drives GoRouterRefreshStream to re-evaluate GoRouter.redirect.
  Stream<AuthStatus> get status;
}

/// Stub implementation — always authenticated.
/// Replace when real auth is ready.
class StubAuthStatusProvider implements AuthStatusProvider {
  @override
  AuthStatus get currentStatus => AuthStatus.authenticated;

  @override
  Stream<AuthStatus> get status => const Stream.empty();
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/router/auth_status_test.dart -v
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add test/router/auth_status_test.dart lib/core/auth/auth_status.dart
git commit -m "feat(auth): add AuthStatus enum + AuthStatusProvider interface + stub"
```

---

### Task 3: Error Page Widget

**Files:**
- Create: `lib/core/routes/app_error_page.dart`
- Test: `test/router/app_error_page_test.dart`

**Interfaces:**
- Consumes: `RouteNames` (Task 1)
- Produces: `class AppErrorPage extends StatelessWidget`

- [ ] **Step 1: Write the failing test**

```dart
// test/router/app_error_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/app_error_page.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

void main() {
  testWidgets('AppErrorPage shows 404 message and back button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppErrorPage(),
      ),
    );

    expect(find.text('Halaman Tidak Ditemukan'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
  });

  testWidgets('AppErrorPage back button navigates to home',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppErrorPage(),
        onGenerateRoute: (settings) {
          if (settings.name == '/${RouteNames.home}') {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Home Placeholder')),
            );
          }
          return null;
        },
      ),
    );

    await tester.tap(find.text('Kembali ke Beranda'));
    await tester.pumpAndSettle();

    expect(find.text('Home Placeholder'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/router/app_error_page_test.dart -v
```

Expected: `Error: Method not found: 'AppErrorPage'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/routes/app_error_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

/// Material 3 error page for 404 / unknown routes.
/// Shows a bell icon (Lonceng brand motif) and a "back to home" button.
class AppErrorPage extends StatelessWidget {
  const AppErrorPage({super.key, this.state});

  final GoRouterState? state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'Halaman Tidak Ditemukan',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (state?.error?.toString().isNotEmpty ?? false)
                Text(
                  state!.error.toString(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed(RouteNames.home),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/router/app_error_page_test.dart -v
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add test/router/app_error_page_test.dart lib/core/routes/app_error_page.dart
git commit -m "feat(routes): add Material 3 error page for 404 handling"
```

---

### Task 4: MainShellScaffold (Stateless Extraction)

**Files:**
- Create: `lib/core/routes/main_shell_scaffold.dart`
- Test: `test/router/main_shell_scaffold_test.dart`

**Interfaces:**
- Consumes: `RouteNames` (Task 1)
- Produces: `class MainShellScaffold extends StatelessWidget`, `class FloatingNavBar extends StatelessWidget`

- [ ] **Step 1: Write the failing test**

```dart
// test/router/main_shell_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';

void main() {
  testWidgets('MainShellScaffold renders child and FloatingNavBar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainShellScaffold(
          currentIndex: 0,
          child: Center(child: Text('Child Content')),
        ),
      ),
    );

    expect(find.text('Child Content'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });

  testWidgets('FloatingNavBar shows 3 items: Home, Jadwal, Profile',
      (WidgetTester tester) async {
    final capturedTaps = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingNavBar(
            currentIndex: 0,
            onTap: capturedTaps.add,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Jadwal'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Jadwal'));
    expect(capturedTaps, [1]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/router/main_shell_scaffold_test.dart -v
```

Expected: `Error: Method not found: 'MainShellScaffold'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/routes/main_shell_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

/// Stateless shell scaffold for the bottom-navigation group.
/// The [currentIndex] is derived externally from router state,
/// fixing the deep-link index desync bug in the original StatefulWidget.
class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed(RouteNames.home);
      case 1:
        context.goNamed(RouteNames.jadwal);
      case 2:
        context.goNamed(RouteNames.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}

/// Floating Bottom Navigation Bar (DESIGN.md section 3.6 & 4)
/// Fixed surface color #201B11 across both light and dark themes
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF201B11),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: const Color(0xFF201B11),
        selectedItemColor: const Color(0xFFFFFFFF),
        unselectedItemColor: const Color(0xFFFBEFDE),
        selectedLabelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/router/main_shell_scaffold_test.dart -v
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add test/router/main_shell_scaffold_test.dart lib/core/routes/main_shell_scaffold.dart
git commit -m "refactor(routes): extract MainShellScaffold + FloatingNavBar as stateless"
```

---

### Task 5: Settings Page

**Files:**
- Create: `lib/features/settings/presentation/pages/settings_page.dart`
- Create: `lib/features/settings/presentation/widgets/settings_widgets.dart`
- Test: `test/features/settings/presentation/pages/settings_page_test.dart`

**Interfaces:**
- Consumes: none (stub page)
- Produces: `class SettingsPage extends StatelessWidget`, `class ThemeSegmentedControl extends StatelessWidget`

> **Design note**: Per §8.3 of the recommendations, Settings is accessed from Profile via `context.pushNamed(RouteNames.settings)` (push, not go) for drill-down UX. The page surfaces theme & reminder controls from DESIGN.md §5.4.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/settings/presentation/pages/settings_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/pages/settings_page.dart';

void main() {
  testWidgets('SettingsPage renders appBar with title and settings items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsPage()),
    );

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Tema Aplikasi'), findsOneWidget);
    expect(find.text('Ingatkan Sebelum Kelas'), findsOneWidget);
    expect(find.text('Versi Aplikasi'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/settings/presentation/pages/settings_page_test.dart -v
```

Expected: `Error: Method not found: 'SettingsPage'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/settings/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/widgets/settings_widgets.dart';

/// Settings page — surfaces theme & reminder controls from DESIGN.md §5.4.
/// Accessed from Profile via context.pushNamed(RouteNames.settings).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Tema Aplikasi'),
            trailing: const ThemeSegmentedControl(),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Ingatkan Sebelum Kelas'),
            subtitle: const Text('5 menit'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('Versi Aplikasi', style: theme.textTheme.bodyMedium),
            subtitle: const Text('1.0.0+1'),
          ),
        ],
      ),
    );
  }
}
```

```dart
// lib/features/settings/presentation/widgets/settings_widgets.dart
import 'package:flutter/material.dart';

/// Placeholder for theme segmented control (Light / Dark / System).
/// Replace with real ThemeMode state management when theme switching is implemented.
class ThemeSegmentedControl extends StatelessWidget {
  const ThemeSegmentedControl({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 120,
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment(label: Text('Light')),
          ButtonSegment(label: Text('Dark')),
          ButtonSegment(label: Text('Auto')),
        ],
        selected: <int>{2},
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/settings/presentation/pages/settings_page_test.dart -v
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add test/features/settings/presentation/pages/settings_page_test.dart lib/features/settings/presentation/pages/settings_page.dart lib/features/settings/presentation/widgets/settings_widgets.dart
git commit -m "feat(settings): add SettingsPage stub with theme & reminder controls"
```

---

### Task 6: Auth Guard Redirect Logic (Pure Function)

**Files:**
- Test: `test/router/auth_guard_test.dart`
- Implementation: `lib/core/routes/app_router.dart` — the `authRedirect` function

**Interfaces:**
- Consumes: `AuthStatus`, `AuthStatusProvider`, `RouteNames`
- Produces: `authRedirect(String? matchedRoute, AuthStatusProvider) → String?`

> **Design note**: The `authRedirect` function accepts `String? matchedRoute` (the route name from `state.matchedRoute`) rather than the full `GoRouterState`. This makes it a pure function — trivially unit-testable without constructing GoRouterState (which is not possible in go_router 17.x test code). In Task 8's `AppRouter.create()`, the `redirect` callback extracts `state.matchedRoute` and passes it to `authRedirect`.

- [ ] **Step 1: Write the failing test**

```dart
// test/router/auth_guard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';

/// Fake provider for testing — allows controlling auth status synchronously.
class FakeAuthStatusProvider implements AuthStatusProvider {
  FakeAuthStatusProvider(this._status);

  AuthStatus _status;

  @override
  AuthStatus get currentStatus => _status;

  @override
  final Stream<AuthStatus> status = const Stream.empty();

  set status(AuthStatus value) => _status = value;
}

void main() {
  group('authRedirect', () {
    late FakeAuthStatusProvider provider;

    setUp(() {
      provider = FakeAuthStatusProvider(AuthStatus.authenticated);
    });

    test('unauthenticated user on /home is redirected to /login', () {
      provider.status = AuthStatus.unauthenticated;

      final result = authRedirect(RouteNames.home, provider);

      expect(result, '/${RouteNames.login}');
    });

    test('authenticated user on /login is redirected to /home', () {
      provider.status = AuthStatus.authenticated;

      final result = authRedirect(RouteNames.login, provider);

      expect(result, '/${RouteNames.home}');
    });

    test('authenticated user on /home stays (no redirect)', () {
      provider.status = AuthStatus.authenticated;

      final result = authRedirect(RouteNames.home, provider);

      expect(result, isNull);
    });

    test('unauthenticated user on /login stays (no redirect)', () {
      provider.status = AuthStatus.unauthenticated;

      final result = authRedirect(RouteNames.login, provider);

      expect(result, isNull);
    });

    test('unknown status lets routing proceed (no redirect)', () {
      provider.status = AuthStatus.unknown;

      final result = authRedirect(RouteNames.home, provider);

      expect(result, isNull);
    });

    test('null matchedRoute with unauthenticated user redirects to /login', () {
      provider.status = AuthStatus.unauthenticated;

      final result = authRedirect(null, provider);

      expect(result, '/${RouteNames.login}');
    });

    test('authenticated user on /settings stays (no redirect)', () {
      provider.status = AuthStatus.authenticated;

      final result = authRedirect(RouteNames.settings, provider);

      expect(result, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/router/auth_guard_test.dart -v
```

Expected: `Error: Method not found: 'authRedirect'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/routes/app_router.dart — add this function (standalone, before AppRouter class)
/// Evaluates auth guard logic. Returns a redirect path or null (no redirect).
///
/// [matchedRoute] is the route's name (obtained from state.matchedRoute).
/// This is a pure function — no GoRouterState dependency — for testability.
String? authRedirect(String? matchedRoute, AuthStatusProvider authStatusProvider) {
  final status = authStatusProvider.currentStatus;

  // Unknown: let routing proceed; pages show loading state.
  if (status == AuthStatus.unknown) return null;

  final isLogin = matchedRoute == RouteNames.login;

  // Unauthenticated: block everything except /login.
  if (status == AuthStatus.unauthenticated) {
    return isLogin ? null : '/${RouteNames.login}';
  }

  // Authenticated: redirect away from /login to home.
  if (isLogin) return '/${RouteNames.home}';

  return null; // authenticated + not on login → allow
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/router/auth_guard_test.dart -v
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add test/router/auth_guard_test.dart lib/core/routes/app_router.dart
git commit -m "test(routes): add auth guard redirect logic with pure-function interface"
```

---

### Task 7: Barrel Exports for New Files

**Files:**
- Create: `lib/core/auth/barrel.dart`
- Modify: `lib/core/routes/barrel.dart`
- Modify: `lib/core/barrel.dart`
- Test: `test/router/exports_test.dart`

**Interfaces:**
- Consumes: none
- Produces: Updated barrel exports

- [ ] **Step 1: Write the failing test**

```dart
// test/router/exports_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/app_error_page.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';

void main() {
  test('all route-related exports resolve', () {
    expect(RouteNames.login, 'login');
    expect(AuthStatus.authenticated, isNotNull);
    expect(AppErrorPage, isNotNull);
    expect(MainShellScaffold, isNotNull);
    expect(FloatingNavBar, isNotNull);
    expect(StubAuthStatusProvider, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/router/exports_test.dart -v
```

Expected: Compilation errors for missing exports

- [ ] **Step 3: Write implementation**

Create `lib/core/auth/barrel.dart`:
```dart
// core/auth barrel
export 'auth_status.dart';
```

Update `lib/core/routes/barrel.dart`:
```dart
// core/routes barrel
export 'app_router.dart';
export 'route_names.dart';
export 'app_error_page.dart';
export 'main_shell_scaffold.dart';
```

Update `lib/core/barrel.dart` — add `auth` export:
```dart
// core barrel exports
export 'constants/barrel.dart';
export 'utils/barrel.dart';
export 'theme/barrel.dart';
export 'errors/barrel.dart';
export 'network/barrel.dart';
export 'models/barrel.dart';
export 'routes/barrel.dart';
export 'auth/barrel.dart';
export 'di/barrel.dart';
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/router/exports_test.dart -v
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/core/routes/barrel.dart lib/core/auth/barrel.dart lib/core/barrel.dart test/router/exports_test.dart
git commit -m "chore(routes): export new route & auth files via barrel"
```

---

### Task 8: Router Factory (AppRouter.create) — Named Routes + Auth Guard + Error Handling

**Files:**
- Modify: `lib/core/routes/app_router.dart` — complete rewrite

**Interfaces:**
- Consumes: `RouteNames`, `AuthStatusProvider`, `authRedirect` (Task 6), `AppErrorPage`, `MainShellScaffold`, all page stubs (including new SettingsPage)
- Produces: `class AppRouter` with `static GoRouter create()` factory, `List<RouteBase> appRoutes`

> **Depends on**: Tasks 1–7 committed. Task 6 committed `authRedirect` to `app_router.dart`. Task 8 rewrites the same file to integrate it.

- [ ] **Step 1: Write the failing test**

```dart
// test/router/app_router_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';

class FakeProvider implements AuthStatusProvider {
  FakeProvider(this._status);
  AuthStatus _status;
  @override
  AuthStatus get currentStatus => _status;
  @override
  final Stream<AuthStatus> status = const Stream.empty();
  set status(AuthStatus v) => _status = v;
}

void main() {
  group('AppRouter.create', () {
    test('returns a GoRouter instance', () {
      final router = AppRouter.create(
        authStatusProvider: StubAuthStatusProvider(),
      );
      expect(router, isA<GoRouter>());
    });

    test('initialLocation defaults to /login', () {
      final router = AppRouter.create(
        authStatusProvider: StubAuthStatusProvider(),
      );
      expect(router.initialLocation, '/login');
    });

    test('all routes are named (no unnamed routes)', () {
      final router = AppRouter.create(
        authStatusProvider: StubAuthStatusProvider(),
      );

      for (final config in router.routerConfig.routes) {
        if (config is GoRoute) {
          expect(config.name, isNotNull,
              reason: 'Route ${config.path} has no name!');
        }
      }
    });

    test('ShellRoute contains exactly home, jadwal, profile', () {
      final router = AppRouter.create(
        authStatusProvider: StubAuthStatusProvider(),
      );

      bool foundShell = false;
      for (final config in router.routerConfig.routes) {
        if (config is ShellRoute) {
          foundShell = true;
          expect(config.routes.length, 3);
          expect(config.routes[0].name, RouteNames.home);
          expect(config.routes[1].name, RouteNames.jadwal);
          expect(config.routes[2].name, RouteNames.profile);
        }
      }
      expect(foundShell, isTrue, reason: 'No ShellRoute found');
    });

    test('login and settings are standalone (not in ShellRoute)', () {
      final router = AppRouter.create(
        authStatusProvider: StubAuthStatusProvider(),
      );

      final topLevelNames = router.routerConfig.routes
          .whereType<GoRoute>()
          .map((r) => r.name)
          .toSet();

      final shellChildNames = router.routerConfig.routes
          .whereType<ShellRoute>()
          .expand((s) => s.routes)
          .whereType<GoRoute>()
          .map((r) => r.name)
          .toSet();

      expect(topLevelNames, contains(RouteNames.login));
      expect(topLevelNames, contains(RouteNames.settings));
      expect(shellChildNames, isNot(contains(RouteNames.login)));
      expect(shellChildNames, isNot(contains(RouteNames.settings)));
    });
  });

  group('auth guard integration', () {
    testWidgets('unauthenticated user deep-linking to /home is redirected to /login',
        (tester) async {
      final provider = FakeProvider(AuthStatus.unauthenticated);
      final router = AppRouter.create(
        authStatusProvider: provider,
        initialLocation: '/home',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('authenticated user on /login is redirected to /home',
        (tester) async {
      final provider = FakeProvider(AuthStatus.authenticated);
      final router = AppRouter.create(
        authStatusProvider: provider,
        initialLocation: '/login',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/router/app_router_test.dart -v
```

Expected: Compilation errors — `AppRouter` class doesn't exist yet

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/routes/app_router.dart
//
// Route configuration using go_router.
// Defines all app routes based on DESIGN.md navigation structure.
//
// Route Inventory (minimum 5 required):
// - /login → LoginPage (auth flow, standalone)
// - /home → HomePage (ShellRoute child, bottom nav)
// - /jadwal → JadwalPage (ShellRoute child, bottom nav)
// - /profile → ProfilePage (ShellRoute child, bottom nav)
// - /settings → SettingsPage (standalone, not in bottom nav)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/routes/main_shell_scaffold.dart';
import 'package:lonceng_unman_fe/core/routes/app_error_page.dart';

// Import feature pages
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/home/presentation/pages/home_page.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/profile_page.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/pages/settings_page.dart';

/// Auth guard redirect logic.
/// Returns a redirect path or null (no redirect).
///
/// [matchedRoute] is the route's name (from state.matchedRoute).
/// Requires all routes to have a name set — otherwise matchedRoute
/// returns null and the guard may fail silently.
String? authRedirect(
  String? matchedRoute,
  AuthStatusProvider authStatusProvider,
) {
  final status = authStatusProvider.currentStatus;

  // Unknown: let routing proceed; pages show loading state.
  if (status == AuthStatus.unknown) return null;

  final isLogin = matchedRoute == RouteNames.login;

  // Unauthenticated: block everything except /login.
  if (status == AuthStatus.unauthenticated) {
    return isLogin ? null : '/${RouteNames.login}';
  }

  // Authenticated: redirect away from /login to home.
  if (isLogin) return '/${RouteNames.home}';

  return null; // authenticated + not on login → allow
}

/// Maps a matched route name to a bottom-nav index.
/// Returns 0 (Home) for any route outside the shell — safe fallback.
int _indexForRoute(String? routeName) {
  switch (routeName) {
    case RouteNames.home:
      return 0;
    case RouteNames.jadwal:
      return 1;
    case RouteNames.profile:
      return 2;
    default:
      return 0;
  }
}

/// Top-level route definitions.
/// The [ShellRoute] wraps the three bottom-navigation children:
/// home, jadwal, profile. /login and /settings are standalone.
final List<RouteBase> appRoutes = <RouteBase>[
  // --- Auth (standalone, no bottom nav) ---
  GoRoute(
    name: RouteNames.login,
    path: '/login',
    builder: (context, state) => const LoginPage(),
  ),

  // --- Main app (bottom navigation shell) ---
  ShellRoute(
    builder: (context, state, child) {
      return MainShellScaffold(
        currentIndex: _indexForRoute(state.matchedRoute),
        child: child,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        name: RouteNames.home,
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        name: RouteNames.jadwal,
        path: '/jadwal',
        builder: (context, state) => const JadwalPage(),
      ),
      GoRoute(
        name: RouteNames.profile,
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  ),

  // --- Settings (standalone; accessible from Profile via pushNamed) ---
  GoRoute(
    name: RouteNames.settings,
    path: '/settings',
    builder: (context, state) => const SettingsPage(),
  ),
];

/// Injectable router factory.
/// Pass [StubAuthStatusProvider] for now; swap in real implementation
/// when auth is implemented.
final class AppRouter {
  AppRouter._();

  static GoRouter create({
    required AuthStatusProvider authStatusProvider,
    String initialLocation = '/login',
    List<NavigatorObserver>? observers,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: GoRouterRefreshStream(authStatusProvider.status),
      redirect: (context, state) =>
          authRedirect(state.matchedRoute, authStatusProvider),
      routes: appRoutes,
      errorBuilder: (context, state) => AppErrorPage(state: state),
      onException: (context, state, error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation error: ${error.toString()}')),
        );
        context.goNamed(RouteNames.home);
      },
      observers: observers ?? [],
      debugLogDiagnostics: false,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/router/app_router_test.dart -v
```

Expected: All tests pass (may need adjustment for GoRouter API specifics)

- [ ] **Step 5: Commit**

```bash
git add lib/core/routes/app_router.dart test/router/app_router_test.dart
git commit -m "refactor(routes): add AppRouter.create factory with named routes, auth guard, error handling"
```

---

### Task 9: Update main.dart Bootstrap

**Files:**
- Modify: `lib/main.dart`
- Test: `test/main_test.dart`

**Interfaces:**
- Consumes: `AppRouter`, `StubAuthStatusProvider`
- Produces: Updated app entry point using factory function

- [ ] **Step 1: Write the failing test**

```dart
// test/main_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/main.dart';

void main() {
  testWidgets('App uses AppRouter.create with injectable router',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());

    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;

    expect(materialApp.routerConfig, isNotNull);
    expect(materialApp.routerConfig, isA<GoRouter>());
  });

  testWidgets('App initial route shows LoginPage', (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/main_test.dart -v
```

Expected: `AppRouter` not found or import errors

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';

void main() {
  runApp(const LoncengUnmanApp());
}

class LoncengUnmanApp extends StatelessWidget {
  const LoncengUnmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.create(
      authStatusProvider: StubAuthStatusProvider(),
    );

    return MaterialApp.router(
      title: 'Lonceng UnMan',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/main_test.dart -v
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/main_test.dart
git commit -m "refactor(main): bootstrap app with AppRouter.create + stub auth provider"
```

---

### Task 10: Update Existing Widget Tests

**Files:**
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `LoncengUnmanApp` (now uses `AppRouter.create`)
- Produces: Updated tests that still pass

- [ ] **Step 1: Verify existing tests still pass**

```bash
flutter test test/widget_test.dart -v
```

Expected: Existing tests pass unchanged (LoNcengUnmanApp() still renders login page)

- [ ] **Step 2: Add routerConfig assertion**

```dart
// test/widget_test.dart (appended)
void main() {
  testWidgets('App starts and shows login page', (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('App has proper theme configuration', (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;
    expect(materialApp.theme?.useMaterial3, isTrue);
  });

  testWidgets('App uses MaterialApp.router for go_router',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LoncengUnmanApp());
    final MaterialApp materialApp =
        tester.widget(find.byType(MaterialApp)) as MaterialApp;
    expect(materialApp.routerConfig, isNotNull);
  });
}
```

- [ ] **Step 3: Run tests**

```bash
flutter test test/widget_test.dart -v
```

Expected: `00:01 +3` — all tests pass

- [ ] **Step 4: Commit**

```bash
git add test/widget_test.dart
git commit -m "test: add routerConfig assertion to widget tests"
```

---

### Task 11: Full Test Suite Verification

No new files — runs all tests and verifies the project compiles and lints clean.

- [ ] **Step 1: Run full test suite**

```bash
cd D:/TUGAS-AKHIR/app/v2/lonceng_unman_fe
flutter test
```

Expected: `All tests passed`

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze
```

Expected: No errors, minimal warnings

- [ ] **Step 3: Run formatter check**

```bash
dart format --output=show --set-exit-if-changed lib/ test/
```

Expected: No formatting changes needed

---

## Key Decisions Summary

| Decision | Choice | Justification |
|---|---|---|
| Route paths | `/login`, `/home`, `/jadwal`, `/profile`, `/settings` | Drop non-semantic `/main/` prefix; shorter, cleaner URLs; no production deep links at v1.0.0+1 |
| Settings placement | Standalone `/settings` route | DESIGN.md §4 defines 3 bottom-nav items; Settings is not one of them; standalone = first-class destination, push-able from Profile |
| Auth guard | Adapter pattern (`AuthStatusProvider`) + stub | Inert today (stub always authenticated), activates when real auth is wired; ~45 lines cost; security scaffolding |
| Named routes | Yes (`RouteNames` class) | Compile-time safety; required by `matchedRoute` in auth guard; refactor-safe |
| Router pattern | Factory function `AppRouter.create()` | Explicit deps, testable; compatible with future `get_it` integration |
| ShellScaffold | Stateless (derived index) | Fixes deep-link index desync; index computed from `state.matchedRoute` |
| DataInitializationPage | Remove stale comment, do NOT wire | 13-line stub, not in 5 required routes, no navigation calls |
| Error handling | `errorBuilder` (404) + `onException` (thrown) | Two distinct error surfaces in go_router 17.x; both wired |
| Path naming | Lowercase, single-word, Indonesian retained | Web-safe URLs; matches DESIGN.md domain language; applies to URLs only |

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `matchedRoute` returns null if route has no `name` | High | Auth guard silently fails | Task 8 enforces named routes; test asserts all routes have names |
| go_router 17.x `GoRouterState` not constructable in tests | High | Unit tests for auth guard fail | Task 6 uses `String?` pure function instead of `GoRouterState`; Task 8 uses `testWidgets` integration tests |
| ShellRoute `builder` routes property API differs | Medium | Test compilation errors | Tests use `router.routerConfig.routes` — adjust if API differs |
| `router.routerConfig` returns `List<RouteBase>` | Medium | Tests iterate wrong structure | Verify go_router 17.3.0 API; the test uses `.routes` property |
| Deep links using old `/main/*` paths break | Low | Users with bookmarks see 404 | Acceptable at v1.0.0+1; no production deep links established |
| Settings page stub content changes | Low | Settings page test breaks | Test asserts on stable text ('Pengaturan', 'Tema Aplikasi') unlikely to change |

## Tradeoffs (from bias-reduced recommendations)

1. **Auth guard (confirmation bias)**: The guard is inert with `StubAuthStatusProvider` — it always returns `authenticated`. This is not wasted code; it's security scaffolding. The adapter pattern costs ~45 lines but provides a tested, verified guard the moment real auth is wired. Alternative: defer entirely (zero cost, zero safety). Recommendation: adapter pattern.

2. **Settings placement (ambiguity)**: Standalone `/settings` vs nested `/profile/settings`. Standalone chosen because DESIGN.md §4 defines 3 bottom-nav items — adding Settings to the shell would require a 4th nav item, contradicting the design. Standalone keeps Settings accessible with a back-stack-preserving `pushNamed` from Profile.

3. **Path prefix removal (ambiguity)**: Dropping `/main/` prefix. Tradeoff: shorter URLs vs. breaking deep links. Acceptable at v1.0.0+1 with no production deep links. If deep links are needed later, a redirect rule can handle `/main/* → /`.

4. **`matchedRoute` vs `uri.path` in guard**: `matchedRoute` returns route name (requires named routes) — compile-time safe once names are used. `uri.path` is a raw string comparison (more fragile). Recommendation: `matchedRoute` with enforced named routes.

5. **`errorBuilder` vs `errorPageBuilder`**: `errorBuilder` returns a `Widget` (simpler); `errorPageBuilder` returns a `Page` (needed for custom transitions). Recommendation: `errorBuilder` now.

6. **ShellScaffold Stateful→Stateless**: Losing local `_currentIndex` state means no programmatic index control without router state. Tradeoff: gains deep-link sync; loses local state control. Acceptable — no swipe gestures planned.

7. **Test coupling to stub text**: Tests assert on `find.text('Login')` etc. Couplings to stub page content. Acceptable per existing convention (`widget_test.dart` already does this). Switch to route-name assertions when pages are implemented.

8. **`errorBuilder` vs `onException`**: `errorBuilder` catches 404 (no matching route); `onException` catches thrown exceptions during navigation/builders. Both wired for production-grade error handling.

---

## Navigation Reference

Current (before refactor):
```
/login → LoginPage  (standalone)
/main/home → HomePage  (ShellRoute)
/main/jadwal → JadwalPage  (ShellRoute)
/main/profile → ProfilePage  (ShellRoute)
```

After refactor:
```
/login → LoginPage  (standalone, named: "login")
/home → HomePage  (ShellRoute child, named: "home")
/jadwal → JadwalPage  (ShellRoute child, named: "jadwal")
/profile → ProfilePage  (ShellRoute child, named: "profile")
/settings → SettingsPage  (standalone, named: "settings")  [NEW]
```

Deep-link navigation from Profile to Settings uses `context.pushNamed(RouteNames.settings)` (push, not go — preserves back-stack).
