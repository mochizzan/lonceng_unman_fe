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
  });
}
