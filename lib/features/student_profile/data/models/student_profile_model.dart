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
    required super.kelas,
    required super.statusKonversi,
    // ── contact_data (optional) ──
    super.noWa,
    super.email,
    super.tempatLahir,
    super.tanggalLahir,
    super.agama,
    super.kelamin,
    super.suku,
    super.statusMenikah,
    super.idKebutuhanKhususMahasiswa,
    super.statusTinggal,
    super.transportasi,
    // ── education_data (optional) ──
    super.namaAsalSekolah,
    super.tahunLulus,
    // ── address_data (optional) ──
    super.propinsi,
    super.kabupaten,
    super.kecamatan,
    super.idWilayah,
    super.desa,
    super.alamatDusun,
    super.alamatRw,
    super.alamatRt,
    super.alamatJalan,
    super.kodePos,
    // ── employment_data (optional) ──
    super.statusBekerja,
    super.namaKantor,
    super.alamatKantor,
    // ── father_data (optional) ──
    super.namaAyah,
    super.tanggalLahirAyah,
    super.nikAyah,
    super.noHpAyah,
    super.idJenjangPendidikanAyah,
    super.idPekerjaanAyah,
    super.idPenghasilanAyah,
    super.idKebutuhanKhususAyah,
    // ── mother_data (optional) ──
    super.namaIbu,
    super.tanggalLahirIbu,
    super.nikIbu,
    super.noHpIbu,
    super.idJenjangPendidikanIbu,
    super.idPekerjaanIbu,
    super.idPenghasilanIbu,
    super.idKebutuhanKhususIbu,
    // ── guardian_data (optional) ──
    super.namaWali,
    super.tanggalLahirWali,
    super.idJenjangPendidikanWali,
    super.idPekerjaanWali,
    super.idPenghasilanWali,
    // ── other_data (optional) ──
    super.penerimaKps,
    super.noKps,
    super.npwp,
    super.remark,
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
      kelas: personal['kelas'] as String? ?? '',
      statusKonversi: personal['status_konversi'] as String? ?? '',
      // ── contact_data ──
      noWa: contact['no_wa'] as String?,
      email: contact['email'] as String?,
      tempatLahir: contact['tempat_lahir'] as String?,
      tanggalLahir: contact['tanggal_lahir'] as String?,
      agama: contact['agama'] as String?,
      kelamin: contact['kelamin'] as String?,
      suku: contact['suku'] as String?,
      statusMenikah: contact['status_menikah'] as String?,
      idKebutuhanKhususMahasiswa:
          contact['id_kebutuhan_khusus_mahasiswa'] as String?,
      statusTinggal: contact['status_tinggal'] as String?,
      transportasi: contact['transportasi'] as String?,
      // ── education_data ──
      namaAsalSekolah: education['nama_asal_sekolah'] as String?,
      tahunLulus: education['tahun_lulus'] as String?,
      // ── address_data ──
      propinsi: address['propinsi'] as String?,
      kabupaten: address['kabupaten'] as String?,
      kecamatan: address['kecamatan'] as String?,
      idWilayah: address['id_wilayah'] as String?,
      desa: address['desa'] as String?,
      alamatDusun: address['alamat_dusun'] as String?,
      alamatRw: address['alamat_rw'] as String?,
      alamatRt: address['alamat_rt'] as String?,
      alamatJalan: address['alamat_jalan'] as String?,
      kodePos: address['kode_pos'] as String?,
      // ── employment_data ──
      statusBekerja: employment['status_bekerja'] as String?,
      namaKantor: employment['nama_kantor'] as String?,
      alamatKantor: employment['alamat_kantor'] as String?,
      // ── father_data ──
      namaAyah: father['nama_ayah'] as String?,
      tanggalLahirAyah: father['tanggal_lahir_ayah'] as String?,
      nikAyah: father['nik_ayah'] as String?,
      noHpAyah: father['no_hp_ayah'] as String?,
      idJenjangPendidikanAyah: father['id_jenjang_pendidikan_ayah'] as String?,
      idPekerjaanAyah: father['id_pekerjaan_ayah'] as String?,
      idPenghasilanAyah: father['id_penghasilan_ayah'] as String?,
      idKebutuhanKhususAyah: father['id_kebutuhan_khusus_ayah'] as String?,
      // ── mother_data ──
      namaIbu: mother['nama_ibu'] as String?,
      tanggalLahirIbu: mother['tanggal_lahir_ibu'] as String?,
      nikIbu: mother['nik_ibu'] as String?,
      noHpIbu: mother['no_hp_ibu'] as String?,
      idJenjangPendidikanIbu: mother['id_jenjang_pendidikan_ibu'] as String?,
      idPekerjaanIbu: mother['id_pekerjaan_ibu'] as String?,
      idPenghasilanIbu: mother['id_penghasilan_ibu'] as String?,
      idKebutuhanKhususIbu: mother['id_kebutuhan_khusus_ibu'] as String?,
      // ── guardian_data ──
      namaWali: guardian['nama_wali'] as String?,
      tanggalLahirWali: guardian['tanggal_lahir_wali'] as String?,
      idJenjangPendidikanWali:
          guardian['id_jenjang_pendidikan_wali'] as String?,
      idPekerjaanWali: guardian['id_pekerjaan_wali'] as String?,
      idPenghasilanWali: guardian['id_penghasilan_wali'] as String?,
      // ── other_data ──
      penerimaKps: other['penerima_kps'] as String?,
      noKps: other['no_kps'] as String?,
      npwp: other['npwp'] as String?,
      remark: other['remark'] as String?,
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
        'kelas': kelas,
        'status_konversi': statusKonversi,
      },
      // ── contact_data ──
      'contact_data': {
        if (noWa != null) 'no_wa': noWa,
        if (email != null) 'email': email,
        if (tempatLahir != null) 'tempat_lahir': tempatLahir,
        if (tanggalLahir != null) 'tanggal_lahir': tanggalLahir,
        if (agama != null) 'agama': agama,
        if (kelamin != null) 'kelamin': kelamin,
        if (suku != null) 'suku': suku,
        if (statusMenikah != null) 'status_menikah': statusMenikah,
        if (idKebutuhanKhususMahasiswa != null)
          'id_kebutuhan_khusus_mahasiswa': idKebutuhanKhususMahasiswa,
        if (statusTinggal != null) 'status_tinggal': statusTinggal,
        if (transportasi != null) 'transportasi': transportasi,
      },
      // ── education_data ──
      'education_data': {
        if (namaAsalSekolah != null) 'nama_asal_sekolah': namaAsalSekolah,
        if (tahunLulus != null) 'tahun_lulus': tahunLulus,
      },
      // ── address_data ──
      'address_data': {
        if (propinsi != null) 'propinsi': propinsi,
        if (kabupaten != null) 'kabupaten': kabupaten,
        if (kecamatan != null) 'kecamatan': kecamatan,
        if (idWilayah != null) 'id_wilayah': idWilayah,
        if (desa != null) 'desa': desa,
        if (alamatDusun != null) 'alamat_dusun': alamatDusun,
        if (alamatRw != null) 'alamat_rw': alamatRw,
        if (alamatRt != null) 'alamat_rt': alamatRt,
        if (alamatJalan != null) 'alamat_jalan': alamatJalan,
        if (kodePos != null) 'kode_pos': kodePos,
      },
      // ── employment_data ──
      'employment_data': {
        if (statusBekerja != null) 'status_bekerja': statusBekerja,
        if (namaKantor != null) 'nama_kantor': namaKantor,
        if (alamatKantor != null) 'alamat_kantor': alamatKantor,
      },
      // ── father_data ──
      'father_data': {
        if (namaAyah != null) 'nama_ayah': namaAyah,
        if (tanggalLahirAyah != null) 'tanggal_lahir_ayah': tanggalLahirAyah,
        if (nikAyah != null) 'nik_ayah': nikAyah,
        if (noHpAyah != null) 'no_hp_ayah': noHpAyah,
        if (idJenjangPendidikanAyah != null)
          'id_jenjang_pendidikan_ayah': idJenjangPendidikanAyah,
        if (idPekerjaanAyah != null) 'id_pekerjaan_ayah': idPekerjaanAyah,
        if (idPenghasilanAyah != null) 'id_penghasilan_ayah': idPenghasilanAyah,
        if (idKebutuhanKhususAyah != null)
          'id_kebutuhan_khusus_ayah': idKebutuhanKhususAyah,
      },
      // ── mother_data ──
      'mother_data': {
        if (namaIbu != null) 'nama_ibu': namaIbu,
        if (tanggalLahirIbu != null) 'tanggal_lahir_ibu': tanggalLahirIbu,
        if (nikIbu != null) 'nik_ibu': nikIbu,
        if (noHpIbu != null) 'no_hp_ibu': noHpIbu,
        if (idJenjangPendidikanIbu != null)
          'id_jenjang_pendidikan_ibu': idJenjangPendidikanIbu,
        if (idPekerjaanIbu != null) 'id_pekerjaan_ibu': idPekerjaanIbu,
        if (idPenghasilanIbu != null) 'id_penghasilan_ibu': idPenghasilanIbu,
        if (idKebutuhanKhususIbu != null)
          'id_kebutuhan_khusus_ibu': idKebutuhanKhususIbu,
      },
      // ── guardian_data ──
      'guardian_data': {
        if (namaWali != null) 'nama_wali': namaWali,
        if (tanggalLahirWali != null) 'tanggal_lahir_wali': tanggalLahirWali,
        if (idJenjangPendidikanWali != null)
          'id_jenjang_pendidikan_wali': idJenjangPendidikanWali,
        if (idPekerjaanWali != null) 'id_pekerjaan_wali': idPekerjaanWali,
        if (idPenghasilanWali != null) 'id_penghasilan_wali': idPenghasilanWali,
      },
      // ── other_data ──
      'other_data': {
        if (penerimaKps != null) 'penerima_kps': penerimaKps,
        if (noKps != null) 'no_kps': noKps,
        if (npwp != null) 'npwp': npwp,
        if (remark != null) 'remark': remark,
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
      kelas: kelas,
      statusKonversi: statusKonversi,
      // ── contact_data ──
      noWa: noWa,
      email: email,
      tempatLahir: tempatLahir,
      tanggalLahir: tanggalLahir,
      agama: agama,
      kelamin: kelamin,
      suku: suku,
      statusMenikah: statusMenikah,
      idKebutuhanKhususMahasiswa: idKebutuhanKhususMahasiswa,
      statusTinggal: statusTinggal,
      transportasi: transportasi,
      // ── education_data ──
      namaAsalSekolah: namaAsalSekolah,
      tahunLulus: tahunLulus,
      // ── address_data ──
      propinsi: propinsi,
      kabupaten: kabupaten,
      kecamatan: kecamatan,
      idWilayah: idWilayah,
      desa: desa,
      alamatDusun: alamatDusun,
      alamatRw: alamatRw,
      alamatRt: alamatRt,
      alamatJalan: alamatJalan,
      kodePos: kodePos,
      // ── employment_data ──
      statusBekerja: statusBekerja,
      namaKantor: namaKantor,
      alamatKantor: alamatKantor,
      // ── father_data ──
      namaAyah: namaAyah,
      tanggalLahirAyah: tanggalLahirAyah,
      nikAyah: nikAyah,
      noHpAyah: noHpAyah,
      idJenjangPendidikanAyah: idJenjangPendidikanAyah,
      idPekerjaanAyah: idPekerjaanAyah,
      idPenghasilanAyah: idPenghasilanAyah,
      idKebutuhanKhususAyah: idKebutuhanKhususAyah,
      // ── mother_data ──
      namaIbu: namaIbu,
      tanggalLahirIbu: tanggalLahirIbu,
      nikIbu: nikIbu,
      noHpIbu: noHpIbu,
      idJenjangPendidikanIbu: idJenjangPendidikanIbu,
      idPekerjaanIbu: idPekerjaanIbu,
      idPenghasilanIbu: idPenghasilanIbu,
      idKebutuhanKhususIbu: idKebutuhanKhususIbu,
      // ── guardian_data ──
      namaWali: namaWali,
      tanggalLahirWali: tanggalLahirWali,
      idJenjangPendidikanWali: idJenjangPendidikanWali,
      idPekerjaanWali: idPekerjaanWali,
      idPenghasilanWali: idPenghasilanWali,
      // ── other_data ──
      penerimaKps: penerimaKps,
      noKps: noKps,
      npwp: npwp,
      remark: remark,
    );
  }
}
