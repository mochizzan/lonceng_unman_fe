import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/khs_timeline_view.dart';

void main() {
  group('parseKhsDetail', () {
    test('parses "2022/2023 Ganjil" correctly', () {
      final r = parseKhsDetail('2022/2023 Ganjil');
      expect(r, isNotNull);
      expect(r!.tahunAjaran, '2022/2023');
      expect(r.semester, 'Ganjil');
    });

    test('parses "2022/2023 Genap" correctly', () {
      final r = parseKhsDetail('2022/2023 Genap');
      expect(r, isNotNull);
      expect(r!.tahunAjaran, '2022/2023');
      expect(r.semester, 'Genap');
    });

    test('handles tahunAjaran with spaces via lastIndexOf', () {
      // e.g. future format "2022/2023 Ganjil Khusus" — last space split still correct.
      final r = parseKhsDetail('2022/2023 Ganjil Khusus');
      expect(r, isNotNull);
      expect(r!.tahunAjaran, '2022/2023 Ganjil');
      expect(r.semester, 'Khusus');
    });

    test('returns null for null input', () {
      expect(parseKhsDetail(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseKhsDetail(''), isNull);
    });

    test('returns null for single token without space', () {
      expect(parseKhsDetail('Ganjil'), isNull);
    });

    test('returns null for "2022/2023" without semester token', () {
      // No space → lastIndexOf returns -1 → null.
      expect(parseKhsDetail('2022/2023'), isNull);
    });
  });
}
