// HomeDS strict split — AC1, AC2, AC6 (subset)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/features/home/data/datasources/home_remote_data_source.dart';

Map<String, dynamic> _krsJson({
  String tahunAjaran = '2026/2027',
  List<Map<String, dynamic>>? mk,
  int totalSks = 6,
}) {
  return {
    'krs': {
      'periode': {'tahun_ajaran': tahunAjaran, 'semester': 'GANJIL'},
      'mahasiswa': {'npm': '11111111', 'nama': 'Budi', 'program_studi': 'SI'},
      'mata_kuliah':
          mk ??
          [
            {
              'kode': 'MK1',
              'nama': 'Algoritma',
              'sks': 3,
              'jadwal': {
                'hari': 'Senin',
                'waktu_mulai': '08:00',
                'waktu_selesai': '09:40',
                'ruang': 'R101',
              },
              'dosen': 'Dr. A',
            },
            {
              'kode': 'MK2',
              'nama': 'Basis Data',
              'sks': 3,
              'jadwal': {
                'hari': 'Selasa',
                'waktu_mulai': '10:00',
                'waktu_selesai': '11:40',
                'ruang': 'R102',
              },
              'dosen': 'Dr. B',
            },
          ],
      'total_sks': totalSks,
    },
  };
}

Map<String, dynamic> _khsDataJson({
  required String tahunAjaran,
  required String semester,
  required double ipk,
}) {
  return {
    'khs': {
      'mahasiswa': {'npm': '11111111', 'nama': 'Budi', 'program_studi': 'SI'},
      'periode': {'tahun_ajaran': tahunAjaran, 'semester': semester},
      'mata_kuliah': [],
      'rekapitulasi': {'total_sks': 20, 'total_mutu': 70, 'ipk': ipk},
    },
    'metadata': {'extracted_at': '', 'source_file': '', 'file_size': 0},
  };
}

void main() {
  late Directory tmp;
  late AcademicCacheService cache;
  late StudentProfileCacheService profileCache;
  late HomeRemoteDataSourceImpl ds;
  const npm = '11111111';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hive_home_alumni_');
    Hive.init(tmp.path);
    cache = AcademicCacheService();
    await cache.initialize();
    profileCache = StudentProfileCacheService();
    await profileCache.initialize();
    // Seed credentials required by HomeDS
    await cache.saveCredentials(npm: npm, password: 'pass');
    ds = HomeRemoteDataSourceImpl(
      academicCacheService: cache,
      studentProfileCacheService: profileCache,
    );
  });

  tearDown(() async {
    await cache.clearAll();
    await profileCache.clearAll();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test(
    'tahunAjaran max from khsList and IPK pair for latestYear (AC1)',
    () async {
      await cache.saveKhsList(
        npm: npm,
        data: [
          {'tahunAjaran': '2024/2025', 'semester': 'GANJIL', 'sks': 20},
          {'tahunAjaran': '2025/2026', 'semester': 'GENAP', 'sks': 20},
          {'tahunAjaran': '2023/2024', 'semester': 'GANJIL', 'sks': 20},
        ],
      );
      await cache.saveKhsDataSemester(
        npm: npm,
        tahunAjaran: '2025/2026',
        semester: 'GANJIL',
        data: _khsDataJson(
          tahunAjaran: '2025/2026',
          semester: 'GANJIL',
          ipk: 3.2,
        ),
      );
      await cache.saveKhsDataSemester(
        npm: npm,
        tahunAjaran: '2025/2026',
        semester: 'GENAP',
        data: _khsDataJson(
          tahunAjaran: '2025/2026',
          semester: 'GENAP',
          ipk: 3.5,
        ),
      );
      // KRS has different year 2026/2027 — should NOT be used
      await cache.saveKrsData(
        npm: npm,
        data: _krsJson(tahunAjaran: '2026/2027'),
      );

      final model = await ds.getHomeData();
      expect(model.tahunAjaran, '2025/2026');
      expect(model.gpaGanjil, closeTo(3.2, 0.001));
      expect(model.gpaGenap, closeTo(3.5, 0.001));
      expect(model.isAlumni, isFalse);
    },
  );

  test(
    'khsList empty → tahunAjaran "" and gpa 0, jadwal from KRS (AC2)',
    () async {
      await cache.saveKrsData(
        npm: npm,
        data: _krsJson(tahunAjaran: '2026/2027', totalSks: 6),
      );

      final model = await ds.getHomeData();
      expect(model.tahunAjaran, '');
      expect(model.gpaGanjil, 0.0);
      expect(model.gpaGenap, 0.0);
      expect(model.sksTaken, 6);
      expect(model.isAlumni, isFalse);
    },
  );

  test('GENAP missing → gpaGenap 0 (tolerant)', () async {
    await cache.saveKhsList(
      npm: npm,
      data: [
        {'tahunAjaran': '2025/2026', 'semester': 'GANJIL', 'sks': 20},
      ],
    );
    await cache.saveKhsDataSemester(
      npm: npm,
      tahunAjaran: '2025/2026',
      semester: 'GANJIL',
      data: _khsDataJson(
        tahunAjaran: '2025/2026',
        semester: 'GANJIL',
        ipk: 3.0,
      ),
    );
    // GENAP not cached
    final model = await ds.getHomeData();
    expect(model.gpaGanjil, closeTo(3.0, 0.001));
    expect(model.gpaGenap, 0.0);
  });

  test('isAlumni true → schedule empty even if KRS exists (AC6)', () async {
    await cache.saveKhsList(
      npm: npm,
      data: [
        {'tahunAjaran': '2025/2026', 'semester': 'GANJIL', 'sks': 20},
      ],
    );
    await cache.saveKhsDataSemester(
      npm: npm,
      tahunAjaran: '2025/2026',
      semester: 'GANJIL',
      data: _khsDataJson(
        tahunAjaran: '2025/2026',
        semester: 'GANJIL',
        ipk: 3.2,
      ),
    );
    await cache.saveKhsDataSemester(
      npm: npm,
      tahunAjaran: '2025/2026',
      semester: 'GENAP',
      data: _khsDataJson(tahunAjaran: '2025/2026', semester: 'GENAP', ipk: 3.5),
    );
    await cache.saveKrsData(
      npm: npm,
      data: _krsJson(tahunAjaran: '2026/2027', totalSks: 20),
    );
    await cache.saveIsAlumni(npm: npm, isAlumni: true);

    final model = await ds.getHomeData();
    expect(model.isAlumni, isTrue);
    expect(model.scheduleItems, isEmpty);
    expect(model.sksTaken, 0);
    expect(model.nextClass, isNull);
    expect(model.tahunAjaran, '2025/2026');
  });

  test(
    'latest handles legacy tahun_ajaran key and skips invalid entries',
    () async {
      await cache.saveKhsList(
        npm: npm,
        data: [
          {'tahun_ajaran': '2024/2025', 'semester': 'GANJIL', 'sks': 20},
          {'tahunAjaran': 'invalid', 'semester': 'GANJIL', 'sks': 20},
          {'tahunAjaran': '2025/2026', 'semester': 'GANJIL', 'sks': 20},
        ],
      );
      await cache.saveKhsDataSemester(
        npm: npm,
        tahunAjaran: '2025/2026',
        semester: 'GANJIL',
        data: _khsDataJson(
          tahunAjaran: '2025/2026',
          semester: 'GANJIL',
          ipk: 3.1,
        ),
      );
      final model = await ds.getHomeData();
      expect(model.tahunAjaran, '2025/2026');
    },
  );
}
