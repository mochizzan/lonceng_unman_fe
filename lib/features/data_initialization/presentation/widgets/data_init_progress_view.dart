import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_status_text.dart'
    as init;
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

/// Duration for auto-continue on step error during fresh login.
const Duration kStepErrorAutoContinue = Duration(seconds: 15);

/// Shared progress view: logo + status text + progress indicator.
/// Listens to [DataInitBloc] and updates automatically.
///
/// Can be used inline (e.g. login page) or wrapped in a dialog
/// (e.g. [DataRefreshOverlay]).
class DataInitProgressView extends StatefulWidget {
  const DataInitProgressView({
    super.key,
    this.onComplete,
    this.onRetry,
    this.onCancel,
    this.isFreshLogin = false,
  });

  /// Called when [DataInitSuccess] is emitted.
  final VoidCallback? onComplete;

  /// Called when user taps retry after [DataInitFailure].
  /// If null, retry button is hidden.
  final VoidCallback? onRetry;

  /// Called when user taps cancel after [DataInitFailure] during fresh login.
  final VoidCallback? onCancel;

  /// Whether this view is shown during a fresh login flow.
  /// If true, error state shows retry + cancel buttons.
  /// If false (pull refresh), error auto-dismisses after 3 seconds.
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

  /// Check if the failed step is a Profile error.
  bool _isProfileError(String? failedStep) {
    if (failedStep == null) return false;
    return failedStep.startsWith('profile');
  }

  /// Start auto-continue timer for step errors (non-profile).
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
        // Cancel timer when state changes (not failure anymore)
        if (state is! DataInitFailure) {
          _autoContinueTimer?.cancel();
        }
      },
      builder: (context, state) {
        final statusText = state is DataInitInProgress
            ? init.dataInitStatusText(state.status, detail: state.detail)
            : state is DataInitSuccess
            ? 'Data siap!'
            : state is DataInitFailure
            ? 'Gagal memuat data'
            : 'Menyiapkan data...';

        final isCompleted = state is DataInitSuccess;

        if (isCompleted && widget.onComplete != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onComplete!(),
          );
        }

        // Handle failure state
        if (state is DataInitFailure && widget.isFreshLogin) {
          final isProfileErr = _isProfileError(state.failedStep);

          // For step errors (non-profile), start auto-continue timer
          if (!isProfileErr && _autoContinueTimer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startAutoContinueTimer(() {
                // Auto-continue: call onRetry to retry the step
                widget.onRetry?.call();
              });
            });
          }
        }

        return Center(
          child: Padding(
            padding: EdgeInsets.all(sp(context, AppDimens.space32)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const BellLogo(),
                SizedBox(height: sp(context, AppDimens.space32)),

                // Status text
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

                // Error message with buttons
                if (state is DataInitFailure) _buildErrorUI(context, state, cs),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorUI(
    BuildContext context,
    DataInitFailure state,
    ColorScheme cs,
  ) {
    final isProfileErr = _isProfileError(state.failedStep);

    return Column(
      children: [
        Icon(Icons.error_outline, size: 48, color: cs.error),
        SizedBox(height: sp(context, AppDimens.space16)),
        Text(
          state.message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        ),

        // Fresh login: show buttons based on error type
        if (widget.isFreshLogin) ...[
          SizedBox(height: sp(context, AppDimens.space24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile error: show Retry button
              if (isProfileErr && widget.onRetry != null)
                FilledButton(
                  onPressed: widget.onRetry,
                  child: const Text('Coba lagi'),
                ),

              // Profile error: show Cancel button
              if (isProfileErr && widget.onCancel != null) ...[
                SizedBox(width: sp(context, AppDimens.space16)),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Batalkan'),
                ),
              ],

              // Step error: show only Retry button (auto-continue after 15s)
              if (!isProfileErr && widget.onRetry != null)
                FilledButton(
                  onPressed: widget.onRetry,
                  child: const Text('Coba lagi'),
                ),
            ],
          ),

          // Step error: show auto-continue countdown
          if (!isProfileErr) ...[
            SizedBox(height: sp(context, AppDimens.space16)),
            Text(
              'Otomatis melanjutkan dalam ${kStepErrorAutoContinue.inSeconds} detik...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ],
    );
  }
}
