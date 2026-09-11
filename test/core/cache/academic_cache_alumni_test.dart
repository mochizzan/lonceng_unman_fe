// AcademicCache isAlumni + clearKrsDataFor — AC4 isolation
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';

void main() {
  late Directory tmp;
  late AcademicCacheService cache;
  const npmA = '11111111';
  const npmB = '22222222';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hive_alumni_');
    Hive.init(tmp.path);
    cache = AcademicCacheService();
    await cache.initialize();
  });

  tearDown(() async {
    await cache.clearAll();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('saveIsAlumni/loadIsAlumni round-trip', () async {
    expect(await cache.loadIsAlumni(npm: npmA), isFalse);
    await cache.saveIsAlumni(npm: npmA, isAlumni: true);
    expect(await cache.loadIsAlumni(npm: npmA), isTrue);
    await cache.saveIsAlumni(npm: npmA, isAlumni: false);
    expect(await cache.loadIsAlumni(npm: npmA), isFalse);
  });

  test('clearKrsDataFor only clears krs, keeps khsList and isAlumni', () async {
    await cache.saveKrsData(
      npm: npmA,
      data: {
        'krs': {'mataKuliah': []},
      },
    );
    await cache.saveKhsList(
      npm: npmA,
      data: [
        {'tahunAjaran': '2025/2026', 'semester': 'GANJIL'},
      ],
    );
    await cache.saveIsAlumni(npm: npmA, isAlumni: true);

    await cache.clearKrsDataFor(npm: npmA);

    expect(await cache.loadKrsData(npm: npmA), isNull);
    expect(await cache.loadIsAlumni(npm: npmA), isTrue);
    expect(await cache.loadKhsList(npm: npmA), isNotNull);
  });

  test('clearKrsDataFor does not affect other NPM', () async {
    await cache.saveKrsData(
      npm: npmA,
      data: {
        'krs': {'a': 1},
      },
    );
    await cache.saveKrsData(
      npm: npmB,
      data: {
        'krs': {'b': 2},
      },
    );

    await cache.clearKrsDataFor(npm: npmA);

    expect(await cache.loadKrsData(npm: npmA), isNull);
    expect(await cache.loadKrsData(npm: npmB), isNotNull);
  });
}
