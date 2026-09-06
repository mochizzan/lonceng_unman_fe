import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_status_text.dart'
    as init;
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/khs_timeline_view.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/wakelock_controller.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

const Duration kStepErrorAutoContinue = Duration(seconds: 15);

class DataInitProgressView extends StatefulWidget {
  const DataInitProgressView({
    super.key,
    this.onComplete,
    this.onRetry,
    this.onCancel,
    this.onClose,
    this.isFreshLogin = false,
    this.onKhsCountChanged,
  });

  final VoidCallback? onComplete;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;
  final bool isFreshLogin;
  final ValueChanged<int>? onKhsCountChanged;

  @override
  State<DataInitProgressView> createState() => _DataInitProgressViewState();
}

class _DataInitProgressViewState extends State<DataInitProgressView> {
  Timer? _autoContinueTimer;
  final Map<String, KhsSemesterTimeline> _khsMap =
      <String, KhsSemesterTimeline>{};
  late final ScrollController _scrollCtrl = ScrollController();
  late final WakelockController _wakelock = WakelockController();
  final ValueNotifier<int> _khsCount = ValueNotifier<int>(0);

  int get khsMapLength => _khsMap.length;
  ValueNotifier<int> get khsCount => _khsCount;

  @override
  void dispose() {
    _autoContinueTimer?.cancel();
    _scrollCtrl.dispose();
    // Fire-and-forget disable — idempotent via guard.
    unawaited(_wakelock.disable());
    _khsCount.dispose();
    super.dispose();
  }

  bool _isProfileError(String? failedStep) {
    if (failedStep == null) return false;
    return failedStep.startsWith('profile');
  }

  String _humanReadableFailedStep(String? failedStep) {
    if (failedStep == null || failedStep.isEmpty) {
      return AppStrings.refreshErrorStepUnknown;
    }
    switch (failedStep) {
      case 'timeout':
        return 'Batas waktu';
      case 'unknown':
        return AppStrings.refreshErrorStepUnknown;
      case 'no_connection':
        return AppStrings.dataInitNoConnectionStep;
      default:
        final status = _statusFromFailedStep(failedStep);
        if (status != null) {
          return init.dataInitStatusText(status).replaceAll('...', '');
        }
        return failedStep;
    }
  }

  DataInitStatus? _statusFromFailedStep(String step) {
    for (final s in DataInitStatus.values) {
      if (s.name == step) return s;
    }
    return null;
  }

  void _startAutoContinueTimer(VoidCallback onAutoContinue) {
    _autoContinueTimer?.cancel();
    _autoContinueTimer = Timer(kStepErrorAutoContinue, () {
      if (mounted) {
        onAutoContinue();
      }
    });
  }

  // -------------------------------------------------------------------------
  // Accumulator — view-side KHS timeline state
  // -------------------------------------------------------------------------

  void _accumulate(DataInitInProgress state) {
    final status = state.status;
    if (status != DataInitStatus.downloadingKhs &&
        status != DataInitStatus.extractingKhs &&
        status != DataInitStatus.fetchingKhsData) {
      return;
    }
    final parsed = parseKhsDetail(state.detail);
    if (parsed == null) return;
    final key = '${parsed.tahunAjaran}|${parsed.semester}';
    final existingKeys = _khsMap.keys.toList();
    final isNewKey = !_khsMap.containsKey(key);

    // Finalize previous semester when a new one starts downloading.
    if (isNewKey && status == DataInitStatus.downloadingKhs) {
      for (final k in existingKeys) {
        final prev = _khsMap[k]!;
        if (prev.fetch == KhsSemesterSubStepStatus.progress) {
          prev.fetch = KhsSemesterSubStepStatus.success;
        }
      }
    }

    final tl = _khsMap.putIfAbsent(
      key,
      () => KhsSemesterTimeline(
        tahunAjaran: parsed.tahunAjaran,
        semester: parsed.semester,
      ),
    );

    switch (status) {
      case DataInitStatus.downloadingKhs:
        tl.download = KhsSemesterSubStepStatus.progress;
        break;
      case DataInitStatus.extractingKhs:
        if (tl.download == KhsSemesterSubStepStatus.progress ||
            tl.download == KhsSemesterSubStepStatus.idle) {
          tl.download = KhsSemesterSubStepStatus.success;
        }
        tl.extract = KhsSemesterSubStepStatus.progress;
        break;
      case DataInitStatus.fetchingKhsData:
        if (tl.extract == KhsSemesterSubStepStatus.progress) {
          tl.extract = KhsSemesterSubStepStatus.success;
        }
        // Light path: download/extract were skipped — mark skipped.
        if (tl.download == KhsSemesterSubStepStatus.idle) {
          tl.download = KhsSemesterSubStepStatus.skipped;
        }
        if (tl.extract == KhsSemesterSubStepStatus.idle) {
          tl.extract = KhsSemesterSubStepStatus.skipped;
        }
        tl.fetch = KhsSemesterSubStepStatus.progress;
        break;
      default:
        break;
    }
  }

  void _finalizeAllProgress() {
    for (final tl in _khsMap.values) {
      if (tl.download == KhsSemesterSubStepStatus.progress) {
        tl.download = KhsSemesterSubStepStatus.success;
      }
      if (tl.extract == KhsSemesterSubStepStatus.progress) {
        tl.extract = KhsSemesterSubStepStatus.success;
      }
      if (tl.fetch == KhsSemesterSubStepStatus.progress) {
        tl.fetch = KhsSemesterSubStepStatus.success;
      }
    }
  }

  void _updateKhsCount() {
    final len = _khsMap.length;
    _khsCount.value = len;
    widget.onKhsCountChanged?.call(len);
  }

  void _autoScrollToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<DataInitBloc, DataInitBlocState>(
      listener: (context, state) async {
        if (state is DataInitInProgress) {
          // Fresh start — clear accumulator.
          if (state.status == DataInitStatus.scrapingProfile) {
            _khsMap.clear();
            _updateKhsCount();
            _autoContinueTimer?.cancel();
            if (!_wakelock.isHeld) {
              await _wakelock.enable();
            }
          }
          // KHS accumulation.
          if (state.status == DataInitStatus.downloadingKhs ||
              state.status == DataInitStatus.extractingKhs ||
              state.status == DataInitStatus.fetchingKhsData) {
            _accumulate(state);
            _updateKhsCount();
            _autoScrollToActive();
          }
        } else if (state is DataInitIdle) {
          _khsMap.clear();
          _updateKhsCount();
          _autoContinueTimer?.cancel();
        } else if (state is DataInitSuccess) {
          _finalizeAllProgress();
          _updateKhsCount();
          await _wakelock.disable();
        } else if (state is DataInitFailure) {
          await _wakelock.disable();
          if (state.failedStep != 'no_connection') {
            // Keep timeline context for debugging — don't clear.
          }
        }

        if (state is! DataInitFailure) {
          _autoContinueTimer?.cancel();
        }
      },
      child: BlocBuilder<DataInitBloc, DataInitBlocState>(
        builder: (context, state) {
          final isCompleted = state is DataInitSuccess;
          final isFailure = state is DataInitFailure;

          final statusText = isFailure
              ? AppStrings.refreshErrorTitle
              : state is DataInitInProgress
              ? init.dataInitStatusText(state.status, detail: state.detail)
              : isCompleted
              ? 'Data siap!'
              : 'Menyiapkan data...';

          if (isCompleted && widget.onComplete != null) {
            final delay = _khsMap.length > 1
                ? const Duration(milliseconds: 1500)
                : const Duration(milliseconds: 500);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(delay, () {
                if (mounted) widget.onComplete!();
              });
            });
          }

          if (isFailure && widget.isFreshLogin) {
            final isProfileErr = _isProfileError(state.failedStep);
            if (!isProfileErr && _autoContinueTimer == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startAutoContinueTimer(() {
                  widget.onRetry?.call();
                });
              });
            }
          }

          if (isFailure) {
            return _buildErrorView(context, cs, state);
          }

          // Header stays centered (original layout). Timeline has its own
          // wrapping container so it does not affect header centering,
          // indicator sizing, or cause Column(mainAxis:center) drift.
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(sp(context, AppDimens.space32)),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BellLogo(),
                        SizedBox(height: sp(context, AppDimens.space32)),
                        Text(
                          isCompleted ? 'Data akademik siap' : statusText,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: cs.onSurface,
                                fontSize: responsiveFontSize(
                                  context,
                                  AppDimens.textMD,
                                ),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: sp(context, AppDimens.space24)),
                        if (!isCompleted && state is! DataInitFailure)
                          CircularProgressIndicator(color: cs.primary),
                      ],
                    ),
                  ),
                  if (_khsMap.isNotEmpty) ...[
                    SizedBox(height: sp(context, AppDimens.space24)),
                    _KhsTimelineContainer(
                      items: _khsMap,
                      controller: _scrollCtrl,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    ColorScheme cs,
    DataInitFailure state,
  ) {
    final stepLabel = _humanReadableFailedStep(state.failedStep);
    final hasActions = widget.onRetry != null || widget.onClose != null;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(sp(context, AppDimens.space32)),
        child: Column(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppDimens.iconError,
                    color: cs.error,
                  ),
                  SizedBox(height: sp(context, AppDimens.space16)),
                  Text(
                    AppStrings.refreshErrorTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sp(context, AppDimens.space16)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sp(context, AppDimens.space16),
                      vertical: sp(context, AppDimens.space8),
                    ),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(
                        sp(context, AppDimens.radiusMD),
                      ),
                    ),
                    child: Text(
                      '${AppStrings.refreshErrorStepPrefix} $stepLabel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: sp(context, AppDimens.space16)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: sp(context, AppDimens.space8),
                    ),
                    child: Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: sp(context, AppDimens.space12)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: sp(context, AppDimens.space16),
                    ),
                    child: Text(
                      AppStrings.refreshErrorHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (hasActions) ...[
                    SizedBox(height: sp(context, AppDimens.space28)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.onRetry != null)
                          FilledButton.icon(
                            onPressed: widget.onRetry,
                            icon: const Icon(Icons.refresh),
                            label: const Text(AppStrings.refreshErrorRetry),
                          ),
                        if (widget.onRetry != null && widget.onClose != null)
                          SizedBox(width: sp(context, AppDimens.space12)),
                        if (widget.onClose != null)
                          OutlinedButton(
                            onPressed: widget.onClose,
                            child: const Text(AppStrings.refreshErrorClose),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Keep timeline context visible under error — outside the
            // centered header so it does not affect centering.
            if (_khsMap.isNotEmpty) ...[
              SizedBox(height: sp(context, AppDimens.space24)),
              _KhsTimelineContainer(items: _khsMap, controller: _scrollCtrl),
            ],
          ],
        ),
      ),
    );
  }
}

/// Own container wrapping the entire KHS timeline list.
/// Isolates timeline scrolling/layout from the header's centered
/// [BellLogo]/[CircularProgressIndicator] and error icon — restoring
/// the original overlay centering that was lost when the timeline
/// was injected directly into the same [Column].
class _KhsTimelineContainer extends StatelessWidget {
  const _KhsTimelineContainer({required this.items, this.controller});

  final Map<String, KhsSemesterTimeline> items;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: KhsTimelineView(items: items, controller: controller),
    );
  }
}
