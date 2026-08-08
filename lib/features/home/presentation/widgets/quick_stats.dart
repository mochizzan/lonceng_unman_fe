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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kiri: icon + tahun ajaran + program studi
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
                  Column(
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
                ],
              ),
              // Kanan: IPK ganjil + genap + tombol Lihat KHS
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // IPK Ganjil
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Ganjil',
                            style: TextStyle(
                              fontSize: AppDimens.textXS,
                              color: cs.onSecondaryContainer.withValues(
                                alpha: ColorValues.opacityMax,
                              ),
                            ),
                          ),
                          Text(
                            data.gpaGanjil.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: AppDimens.textLG,
                              fontWeight: FontWeight.bold,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppDimens.space12),
                      // IPK Genap
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Genap',
                            style: TextStyle(
                              fontSize: AppDimens.textXS,
                              color: cs.onSecondaryContainer.withValues(
                                alpha: ColorValues.opacityMax,
                              ),
                            ),
                          ),
                          Text(
                            data.gpaGenap.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: AppDimens.textLG,
                              fontWeight: FontWeight.bold,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space4),
                  // Tombol Lihat KHS
                  GestureDetector(
                    onTap: onKhsTap,
                    child: Text(
                      'Lihat KHS >',
                      style: TextStyle(
                        fontSize: AppDimens.textXS,
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
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
}
