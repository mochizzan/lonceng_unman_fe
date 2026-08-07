// KHS (Kartu Hasil Studi) entities.
//
// Domain-layer entities representing KHS data from the LMS.
// Follows Clean Architecture: domain layer has no framework dependencies.

import 'package:lonceng_unman_fe/core/domain/metadata_entity.dart';
import 'package:lonceng_unman_fe/core/utils/app_utils.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';

class MataKuliahKhsEntity {
  final String kode;
  final String nama;
  final int sks;
  final String nilai;
  final double bobot;
  final int mutu;

  const MataKuliahKhsEntity({
    required this.kode,
    required this.nama,
    required this.sks,
    required this.nilai,
    required this.bobot,
    required this.mutu,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MataKuliahKhsEntity &&
          runtimeType == other.runtimeType &&
          kode == other.kode &&
          nama == other.nama &&
          sks == other.sks &&
          nilai == other.nilai &&
          bobot == other.bobot &&
          mutu == other.mutu;

  @override
  int get hashCode => Object.hash(kode, nama, sks, nilai, bobot, mutu);
}

class RekapitulasiEntity {
  final int totalSks;
  final int totalMutu;
  final double ipk;

  const RekapitulasiEntity({
    required this.totalSks,
    required this.totalMutu,
    required this.ipk,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RekapitulasiEntity &&
          runtimeType == other.runtimeType &&
          totalSks == other.totalSks &&
          totalMutu == other.totalMutu &&
          ipk == other.ipk;

  @override
  int get hashCode => Object.hash(totalSks, totalMutu, ipk);
}

class KhsDataEntity {
  final MahasiswaEntity mahasiswa;
  final PeriodeEntity periode;
  final List<MataKuliahKhsEntity> mataKuliah;
  final RekapitulasiEntity rekapitulasi;

  const KhsDataEntity({
    required this.mahasiswa,
    required this.periode,
    required this.mataKuliah,
    required this.rekapitulasi,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhsDataEntity &&
          runtimeType == other.runtimeType &&
          mahasiswa == other.mahasiswa &&
          periode == other.periode &&
          listEquals(mataKuliah, other.mataKuliah) &&
          rekapitulasi == other.rekapitulasi;

  @override
  int get hashCode => Object.hash(mahasiswa, periode, rekapitulasi);
}

class KhsEntity {
  final KhsDataEntity khs;
  final MetadataEntity metadata;

  const KhsEntity({required this.khs, required this.metadata});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhsEntity &&
          runtimeType == other.runtimeType &&
          khs == other.khs &&
          metadata == other.metadata;

  @override
  int get hashCode => Object.hash(khs, metadata);
}

class KhsSemesterEntity {
  final String tahunAjaran;
  final String semester;
  final int sks;

  const KhsSemesterEntity({
    required this.tahunAjaran,
    required this.semester,
    required this.sks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhsSemesterEntity &&
          runtimeType == other.runtimeType &&
          tahunAjaran == other.tahunAjaran &&
          semester == other.semester &&
          sks == other.sks;

  @override
  int get hashCode => Object.hash(tahunAjaran, semester, sks);
}
