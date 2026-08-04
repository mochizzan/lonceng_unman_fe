import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/utils/day_name_mapper.dart';

void main() {
  group('DayNameMapper', () {
    group('weekdayFromName', () {
      test('returns DateTime.monday for Senin', () {
        expect(DayNameMapper.weekdayFromName('Senin'), DateTime.monday);
      });

      test('returns DateTime.tuesday for Selasa', () {
        expect(DayNameMapper.weekdayFromName('Selasa'), DateTime.tuesday);
      });

      test('returns DateTime.wednesday for Rabu', () {
        expect(DayNameMapper.weekdayFromName('Rabu'), DateTime.wednesday);
      });

      test('returns DateTime.thursday for Kamis', () {
        expect(DayNameMapper.weekdayFromName('Kamis'), DateTime.thursday);
      });

      test('returns DateTime.friday for Jumat', () {
        expect(DayNameMapper.weekdayFromName('Jumat'), DateTime.friday);
      });

      test('returns DateTime.saturday for Sabtu', () {
        expect(DayNameMapper.weekdayFromName('Sabtu'), DateTime.saturday);
      });

      test('returns DateTime.sunday for Minggu', () {
        expect(DayNameMapper.weekdayFromName('Minggu'), DateTime.sunday);
      });

      test('throws ArgumentError for unknown day name', () {
        expect(
          () => DayNameMapper.weekdayFromName('InvalidDay'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('nextOccurrence', () {
      test('returns today when target day is today', () {
        // 2026-08-05 is a Wednesday (Rabu)
        final now = DateTime(2026, 8, 5, 10, 0);
        final result = DayNameMapper.nextOccurrence('Rabu', now: now);
        expect(result, DateTime(2026, 8, 5));
      });

      test('returns next week when target day has passed', () {
        // 2026-08-05 is Wednesday, Senin (Monday) was 2 days ago
        final now = DateTime(2026, 8, 5, 10, 0);
        final result = DayNameMapper.nextOccurrence('Senin', now: now);
        expect(result, DateTime(2026, 8, 10)); // Next Monday
      });

      test('returns tomorrow when target day is tomorrow', () {
        // 2026-08-05 is Wednesday, Kamis (Thursday) is tomorrow
        final now = DateTime(2026, 8, 5, 10, 0);
        final result = DayNameMapper.nextOccurrence('Kamis', now: now);
        expect(result, DateTime(2026, 8, 6));
      });

      test('returns next occurrence 6 days later', () {
        // 2026-08-05 is Wednesday, Minggu (Sunday) is 4 days later
        final now = DateTime(2026, 8, 5, 10, 0);
        final result = DayNameMapper.nextOccurrence('Minggu', now: now);
        expect(result, DateTime(2026, 8, 9));
      });
    });

    group('availableDays', () {
      test('returns all 7 Indonesian day names', () {
        expect(DayNameMapper.availableDays, hasLength(7));
        expect(DayNameMapper.availableDays, contains('Senin'));
        expect(DayNameMapper.availableDays, contains('Minggu'));
      });
    });
  });
}
