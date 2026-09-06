import 'package:lonceng_unman_fe/core/data/models/metadata_model.dart';
import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';

class MataKuliahKhsModel extends MataKuliahKhsEntity {
  const MataKuliahKhsModel({
    required super.kode,
    required super.nama,
    required super.sks,
    required super.nilai,
    required super.mutu,
    required super.dosen,
  });

  factory MataKuliahKhsModel.fromJson(Map<String, dynamic> json) {
    return MataKuliahKhsModel(
      kode: json['kode'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      sks: json['sks'] as int? ?? 0,
      nilai: json['nilai'] as String? ?? '',
      mutu: json['mutu'] as int? ?? 0,
      dosen: json['dosen'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'kode': kode,
    'nama': nama,
    'sks': sks,
    'nilai': nilai,
    'mutu': mutu,
    'dosen': dosen,
  };
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

  Map<String, dynamic> toJson() => {
    'total_sks': totalSks,
    'total_mutu': totalMutu,
    'ipk': ipk,
  };
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

  Map<String, dynamic> toJson() => {
    'mahasiswa': {
      'npm': mahasiswa.npm,
      'nama': mahasiswa.nama,
      'program_studi': mahasiswa.programStudi,
    },
    'periode': {
      'tahun_ajaran': periode.tahunAjaran,
      'semester': periode.semester,
    },
    'mata_kuliah': mataKuliah
        .map(
          (e) => {
            'kode': e.kode,
            'nama': e.nama,
            'sks': e.sks,
            'nilai': e.nilai,
            'mutu': e.mutu,
            'dosen': e.dosen,
          },
        )
        .toList(),
    'rekapitulasi': {
      'total_sks': rekapitulasi.totalSks,
      'total_mutu': rekapitulasi.totalMutu,
      'ipk': rekapitulasi.ipk,
    },
  };
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

  Map<String, dynamic> toJson() => {
    'khs': {
      'mahasiswa': {
        'npm': khs.mahasiswa.npm,
        'nama': khs.mahasiswa.nama,
        'program_studi': khs.mahasiswa.programStudi,
      },
      'periode': {
        'tahun_ajaran': khs.periode.tahunAjaran,
        'semester': khs.periode.semester,
      },
      'mata_kuliah': khs.mataKuliah
          .map(
            (e) => {
              'kode': e.kode,
              'nama': e.nama,
              'sks': e.sks,
              'nilai': e.nilai,
              'mutu': e.mutu,
              'dosen': e.dosen,
            },
          )
          .toList(),
      'rekapitulasi': {
        'total_sks': khs.rekapitulasi.totalSks,
        'total_mutu': khs.rekapitulasi.totalMutu,
        'ipk': khs.rekapitulasi.ipk,
      },
    },
    'metadata': {
      'extracted_at': metadata.extractedAt,
      'source_file': metadata.sourceFile,
      'file_size': metadata.fileSize,
    },
  };
}

class KhsSemesterModel extends KhsSemesterEntity {
  const KhsSemesterModel({
    required super.tahunAjaran,
    required super.semester,
    required super.sks,
  });

  factory KhsSemesterModel.fromJson(Map<String, dynamic> json) {
    final ta = json['tahunAjaran'] ?? json['tahun_ajaran'];
    return KhsSemesterModel(
      tahunAjaran: ta is Map<String, dynamic>
          ? '${ta['awal']}/${ta['akhir']}'
          : ta as String? ?? '',
      semester: json['semester'] as String? ?? '',
      sks: json['sks'] as int? ?? 0,
    );
  }
}
