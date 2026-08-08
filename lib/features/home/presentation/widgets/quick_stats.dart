// home - Quick Stats widget
//
// Grid of stat cards: SKS semester, kuliah hari ini, semester info, IPK.
// Matches the HTML template's quick stats section.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/shared/widgets/stat_card.dart';

class QuickStats extends StatelessWidget {
  const QuickStats({super.key, required this.data, this.onKhsTap});

  final HomeEntity data;
  final VoidCallback? onKhsTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // SKS and class count cards (2x1 grid)
        Row(
          children: [
            // SKS Semester Ini
            Expanded(
              child: StatCard(
                icon: Icons.auto_stories,
                iconColor: cs.primary,
                iconBg: cs.surfaceContainerHighest,
                label: AppStrings.homeSksSemester,
                labelColor: cs.onSurfaceVariant,
                value: data.sksTaken.toString(),
                valueColor: cs.onSurface,
                footnote: ' ${AppStrings.homeSksUnit}',
                footnoteColor: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            // Kuliah Hari Ini
            Expanded(
              child: StatCard(
                icon: Icons.calendar_today,
                iconColor: cs.primary,
                iconBg: cs.surfaceContainerHighest,
                label: AppStrings.homeKuliahHariIni,
                labelColor: cs.onSurfaceVariant,
                value: '${data.todayClassCount}',
                valueColor: cs.onSurface,
                footnote: ' ${AppStrings.homeClassUnit}',
                footnoteColor: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space12),
        // Tahun Ajaran + IPK card (full width) — secondary container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppDimens.radius2XL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: icon + tahun ajaran + program studi ──
              Row(
                children: [
                  Container(
                    width: AppDimens.avatarMD,
                    height: AppDimens.avatarMD,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                    ),
                    child: Icon(
                      Icons.school,
                      size: AppDimens.iconMD,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.tahunAjaran,
                          style: TextStyle(
                            fontSize: AppDimens.textLG,
                            fontWeight: FontWeight.bold,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                        Text(
                          data.studyProgram,
                          style: TextStyle(
                            fontSize: AppDimens.textSM,
                            color: cs.onSecondaryContainer.withValues(
                              alpha: ColorValues.opacityMax,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),
              // ── IPK section: chips + Lihat KHS button ──
              Row(
                children: [
                  // IPK Ganjil chip
                  _buildIpkChip(
                    label: 'Ganjil',
                    value: data.gpaGanjil.toStringAsFixed(2),
                    cs: cs,
                  ),
                  const SizedBox(width: AppDimens.space12),
                  // IPK Genap chip
                  _buildIpkChip(
                    label: 'Genap',
                    value: data.gpaGenap.toStringAsFixed(2),
                    cs: cs,
                  ),
                  const Spacer(),
                  // Tombol Lihat KHS
                  GestureDetector(
                    onTap: onKhsTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat KHS',
                          style: TextStyle(
                            fontSize: AppDimens.textSM,
                            fontWeight: FontWeight.w600,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: AppDimens.iconSM,
                          color: cs.onSecondaryContainer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a small chip displaying IPK label and value.
  static Widget _buildIpkChip({
    required String label,
    required String value,
    required ColorScheme cs,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space8,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimens.textXS,
              color: cs.onSecondaryContainer.withValues(
                alpha: ColorValues.opacityMax,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space2),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimens.textLG,
              fontWeight: FontWeight.bold,
              color: cs.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
