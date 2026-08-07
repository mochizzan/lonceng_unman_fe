import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';

/// Human-readable progress labels for the data-init pipeline.
String dataInitStatusText(DataInitStatus status) {
  switch (status) {
    case DataInitStatus.idle:
      return 'Menyiapkan...';
    case DataInitStatus.authenticating:
      return 'Memverifikasi akun...';
    case DataInitStatus.downloadingKrs:
      return 'Mengunduh KRS...';
    case DataInitStatus.extractingKrs:
      return 'Mengekstrak KRS...';
    case DataInitStatus.fetchingKrsData:
      return 'Memuat data KRS...';
    case DataInitStatus.fetchingKhsSemesters:
      return 'Mengambil daftar KHS...';
    case DataInitStatus.downloadingKhs:
      return 'Mengunduh data KHS...';
    case DataInitStatus.extractingKhs:
      return 'Mengekstrak data KHS...';
    case DataInitStatus.fetchingKhsData:
      return 'Mengambil data KHS...';
    case DataInitStatus.completed:
      return 'Data akademik siap';
    case DataInitStatus.failed:
      return 'Gagal memuat data';
  }
}
