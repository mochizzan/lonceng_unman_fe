// test/features/auth/data/datasources/auth_remote_data_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/auth/data/models/auth_model.dart';

void main() {
  group('AuthModel', () {
    test('fromMap creates AuthModel from JSON map', () {
      final model = AuthModel.fromMap({
        'npm': '21081010001',
        'password': 'secret',
      });
      expect(model.npm, '21081010001');
      expect(model.password, 'secret');
    });

    test('toMap serializes to JSON map', () {
      final model = AuthModel(npm: '21081010001', password: 'secret');
      final map = model.toMap();
      expect(map['npm'], '21081010001');
      expect(map['password'], 'secret');
    });
  });
}
