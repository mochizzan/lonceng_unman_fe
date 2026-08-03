// home - Quick Stats widget
//
// Grid of stat cards: SKS semester, kuliah hari ini, semester info, IPK.
// Matches the HTML template's quick stats section.

import 'package:flutter/material.dart';
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
                label: 'SKS Semester Ini',
                labelColor: cs.onSurfaceVariant,
                value: data.sksTaken.toString(),
                valueColor: cs.onSurface,
                footnote: ' / ${data.sksTotal}',
                footnoteColor: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            // Kuliah Hari Ini
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today,
                iconColor: cs.primary,
                iconBg: cs.surfaceContainerHighest,
                label: 'Kuliah Hari Ini',
                labelColor: cs.onSurfaceVariant,
                value: '${data.todayClassCount}',
                valueColor: cs.onSurface,
                footnote: ' Kelas',
                footnoteColor: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Semester + IPK card (full width) — secondary container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Semester info
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.school,
                      size: 20,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.semester,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        data.studyProgram,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSecondaryContainer.withValues(alpha: 0.7),
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
                    'IPK Terakhir',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSecondaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    data.gpa.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 16,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: footnote,
                  style: TextStyle(
                    fontSize: 13,
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
