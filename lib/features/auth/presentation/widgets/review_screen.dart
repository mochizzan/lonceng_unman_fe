// auth - Review Screen Widget
//
// Overlay screen yang menampilkan data profil mahasiswa yang sudah di-scrape
// untuk konfirmasi sebelum akun diaktifkan. Mengikuti design system
// Material 3 dengan seed color yang sudah ada di app.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/features/student_profile/domain/entities/student_profile_entity.dart';

/// Overlay screen untuk review data profil mahasiswa setelah scraping.
///
/// Menampilkan 6 field utama dari [StudentProfileEntity] dalam bentuk card,
/// dengan dua tombol aksi: "Bukan Akun Saya" (outlined) dan
/// "Ya, Konfirmasi" (filled).
class ReviewScreen extends StatelessWidget {
  final StudentProfileEntity data;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const ReviewScreen({
    super.key,
    required this.data,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Header ──
              Icon(
                Icons.person_search_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Konfirmasi Data Profil',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pastikan data di bawah ini adalah data Anda.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Profile Card ──
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ProfileField(label: 'NIM', value: data.nim),
                        const Divider(height: 24),
                        _ProfileField(label: 'NISN', value: data.nisn),
                        const Divider(height: 24),
                        _ProfileField(label: 'NIK', value: data.nik),
                        const Divider(height: 24),
                        _ProfileField(label: 'Nama', value: data.namaMahasiswa),
                        const Divider(height: 24),
                        _ProfileField(
                          label: 'Program Studi',
                          value: data.programStudi,
                        ),
                        const Divider(height: 24),
                        _ProfileField(label: 'Semester', value: data.semester),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Bukan Akun Saya'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Ya, Konfirmasi'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget internal untuk menampilkan satu field profil.
class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
