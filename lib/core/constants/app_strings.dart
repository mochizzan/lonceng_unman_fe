// lib/core/constants/app_strings.dart
/// Centralized UI strings for the entire application.
///
/// All user-facing text lives here — no hardcoded strings in widgets.
/// Organized by feature for easy discovery.
abstract final class AppStrings {
  // ─── App ──────────────────────────────────────────────
  static const String appName = 'Lonceng UnMan';
  static const String appVersion = '1.0.0+1';

  // ─── Auth ─────────────────────────────────────────────
  static const String loginGreeting = 'Halo Mahasiswa!';
  static const String loginSubtitle = 'Masuk dengan NPM dan password kamu';
  static const String loginSubtitleDetail =
      'Masuk dengan NPM kamu untuk melihat jadwal & info perkuliahan.';
  static const String loginButton = 'Masuk Akun';
  static const String loginNpmHint = 'NPM';
  static const String loginPasswordHint = 'Password';
  static const String loginNpmHelper = 'Gunakan NPM aktif kamu';
  static const String loginHelpdesk = 'Butuh bantuan? ';
  static const String loginHelpdeskLink = 'Helpdesk IT';
  static const String loginNoAccount = 'NPM belum terdaftar? ';
  static const String loginContactAdmin = 'Hubungi Admin';

  // ─── Home ─────────────────────────────────────────────
  static const String homeGreeting = 'Halo, {name} 👋';
  static const String homeNextClassIn = 'Kelas berikutnya dalam';
  static const String homeLecturerLabel = 'Dosen Pengampu';
  static const String homeLocationLabel = 'Lokasi Kelas';
  static const String homeViewMaterials = 'Lihat Materi Kelas';
  static const String homeScheduleTitle = 'Jadwal Hari Ini';
  static const String homeViewAll = 'Lihat Semua';
  static const String homeNoSchedule = 'Tidak ada jadwal hari ini';
  static const String homeStatusOngoing = 'Sedang Berlangsung';
  static const String homeStatusUpcoming = 'Segera';
  static const String homeSksUnit = 'SKS';
  static const String homeClassUnit = 'Kelas';
  static const String homeSksSemester = 'SKS Semester Ini';
  static const String homeKuliahHariIni = 'Kuliah Hari Ini';
  static const String homeKelas = 'Kelas';
  static const String homeIpkTerakhir = 'IPK Terakhir';

  // ─── Jadwal ───────────────────────────────────────────
  static const String jadwalStatusOngoing = 'SEDANG BERLANGSUNG';
  static const String jadwalNullFallback = '-';

  // ─── Profile ──────────────────────────────────────────
  static const String profileTitle = 'Profil';
  static const String profileTitleFull = 'Profil Saya';
  static const String profileEditTooltip = 'Edit Profil';
  static const String profileTabAbout = 'Tentang';
  static const String profileProgramStudi = 'Program Studi';
  static const String profileSemester = 'Semester';
  static const String profileSettingsButton = 'Pengaturan';

  // ─── Settings ─────────────────────────────────────────
  static const String settingsTitle = 'Pengaturan';
  static const String settingsSectionAppearance = 'Tampilan';
  static const String settingsThemeLabel = 'Tema Aplikasi';
  static const String settingsThemeLight = 'Terang';
  static const String settingsThemeDark = 'Gelap';
  static const String settingsThemeSystem = 'Sistem';
  static const String settingsSectionNotification = 'Notifikasi';
  static const String settingsReminderLabel = 'Ingatkan Sebelum Kelas';
  static const String settingsReminderValue = '5 menit';
  static const String settingsSectionAbout = 'Tentang';
  static const String settingsVersionLabel = 'Versi Aplikasi';
  static const String settingsAppName = 'Lonceng UnMan';

  // ─── Error Pages ──────────────────────────────────────
  static const String errorNotFound = 'Halaman Tidak Ditemukan';
  static const String errorNotFoundDesc =
      'Halaman yang kamu cari tidak tersedia atau sudah dipindahkan.';
  static const String errorBackToHome = 'Kembali ke Beranda';

  // ─── Day Names (Indonesian) ───────────────────────────
  static const String dayMonday = 'Senin';
  static const String dayTuesday = 'Selasa';
  static const String dayWednesday = 'Rabu';
  static const String dayThursday = 'Kamis';
  static const String dayFriday = 'Jumat';
  static const String daySaturday = 'Sabtu';
  static const String daySunday = 'Minggu';

  static const List<String> dayNames = [
    dayMonday,
    dayTuesday,
    dayWednesday,
    dayThursday,
    dayFriday,
    daySaturday,
    daySunday,
  ];

  static const List<String> dayNamesShort = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  // ─── Month Names (Indonesian) ─────────────────────────
  static const String monthJanuary = 'Januari';
  static const String monthFebruary = 'Februari';
  static const String monthMarch = 'Maret';
  static const String monthApril = 'April';
  static const String monthMay = 'Mei';
  static const String monthJune = 'Juni';
  static const String monthJuly = 'Juli';
  static const String monthAugust = 'Agustus';
  static const String monthSeptember = 'September';
  static const String monthOctober = 'Oktober';
  static const String monthNovember = 'November';
  static const String monthDecember = 'Desember';

  static const List<String> monthNames = [
    monthJanuary,
    monthFebruary,
    monthMarch,
    monthApril,
    monthMay,
    monthJune,
    monthJuly,
    monthAugust,
    monthSeptember,
    monthOctober,
    monthNovember,
    monthDecember,
  ];

  // ─── Notification (errors) ─────────────────────────
  static const String settingsNotificationPermissionDenied =
      'Izin notifikasi belum diberikan. Aktifkan di Pengaturan Sistem.';
  static const String notificationShowError = 'Gagal menampilkan notifikasi';

  // ─── Settings (reminder format) ─────────────────────
  static const String settingsReminderHour = '1 jam';
  static String settingsReminderMinutes(int minutes) => '$minutes menit';
}
