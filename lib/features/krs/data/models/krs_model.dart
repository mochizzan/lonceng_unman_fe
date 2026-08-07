import 'package:lonceng_unman_fe/core/data/models/metadata_model.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';

class MahasiswaModel extends MahasiswaEntity {
  const MahasiswaModel({
    required super.nama,
    required super.npm,
    required super.programStudi,
  });

  factory MahasiswaModel.fromJson(Map<String, dynamic> json) {
    return MahasiswaModel(
      nama: json['nama'] as String? ?? '',
      npm: json['npm'] as String? ?? '',
      programStudi: json['program_studi'] as String? ?? '',
    );
  }
}

class PeriodeModel extends PeriodeEntity {
  const PeriodeModel({required super.tahunAjaran, required super.semester});

  factory PeriodeModel.fromJson(Map<String, dynamic> json) {
    final ta = json['tahun_ajaran'];
    return PeriodeModel(
      tahunAjaran: ta is Map<String, dynamic>
          ? '${ta['awal']}/${ta['akhir']}'
          : ta as String? ?? '',
      semester: json['semester'] as String? ?? '',
    );
  }
}

class MataKuliahKrsModel extends MataKuliahKrsEntity {
  const MataKuliahKrsModel({
    required super.kode,
    required super.nama,
    required super.sks,
    required super.hari,
    required super.jamMulai,
    required super.jamSelesai,
    required super.dosen,
  });

  factory MataKuliahKrsModel.fromJson(Map<String, dynamic> json) {
    final jadwal = json['jadwal'] as Map<String, dynamic>? ?? {};
    return MataKuliahKrsModel(
      kode: json['kode'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      sks: json['sks'] as int? ?? 0,
      hari: jadwal['hari'] as String? ?? '',
      jamMulai: jadwal['waktu_mulai'] as String? ?? '',
      jamSelesai: jadwal['waktu_selesai'] as String? ?? '',
      dosen: json['dosen'] as String? ?? '',
    );
  }
}

class KrsDataModel extends KrsDataEntity {
  const KrsDataModel({
    required super.mahasiswa,
    required super.periode,
    required super.mataKuliah,
    required super.totalSks,
  });

  factory KrsDataModel.fromJson(Map<String, dynamic> json) {
    return KrsDataModel(
      mahasiswa: MahasiswaModel.fromJson(
        json['mahasiswa'] as Map<String, dynamic>? ?? {},
      ),
      periode: PeriodeModel.fromJson(
        json['periode'] as Map<String, dynamic>? ?? {},
      ),
      mataKuliah:
          (json['mata_kuliah'] as List<dynamic>?)
              ?.map(
                (e) => MataKuliahKrsModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalSks: json['total_sks'] as int? ?? 0,
    );
  }
}

class KrsModel extends KrsEntity {
  const KrsModel({required super.krs, required super.metadata});

  factory KrsModel.fromJson(Map<String, dynamic> json) {
    return KrsModel(
      krs: KrsDataModel.fromJson(json['krs'] as Map<String, dynamic>? ?? {}),
      metadata: MetadataModel.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
