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
    case DataInitStatus.fetchingSemesters:
      return 'Mengambil daftar semester...';
    case DataInitStatus.downloadingKhs:
      return 'Mengunduh KHS...';
    case DataInitStatus.extractingKrs:
      return 'Mengekstrak KRS...';
    case DataInitStatus.extractingKhs:
      return 'Mengekstrak KHS...';
    case DataInitStatus.fetchingKrsData:
      return 'Memuat data KRS...';
    case DataInitStatus.fetchingKhsData:
      return 'Memuat data KHS...';
    case DataInitStatus.completed:
      return 'Data akademik siap';
    case DataInitStatus.failed:
      return 'Gagal memuat data';
  }
}
