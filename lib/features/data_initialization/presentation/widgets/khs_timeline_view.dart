import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/theme.dart';

// ---------------------------------------------------------------------------
// Local model — view-only, NOT domain entity
// ---------------------------------------------------------------------------

enum KhsSemesterSubStepStatus { idle, progress, success, error, skipped }

class KhsSemesterTimeline {
  KhsSemesterTimeline({required this.tahunAjaran, required this.semester});

  final String tahunAjaran;
  final String semester;

  KhsSemesterSubStepStatus download = KhsSemesterSubStepStatus.idle;
  KhsSemesterSubStepStatus extract = KhsSemesterSubStepStatus.idle;
  KhsSemesterSubStepStatus fetch = KhsSemesterSubStepStatus.idle;

  String get label => '$tahunAjaran \u2014 $semester';

  /// Worst status across sub-steps: error > progress > success > idle/skipped.
  KhsSemesterSubStepStatus get overall {
    final all = [download, extract, fetch];
    if (all.contains(KhsSemesterSubStepStatus.error)) {
      return KhsSemesterSubStepStatus.error;
    }
    if (all.contains(KhsSemesterSubStepStatus.progress)) {
      return KhsSemesterSubStepStatus.progress;
    }
    if (all.contains(KhsSemesterSubStepStatus.success)) {
      return KhsSemesterSubStepStatus.success;
    }
    return KhsSemesterSubStepStatus.idle;
  }

  bool get isLight =>
      download == KhsSemesterSubStepStatus.skipped &&
      extract == KhsSemesterSubStepStatus.skipped;
}

// ---------------------------------------------------------------------------
// Parser helper — single source of truth for accumulator + tests
// ---------------------------------------------------------------------------

/// Parse `detail` formatted as `"$tahunAjaran $semester"` where `tahunAjaran`
/// contains `/` (e.g. `"2022/2023 Ganjil"`). Splits at last space.
/// Returns `null` if null/empty or no space found.
({String tahunAjaran, String semester})? parseKhsDetail(String? detail) {
  if (detail == null || detail.isEmpty) return null;
  final idx = detail.lastIndexOf(' ');
  if (idx <= 0) return null;
  return (
    tahunAjaran: detail.substring(0, idx),
    semester: detail.substring(idx + 1),
  );
}

// ---------------------------------------------------------------------------
// Color helpers — existing tokens only, no new hex
// ---------------------------------------------------------------------------

Color _chipBg(
  KhsSemesterSubStepStatus status,
  ColorScheme cs,
  AppColors appColors,
) {
  switch (status) {
    case KhsSemesterSubStepStatus.progress:
      return cs.primaryContainer;
    case KhsSemesterSubStepStatus.success:
      return appColors.successContainer;
    case KhsSemesterSubStepStatus.error:
      return cs.errorContainer;
    case KhsSemesterSubStepStatus.skipped:
    case KhsSemesterSubStepStatus.idle:
      return cs.surfaceContainerHighest;
  }
}

Color _chipFg(
  KhsSemesterSubStepStatus status,
  ColorScheme cs,
  AppColors appColors,
) {
  switch (status) {
    case KhsSemesterSubStepStatus.progress:
      return cs.onPrimaryContainer;
    case KhsSemesterSubStepStatus.success:
      return appColors.onSuccessContainer;
    case KhsSemesterSubStepStatus.error:
      return cs.onErrorContainer;
    case KhsSemesterSubStepStatus.skipped:
    case KhsSemesterSubStepStatus.idle:
      return cs.onSurfaceVariant;
  }
}

IconData _statusIcon(KhsSemesterSubStepStatus status, {bool isLight = false}) {
  if (isLight &&
      (status == KhsSemesterSubStepStatus.skipped ||
          status == KhsSemesterSubStepStatus.idle)) {
    return Icons.remove;
  }
  switch (status) {
    case KhsSemesterSubStepStatus.progress:
      return Icons.autorenew;
    case KhsSemesterSubStepStatus.success:
      return Icons.check_circle;
    case KhsSemesterSubStepStatus.error:
      return Icons.error;
    case KhsSemesterSubStepStatus.skipped:
      return Icons.remove;
    case KhsSemesterSubStepStatus.idle:
      return Icons.circle_outlined;
  }
}

Color _dotColor(
  KhsSemesterSubStepStatus overall,
  ColorScheme cs,
  AppColors appColors,
) {
  switch (overall) {
    case KhsSemesterSubStepStatus.progress:
      return cs.primary;
    case KhsSemesterSubStepStatus.success:
      return appColors.success;
    case KhsSemesterSubStepStatus.error:
      return cs.error;
    case KhsSemesterSubStepStatus.skipped:
    case KhsSemesterSubStepStatus.idle:
      return cs.outlineVariant;
  }
}

String _chipLabel(
  String base,
  KhsSemesterSubStepStatus status, {
  bool isLightDownloadOrExtract = false,
}) {
  if (isLightDownloadOrExtract &&
      (status == KhsSemesterSubStepStatus.skipped ||
          status == KhsSemesterSubStepStatus.idle)) {
    return 'Dilewati';
  }
  return base;
}

// ---------------------------------------------------------------------------
// Timeline widget
// ---------------------------------------------------------------------------

class KhsTimelineView extends StatelessWidget {
  const KhsTimelineView({super.key, required this.items, this.controller});

  final Map<String, KhsSemesterTimeline> items;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light;

    if (items.isEmpty) return const SizedBox.shrink();

    final entries = items.values.toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: ListView.builder(
        controller: controller,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: entries.length,
        padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
        itemBuilder: (context, index) {
          final tl = entries[index];
          final isLast = index == entries.length - 1;

          return Semantics(
            label: 'KHS ${tl.label}, ${tl.overall.name}',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left rail: dot + vertical line
                SizedBox(
                  width: AppDimens.space24,
                  child: Column(
                    children: [
                      Container(
                        width: AppDimens.dotMD + 2,
                        height: AppDimens.dotMD + 2,
                        decoration: BoxDecoration(
                          color: _dotColor(tl.overall, cs, appColors),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 56,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                ),
                // Right card
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: isLast ? 0 : AppDimens.space12,
                    ),
                    padding: const EdgeInsets.all(AppDimens.space12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tl.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppDimens.space8),
                        Wrap(
                          spacing: AppDimens.space8,
                          runSpacing: AppDimens.space8,
                          children: [
                            _Chip(
                              label: _chipLabel(
                                'DOWNLOAD',
                                tl.download,
                                isLightDownloadOrExtract: tl.isLight,
                              ),
                              status: tl.download,
                              cs: cs,
                              appColors: appColors,
                            ),
                            _Chip(
                              label: _chipLabel(
                                'EXTRACT',
                                tl.extract,
                                isLightDownloadOrExtract: tl.isLight,
                              ),
                              status: tl.extract,
                              cs: cs,
                              appColors: appColors,
                            ),
                            _Chip(
                              label: 'GET',
                              status: tl.fetch,
                              cs: cs,
                              appColors: appColors,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.status,
    required this.cs,
    required this.appColors,
  });

  final String label;
  final KhsSemesterSubStepStatus status;
  final ColorScheme cs;
  final AppColors appColors;

  @override
  Widget build(BuildContext context) {
    final bg = _chipBg(status, cs, appColors);
    final fg = _chipFg(status, cs, appColors);
    final isLightChip =
        label == 'Dilewati' &&
        (status == KhsSemesterSubStepStatus.skipped ||
            status == KhsSemesterSubStepStatus.idle);
    final icon = _statusIcon(status, isLight: isLightChip);

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimens.iconSM, color: fg),
          const SizedBox(width: AppDimens.space4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (status == KhsSemesterSubStepStatus.progress) {
      return _PulsingChip(child: content);
    }
    return content;
  }
}

class _PulsingChip extends StatefulWidget {
  const _PulsingChip({required this.child});
  final Widget child;

  @override
  State<_PulsingChip> createState() => _PulsingChipState();
}

class _PulsingChipState extends State<_PulsingChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.6,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
