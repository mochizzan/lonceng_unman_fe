// test/features/auth/data/datasources/auth_remote_data_source_test.dart
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
      final model = AuthModel(
        npm: '21081010001',
        token: 'abc123',
        expiresAt: now,
      );
      final map = model.toMap();
      expect(map['npm'], '21081010001');
      expect(map['token'], 'abc123');
      expect(map['expiresAt'], now.toIso8601String());
    });
  });
}
