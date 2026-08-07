// KRS (Kartu Rencana Studi) entities.
//
// Domain-layer entities representing KRS data from the LMS.
// Follows Clean Architecture: domain layer has no framework dependencies.

import 'package:lonceng_unman_fe/core/domain/metadata_entity.dart';
import 'package:lonceng_unman_fe/core/utils/app_utils.dart';

class MahasiswaEntity {
  final String nama;
  final String npm;
  final String programStudi;

  const MahasiswaEntity({
    required this.nama,
    required this.npm,
    required this.programStudi,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MahasiswaEntity &&
          runtimeType == other.runtimeType &&
          nama == other.nama &&
          npm == other.npm &&
          programStudi == other.programStudi;

  @override
  int get hashCode => Object.hash(nama, npm, programStudi);
}

class PeriodeEntity {
  final String tahunAjaran;
  final String semester;

  const PeriodeEntity({required this.tahunAjaran, required this.semester});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodeEntity &&
          runtimeType == other.runtimeType &&
          tahunAjaran == other.tahunAjaran &&
          semester == other.semester;

  @override
  int get hashCode => Object.hash(tahunAjaran, semester);
}

class MataKuliahKrsEntity {
  final String kode;
  final String nama;
  final int sks;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String dosen;

  const MataKuliahKrsEntity({
    required this.kode,
    required this.nama,
    required this.sks,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.dosen,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MataKuliahKrsEntity &&
          runtimeType == other.runtimeType &&
          kode == other.kode &&
          nama == other.nama &&
          sks == other.sks &&
          hari == other.hari &&
          jamMulai == other.jamMulai &&
          jamSelesai == other.jamSelesai &&
          dosen == other.dosen;

  @override
  int get hashCode =>
      Object.hash(kode, nama, sks, hari, jamMulai, jamSelesai, dosen);
}

class KrsDataEntity {
  final MahasiswaEntity mahasiswa;
  final PeriodeEntity periode;
  final List<MataKuliahKrsEntity> mataKuliah;
  final int totalSks;

  const KrsDataEntity({
    required this.mahasiswa,
    required this.periode,
    required this.mataKuliah,
    required this.totalSks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KrsDataEntity &&
          runtimeType == other.runtimeType &&
          mahasiswa == other.mahasiswa &&
          periode == other.periode &&
          listEquals(mataKuliah, other.mataKuliah) &&
          totalSks == other.totalSks;

  @override
  int get hashCode => Object.hash(mahasiswa, periode, totalSks);
}

class KrsEntity {
  final KrsDataEntity krs;
  final MetadataEntity metadata;

  const KrsEntity({required this.krs, required this.metadata});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KrsEntity &&
          runtimeType == other.runtimeType &&
          krs == other.krs &&
          metadata == other.metadata;

  @override
  int get hashCode => Object.hash(krs, metadata);
}
