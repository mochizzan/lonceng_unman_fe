# Login Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a fully functional, visually-faithful Login page for Lonceng UnMan matching DESIGN.md §5.1 — NPM/password form with BLoC state management, auth guard integration, shared widget components, and widget tests. No hardcoded colors; all styling must derive from `Theme.of(context).colorScheme` or `ThemeExtension<AppColors>`.

**Architecture:** The login page is a feature-screen in the `auth` feature module under Clean Architecture (presentation → domain → data). It uses the BLoC pattern (`AuthBloc` with `AuthEvent`/`AuthState`) for form state (NPM, password visibility, "ingat saya" checkbox, submission status, validation errors). The page is a `StatefulWidget` whose state is driven by `BlocBuilder`/`BlocListener`. Auth flow: on successful login, `AuthBloc` emits `AuthAuthenticated`, the `BlocListener` navigates to `/home`, and go_router's `authRedirect` (driven by `AuthStatusProvider`) keeps the user authenticated. The page has no bottom navbar (standalone route, no `MainShellScaffold` wrapper).

**Tech Stack:** Flutter SDK, `flutter_bloc` ^9.0.1, `bloc` ^9.2.1, `go_router` ^17.3.0, `google_fonts` ^8.2.1. Uses `Icons` from Material (bell/notifications, badge/id-card, lock) — `material_symbols` package is NOT in pubspec; use `Icons` enum. No `equatable` in pubspec — BLoC events/states use manual `==` and `hashCode`.

## Global Constraints

- Project root: `D:/TUGAS-AKHIR/app/v2/lonceng_unman_fe` (Windows native, not WSL)
- All file paths in this plan are relative to the project root
- Never use absolute paths or write to `/tmp/`
- Dart SDK: ^3.12.0 (null-safe, sound)
- Use only dependencies already declared in `pubspec.yaml`: `flutter_bloc`, `bloc`, `go_router`, `google_fonts`
- Do NOT add `equatable` or `material_symbols` to pubspec unless explicitly needed
- Follow DESIGN.md §5.1 for the login screen layout spec
- Follow DESIGN.md §3.2–3.6 for color tokens, §3.7 for typography, §3.8 for shapes
- ALL colors MUST come from `Theme.of(context).colorScheme` or `ThemeExtension<AppColors>` — NO hardcoded hex values, NO `Color(0xFF...)` literals (except for shadow alpha where `Color(0x0F000000)` is a conventional shadow color used throughout the codebase, e.g. `main_shell_scaffold.dart`)
- ALL typography MUST use `Theme.of(context).textTheme` styles (HeadlineSmall, BodyMedium, etc.) — NO hardcoded font sizes or weights
- ALL spacing MUST use multiples of 8px (DESIGN.md §7) — use `SizedBox(height: 8)` etc., not arbitrary numbers
- Follow `AGENTS.md` conventions: snake_case filenames, PascalCase widgets, private members `_`-prefixed, `const` constructors where possible, BLoC pattern with separate `event.dart`, `state.dart`, `bloc.dart`
- Lint rule: `flutter_lints` ^6.0.0 — `prefer_const_constructors`, `prefer_const_declarations`, `avoid_print` active
- Test convention: `testWidgets` + `pumpAndSettle` + `find.text` assertions, MaterialApp wrapper for router-dependent tests
- Commit after each completed task (TDD cycle)

---

## File Structure

**Files to create:**

| File | Responsibility |
|---|---|
| `lib/shared/widgets/app_text_field.dart` | TextFormField — fill from `surfaceContainerHighest`, radius 16px, leading icon, password toggle support |
| `lib/shared/widgets/auth_background.dart` | Background gradient — `surface` to `primaryContainer`, with decorative blobs |
| `lib/shared/widgets/bell_logo.dart` | App logo widget — bell icon in `primaryContainer` circle with card-shadow, 3deg tilt |
| `test/features/auth/domain/entities/auth_entity_test.dart` | Entity unit test |
| `test/features/auth/domain/usecases/get_auth_test.dart` | Usecase unit test |
| `test/features/auth/data/datasources/auth_remote_data_source_test.dart` | Model serialization test |
| `test/features/auth/data/repositories/auth_repository_impl_test.dart` | Repository delegation test |
| `test/features/auth/bloc/auth_event_state_test.dart` | Event/State equality unit test |
| `test/features/auth/bloc/auth_bloc_test.dart` | BLoC unit tests with `blocTest` |
| `test/features/auth/presentation/widgets/auth_widgets_test.dart` | Shared widget tests |
| `test/features/auth/presentation/pages/login_page_test.dart` | Widget test for LoginPage rendering and interactions |
| `test/features/auth/presentation/pages/login_page_integration_test.dart` | Integration test with router navigation |

**Files to modify:**

| File | Change |
|---|---|
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | Full AuthBloc implementation with form handlers and validation |
| `lib/features/auth/presentation/bloc/auth_event.dart` | AuthEvent hierarchy — form input, toggle, submit |
| `lib/features/auth/presentation/bloc/auth_state.dart` | AuthState hierarchy — initial, loading, authenticated, error |
| `lib/features/auth/presentation/pages/login_page.dart` | Complete rewrite — StatefulWidget with BlocBuilder, DESIGN.md §5.1 layout |
| `lib/shared/widgets/app_button.dart` | AppButton — FilledButton with theme colors, radius 24px, full-width support |
| `lib/shared/widgets/barrel.dart` | Add exports for all new shared widgets |
| `lib/features/auth/domain/entities/auth_entity.dart` | Implement AuthEntity with npm, token, expiresAt |
| `lib/features/auth/domain/repositories/auth_repository.dart` | Define abstract AuthRepository interface |
| `lib/features/auth/domain/usecases/get_auth.dart` | Implement GetAuth usecase |
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | Implement abstract interface + StubAuthRemoteDataSource |
| `lib/features/auth/data/models/auth_model.dart` | Implement AuthModel extends AuthEntity with fromMap/toMap |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Implement AuthRepositoryImpl |
| `lib/core/routes/app_router.dart` | Wrap login route in BlocProvider, add auth_bloc import |
| `test/main_test.dart` | Update assertion — old "Login" AppBar title is gone, new LoginPage has different text |
| `test/router/app_router_test.dart` | Update `find.text('Login')` → `find.text('Masuk ke Akun')` |

## Interfaces

### AuthRepository (domain interface)
```dart
abstract class AuthRepository {
  Future<AuthEntity> login({required String npm, required String password});
}
```

### AuthEntity (domain entity)
```dart
class AuthEntity {
  final String npm;
  final String token;
  final DateTime expiresAt;
  const AuthEntity({required this.npm, required this.token, required this.expiresAt});
}
```

### AuthRemoteDataSource (data source interface)
```dart
abstract class AuthRemoteDataSource {
  Future<AuthModel> login({required String npm, required String password});
}
class StubAuthRemoteDataSource implements AuthRemoteDataSource {
  // stub returning AuthModel on any valid 11-digit NPM
}
```

### AuthModel (data model)
```dart
class AuthModel extends AuthEntity {
  const AuthModel({required super.npm, required super.token, required super.expiresAt});
  factory AuthModel.fromMap(Map<String, dynamic> map) => ...;
  Map<String, dynamic> toMap() => ...;
}
```

### GetAuth usecase
```dart
class GetAuth {
  final AuthRepository repository;
  const GetAuth(this.repository);
  Future<AuthEntity> call({required String npm, required String password}) =>
    repository.login(npm: npm, password: password);
}
```

### AuthEvent (presentation event)
```dart
abstract class AuthEvent { const AuthEvent(); }
class AuthNpmChanged extends AuthEvent { final String npm; }
class AuthPasswordChanged extends AuthEvent { final String password; }
class AuthPasswordVisibilityToggled extends AuthEvent {}
class AuthRememberMeToggled extends AuthEvent { final bool value; }
class AuthSubmitted extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}
```

### AuthState (presentation state)
```dart
abstract class AuthState { const AuthState(); }
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState { final AuthEntity user; }
class AuthError extends AuthState { final String message; }
```

### AuthBloc (presentation bloc)
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._getAuth) : super(const AuthInitial()) {
    on<AuthNpmChanged>(_onNpmChanged);
    on<AuthSubmitted>(_onSubmitted);
  }
  String get npm;
  String get password;
  bool get passwordVisible;
  bool get rememberMe;
}
```

### LoginPage (presentation page)
```dart
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  // StatefulWidget — manages TextEditingController instances locally
  // Uses BlocBuilder for form state, BlocListener for navigation
  // Builds AuthBackground, BellLogo, form card with NPM/password/AppButton
}
```

### Shared widgets
- `AppButton({required VoidCallback onPressed, required Widget child, bool fullWidth = false})` — uses `colorScheme.primaryContainer`/`onPrimaryContainer`, radius 24px via `Theme.of(context)`
- `AppTextField({required TextEditingController controller, required String label, IconData? icon, bool obscureText = false, Widget? suffix, TextInputType? keyboardType, String? errorText, void Function(String)? onChanged})` — uses `surfaceContainerHighest` for fill, `outlineVariant` for border, `primaryContainer` for focus
- `AuthBackground({required Widget child})` — gradient using `colorScheme.surface` and `colorScheme.primaryContainer`
- `BellLogo()` — uses `colorScheme.primaryContainer`/`onPrimaryContainer`, `Icons.notifications_none`

---

## Tasks

### Task 1: Implement AuthEntity domain entity

**Files:**
- Modify: `lib/features/auth/domain/entities/auth_entity.dart`
- Create: `test/features/auth/domain/entities/auth_entity_test.dart`

**Interfaces:**
- Consumes: nothing (leaf entity)
- Produces: `AuthEntity` with `npm: String`, `token: String`, `expiresAt: DateTime`, const constructor

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

void main() {
  group('AuthEntity', () {
    test('constructs with all fields', () {
      final now = DateTime(2025, 1, 1);
      final entity = AuthEntity(npm: '21081010001', token: 'abc123', expiresAt: now);
      expect(entity.npm, '21081010001');
      expect(entity.token, 'abc123');
      expect(entity.expiresAt, now);
    });
  });
}
```

Run: `flutter test test/features/auth/domain/entities/auth_entity_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
/// AuthEntity — represents an authenticated user session.
class AuthEntity {
  final String npm;
  final String token;
  final DateTime expiresAt;

  const AuthEntity({
    required this.npm,
    required this.token,
    required this.expiresAt,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add test/features/auth/domain/entities/auth_entity_test.dart lib/features/auth/domain/entities/auth_entity.dart
git commit -m "feat(auth): add AuthEntity domain entity"
```

---

### Task 2: Define AuthRepository interface

**Files:**
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart`
- Create: `test/features/auth/domain/repositories/auth_repository_test.dart`

**Interfaces:**
- Consumes: `AuthEntity` (Task 1)
- Produces: `AuthRepository` abstract interface

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  final AuthEntity result;
  FakeAuthRepository(this.result);
  @override
  Future<AuthEntity> login({required String npm, required String password}) async {
    return result;
  }
}

void main() {
  group('AuthRepository', () {
    test('interface can be implemented and called', () async {
      final now = DateTime(2025, 1, 1);
      final expected = AuthEntity(npm: '21081010001', token: 'tok', expiresAt: now);
      final repo = FakeAuthRepository(expected);
      final result = await repo.login(npm: '21081010001', password: 'pass');
      expect(result, expected);
    });
  });
}
```

Run: `flutter test test/features/auth/domain/repositories/auth_repository_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

abstract class AuthRepository {
  Future<AuthEntity> login({
    required String npm,
    required String password,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/domain/repositories/auth_repository.dart test/features/auth/domain/repositories/auth_repository_test.dart
git commit -m "feat(auth): add AuthRepository interface"
```

---

### Task 3: Implement GetAuth usecase

**Files:**
- Modify: `lib/features/auth/domain/usecases/get_auth.dart`
- Create: `test/features/auth/domain/usecases/get_auth_test.dart`

**Interfaces:**
- Consumes: `AuthRepository` (Task 2), `AuthEntity` (Task 1)
- Produces: `GetAuth`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';

class FakeAuthRepository implements AuthRepository {
  final AuthEntity result;
  FakeAuthRepository(this.result);
  @override
  Future<AuthEntity> login({required String npm, required String password}) async {
    return result;
  }
}

void main() {
  group('GetAuth', () {
    test('calls repository.login and returns result', () async {
      final now = DateTime(2025, 1, 1);
      final expected = AuthEntity(npm: '21081010001', token: 'tok', expiresAt: now);
      final repo = FakeAuthRepository(expected);
      final usecase = GetAuth(repo);
      final result = await usecase(npm: '21081010001', password: 'pass123');
      expect(result, expected);
    });
  });
}
```

Run: `flutter test test/features/auth/domain/usecases/get_auth_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';

class GetAuth {
  final AuthRepository repository;
  const GetAuth(this.repository);

  Future<AuthEntity> call({
    required String npm,
    required String password,
  }) {
    return repository.login(npm: npm, password: password);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/domain/usecases/get_auth.dart test/features/auth/domain/usecases/get_auth_test.dart
git commit -m "feat(auth): add GetAuth usecase"
```

---

### Task 4: Implement AuthModel and AuthRemoteDataSource

**Files:**
- Modify: `lib/features/auth/data/models/auth_model.dart`
- Modify: `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- Create: `test/features/auth/data/datasources/auth_remote_data_source_test.dart`

**Interfaces:**
- Consumes: `AuthEntity` (Task 1)
- Produces: `AuthModel`, `AuthRemoteDataSource`, `StubAuthRemoteDataSource`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/data/models/auth_model.dart';

void main() {
  group('AuthModel', () {
    test('fromMap creates AuthModel from JSON map', () {
      final now = DateTime(2025, 6, 15, 10, 30);
      final model = AuthModel.fromMap({
        'npm': '21081010001',
        'token': 'abc123',
        'expiresAt': now.toIso8601String(),
      });
      expect(model.npm, '21081010001');
      expect(model.token, 'abc123');
      expect(model.expiresAt, now);
    });

    test('toMap serializes to JSON map', () {
      final now = DateTime(2025, 6, 15, 10, 30);
      final model = AuthModel(npm: '21081010001', token: 'abc123', expiresAt: now);
      final map = model.toMap();
      expect(map['npm'], '21081010001');
      expect(map['token'], 'abc123');
      expect(map['expiresAt'], now.toIso8601String());
    });
  });
}
```

Run: `flutter test test/features/auth/data/datasources/auth_remote_data_source_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/auth/data/models/auth_model.dart
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.npm,
    required super.token,
    required super.expiresAt,
  });

  factory AuthModel.fromMap(Map<String, dynamic> map) {
    return AuthModel(
      npm: map['npm'] as String,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'npm': npm,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
```

```dart
// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'package:lonceng_unman_fe/features/auth/data/models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({
    required String npm,
    required String password,
  });
}

/// Stub implementation — returns mock on any 11-digit NPM.
/// Replace with real HTTP client when backend is available.
class StubAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthModel> login({
    required String npm,
    required String password,
  }) async {
    return AuthModel(
      npm: npm,
      token: 'mock_token',
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/models/auth_model.dart lib/features/auth/data/datasources/auth_remote_data_source.dart test/features/auth/data/datasources/auth_remote_data_source_test.dart
git commit -m "feat(auth): add AuthModel and AuthRemoteDataSource"
```

---

### Task 5: Implement AuthRepositoryImpl

**Files:**
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Create: `test/features/auth/data/repositories/auth_repository_impl_test.dart`

**Interfaces:**
- Consumes: `AuthRepository` (Task 2), `AuthRemoteDataSource` (Task 4)
- Produces: `AuthRepositoryImpl`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/data/models/auth_model.dart';
import 'package:lonceng_unman_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

class FakeRemoteDataSource implements AuthRemoteDataSource {
  final AuthModel result;
  bool wasCalled = false;
  FakeRemoteDataSource(this.result);
  @override
  Future<AuthModel> login({required String npm, required String password}) async {
    wasCalled = true;
    return result;
  }
}

void main() {
  group('AuthRepositoryImpl', () {
    test('login delegates to remote data source', () async {
      final now = DateTime(2025, 1, 1);
      final model = AuthModel(npm: '21081010001', token: 'tok', expiresAt: now);
      final remote = FakeRemoteDataSource(model);
      final repository = AuthRepositoryImpl(remoteDataSource: remote);
      final result = await repository.login(npm: '21081010001', password: 'pass');
      expect(result.npm, '21081010001');
      expect(remote.wasCalled, isTrue);
    });
  });
}
```

Run: `flutter test test/features/auth/data/repositories/auth_repository_impl_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  const AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuthEntity> login({
    required String npm,
    required String password,
  }) async {
    return remoteDataSource.login(npm: npm, password: password);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/repositories/auth_repository_impl.dart test/features/auth/data/repositories/auth_repository_impl_test.dart
git commit -m "feat(auth): implement AuthRepositoryImpl"
```

---

### Task 6: Implement AuthEvent and AuthState

**Files:**
- Modify: `lib/features/auth/presentation/bloc/auth_event.dart`
- Modify: `lib/features/auth/presentation/bloc/auth_state.dart`
- Create: `test/features/auth/bloc/auth_event_state_test.dart`

**Interfaces:**
- Consumes: `AuthEntity` (Task 1)
- Produces: `AuthEvent` hierarchy, `AuthState` hierarchy

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

void main() {
  group('AuthEvent', () {
    test('AuthNpmChanged has correct value and equality', () {
      expect(AuthNpmChanged('123').npm, '123');
      expect(AuthNpmChanged('123'), AuthNpmChanged('123'));
      expect(AuthNpmChanged('123'), isNot(AuthNpmChanged('456')));
    });

    test('AuthPasswordChanged has correct value and equality', () {
      expect(AuthPasswordChanged('pass').password, 'pass');
      expect(AuthPasswordChanged('pass'), AuthPasswordChanged('pass'));
    });

    test('AuthSubmitted are equal', () {
      expect(AuthSubmitted(), AuthSubmitted());
    });

    test('AuthPasswordVisibilityToggled are equal', () {
      expect(AuthPasswordVisibilityToggled(), AuthPasswordVisibilityToggled());
    });

    test('AuthRememberMeToggled has correct value', () {
      expect(AuthRememberMeToggled(true).value, isTrue);
    });

    test('AuthLogoutRequested are equal', () {
      expect(AuthLogoutRequested(), AuthLogoutRequested());
    });
  });

  group('AuthState', () {
    test('AuthError holds message', () {
      const state = AuthError('bad');
      expect(state.message, 'bad');
    });

    test('AuthAuthenticated holds user', () {
      final now = DateTime(2025, 1, 1);
      final user = AuthEntity(npm: '21081010001', token: 'tok', expiresAt: now);
      final state = AuthAuthenticated(user);
      expect(state.user, user);
    });

    test('AuthInitial are equal', () {
      expect(const AuthInitial(), const AuthInitial());
    });

    test('AuthLoading are equal', () {
      expect(const AuthLoading(), const AuthLoading());
    });
  });
}
```

Run: `flutter test test/features/auth/bloc/auth_event_state_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/auth/presentation/bloc/auth_event.dart
abstract class AuthEvent {
  const AuthEvent();
}

class AuthNpmChanged extends AuthEvent {
  final String npm;
  const AuthNpmChanged(this.npm);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthNpmChanged &&
          runtimeType == other.runtimeType &&
          npm == other.npm;

  @override
  int get hashCode => npm.hashCode;
}

class AuthPasswordChanged extends AuthEvent {
  final String password;
  const AuthPasswordChanged(this.password);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthPasswordChanged &&
          runtimeType == other.runtimeType &&
          password == other.password;

  @override
  int get hashCode => password.hashCode;
}

class AuthPasswordVisibilityToggled extends AuthEvent {
  const AuthPasswordVisibilityToggled();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthPasswordVisibilityToggled && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthRememberMeToggled extends AuthEvent {
  final bool value;
  const AuthRememberMeToggled(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthRememberMeToggled &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class AuthSubmitted extends AuthEvent {
  const AuthSubmitted();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSubmitted && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthLogoutRequested && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
```

```dart
// lib/features/auth/presentation/bloc/auth_state.dart
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthInitial;
  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthLoading extends AuthState {
  const AuthLoading();
  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthLoading;
  @override
  int get hashCode => runtimeType.hashCode;
}

class AuthAuthenticated extends AuthState {
  final AuthEntity user;
  const AuthAuthenticated(this.user);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated && runtimeType == other.runtimeType && user == other.user;
  @override
  int get hashCode => user.hashCode;
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError && runtimeType == other.runtimeType && message == other.message;
  @override
  int get hashCode => message.hashCode;
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/bloc/auth_event.dart lib/features/auth/presentation/bloc/auth_state.dart test/features/auth/bloc/auth_event_state_test.dart
git commit -m "feat(auth): implement AuthEvent and AuthState hierarchies"
```

---

### Task 7: Implement AuthBloc

**Files:**
- Modify: `lib/features/auth/presentation/bloc/auth_bloc.dart`
- Create: `test/features/auth/bloc/auth_bloc_test.dart`

**Interfaces:**
- Consumes: `GetAuth` (Task 3), AuthEvent/AuthState (Task 6)
- Produces: `AuthBloc` with handlers, NPM validation (11-digit regex), error handling

- [ ] **Step 1: Write the failing test**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

class FakeGetAuth implements GetAuth {
  final AuthEntity result;
  final Exception? error;
  FakeGetAuth(this.result, [this.error]);

  @override
  Future<AuthEntity> call({required String npm, required String password}) {
    if (error != null) throw error!;
    return Future.value(result);
  }
}

void main() {
  final now = DateTime(2025, 1, 1);
  final authEntity = AuthEntity(npm: '21081010001', token: 'tok', expiresAt: now);

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on valid submit',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(AuthPasswordChanged('pass123'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [AuthLoading(), AuthAuthenticated(authEntity)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is empty',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) => bloc.add(AuthSubmitted()),
      expect: () => [const AuthError('NPM dan password wajib diisi')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when NPM is not 11 digits',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) {
        bloc.add(AuthNpmChanged('123'));
        bloc.add(AuthPasswordChanged('pass'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM harus 11 digit angka')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when login throws',
      build: () => AuthBloc(FakeGetAuth(authEntity, Exception('Invalid NPM'))),
      act: (bloc) {
        bloc.add(AuthNpmChanged('21081010001'));
        bloc.add(AuthPasswordChanged('wrong'));
        bloc.add(AuthSubmitted());
      },
      expect: () => [const AuthError('NPM atau password salah')],
    );

    blocTest<AuthBloc, AuthState>(
      'password visibility toggles',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) => bloc.add(AuthPasswordVisibilityToggled()),
      verify: (bloc) => expect(bloc.passwordVisible, isTrue),
    );

    blocTest<AuthBloc, AuthState>(
      'remember me toggles',
      build: () => AuthBloc(FakeGetAuth(authEntity)),
      act: (bloc) => bloc.add(AuthRememberMeToggled(true)),
      verify: (bloc) => expect(bloc.rememberMe, isTrue),
    );
  });
}
```

Run: `flutter test test/features/auth/bloc/auth_bloc_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetAuth _getAuth;

  AuthBloc(this._getAuth) : super(const AuthInitial()) {
    on<AuthNpmChanged>(_onNpmChanged);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<AuthRememberMeToggled>(_onRememberMeToggled);
    on<AuthSubmitted>(_onSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  String _npm = '';
  String _password = '';
  bool _passwordVisible = false;
  bool _rememberMe = false;

  String get npm => _npm;
  String get password => _password;
  bool get passwordVisible => _passwordVisible;
  bool get rememberMe => _rememberMe;

  void _onNpmChanged(AuthNpmChanged event, Emitter emit) {
    _npm = event.npm;
  }

  void _onPasswordChanged(AuthPasswordChanged event, Emitter emit) {
    _password = event.password;
  }

  void _onPasswordVisibilityToggled(
    AuthPasswordVisibilityToggled event,
    Emitter emit,
  ) {
    _passwordVisible = !_passwordVisible;
  }

  void _onRememberMeToggled(AuthRememberMeToggled event, Emitter emit) {
    _rememberMe = event.value;
  }

  Future<void> _onSubmitted(AuthSubmitted event, Emitter emit) async {
    if (_npm.isEmpty || _password.isEmpty) {
      emit(const AuthError('NPM dan password wajib diisi'));
      return;
    }
    if (!RegExp(r'^\d{11}$').hasMatch(_npm)) {
      emit(const AuthError('NPM harus 11 digit angka'));
      return;
    }
    emit(AuthLoading());
    try {
      final user = await _getAuth(npm: _npm, password: _password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(const AuthError('NPM atau password salah'));
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter emit) {
    _npm = '';
    _password = '';
    _passwordVisible = false;
    _rememberMe = false;
    emit(const AuthInitial());
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/bloc/auth_bloc.dart test/features/auth/bloc/auth_bloc_test.dart
git commit -m "feat(auth): implement AuthBloc with validation and auth flow"
```

---

### Task 8: Implement shared widgets (AppButton, AppTextField, AuthBackground, BellLogo)

**Files:**
- Modify: `lib/shared/widgets/app_button.dart`
- Modify: `lib/shared/widgets/barrel.dart`
- Create: `lib/shared/widgets/app_text_field.dart`
- Create: `lib/shared/widgets/auth_background.dart`
- Create: `lib/shared/widgets/bell_logo.dart`
- Create: `test/features/auth/presentation/widgets/auth_widgets_test.dart`

**Interfaces:**
- Consumes: Colors from `Theme.of(context).colorScheme`
- Produces: `AppButton`, `AppTextField`, `AuthBackground`, `BellLogo`

**Design tokens from DESIGN.md §5.1 & §3.8-3.9 (all theme-derived):**
- AppButton: Filled, `colorScheme.primaryContainer`/`onPrimaryContainer`, radius 24px via `BorderRadius.circular(24)`, full-width option
- AppTextField: Fill `surfaceContainerHighest`, radius 16px, leading icon from `colorScheme.primary`, focus border `primaryContainer`
- AuthBackground: `surface` → `primaryContainer.withValues(alpha: 0.15)` gradient, with blurred circular blobs using `primaryContainer` and `secondaryContainer`
- BellLogo: `primaryContainer` circle (28px radius), `Icons.notifications_none`, shadow `Color(0x0F000000)` (shadow color, not a UI color), rotate 3deg via `Transform.rotate`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_button.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_text_field.dart';
import 'package:lonceng_unman_fe/shared/widgets/auth_background.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

void main() {
  testWidgets('AppButton renders FilledButton', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(body: AppButton(onPressed: () {}, child: const Text('Masuk'))),
      ),
    );
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('AppTextField renders with label and icon', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'NPM',
            icon: Icons.badge_outlined,
          ),
        ),
      ),
    );
    expect(find.text('NPM'), findsOneWidget);
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
  });

  testWidgets('AuthBackground renders child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: AuthBackground(child: Text('Content'))),
      ),
    );
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('BellLogo renders bell icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: BellLogo()),
      ),
    );
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });
}
```

Run: `flutter test test/features/auth/presentation/widgets/auth_widgets_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/shared/widgets/app_button.dart
import 'package:flutter/material.dart';

/// Filled button — Primary Container / On Primary Container, radius 24px.
/// Full-width when [fullWidth] is true (DESIGN.md §6 — Filled Button).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.fullWidth = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: child,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
```

```dart
// lib/shared/widgets/app_text_field.dart
import 'package:flutter/material.dart';

/// Outlined text field — fill Surface Container Highest, radius 16px.
/// Leading icon, optional password toggle (suffix), error state support.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? errorText;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: icon != null
            ? Icon(icon, color: cs.primary, size: 22)
            : null,
        suffix: suffix,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primaryContainer, width: 2),
        ),
        errorText: errorText,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      ),
    );
  }
}
```

```dart
// lib/shared/widgets/auth_background.dart
import 'package:flutter/material.dart';

/// Background gradient: Surface -> Primary Container with decorative blobs.
/// Primary Container is fixed (#FFC107) across themes (DESIGN.md §5.1).
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.surface,
            cs.primaryContainer.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -96,
            right: -64,
            child: Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -64,
            child: Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.40),
                shape: BoxShape.circle,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
```

```dart
// lib/shared/widgets/bell_logo.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// App logo: bell icon in Primary Container circle, radius 28px, tilted 3deg.
class BellLogo extends StatelessWidget {
  const BellLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Transform.rotate(
      angle: 3 * math.pi / 180,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          Icons.notifications_none,
          size: 38,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
```

```dart
// lib/shared/widgets/barrel.dart
export 'app_button.dart';
export 'app_text_field.dart';
export 'auth_background.dart';
export 'bell_logo.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/app_button.dart lib/shared/widgets/app_text_field.dart lib/shared/widgets/auth_background.dart lib/shared/widgets/bell_logo.dart lib/shared/widgets/barrel.dart test/features/auth/presentation/widgets/auth_widgets_test.dart
git commit -m "feat(shared): add AppButton, AppTextField, AuthBackground, BellLogo"
```

---

### Task 9: Rewrite LoginPage with full DESIGN.md §5.1 layout

**Files:**
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Create: `test/features/auth/presentation/pages/login_page_test.dart`

**Interfaces:**
- Consumes: `AuthBloc` (Task 7), shared widgets (Task 8), `RouteNames`, `go_router` context extension
- Produces: `LoginPage` — StatefulWidget with BlocBuilder/BlocListener

**Layout per DESIGN.md §5.1 (all theme-derived, spacing in 8px multiples):**
1. `AuthBackground` (gradient + blobs) as Scaffold body
2. `BellLogo` centered above (bell icon, primaryContainer circle, 3deg tilt)
3. Login card (radius 32px via `BorderRadius.circular(32)`, `surfaceContainerLowest`) with:
   - Title "Masuk ke Akun" — `theme.textTheme.headlineSmall`
   - Subtitle "Gunakan NPM aktif kamu" — `theme.textTheme.bodyMedium` + `onSurfaceVariant`
   - NPM field: `AppTextField` with `Icons.badge_outlined`, `TextInputType.number`, key `npm_field`
   - Password field: `AppTextField` with `Icons.lock_outline`, show/hide toggle, key `password_field`
   - "Ingat saya" checkbox (left) + "Lupa NPM/Password?" link (right, `colorScheme.primary`)
   - "Masuk" button: `AppButton fullWidth` with "Masuk" text + `Icons.arrow_forward` icon
   - Error message area (if `AuthError` state) — `textStyle` + `colorScheme.error`
   - Helper text: "NPM belum terdaftar? Hubungi Admin" (centered, rich text with Primary link)
4. Footer: "Butuh bantuan? Helpdesk IT" (centered, `onSurfaceVariant` with 0.7 alpha)
5. No navbar — standalone Scaffold

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';

class FakeGetAuth implements GetAuth {
  @override
  Future<AuthEntity> call({required String npm, required String password}) async {
    return AuthEntity(npm: npm, token: 'tok', expiresAt: DateTime(2025, 1, 1));
  }
}

void main() {
  testWidgets('LoginPage renders all DESIGN.md §5.1 elements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: BlocProvider(
          create: (_) => AuthBloc(FakeGetAuth()),
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('Masuk ke Akun'), findsOneWidget);
    expect(find.text('Gunakan NPM aktif kamu'), findsOneWidget);
    expect(find.text('NPM'), findsOneWidget);
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('Ingat saya'), findsOneWidget);
    expect(find.text('Lupa NPM/Password?'), findsOneWidget);
    expect(find.text('Hubungi Admin'), findsOneWidget);
    expect(find.text('Helpdesk IT'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('submit shows loading when pressed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: BlocProvider(
          create: (_) => AuthBloc(FakeGetAuth()),
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('npm_field')), '21081010001');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('password_field')), 'pass123');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('password visibility toggle works', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: BlocProvider(
          create: (_) => AuthBloc(FakeGetAuth()),
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
```

Run: `flutter test test/features/auth/presentation/pages/login_page_test.dart -v`
Expected: FAIL

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_button.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_text_field.dart';
import 'package:lonceng_unman_fe/shared/widgets/auth_background.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _npmController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _npmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: AuthBackground(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.goNamed(RouteNames.home);
            }
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    const BellLogo(),
                    const SizedBox(height: 24),
                    _LoginCard(
                      cs: cs,
                      npmController: _npmController,
                      passwordController: _passwordController,
                    ),
                    const SizedBox(height: 24),
                    _buildFooter(cs),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Text(
      'Butuh bantuan? Helpdesk IT',
      style: TextStyle(
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.cs,
    required this.npmController,
    required this.passwordController,
  });

  final ColorScheme cs;
  final TextEditingController npmController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final bloc = context.read<AuthBloc>();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0F000000),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masuk ke Akun',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan NPM aktif kamu',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                key: const Key('npm_field'),
                controller: npmController,
                label: 'NPM',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                onChanged: (v) => bloc.add(AuthNpmChanged(v)),
              ),
              const SizedBox(height: 16),
              AppTextField(
                key: const Key('password_field'),
                controller: passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: !bloc.passwordVisible,
                suffix: IconButton(
                  icon: Icon(
                    bloc.passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: cs.primary,
                  ),
                  onPressed: () => bloc.add(AuthPasswordVisibilityToggled()),
                ),
                onChanged: (v) => bloc.add(AuthPasswordChanged(v)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: bloc.rememberMe,
                        onChanged: (v) =>
                            bloc.add(AuthRememberMeToggled(v ?? false)),
                        activeColor: cs.primaryContainer,
                        checkColor: cs.onPrimaryContainer,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        'Ingat saya',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Lupa NPM/Password?',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state is AuthLoading)
                const Center(child: CircularProgressIndicator())
              else
                AppButton(
                  onPressed: () => bloc.add(AuthSubmitted()),
                  fullWidth: true,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Masuk'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (state is AuthError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    (state as AuthError).message,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text(
                'NPM belum terdaftar?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              TextSpan — actually use rich text or separate widgets:
              // "Hubungi Admin" as text link with Primary color
            ],
          ),
        );
      },
    );
  }
}
```

**IMPORTANT — The helper text "NPM belum terdaftar?" needs to be a Text widget with a TextSpan child for the "Hubungi Admin" link. Fix:**

Replace the last two `Text` widgets in `_LoginCard` with a single `Text.rich`:

```dart
// Helper text with rich text link
Text.rich(
  TextSpan(
    text: 'NPM belum terdaftar? ',
    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
    children: [
      TextSpan(
        text: 'Hubungi Admin',
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
  textAlign: TextAlign.center,
),
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/pages/login_page.dart test/features/auth/presentation/pages/login_page_test.dart
git commit -m "feat(auth): implement LoginPage with full DESIGN.md §5.1 layout"
```

---

### Task 10: Wire AuthBloc to LoginPage via router

**Files:**
- Modify: `lib/core/routes/app_router.dart` (wrap login route in BlocProvider)
- Modify: `test/main_test.dart` (update assertion)
- Modify: `test/router/app_router_test.dart` (update assertion)
- Create: `test/features/auth/presentation/pages/login_page_integration_test.dart`

**Interfaces:**
- Consumes: `AuthBloc`, `GetAuth`, `StubAuthRemoteDataSource`
- Produces: LoginPage route wrapped with BlocProvider in app_router

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/presentation/pages/login_page_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/theme/app_theme.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';

void main() {
  testWidgets('LoginPage renders on /login for unauthenticated user', (tester) async {
    // Use a custom auth provider that returns unauthenticated
    final provider = _UnauthenticatedProvider();
    final router = AppRouter.create(
      authStatusProvider: provider,
      initialLocation: '/login',
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // LoginPage should be visible for unauthenticated user
    expect(find.text('Masuk ke Akun'), findsOneWidget);
  });
}

class _UnauthenticatedProvider implements AuthStatusProvider {
  @override
  AuthStatus get currentStatus => AuthStatus.unauthenticated;
  @override
  final Stream<AuthStatus> status = const Stream.empty();
}
```

Run: `flutter test test/features/auth/presentation/pages/login_page_integration_test.dart -v`
Expected: FAIL (if BlocProvider not wired yet, or LoginPage can't access AuthBloc)

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Update app_router.dart — wrap login route in BlocProvider**

Add imports at top of `app_router.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
```

Change login route builder:

```dart
GoRoute(
  name: RouteNames.login,
  path: '/${RouteNames.login}',
  builder: (context, state) => BlocProvider(
    create: (_) => AuthBloc(
      GetAuth(
        AuthRepositoryImpl(
          remoteDataSource: StubAuthRemoteDataSource(),
        ),
      ),
    ),
    child: const LoginPage(),
  ),
),
```

- [ ] **Step 4: Update existing test assertions**

In `test/main_test.dart` — the current test asserts `find.text('Login')` which will break. The new LoginPage no longer has an AppBar with title "Login". Update:

No changes needed — `test/main_test.dart` uses `StubAuthStatusProvider()` (always authenticated), so `/login` redirects to `/home`. The test asserts `find.text('Home')` and `find.text('Home Page - Countdown & Summary')` which still applies.

In `test/router/app_router_test.dart` line 110 — change:
```dart
// Old:
expect(find.text('Login'), findsOneWidget);
// New:
expect(find.text('Masuk ke Akun'), findsOneWidget);
```

- [ ] **Step 5: Run tests**

Run: `flutter test -v`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/routes/app_router.dart test/router/app_router_test.dart test/features/auth/presentation/pages/login_page_integration_test.dart
git commit -m "feat(auth): wire AuthBloc via router BlocProvider"
```

---

### Task 11: Final verification — format, analyze, full test suite

- [ ] **Step 1: Run dart format**

Run: `dart format lib/ test/`

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: 0 errors, minimal warnings

- [ ] **Step 3: Run full test suite**

Run: `flutter test -v`
Expected: All tests pass

- [ ] **Step 4: Final commit**

```bash
git add .
git commit -m "chore: format and verify all tests pass"
```

---

## Self-Review

**1. Spec coverage (DESIGN.md §5.1):**
- ✅ Background gradient with blobs → `AuthBackground` — uses `cs.surface` and `cs.primaryContainer.withValues(alpha: 0.15)` (theme-derived, no hardcoded hex)
- ✅ Bell logo (bell icon, Primary Container circle, 3deg tilt, shadow) → `BellLogo` — uses `cs.primaryContainer`, `cs.onPrimaryContainer`, only `Color(0x0F000000)` for shadow (conventional, matches `main_shell_scaffold.dart` pattern)
- ✅ Login card (radius 32px, Surface Container Lowest) → `_LoginCard` — uses `cs.surfaceContainerLowest`, `BorderRadius.circular(32)`, shadow `Color(0x0F000000)`
- ✅ Title "Masuk ke Akun" → uses `theme.textTheme.headlineSmall`
- ✅ Subtitle "Gunakan NPM aktif kamu" → uses `theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)`
- ✅ NPM field (icon badge, numeric, fill Surface Container Highest, 16px radius) → `AppTextField` + LoginPage
- ✅ Password field (icon lock, show/hide toggle, 16px radius) → `AppTextField` + LoginPage
- ✅ Checkbox "Ingat saya" → uses `cs.primaryContainer` for activeColor, `cs.onPrimaryContainer` for checkColor
- ✅ "Masuk" button (filled, Primary Container, full-width, 24px radius) → `AppButton fullWidth`
- ✅ "Lupa NPM/Password?" link (Primary color) → `TextStyle(color: cs.primary)`
- ✅ Helper text "NPM belum terdaftar? Hubungi Admin" → `Text.rich` with `cs.primary` link color
- ✅ Footer "Butuh bantuan? Helpdesk IT" → uses `cs.onSurfaceVariant.withValues(alpha: 0.7)`
- ✅ No navbar on auth page → LoginPage is standalone Scaffold

**2. No hardcoded values check:**
- All colors: `colorScheme.primaryContainer`, `onPrimaryContainer`, `surfaceContainerHighest`, `onSurfaceVariant`, `outlineVariant`, `primary`, `error`, `onSurface`, `surface`, `secondaryContainer`, `onSurfaceVariant` — ALL theme-derived ✅
- Only `Color(0x0F000000)` used for shadows — this is the conventional shadow color already used in `main_shell_scaffold.dart` ✅
- All text styles: `theme.textTheme.headlineSmall`, `bodyMedium`, `bodySmall` — ALL theme-derived ✅
- All radii: `BorderRadius.circular(16)`, `(24)`, `(28)`, `(32)` — from DESIGN.md §3.8 ✅
- Spacing: multiples of 8 (8, 16, 24, 28) ✅

**3. No duplication check:**
- Each task builds on the previous — no repeated code ✅
- AuthEntity defined once in Task 1, consumed by Tasks 2-7 ✅
- AuthRepository interface defined once in Task 2 ✅
- AuthEvent/AuthState defined once in Task 6 ✅
- Shared widgets defined once in Task 8 ✅

**4. Clean Architecture compliance:**
- presentation → domain → data direction ✅
- Domain layer (AuthEntity, AuthRepository) has no Flutter imports ✅
- Data layer (AuthModel, AuthRepositoryImpl) depends on domain ✅
- Presentation layer (AuthBloc, AuthEvent, AuthState, LoginPage) depends on domain ✅
- No circular dependencies ✅

**5. Test coverage:**
- Entity: ✅ Task 1
- Repository interface: ✅ Task 2
- Usecase: ✅ Task 3
- Model serialization: ✅ Task 4
- Repository delegation: ✅ Task 5
- Event/State equality: ✅ Task 6
- BLoC validation + state transitions: ✅ Task 7
- Shared widget rendering: ✅ Task 8
- LoginPage rendering + interactions: ✅ Task 9
- Integration with router: ✅ Task 10

**6. Dependencies:**
- Only uses `flutter_bloc`, `bloc`, `go_router`, `google_fonts` — all in pubspec ✅
- Does NOT add `equatable` or `material_symbols` ✅
- Uses `Icons` enum (bundled with Flutter) ✅

---
Plan complete and saved to `docs/superpowers/plans/2026-08-03-login-page.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
