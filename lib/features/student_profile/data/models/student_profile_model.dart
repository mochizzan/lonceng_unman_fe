// student_profile_model.dart
//
// Data model untuk StudentProfileEntity.
// Mengikuti pattern dari KrsModel di krs_model.dart.
// Mengkonversi data dari API (nested structure) ke entity.

import 'package:lonceng_unman_fe/features/student_profile/domain/entities/student_profile_entity.dart';

/// Data model untuk profil mahasiswa yang mencakup 9 kategori dari backend API.
///
/// Mapping API:
/// - `personal_data` → personal fields
/// - `contact_data` → contact fields
/// - `education_data` → education fields
/// - `address_data` → address fields
/// - `employment_data` → employment fields
/// - `father_data` → father fields
/// - `mother_data` → mother fields
/// - `guardian_data` → guardian fields
/// - `other_data` → other fields
class StudentProfileModel extends StudentProfileEntity {
  const StudentProfileModel({
    // ── personal_data (required) ──
    required super.nim,
    required super.nisn,
    required super.nik,
    required super.namaMahasiswa,
    required super.programStudi,
    required super.semester,
    required super.fakultas,
    required super.angkatan,
    // ── contact_data (optional) ──
    super.email,
    super.noHp,
    super.alamatLengkap,
    super.kota,
    super.provinsi,
    super.kodePos,
    super.kecamatan,
    super.kelurahan,
    super.negara,
    super.noHpOrangtua,
    super.namaKontakDarurat,
    // ── education_data (optional) ──
    super.status,
    super.tahunAjaran,
    // ── address_data (optional) ──
    super.alamatRumah,
    super.rt,
    super.rw,
    super.kelurahanRumah,
    super.kecamatanRumah,
    super.kotaRumah,
    super.provinsiRumah,
    super.kodePosRumah,
    super.alamatSementara,
    super.alamatSementaraRt,
    super.alamatSementaraRw,
    super.alamatSementaraKelurahan,
    super.alamatSementaraKecamatan,
    super.alamatSementaraKota,
    super.alamatSementaraProvinsi,
    super.alamatSementaraKodePos,
    // ── employment_data (optional) ──
    super.pekerjaan,
    super.perusahaan,
    super.penghasilan,
    // ── father_data (optional) ──
    super.namaAyah,
    super.tempatLahirAyah,
    super.tanggalLahirAyah,
    super.pekerjaanAyah,
    super.penghasilanAyah,
    super.alamatAyah,
    super.noHpAyah,
    super.emailAyah,
    // ── mother_data (optional) ──
    super.namaIbu,
    super.tempatLahirIbu,
    super.tanggalLahirIbu,
    super.pekerjaanIbu,
    super.penghasilanIbu,
    super.alamatIbu,
    super.noHpIbu,
    super.emailIbu,
    // ── guardian_data (optional) ──
    super.namaWali,
    super.hubunganWali,
    super.pekerjaanWali,
    super.alamatWali,
    super.noHpWali,
    // ── other_data (optional) ──
    super.golonganDarah,
    super.riwayatPenyakit,
    super.riwayatAlergi,
    super.riwayatOperasi,
  });

  /// Membuat model dari JSON response API.
  ///
  /// API mengembalikan nested structure:
  /// ```json
  /// {
  ///   "personal_data": { ... },
  ///   "contact_data": { ... },
  ///   "education_data": { ... },
  ///   "address_data": { ... },
  ///   "employment_data": { ... },
  ///   "father_data": { ... },
  ///   "mother_data": { ... },
  ///   "guardian_data": { ... },
  ///   "other_data": { ... }
  /// }
  /// ```
  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    // ── personal_data ──
    final personal = json['personal_data'] as Map<String, dynamic>? ?? {};

    // ── contact_data ──
    final contact = json['contact_data'] as Map<String, dynamic>? ?? {};

    // ── education_data ──
    final education = json['education_data'] as Map<String, dynamic>? ?? {};

    // ── address_data ──
    final address = json['address_data'] as Map<String, dynamic>? ?? {};

    // ── employment_data ──
    final employment = json['employment_data'] as Map<String, dynamic>? ?? {};

    // ── father_data ──
    final father = json['father_data'] as Map<String, dynamic>? ?? {};

    // ── mother_data ──
    final mother = json['mother_data'] as Map<String, dynamic>? ?? {};

    // ── guardian_data ──
    final guardian = json['guardian_data'] as Map<String, dynamic>? ?? {};

    // ── other_data ──
    final other = json['other_data'] as Map<String, dynamic>? ?? {};

    return StudentProfileModel(
      // ── personal_data (required) ──
      nim: personal['nim'] as String? ?? '',
      nisn: personal['nisn'] as String? ?? '',
      nik: personal['nik'] as String? ?? '',
      namaMahasiswa: personal['nama_mahasiswa'] as String? ?? '',
      programStudi: personal['program_studi'] as String? ?? '',
      semester: personal['semester'] as String? ?? '',
      fakultas: personal['fakultas'] as String? ?? '',
      angkatan: personal['angkatan'] as String? ?? '',
      // ── contact_data ──
      email: contact['email'] as String?,
      noHp: contact['no_hp'] as String?,
      alamatLengkap: contact['alamat_lengkap'] as String?,
      kota: contact['kota'] as String?,
      provinsi: contact['provinsi'] as String?,
      kodePos: contact['kode_pos'] as String?,
      kecamatan: contact['kecamatan'] as String?,
      kelurahan: contact['kelurahan'] as String?,
      negara: contact['negara'] as String?,
      noHpOrangtua: contact['no_hp_orangtua'] as String?,
      namaKontakDarurat: contact['nama_kontak_darurat'] as String?,
      // ── education_data ──
      status: education['status'] as String?,
      tahunAjaran: education['tahun_ajaran'] as String?,
      // ── address_data ──
      alamatRumah: address['alamat_lengkap'] as String?,
      rt: address['rt'] as String?,
      rw: address['rw'] as String?,
      kelurahanRumah: address['kelurahan'] as String?,
      kecamatanRumah: address['kecamatan'] as String?,
      kotaRumah: address['kota'] as String?,
      provinsiRumah: address['provinsi'] as String?,
      kodePosRumah: address['kode_pos'] as String?,
      alamatSementara: address['alamat_sementara'] as String?,
      alamatSementaraRt: address['alamat_sementara_rt'] as String?,
      alamatSementaraRw: address['alamat_sementara_rw'] as String?,
      alamatSementaraKelurahan:
          address['alamat_sementara_kelurahan'] as String?,
      alamatSementaraKecamatan:
          address['alamat_sementara_kecamatan'] as String?,
      alamatSementaraKota: address['alamat_sementara_kota'] as String?,
      alamatSementaraProvinsi: address['alamat_sementara_provinsi'] as String?,
      alamatSementaraKodePos: address['alamat_sementara_kode_pos'] as String?,
      // ── employment_data ──
      pekerjaan: employment['pekerjaan'] as String?,
      perusahaan: employment['perusahaan'] as String?,
      penghasilan: employment['penghasilan'] as String?,
      // ── father_data ──
      namaAyah: father['nama_ayah'] as String?,
      tempatLahirAyah: father['tempat_lahir_ayah'] as String?,
      tanggalLahirAyah: father['tanggal_lahir_ayah'] as String?,
      pekerjaanAyah: father['pekerjaan_ayah'] as String?,
      penghasilanAyah: father['penghasilan_ayah'] as String?,
      alamatAyah: father['alamat_ayah'] as String?,
      noHpAyah: father['no_hp_ayah'] as String?,
      emailAyah: father['email_ayah'] as String?,
      // ── mother_data ──
      namaIbu: mother['nama_ibu'] as String?,
      tempatLahirIbu: mother['tempat_lahir_ibu'] as String?,
      tanggalLahirIbu: mother['tanggal_lahir_ibu'] as String?,
      pekerjaanIbu: mother['pekerjaan_ibu'] as String?,
      penghasilanIbu: mother['penghasilan_ibu'] as String?,
      alamatIbu: mother['alamat_ibu'] as String?,
      noHpIbu: mother['no_hp_ibu'] as String?,
      emailIbu: mother['email_ibu'] as String?,
      // ── guardian_data ──
      namaWali: guardian['nama_wali'] as String?,
      hubunganWali: guardian['hubungan_wali'] as String?,
      pekerjaanWali: guardian['pekerjaan_wali'] as String?,
      alamatWali: guardian['alamat_wali'] as String?,
      noHpWali: guardian['no_hp_wali'] as String?,
      // ── other_data ──
      golonganDarah: other['golongan_darah'] as String?,
      riwayatPenyakit: other['riwayat_penyakit'] as String?,
      riwayatAlergi: other['riwayat_alergi'] as String?,
      riwayatOperasi: other['riwayat_operasi'] as String?,
    );
  }

  /// Mengkonversi model ke Map untuk penyimpanan cache atau debugging.
  ///
  /// Mengembalikan nested structure yang sesuai dengan API response.
  Map<String, dynamic> toJson() {
    return {
      // ── personal_data ──
      'personal_data': {
        'nim': nim,
        'nisn': nisn,
        'nik': nik,
        'nama_mahasiswa': namaMahasiswa,
        'program_studi': programStudi,
        'semester': semester,
        'fakultas': fakultas,
        'angkatan': angkatan,
      },
      // ── contact_data ──
      'contact_data': {
        if (email != null) 'email': email,
        if (noHp != null) 'no_hp': noHp,
        if (alamatLengkap != null) 'alamat_lengkap': alamatLengkap,
        if (kota != null) 'kota': kota,
        if (provinsi != null) 'provinsi': provinsi,
        if (kodePos != null) 'kode_pos': kodePos,
        if (kecamatan != null) 'kecamatan': kecamatan,
        if (kelurahan != null) 'kelurahan': kelurahan,
        if (negara != null) 'negara': negara,
        if (noHpOrangtua != null) 'no_hp_orangtua': noHpOrangtua,
        if (namaKontakDarurat != null) 'nama_kontak_darurat': namaKontakDarurat,
      },
      // ── education_data ──
      'education_data': {
        if (status != null) 'status': status,
        if (tahunAjaran != null) 'tahun_ajaran': tahunAjaran,
      },
      // ── address_data ──
      'address_data': {
        if (alamatRumah != null) 'alamat_lengkap': alamatRumah,
        if (rt != null) 'rt': rt,
        if (rw != null) 'rw': rw,
        if (kelurahanRumah != null) 'kelurahan': kelurahanRumah,
        if (kecamatanRumah != null) 'kecamatan': kecamatanRumah,
        if (kotaRumah != null) 'kota': kotaRumah,
        if (provinsiRumah != null) 'provinsi': provinsiRumah,
        if (kodePosRumah != null) 'kode_pos': kodePosRumah,
        if (alamatSementara != null) 'alamat_sementara': alamatSementara,
        if (alamatSementaraRt != null) 'alamat_sementara_rt': alamatSementaraRt,
        if (alamatSementaraRw != null) 'alamat_sementara_rw': alamatSementaraRw,
        if (alamatSementaraKelurahan != null)
          'alamat_sementara_kelurahan': alamatSementaraKelurahan,
        if (alamatSementaraKecamatan != null)
          'alamat_sementara_kecamatan': alamatSementaraKecamatan,
        if (alamatSementaraKota != null)
          'alamat_sementara_kota': alamatSementaraKota,
        if (alamatSementaraProvinsi != null)
          'alamat_sementara_provinsi': alamatSementaraProvinsi,
        if (alamatSementaraKodePos != null)
          'alamat_sementara_kode_pos': alamatSementaraKodePos,
      },
      // ── employment_data ──
      'employment_data': {
        if (pekerjaan != null) 'pekerjaan': pekerjaan,
        if (perusahaan != null) 'perusahaan': perusahaan,
        if (penghasilan != null) 'penghasilan': penghasilan,
      },
      // ── father_data ──
      'father_data': {
        if (namaAyah != null) 'nama_ayah': namaAyah,
        if (tempatLahirAyah != null) 'tempat_lahir_ayah': tempatLahirAyah,
        if (tanggalLahirAyah != null) 'tanggal_lahir_ayah': tanggalLahirAyah,
        if (pekerjaanAyah != null) 'pekerjaan_ayah': pekerjaanAyah,
        if (penghasilanAyah != null) 'penghasilan_ayah': penghasilanAyah,
        if (alamatAyah != null) 'alamat_ayah': alamatAyah,
        if (noHpAyah != null) 'no_hp_ayah': noHpAyah,
        if (emailAyah != null) 'email_ayah': emailAyah,
      },
      // ── mother_data ──
      'mother_data': {
        if (namaIbu != null) 'nama_ibu': namaIbu,
        if (tempatLahirIbu != null) 'tempat_lahir_ibu': tempatLahirIbu,
        if (tanggalLahirIbu != null) 'tanggal_lahir_ibu': tanggalLahirIbu,
        if (pekerjaanIbu != null) 'pekerjaan_ibu': pekerjaanIbu,
        if (penghasilanIbu != null) 'penghasilan_ibu': penghasilanIbu,
        if (alamatIbu != null) 'alamat_ibu': alamatIbu,
        if (noHpIbu != null) 'no_hp_ibu': noHpIbu,
        if (emailIbu != null) 'email_ibu': emailIbu,
      },
      // ── guardian_data ──
      'guardian_data': {
        if (namaWali != null) 'nama_wali': namaWali,
        if (hubunganWali != null) 'hubungan_wali': hubunganWali,
        if (pekerjaanWali != null) 'pekerjaan_wali': pekerjaanWali,
        if (alamatWali != null) 'alamat_wali': alamatWali,
        if (noHpWali != null) 'no_hp_wali': noHpWali,
      },
      // ── other_data ──
      'other_data': {
        if (golonganDarah != null) 'golongan_darah': golonganDarah,
        if (riwayatPenyakit != null) 'riwayat_penyakit': riwayatPenyakit,
        if (riwayatAlergi != null) 'riwayat_alergi': riwayatAlergi,
        if (riwayatOperasi != null) 'riwayat_operasi': riwayatOperasi,
      },
    };
  }

  /// Mengembalikan entity bersih tanpa informasi model.
  @override
  StudentProfileEntity toEntity() {
    return StudentProfileEntity(
      // ── personal_data ──
      nim: nim,
      nisn: nisn,
      nik: nik,
      namaMahasiswa: namaMahasiswa,
      programStudi: programStudi,
      semester: semester,
      fakultas: fakultas,
      angkatan: angkatan,
      // ── contact_data ──
      email: email,
      noHp: noHp,
      alamatLengkap: alamatLengkap,
      kota: kota,
      provinsi: provinsi,
      kodePos: kodePos,
      kecamatan: kecamatan,
      kelurahan: kelurahan,
      negara: negara,
      noHpOrangtua: noHpOrangtua,
      namaKontakDarurat: namaKontakDarurat,
      // ── education_data ──
      status: status,
      tahunAjaran: tahunAjaran,
      // ── address_data ──
      alamatRumah: alamatRumah,
      rt: rt,
      rw: rw,
      kelurahanRumah: kelurahanRumah,
      kecamatanRumah: kecamatanRumah,
      kotaRumah: kotaRumah,
      provinsiRumah: provinsiRumah,
      kodePosRumah: kodePosRumah,
      alamatSementara: alamatSementara,
      alamatSementaraRt: alamatSementaraRt,
      alamatSementaraRw: alamatSementaraRw,
      alamatSementaraKelurahan: alamatSementaraKelurahan,
      alamatSementaraKecamatan: alamatSementaraKecamatan,
      alamatSementaraKota: alamatSementaraKota,
      alamatSementaraProvinsi: alamatSementaraProvinsi,
      alamatSementaraKodePos: alamatSementaraKodePos,
      // ── employment_data ──
      pekerjaan: pekerjaan,
      perusahaan: perusahaan,
      penghasilan: penghasilan,
      // ── father_data ──
      namaAyah: namaAyah,
      tempatLahirAyah: tempatLahirAyah,
      tanggalLahirAyah: tanggalLahirAyah,
      pekerjaanAyah: pekerjaanAyah,
      penghasilanAyah: penghasilanAyah,
      alamatAyah: alamatAyah,
      noHpAyah: noHpAyah,
      emailAyah: emailAyah,
      // ── mother_data ──
      namaIbu: namaIbu,
      tempatLahirIbu: tempatLahirIbu,
      tanggalLahirIbu: tanggalLahirIbu,
      pekerjaanIbu: pekerjaanIbu,
      penghasilanIbu: penghasilanIbu,
      alamatIbu: alamatIbu,
      noHpIbu: noHpIbu,
      emailIbu: emailIbu,
      // ── guardian_data ──
      namaWali: namaWali,
      hubunganWali: hubunganWali,
      pekerjaanWali: pekerjaanWali,
      alamatWali: alamatWali,
      noHpWali: noHpWali,
      // ── other_data ──
      golonganDarah: golonganDarah,
      riwayatPenyakit: riwayatPenyakit,
      riwayatAlergi: riwayatAlergi,
      riwayatOperasi: riwayatOperasi,
    );
  }
}
