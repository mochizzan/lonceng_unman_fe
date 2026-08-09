// profil_lengkap_page.dart
//
// Halaman "Profil Lengkap" yang menampilkan seluruh data profil mahasiswa
// dari 9 kategori menggunakan ExpansionTile.
// Data dimuat dari StudentProfileCacheService (Hive).
// Semua field readonly.

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/models/student_profile_model.dart';

/// Halaman Profil Lengkap — menampilkan 9 section data profil mahasiswa.
class ProfilLengkapPage extends StatefulWidget {
  const ProfilLengkapPage({super.key});

  @override
  State<ProfilLengkapPage> createState() => _ProfilLengkapPageState();
}

class _ProfilLengkapPageState extends State<ProfilLengkapPage> {
  StudentProfileModel? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final academicCache = Services.get<AcademicCacheService>();
      final credentials = await academicCache.loadCredentials();
      if (credentials == null || !mounted) {
        setState(() {
          _error = 'Tidak dapat memuat data kredensial.';
          _isLoading = false;
        });
        return;
      }

      final npm = credentials['npm']!;
      final profileCache = Services.get<StudentProfileCacheService>();
      final rawData = await profileCache.loadProfile(npm: npm);
      if (rawData == null || !mounted) {
        setState(() {
          _error = 'Data profil tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }

      final model = StudentProfileModel.fromJson(rawData);
      if (mounted) {
        setState(() {
          _profile = model;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        'Gagal memuat profil lengkap: $e',
        name: 'ProfilLengkapPage',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data profil.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.profile);
            }
          },
        ),
        title: const Text('Profil Lengkap'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: AppDimens.iconError,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimens.textMD,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadProfile();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPaddingHorizontal,
      ).copyWith(bottom: AppDimens.space80),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.space16),
          _buildSection(
            context,
            title: 'Data Pribadi',
            icon: Icons.person_outline,
            children: [
              _buildField('NIM', profile.nim),
              _buildField('NISN', profile.nisn),
              _buildField('NIK', profile.nik),
              _buildField('Nama Mahasiswa', profile.namaMahasiswa),
              _buildField('Program Studi', profile.programStudi),
              _buildField('Semester', profile.semester),
              _buildField('Kelas', profile.kelas),
              _buildField('Status Konversi', profile.statusKonversi),
            ],
          ),
          _buildSection(
            context,
            title: 'Kontak',
            icon: Icons.contact_phone_outlined,
            children: [
              _buildField('No. WA', profile.noWa),
              _buildField('Email', profile.email),
              _buildField('Tempat Lahir', profile.tempatLahir),
              _buildField('Tanggal Lahir', profile.tanggalLahir),
              _buildField('Agama', profile.agama),
              _buildField('Jenis Kelamin', profile.kelamin),
              _buildField('Suku', profile.suku),
              _buildField('Status Menikah', profile.statusMenikah),
              _buildField(
                'Kebutuhan Khusus',
                profile.idKebutuhanKhususMahasiswa,
              ),
              _buildField('Status Tinggal', profile.statusTinggal),
              _buildField('Transportasi', profile.transportasi),
            ],
          ),
          _buildSection(
            context,
            title: 'Pendidikan',
            icon: Icons.school_outlined,
            children: [
              _buildField('Nama Asal Sekolah', profile.namaAsalSekolah),
              _buildField('Tahun Lulus', profile.tahunLulus),
            ],
          ),
          _buildSection(
            context,
            title: 'Alamat',
            icon: Icons.home_outlined,
            children: [
              _buildField('Alamat Dusun', profile.alamatDusun),
              _buildField('Alamat Jalan', profile.alamatJalan),
              _buildField('RT', profile.alamatRt),
              _buildField('RW', profile.alamatRw),
              _buildField('Desa', profile.desa),
              _buildField('Kecamatan', profile.kecamatan),
              _buildField('Kabupaten', profile.kabupaten),
              _buildField('Propinsi', profile.propinsi),
              _buildField('Kode Pos', profile.kodePos),
              _buildField('ID Wilayah', profile.idWilayah),
            ],
          ),
          _buildSection(
            context,
            title: 'Pekerjaan',
            icon: Icons.work_outline,
            children: [
              _buildField('Status Bekerja', profile.statusBekerja),
              _buildField('Nama Kantor', profile.namaKantor),
              _buildField('Alamat Kantor', profile.alamatKantor),
            ],
          ),
          _buildSection(
            context,
            title: 'Data Ayah',
            icon: Icons.male_outlined,
            children: [
              _buildField('Nama Ayah', profile.namaAyah),
              _buildField('Tanggal Lahir', profile.tanggalLahirAyah),
              _buildField('NIK', profile.nikAyah),
              _buildField('No. HP', profile.noHpAyah),
              _buildField(
                'Jenjang Pendidikan',
                profile.idJenjangPendidikanAyah,
              ),
              _buildField('Pekerjaan', profile.idPekerjaanAyah),
              _buildField('Penghasilan', profile.idPenghasilanAyah),
              _buildField('Kebutuhan Khusus', profile.idKebutuhanKhususAyah),
            ],
          ),
          _buildSection(
            context,
            title: 'Data Ibu',
            icon: Icons.female_outlined,
            children: [
              _buildField('Nama Ibu', profile.namaIbu),
              _buildField('Tanggal Lahir', profile.tanggalLahirIbu),
              _buildField('NIK', profile.nikIbu),
              _buildField('No. HP', profile.noHpIbu),
              _buildField('Jenjang Pendidikan', profile.idJenjangPendidikanIbu),
              _buildField('Pekerjaan', profile.idPekerjaanIbu),
              _buildField('Penghasilan', profile.idPenghasilanIbu),
              _buildField('Kebutuhan Khusus', profile.idKebutuhanKhususIbu),
            ],
          ),
          _buildSection(
            context,
            title: 'Data Wali',
            icon: Icons.supervisor_account_outlined,
            children: [
              _buildField('Nama Wali', profile.namaWali),
              _buildField('Tanggal Lahir', profile.tanggalLahirWali),
              _buildField(
                'Jenjang Pendidikan',
                profile.idJenjangPendidikanWali,
              ),
              _buildField('Pekerjaan', profile.idPekerjaanWali),
              _buildField('Penghasilan', profile.idPenghasilanWali),
            ],
          ),
          _buildSection(
            context,
            title: 'Data Lainnya',
            icon: Icons.more_horiz_outlined,
            children: [
              _buildField('Penerima KPS', profile.penerimaKps),
              _buildField('No. KPS', profile.noKps),
              _buildField('NPWP', profile.npwp),
              _buildField('Keterangan', profile.remark),
            ],
          ),
        ],
      ),
    );
  }

  /// Section dengan ExpansionTile.
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: AppDimens.textMD,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        shape: const RoundedRectangleBorder(),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space8,
        ),
        children: children,
      ),
    );
  }

  /// Field readonly: Label di atas, Value di bawah.
  /// Jika value null/empty, tampilkan '-'.
  Widget _buildField(String label, String? value) {
    final cs = Theme.of(context).colorScheme;
    final displayValue = (value != null && value.isNotEmpty) ? value : '-';

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimens.space2),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: AppDimens.textMD,
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
