// student_profile_entity.dart
//
// Domain-layer entity untuk data profil mahasiswa.
// Mengikuti Clean Architecture: domain layer tidak punya dependensi framework.
//
// 9 kategori dari backend API:
// 1. personal_data (required)
// 2. contact_data (optional)
// 3. education_data (optional)
// 4. address_data (optional)
// 5. employment_data (optional)
// 6. father_data (optional)
// 7. mother_data (optional)
// 8. guardian_data (optional)
// 9. other_data (optional)

/// Entity profil mahasiswa yang mencakup 9 kategori data dari backend API.
class StudentProfileEntity {
  const StudentProfileEntity({
    // ── personal_data (required) ──
    required this.nim,
    required this.nisn,
    required this.nik,
    required this.namaMahasiswa,
    required this.programStudi,
    required this.semester,
    required this.fakultas,
    required this.angkatan,
    // ── contact_data (optional) ──
    this.email,
    this.noHp,
    this.alamatLengkap,
    this.kota,
    this.provinsi,
    this.kodePos,
    this.kecamatan,
    this.kelurahan,
    this.negara,
    this.noHpOrangtua,
    this.namaKontakDarurat,
    // ── education_data (optional) ──
    this.status,
    this.tahunAjaran,
    // ── address_data (optional) ──
    this.alamatRumah,
    this.rt,
    this.rw,
    this.kelurahanRumah,
    this.kecamatanRumah,
    this.kotaRumah,
    this.provinsiRumah,
    this.kodePosRumah,
    this.alamatSementara,
    this.alamatSementaraRt,
    this.alamatSementaraRw,
    this.alamatSementaraKelurahan,
    this.alamatSementaraKecamatan,
    this.alamatSementaraKota,
    this.alamatSementaraProvinsi,
    this.alamatSementaraKodePos,
    // ── employment_data (optional) ──
    this.pekerjaan,
    this.perusahaan,
    this.penghasilan,
    // ── father_data (optional) ──
    this.namaAyah,
    this.tempatLahirAyah,
    this.tanggalLahirAyah,
    this.pekerjaanAyah,
    this.penghasilanAyah,
    this.alamatAyah,
    this.noHpAyah,
    this.emailAyah,
    // ── mother_data (optional) ──
    this.namaIbu,
    this.tempatLahirIbu,
    this.tanggalLahirIbu,
    this.pekerjaanIbu,
    this.penghasilanIbu,
    this.alamatIbu,
    this.noHpIbu,
    this.emailIbu,
    // ── guardian_data (optional) ──
    this.namaWali,
    this.hubunganWali,
    this.pekerjaanWali,
    this.alamatWali,
    this.noHpWali,
    // ── other_data (optional) ──
    this.golonganDarah,
    this.riwayatPenyakit,
    this.riwayatAlergi,
    this.riwayatOperasi,
  });

  // ═══════════════════════════════════════════════════════════════
  // personal_data (required)
  // ═══════════════════════════════════════════════════════════════
  final String nim;
  final String nisn;
  final String nik;
  final String namaMahasiswa;
  final String programStudi;
  final String semester;
  final String fakultas;
  final String angkatan;

  // ═══════════════════════════════════════════════════════════════
  // contact_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? email;
  final String? noHp;
  final String? alamatLengkap;
  final String? kota;
  final String? provinsi;
  final String? kodePos;
  final String? kecamatan;
  final String? kelurahan;
  final String? negara;
  final String? noHpOrangtua;
  final String? namaKontakDarurat;

  // ═══════════════════════════════════════════════════════════════
  // education_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? status;
  final String? tahunAjaran;

  // ═══════════════════════════════════════════════════════════════
  // address_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? alamatRumah;
  final String? rt;
  final String? rw;
  final String? kelurahanRumah;
  final String? kecamatanRumah;
  final String? kotaRumah;
  final String? provinsiRumah;
  final String? kodePosRumah;
  final String? alamatSementara;
  final String? alamatSementaraRt;
  final String? alamatSementaraRw;
  final String? alamatSementaraKelurahan;
  final String? alamatSementaraKecamatan;
  final String? alamatSementaraKota;
  final String? alamatSementaraProvinsi;
  final String? alamatSementaraKodePos;

  // ═══════════════════════════════════════════════════════════════
  // employment_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? pekerjaan;
  final String? perusahaan;
  final String? penghasilan;

  // ═══════════════════════════════════════════════════════════════
  // father_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? namaAyah;
  final String? tempatLahirAyah;
  final String? tanggalLahirAyah;
  final String? pekerjaanAyah;
  final String? penghasilanAyah;
  final String? alamatAyah;
  final String? noHpAyah;
  final String? emailAyah;

  // ═══════════════════════════════════════════════════════════════
  // mother_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? namaIbu;
  final String? tempatLahirIbu;
  final String? tanggalLahirIbu;
  final String? pekerjaanIbu;
  final String? penghasilanIbu;
  final String? alamatIbu;
  final String? noHpIbu;
  final String? emailIbu;

  // ═══════════════════════════════════════════════════════════════
  // guardian_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? namaWali;
  final String? hubunganWali;
  final String? pekerjaanWali;
  final String? alamatWali;
  final String? noHpWali;

  // ═══════════════════════════════════════════════════════════════
  // other_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? golonganDarah;
  final String? riwayatPenyakit;
  final String? riwayatAlergi;
  final String? riwayatOperasi;

  /// Mengembalikan entity ini sendiri.
  /// Subclass (misal [StudentProfileModel]) override untuk mengembalikan
  /// entity yang bersih.
  StudentProfileEntity toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentProfileEntity &&
          runtimeType == other.runtimeType &&
          // ── personal_data ──
          nim == other.nim &&
          nisn == other.nisn &&
          nik == other.nik &&
          namaMahasiswa == other.namaMahasiswa &&
          programStudi == other.programStudi &&
          semester == other.semester &&
          fakultas == other.fakultas &&
          angkatan == other.angkatan &&
          // ── contact_data ──
          email == other.email &&
          noHp == other.noHp &&
          alamatLengkap == other.alamatLengkap &&
          kota == other.kota &&
          provinsi == other.provinsi &&
          kodePos == other.kodePos &&
          kecamatan == other.kecamatan &&
          kelurahan == other.kelurahan &&
          negara == other.negara &&
          noHpOrangtua == other.noHpOrangtua &&
          namaKontakDarurat == other.namaKontakDarurat &&
          // ── education_data ──
          status == other.status &&
          tahunAjaran == other.tahunAjaran &&
          // ── address_data ──
          alamatRumah == other.alamatRumah &&
          rt == other.rt &&
          rw == other.rw &&
          kelurahanRumah == other.kelurahanRumah &&
          kecamatanRumah == other.kecamatanRumah &&
          kotaRumah == other.kotaRumah &&
          provinsiRumah == other.provinsiRumah &&
          kodePosRumah == other.kodePosRumah &&
          alamatSementara == other.alamatSementara &&
          alamatSementaraRt == other.alamatSementaraRt &&
          alamatSementaraRw == other.alamatSementaraRw &&
          alamatSementaraKelurahan == other.alamatSementaraKelurahan &&
          alamatSementaraKecamatan == other.alamatSementaraKecamatan &&
          alamatSementaraKota == other.alamatSementaraKota &&
          alamatSementaraProvinsi == other.alamatSementaraProvinsi &&
          alamatSementaraKodePos == other.alamatSementaraKodePos &&
          // ── employment_data ──
          pekerjaan == other.pekerjaan &&
          perusahaan == other.perusahaan &&
          penghasilan == other.penghasilan &&
          // ── father_data ──
          namaAyah == other.namaAyah &&
          tempatLahirAyah == other.tempatLahirAyah &&
          tanggalLahirAyah == other.tanggalLahirAyah &&
          pekerjaanAyah == other.pekerjaanAyah &&
          penghasilanAyah == other.penghasilanAyah &&
          alamatAyah == other.alamatAyah &&
          noHpAyah == other.noHpAyah &&
          emailAyah == other.emailAyah &&
          // ── mother_data ──
          namaIbu == other.namaIbu &&
          tempatLahirIbu == other.tempatLahirIbu &&
          tanggalLahirIbu == other.tanggalLahirIbu &&
          pekerjaanIbu == other.pekerjaanIbu &&
          penghasilanIbu == other.penghasilanIbu &&
          alamatIbu == other.alamatIbu &&
          noHpIbu == other.noHpIbu &&
          emailIbu == other.emailIbu &&
          // ── guardian_data ──
          namaWali == other.namaWali &&
          hubunganWali == other.hubunganWali &&
          pekerjaanWali == other.pekerjaanWali &&
          alamatWali == other.alamatWali &&
          noHpWali == other.noHpWali &&
          // ── other_data ──
          golonganDarah == other.golonganDarah &&
          riwayatPenyakit == other.riwayatPenyakit &&
          riwayatAlergi == other.riwayatAlergi &&
          riwayatOperasi == other.riwayatOperasi;

  @override
  int get hashCode {
    // Dart Object.hash maksimal 20 argumen, sehingga perlu dipecah
    // menjadi beberapa bagian lalu digabungkan.
    final part1 = Object.hash(
      nim,
      nisn,
      nik,
      namaMahasiswa,
      programStudi,
      semester,
      fakultas,
      angkatan,
      email,
      noHp,
      alamatLengkap,
      kota,
      provinsi,
      kodePos,
      kecamatan,
      kelurahan,
      negara,
      noHpOrangtua,
      namaKontakDarurat,
      status,
    );
    final part2 = Object.hash(
      tahunAjaran,
      alamatRumah,
      rt,
      rw,
      kelurahanRumah,
      kecamatanRumah,
      kotaRumah,
      provinsiRumah,
      kodePosRumah,
      alamatSementara,
      alamatSementaraRt,
      alamatSementaraRw,
      alamatSementaraKelurahan,
      alamatSementaraKecamatan,
      alamatSementaraKota,
      alamatSementaraProvinsi,
      alamatSementaraKodePos,
      pekerjaan,
      perusahaan,
      penghasilan,
    );
    final part3 = Object.hash(
      namaAyah,
      tempatLahirAyah,
      tanggalLahirAyah,
      pekerjaanAyah,
      penghasilanAyah,
      alamatAyah,
      noHpAyah,
      emailAyah,
      namaIbu,
      tempatLahirIbu,
      tanggalLahirIbu,
      pekerjaanIbu,
      penghasilanIbu,
      alamatIbu,
      noHpIbu,
      emailIbu,
      namaWali,
      hubunganWali,
      pekerjaanWali,
      alamatWali,
    );
    final part4 = Object.hash(
      noHpWali,
      golonganDarah,
      riwayatPenyakit,
      riwayatAlergi,
      riwayatOperasi,
    );
    return Object.hash(part1, part2, part3, part4);
  }
}
