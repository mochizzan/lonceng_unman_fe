// test/features/auth/domain/entities/auth_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/domain/entities/auth_entity.dart';

void main() {
  group('AuthEntity', () {
    test('constructs with all fields', () {
      final entity = AuthEntity(npm: '21081010001', password: 'abc123');
      expect(entity.npm, '21081010001');
      expect(entity.password, 'abc123');
    });

    test('two instances with equal fields are equal', () {
      final a = AuthEntity(npm: '21081010001', password: 'abc123');
      final b = AuthEntity(npm: '21081010001', password: 'abc123');
      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different fields are not equal', () {
      final a = AuthEntity(npm: '21081010001', password: 'abc123');
      final b = AuthEntity(npm: '21081010001', password: 'different');
      expect(a == b, isFalse);
    });
  });
}
