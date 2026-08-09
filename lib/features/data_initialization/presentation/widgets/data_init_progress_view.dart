import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_status_text.dart'
    as init;
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

/// Shared progress view: logo + status text + progress indicator.
/// Listens to [DataInitBloc] and updates automatically.
///
/// Can be used inline (e.g. login page) or wrapped in a dialog
/// (e.g. [DataRefreshOverlay]).
class DataInitProgressView extends StatelessWidget {
  const DataInitProgressView({super.key, this.onComplete, this.onRetry});

  /// Called when [DataInitSuccess] is emitted.
  final VoidCallback? onComplete;

  /// Called when user taps retry after [DataInitFailure].
  /// If null, retry button is hidden.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<DataInitBloc, DataInitBlocState>(
      builder: (context, state) {
        final statusText = state is DataInitInProgress
            ? init.dataInitStatusText(state.status, detail: state.detail)
            : state is DataInitSuccess
            ? 'Data siap!'
            : state is DataInitFailure
            ? 'Gagal memuat data'
            : 'Menyiapkan data...';

        final isCompleted = state is DataInitSuccess;

        if (isCompleted && onComplete != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onComplete!());
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

                // Error message with retry button
                if (state is DataInitFailure)
                  Column(
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
                      if (onRetry != null) ...[
                        SizedBox(height: sp(context, AppDimens.space24)),
                        FilledButton(
                          onPressed: onRetry,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
