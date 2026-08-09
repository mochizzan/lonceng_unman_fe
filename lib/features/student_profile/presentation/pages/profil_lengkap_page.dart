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
              _buildField('Fakultas', profile.fakultas),
              _buildField('Angkatan', profile.angkatan),
            ],
          ),
          _buildSection(
            context,
            title: 'Kontak',
            icon: Icons.contact_phone_outlined,
            children: [
              _buildField('Email', profile.email),
              _buildField('No. HP', profile.noHp),
              _buildField('Alamat Lengkap', profile.alamatLengkap),
              _buildField('Kota', profile.kota),
              _buildField('Provinsi', profile.provinsi),
              _buildField('Kode Pos', profile.kodePos),
              _buildField('Kecamatan', profile.kecamatan),
              _buildField('Kelurahan', profile.kelurahan),
              _buildField('Negara', profile.negara),
              _buildField('No. HP Orang Tua', profile.noHpOrangtua),
              _buildField('Nama Kontak Darurat', profile.namaKontakDarurat),
            ],
          ),
          _buildSection(
            context,
            title: 'Pendidikan',
            icon: Icons.school_outlined,
            children: [
              _buildField('Status', profile.status),
              _buildField('Tahun Ajaran', profile.tahunAjaran),
            ],
          ),
          _buildSection(
            context,
            title: 'Alamat',
            icon: Icons.home_outlined,
            children: [
              // Alamat Rumah
              _buildField('Alamat Rumah', profile.alamatRumah),
              _buildField('RT', profile.rt),
              _buildField('RW', profile.rw),
              _buildField('Kelurahan', profile.kelurahanRumah),
              _buildField('Kecamatan', profile.kecamatanRumah),
              _buildField('Kota', profile.kotaRumah),
              _buildField('Provinsi', profile.provinsiRumah),
              _buildField('Kode Pos', profile.kodePosRumah),
              // Alamat Sementara
              const Divider(height: AppDimens.space24),
              _buildField('Alamat Sementara', profile.alamatSementara),
              _buildField('RT Sementara', profile.alamatSementaraRt),
              _buildField('RW Sementara', profile.alamatSementaraRw),
              _buildField(
                'Kelurahan Sementara',
                profile.alamatSementaraKelurahan,
              ),
              _buildField(
                'Kecamatan Sementara',
                profile.alamatSementaraKecamatan,
              ),
              _buildField('Kota Sementara', profile.alamatSementaraKota),
              _buildField(
                'Provinsi Sementara',
                profile.alamatSementaraProvinsi,
              ),
              _buildField('Kode Pos Sementara', profile.alamatSementaraKodePos),
            ],
          ),
          _buildSection(
            context,
            title: 'Pekerjaan',
            icon: Icons.work_outline,
            children: [
              _buildField('Pekerjaan', profile.pekerjaan),
              _buildField('Perusahaan', profile.perusahaan),
              _buildField('Penghasilan', profile.penghasilan),
            ],
          ),
          _buildSection(
            context,
            title: 'Data Ayah',
            icon: Icons.male_outlined,
            children: [
              _buildField('Nama Ayah', profile.namaAyah),
              _buildField('Tempat Lahir', profile.tempatLahirAyah),
              _buildField('Tanggal Lahir', profile.tanggalLahirAyah),
              _buildField('Pekerjaan', profile.pekerjaanAyah),
              _buildField('Penghasilan', profile.penghasilanAyah),
              _buildField('Alamat', profile.alamatAyah),
              _buildField('No. HP', profile.noHpAyah),
              _buildField('Email', profile.emailAyah),
            ],
          ),
          _buildSection(
            context,
            title: 'Data Ibu',
            icon: Icons.female_outlined,
            children: [
              _buildField('Nama Ibu', profile.namaIbu),
              _buildField('Tempat Lahir', profile.tempatLahirIbu),
              _buildField('Tanggal Lahir', profile.tanggalLahirIbu),
              _buildField('Pekerjaan', profile.pekerjaanIbu),
              _buildField('Penghasilan', profile.penghasilanIbu),
              _buildField('Alamat', profile.alamatIbu),
              _buildField('No. HP', profile.noHpIbu),
              _buildField('Email', profile.emailIbu),
            ],
          ),
          _buildSection(
            context,
            title: 'Data Wali',
            icon: Icons.supervisor_account_outlined,
            children: [
              _buildField('Nama Wali', profile.namaWali),
              _buildField('Hubungan', profile.hubunganWali),
              _buildField('Pekerjaan', profile.pekerjaanWali),
              _buildField('Alamat', profile.alamatWali),
              _buildField('No. HP', profile.noHpWali),
            ],
          ),
          _buildSection(
            context,
            title: 'Data Lainnya',
            icon: Icons.more_horiz_outlined,
            children: [
              _buildField('Golongan Darah', profile.golonganDarah),
              _buildField('Riwayat Penyakit', profile.riwayatPenyakit),
              _buildField('Riwayat Alergi', profile.riwayatAlergi),
              _buildField('Riwayat Operasi', profile.riwayatOperasi),
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
