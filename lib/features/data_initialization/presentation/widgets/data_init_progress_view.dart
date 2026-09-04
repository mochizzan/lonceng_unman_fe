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
  });

  final VoidCallback? onComplete;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;
  final bool isFreshLogin;

  @override
  State<DataInitProgressView> createState() => _DataInitProgressViewState();
}

class _DataInitProgressViewState extends State<DataInitProgressView> {
  Timer? _autoContinueTimer;

  @override
  void dispose() {
    _autoContinueTimer?.cancel();
    super.dispose();
  }

  bool _isProfileError(String? failedStep) {
    if (failedStep == null) return false;
    return failedStep.startsWith('profile');
  }

  /// Translates the technical `failedStep` (e.g. "downloadingKrs", "timeout")
  /// from [DataInitFailure] into a human-readable Indonesian label so users
  /// can see which pipeline step broke.
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
        // Map raw status name (e.g. downloadingKrs) to its Indonesian label
        // by reusing the existing status-text helper. Falls back to the
        // raw identifier if no mapping exists.
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<DataInitBloc, DataInitBlocState>(
      listener: (context, state) {
        if (state is! DataInitFailure) {
          _autoContinueTimer?.cancel();
        }
      },
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onComplete!(),
          );
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

        return Center(
          child: Padding(
            padding: EdgeInsets.all(sp(context, AppDimens.space32)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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

                // Progress indicator
                if (!isCompleted && state is! DataInitFailure)
                  CircularProgressIndicator(color: cs.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Detailed error view shown inside the refresh overlay when the pipeline
  /// fails. Displays the failed step, the human-readable error message, and
  /// retry/close actions so users can act without pull-refreshing again.
  Widget _buildErrorView(
    BuildContext context,
    ColorScheme cs,
    DataInitFailure state,
  ) {
    final stepLabel = _humanReadableFailedStep(state.failedStep);
    final hasActions = widget.onRetry != null || widget.onClose != null;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(sp(context, AppDimens.space32)),
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
            // Failed step — gives users a precise pointer to where the
            // pipeline broke instead of a generic "fetch failed" message.
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
            // Underlying error message (already run through ErrorHandler so
            // it is a friendly Indonesian sentence — not a raw stack trace).
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
        ),
      ),
    );
  }
}
