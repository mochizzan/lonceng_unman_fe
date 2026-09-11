// KrsDS writer 409/200/404 — AC4 & AC5
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';

void main() {
  late Directory tmp;
  late AcademicCacheService cache;
  const npm = '33333333';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hive_krs_alumni_');
    Hive.init(tmp.path);
    cache = AcademicCacheService();
    await cache.initialize();
  });

  tearDown(() async {
    await cache.clearAll();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  http.Client alumniClient() => MockClient((_) async {
    return http.Response(
      jsonEncode({
        'status': 'error',
        'message': 'Mahasiswa status ALUMNI — KRS tidak tersedia',
      }),
      409,
      headers: {'content-type': 'application/json'},
    );
  });

  http.Client notFoundClient() => MockClient((_) async {
    return http.Response(
      jsonEncode({'status': 'error', 'message': 'Not found'}),
      404,
      headers: {'content-type': 'application/json'},
    );
  });

  test(
    '409 clears krs + sets isAlumni true + rethrows AlumniException',
    () async {
      // Seed krs so we can verify it gets cleared.
      await cache.saveKrsData(
        npm: npm,
        data: {
          'krs': {
            'periode': {'tahun_ajaran': '2025/2026', 'semester': 'GANJIL'},
            'mahasiswa': {'nama': 'A', 'program_studi': 'SI'},
            'mataKuliah': [],
            'totalSks': 0,
          },
        },
      );
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: alumniClient(),
      );
      final ds = KrsRemoteDataSourceImpl(
        apiClient: api,
        academicCacheService: cache,
      );

      await expectLater(
        ds.getKrsData(npm: npm, forceRefresh: true),
        throwsA(isA<AlumniException>()),
      );
      expect(await cache.loadKrsData(npm: npm), isNull);
      expect(await cache.loadIsAlumni(npm: npm), isTrue);
    },
  );

  test('404 sets isAlumni false and does NOT clear krs', () async {
    await cache.saveKrsData(
      npm: npm,
      data: {
        'krs': {
          'periode': {'tahun_ajaran': '2025/2026', 'semester': 'GANJIL'},
          'mahasiswa': {'nama': 'A', 'program_studi': 'SI'},
          'mataKuliah': [],
          'totalSks': 0,
        },
      },
    );
    await cache.saveIsAlumni(npm: npm, isAlumni: true);
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: notFoundClient(),
    );
    final ds = KrsRemoteDataSourceImpl(
      apiClient: api,
      academicCacheService: cache,
    );

    await expectLater(
      ds.getKrsData(npm: npm, forceRefresh: true),
      throwsA(isA<ServerException>()),
    );
    expect(await cache.loadKrsData(npm: npm), isNotNull);
    expect(await cache.loadIsAlumni(npm: npm), isFalse);
  });
}
