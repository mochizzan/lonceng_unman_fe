// home - Quick Stats widget
//
// Grid of stat cards: SKS semester, kuliah hari ini, semester info, IPK.
// Matches the HTML template's quick stats section.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/shared/widgets/stat_card.dart';

class QuickStats extends StatelessWidget {
  const QuickStats({super.key, required this.data});

  final HomeEntity data;

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
                footnote: ' / ${data.sksTotal} ${AppStrings.homeSksUnit}',
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
        // Semester + IPK card (full width) — secondary container
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
              // Semester info
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
                        data.semester,
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
                            alpha: AppColors.opacityMax,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // IPK
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.homeIpkTerakhir,
                    style: TextStyle(
                      fontSize: AppDimens.textXS,
                      color: cs.onSecondaryContainer.withValues(
                        alpha: AppColors.opacityMax,
                      ),
                    ),
                  ),
                  Text(
                    data.gpa.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: AppDimens.textXL,
                      fontWeight: FontWeight.bold,
                      color: cs.onSecondaryContainer,
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
