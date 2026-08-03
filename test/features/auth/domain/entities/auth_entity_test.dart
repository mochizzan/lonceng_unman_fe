// test/features/auth/domain/entities/auth_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

void main() {
  group('AuthEntity', () {
    test('constructs with all fields', () {
      final now = DateTime(2025, 1, 1);
      final entity = AuthEntity(
        npm: '21081010001',
        token: 'abc123',
        expiresAt: now,
      );
      expect(entity.npm, '21081010001');
      expect(entity.token, 'abc123');
      expect(entity.expiresAt, now);
    });

    test('two instances with equal fields are equal', () {
      final now = DateTime(2025, 1, 1);
      final a = AuthEntity(npm: '21081010001', token: 'abc123', expiresAt: now);
      final b = AuthEntity(npm: '21081010001', token: 'abc123', expiresAt: now);
      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different fields are not equal', () {
      final now = DateTime(2025, 1, 1);
      final a = AuthEntity(npm: '21081010001', token: 'abc123', expiresAt: now);
      final b = AuthEntity(
        npm: '21081010001',
        token: 'abc123',
        expiresAt: DateTime(2025, 1, 2),
      );
      expect(a == b, isFalse);
    });
  });
}
