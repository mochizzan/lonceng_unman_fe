import 'package:lonceng_unman_fe/core/data/models/metadata_model.dart';
import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';

class MataKuliahKhsModel extends MataKuliahKhsEntity {
  const MataKuliahKhsModel({
    required super.kode,
    required super.nama,
    required super.sks,
    required super.nilai,
    required super.bobot,
    required super.mutu,
  });

  factory MataKuliahKhsModel.fromJson(Map<String, dynamic> json) {
    return MataKuliahKhsModel(
      kode: json['kode'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      sks: json['sks'] as int? ?? 0,
      nilai: json['nilai'] as String? ?? '',
      bobot: (json['bobot'] as num?)?.toDouble() ?? 0.0,
      mutu: json['mutu'] as int? ?? 0,
    );
  }
}

class RekapitulasiModel extends RekapitulasiEntity {
  const RekapitulasiModel({
    required super.totalSks,
    required super.totalMutu,
    required super.ipk,
  });

  factory RekapitulasiModel.fromJson(Map<String, dynamic> json) {
    return RekapitulasiModel(
      totalSks: json['total_sks'] as int? ?? 0,
      totalMutu: json['total_mutu'] as int? ?? 0,
      ipk: (json['ipk'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class KhsDataModel extends KhsDataEntity {
  const KhsDataModel({
    required super.mahasiswa,
    required super.periode,
    required super.mataKuliah,
    required super.rekapitulasi,
  });

  factory KhsDataModel.fromJson(Map<String, dynamic> json) {
    return KhsDataModel(
      mahasiswa: MahasiswaModel.fromJson(
        json['mahasiswa'] as Map<String, dynamic>? ?? {},
      ),
      periode: PeriodeModel.fromJson(
        json['periode'] as Map<String, dynamic>? ?? {},
      ),
      mataKuliah:
          (json['mata_kuliah'] as List<dynamic>?)
              ?.map(
                (e) => MataKuliahKhsModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      rekapitulasi: RekapitulasiModel.fromJson(
        json['rekapitulasi'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class KhsModel extends KhsEntity {
  const KhsModel({required super.khs, required super.metadata});

  factory KhsModel.fromJson(Map<String, dynamic> json) {
    return KhsModel(
      khs: KhsDataModel.fromJson(json['khs'] as Map<String, dynamic>? ?? {}),
      metadata: MetadataModel.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class KhsSemesterModel extends KhsSemesterEntity {
  const KhsSemesterModel({
    required super.tahunAjaran,
    required super.semester,
    required super.sks,
  });

  factory KhsSemesterModel.fromJson(Map<String, dynamic> json) {
    return KhsSemesterModel(
      tahunAjaran: json['tahun_ajaran'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      sks: json['sks'] as int? ?? 0,
    );
  }
}
