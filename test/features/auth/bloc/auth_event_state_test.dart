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
