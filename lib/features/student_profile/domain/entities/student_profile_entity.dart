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
    required this.kelas,
    required this.statusKonversi,
    // ── contact_data (optional) ──
    this.noWa,
    this.email,
    this.tempatLahir,
    this.tanggalLahir,
    this.agama,
    this.kelamin,
    this.suku,
    this.statusMenikah,
    this.idKebutuhanKhususMahasiswa,
    this.statusTinggal,
    this.transportasi,
    // ── education_data (optional) ──
    this.namaAsalSekolah,
    this.tahunLulus,
    // ── address_data (optional) ──
    this.propinsi,
    this.kabupaten,
    this.kecamatan,
    this.idWilayah,
    this.desa,
    this.alamatDusun,
    this.alamatRw,
    this.alamatRt,
    this.alamatJalan,
    this.kodePos,
    // ── employment_data (optional) ──
    this.statusBekerja,
    this.namaKantor,
    this.alamatKantor,
    // ── father_data (optional) ──
    this.namaAyah,
    this.tanggalLahirAyah,
    this.nikAyah,
    this.noHpAyah,
    this.idJenjangPendidikanAyah,
    this.idPekerjaanAyah,
    this.idPenghasilanAyah,
    this.idKebutuhanKhususAyah,
    // ── mother_data (optional) ──
    this.namaIbu,
    this.tanggalLahirIbu,
    this.nikIbu,
    this.noHpIbu,
    this.idJenjangPendidikanIbu,
    this.idPekerjaanIbu,
    this.idPenghasilanIbu,
    this.idKebutuhanKhususIbu,
    // ── guardian_data (optional) ──
    this.namaWali,
    this.tanggalLahirWali,
    this.idJenjangPendidikanWali,
    this.idPekerjaanWali,
    this.idPenghasilanWali,
    // ── other_data (optional) ──
    this.penerimaKps,
    this.noKps,
    this.npwp,
    this.remark,
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
  final String kelas;
  final String statusKonversi;

  // ═══════════════════════════════════════════════════════════════
  // contact_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? noWa;
  final String? email;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? agama;
  final String? kelamin;
  final String? suku;
  final String? statusMenikah;
  final String? idKebutuhanKhususMahasiswa;
  final String? statusTinggal;
  final String? transportasi;

  // ═══════════════════════════════════════════════════════════════
  // education_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? namaAsalSekolah;
  final String? tahunLulus;

  // ═══════════════════════════════════════════════════════════════
  // address_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? propinsi;
  final String? kabupaten;
  final String? kecamatan;
  final String? idWilayah;
  final String? desa;
  final String? alamatDusun;
  final String? alamatRw;
  final String? alamatRt;
  final String? alamatJalan;
  final String? kodePos;

  // ═══════════════════════════════════════════════════════════════
  // employment_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? statusBekerja;
  final String? namaKantor;
  final String? alamatKantor;

  // ═══════════════════════════════════════════════════════════════
  // father_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? namaAyah;
  final String? tanggalLahirAyah;
  final String? nikAyah;
  final String? noHpAyah;
  final String? idJenjangPendidikanAyah;
  final String? idPekerjaanAyah;
  final String? idPenghasilanAyah;
  final String? idKebutuhanKhususAyah;

  // ═══════════════════════════════════════════════════════════════
  // mother_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? namaIbu;
  final String? tanggalLahirIbu;
  final String? nikIbu;
  final String? noHpIbu;
  final String? idJenjangPendidikanIbu;
  final String? idPekerjaanIbu;
  final String? idPenghasilanIbu;
  final String? idKebutuhanKhususIbu;

  // ═══════════════════════════════════════════════════════════════
  // guardian_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? namaWali;
  final String? tanggalLahirWali;
  final String? idJenjangPendidikanWali;
  final String? idPekerjaanWali;
  final String? idPenghasilanWali;

  // ═══════════════════════════════════════════════════════════════
  // other_data (optional)
  // ═══════════════════════════════════════════════════════════════
  final String? penerimaKps;
  final String? noKps;
  final String? npwp;
  final String? remark;

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
          kelas == other.kelas &&
          statusKonversi == other.statusKonversi &&
          // ── contact_data ──
          noWa == other.noWa &&
          email == other.email &&
          tempatLahir == other.tempatLahir &&
          tanggalLahir == other.tanggalLahir &&
          agama == other.agama &&
          kelamin == other.kelamin &&
          suku == other.suku &&
          statusMenikah == other.statusMenikah &&
          idKebutuhanKhususMahasiswa == other.idKebutuhanKhususMahasiswa &&
          statusTinggal == other.statusTinggal &&
          transportasi == other.transportasi &&
          // ── education_data ──
          namaAsalSekolah == other.namaAsalSekolah &&
          tahunLulus == other.tahunLulus &&
          // ── address_data ──
          propinsi == other.propinsi &&
          kabupaten == other.kabupaten &&
          kecamatan == other.kecamatan &&
          idWilayah == other.idWilayah &&
          desa == other.desa &&
          alamatDusun == other.alamatDusun &&
          alamatRw == other.alamatRw &&
          alamatRt == other.alamatRt &&
          alamatJalan == other.alamatJalan &&
          kodePos == other.kodePos &&
          // ── employment_data ──
          statusBekerja == other.statusBekerja &&
          namaKantor == other.namaKantor &&
          alamatKantor == other.alamatKantor &&
          // ── father_data ──
          namaAyah == other.namaAyah &&
          tanggalLahirAyah == other.tanggalLahirAyah &&
          nikAyah == other.nikAyah &&
          noHpAyah == other.noHpAyah &&
          idJenjangPendidikanAyah == other.idJenjangPendidikanAyah &&
          idPekerjaanAyah == other.idPekerjaanAyah &&
          idPenghasilanAyah == other.idPenghasilanAyah &&
          idKebutuhanKhususAyah == other.idKebutuhanKhususAyah &&
          // ── mother_data ──
          namaIbu == other.namaIbu &&
          tanggalLahirIbu == other.tanggalLahirIbu &&
          nikIbu == other.nikIbu &&
          noHpIbu == other.noHpIbu &&
          idJenjangPendidikanIbu == other.idJenjangPendidikanIbu &&
          idPekerjaanIbu == other.idPekerjaanIbu &&
          idPenghasilanIbu == other.idPenghasilanIbu &&
          idKebutuhanKhususIbu == other.idKebutuhanKhususIbu &&
          // ── guardian_data ──
          namaWali == other.namaWali &&
          tanggalLahirWali == other.tanggalLahirWali &&
          idJenjangPendidikanWali == other.idJenjangPendidikanWali &&
          idPekerjaanWali == other.idPekerjaanWali &&
          idPenghasilanWali == other.idPenghasilanWali &&
          // ── other_data ──
          penerimaKps == other.penerimaKps &&
          noKps == other.noKps &&
          npwp == other.npwp &&
          remark == other.remark;

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
      kelas,
      statusKonversi,
      noWa,
      email,
      tempatLahir,
      tanggalLahir,
      agama,
      kelamin,
      suku,
      statusMenikah,
      idKebutuhanKhususMahasiswa,
      statusTinggal,
      transportasi,
      namaAsalSekolah,
    );
    final part2 = Object.hash(
      tahunLulus,
      propinsi,
      kabupaten,
      kecamatan,
      idWilayah,
      desa,
      alamatDusun,
      alamatRw,
      alamatRt,
      alamatJalan,
      kodePos,
      statusBekerja,
      namaKantor,
      alamatKantor,
      namaAyah,
      tanggalLahirAyah,
      nikAyah,
      noHpAyah,
      idJenjangPendidikanAyah,
      idPekerjaanAyah,
    );
    final part3 = Object.hash(
      idPenghasilanAyah,
      idKebutuhanKhususAyah,
      namaIbu,
      tanggalLahirIbu,
      nikIbu,
      noHpIbu,
      idJenjangPendidikanIbu,
      idPekerjaanIbu,
      idPenghasilanIbu,
      idKebutuhanKhususIbu,
      namaWali,
      tanggalLahirWali,
      idJenjangPendidikanWali,
      idPekerjaanWali,
      idPenghasilanWali,
      penerimaKps,
      noKps,
      npwp,
      remark,
    );
    return Object.hash(part1, part2, part3);
  }
}
