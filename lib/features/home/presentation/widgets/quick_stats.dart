// home - Quick Stats widget
//
// Grid of stat cards: SKS semester, kuliah hari ini, semester info, IPK.
// Matches the HTML template's quick stats section.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';

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
              child: _StatCard(
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
              child: _StatCard(
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.valueColor,
    required this.footnote,
    required this.footnoteColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final Color labelColor;
  final String value;
  final Color valueColor;
  final String footnote;
  final Color footnoteColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius2XL),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimens.avatarSM,
            height: AppDimens.avatarSM,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: AppDimens.iconSM, color: iconColor),
          ),
          Text(
            label,
            style: TextStyle(fontSize: AppDimens.textSM, color: labelColor),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: AppDimens.text4XL,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: footnote,
                  style: TextStyle(
                    fontSize: AppDimens.textBase,
                    fontWeight: FontWeight.w500,
                    color: footnoteColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
