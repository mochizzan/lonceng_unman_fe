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
    final rawDetail = state.detail;
    if (rawDetail == null) return;
    // Sentinel: "$tahunAjaran $semester ::error::<download|extract|fetch>"
    // DataInitStatus frozen -> detail reuse. Strip suffix before parse.
    final isSentinel = rawDetail.contains(' ::error::');
    String baseDetail = rawDetail;
    String? failSub;
    if (isSentinel) {
      final sep = rawDetail.indexOf(' ::error::');
      baseDetail = rawDetail.substring(0, sep);
      failSub = rawDetail.substring(sep + ' ::error::'.length).trim();
    }
    final parsed = parseKhsDetail(baseDetail);
    if (parsed == null) return;
    final key = '${parsed.tahunAjaran}|${parsed.semester}';
    final existingKeys = _khsMap.keys.toList();
    final isNewKey = !_khsMap.containsKey(key);

    // Finalize previous semester when a new one starts downloading
    // — but never overwrite an error.
    if (isNewKey && status == DataInitStatus.downloadingKhs && !isSentinel) {
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

    // Sentinel path: mark that sub-step merah, do not touch others.
    if (isSentinel) {
      switch (failSub) {
        case 'download':
          tl.download = KhsSemesterSubStepStatus.error;
          break;
        case 'extract':
          tl.extract = KhsSemesterSubStepStatus.error;
          break;
        case 'fetch':
        default:
          tl.fetch = KhsSemesterSubStepStatus.error;
          break;
      }
      // Ensure view rebuild counts this semester.
      return;
    }

    // Normal progress path — never overwrite error.
    switch (status) {
      case DataInitStatus.downloadingKhs:
        if (tl.download != KhsSemesterSubStepStatus.error) {
          tl.download = KhsSemesterSubStepStatus.progress;
        }
        break;
      case DataInitStatus.extractingKhs:
        if (tl.download == KhsSemesterSubStepStatus.progress) {
          tl.download = KhsSemesterSubStepStatus.success;
        } else if (tl.download == KhsSemesterSubStepStatus.error) {
          // keep merah — do not touch
        }
        if (tl.extract != KhsSemesterSubStepStatus.error) {
          tl.extract = KhsSemesterSubStepStatus.progress;
        }
        break;
      case DataInitStatus.fetchingKhsData:
        if (tl.extract == KhsSemesterSubStepStatus.progress) {
          tl.extract = KhsSemesterSubStepStatus.success;
        }
        // Light path: download/extract were skipped — mark skipped
        // but never overwrite error.
        if (tl.download == KhsSemesterSubStepStatus.idle) {
          tl.download = KhsSemesterSubStepStatus.skipped;
        }
        if (tl.extract == KhsSemesterSubStepStatus.idle) {
          tl.extract = KhsSemesterSubStepStatus.skipped;
        }
        if (tl.fetch != KhsSemesterSubStepStatus.error) {
          tl.fetch = KhsSemesterSubStepStatus.progress;
        }
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
      // error stays merah — never jadi hijau
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

          // Layout restores original centered overlay: header (logo +
          // status + spinner) stays centered in viewport; KHS timeline
          // lives in its own bordered container below and does not
          // shift the header's centering calculation.
          return LayoutBuilder(
            builder: (context, constraints) {
              final header = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BellLogo(),
                  SizedBox(height: sp(context, AppDimens.space32)),
                  Text(
                    isCompleted ? 'Data akademik siap' : statusText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface,
                      fontSize: responsiveFontSize(context, AppDimens.textMD),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sp(context, AppDimens.space24)),
                  if (!isCompleted && state is! DataInitFailure)
                    CircularProgressIndicator(color: cs.primary),
                ],
              );

              // Empty timeline: keep original exact centering (no extra
              // container, no bottom gap — avoids the "hanging" wrap).
              if (_khsMap.isEmpty) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(sp(context, AppDimens.space32)),
                        child: header,
                      ),
                    ),
                  ),
                );
              }

              // With timeline: flex layout — vertical Column.
              // Header preserved as centered band (Center + ConstrainedBox
              // minHeight), timeline in its own wrapping Container below.
              // No Expanded/Flexible on unbounded axis (inside
              // SingleChildScrollView) — constraint-safety rule.
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.all(sp(context, AppDimens.space32)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: header),
                        SizedBox(height: sp(context, AppDimens.space24)),
                        // Timeline — own container, bounded scroll inside
                        _KhsTimelineContainer(
                          items: _khsMap,
                          controller: _scrollCtrl,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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

    final errorHeader = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: AppDimens.iconError, color: cs.error),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
    );

    // Same hanging fix as success path. When KHS empty, just center
    // the error header (no timeline container, no bottom gap).
    if (_khsMap.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(sp(context, AppDimens.space32)),
                  child: errorHeader,
                ),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.all(sp(context, AppDimens.space32)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: errorHeader),
                  SizedBox(height: sp(context, AppDimens.space24)),
                  _KhsTimelineContainer(
                    items: _khsMap,
                    controller: _scrollCtrl,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
