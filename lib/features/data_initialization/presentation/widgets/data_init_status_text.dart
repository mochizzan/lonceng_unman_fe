import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';

/// Human-readable progress labels for the data-init pipeline.
///
/// When [detail] is provided (e.g. tahun ajaran info), it is appended
/// to KHS-related status messages.
String dataInitStatusText(DataInitStatus status, {String? detail}) {
  switch (status) {
    case DataInitStatus.idle:
      return 'Menyiapkan...';
    case DataInitStatus.authenticating:
      return 'Memverifikasi akun...';
    case DataInitStatus.clearingCache:
      return 'Membersihkan cache...';
    case DataInitStatus.scrapingProfile:
      return 'Mengambil data profil...';
    case DataInitStatus.gettingProfile:
      return 'Memproses data profil...';
    case DataInitStatus.fetchingPhoto:
      return 'Mengambil foto profil...';
    case DataInitStatus.downloadingKrs:
      return 'Mengunduh KRS...';
    case DataInitStatus.extractingKrs:
      return 'Mengekstrak KRS...';
    case DataInitStatus.fetchingKrsData:
      return 'Memuat data KRS...';
    case DataInitStatus.fetchingKhsSemesters:
      return 'Mengambil daftar KHS...';
    case DataInitStatus.downloadingKhs:
      return detail != null
          ? 'Mengunduh KHS $detail...'
          : 'Mengunduh data KHS...';
    case DataInitStatus.extractingKhs:
      return detail != null
          ? 'Mengekstrak KHS $detail...'
          : 'Mengekstrak data KHS...';
    case DataInitStatus.fetchingKhsData:
      return detail != null ? 'Memuat KHS $detail...' : 'Mengambil data KHS...';
    case DataInitStatus.krsEmpty:
      return 'Mata kuliah kosong';
    case DataInitStatus.khsEmpty:
      return 'Riwayat nilai belum tersedia';
    case DataInitStatus.photoEmpty:
      return 'Foto belum tersedia';
    case DataInitStatus.completed:
      return 'Data akademik siap';
    case DataInitStatus.completedWithErrors:
      return 'Data akademik siap (beberapa data mungkin belum lengkap)';
    case DataInitStatus.failed:
      return 'Gagal memuat data';
  }
}
