import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_status_text.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

/// Full-screen blocking overlay for data refresh progress.
/// Covers everything including bottom navbar.
/// Dismissable only on completion or error.
class DataRefreshOverlay extends StatelessWidget {
  const DataRefreshOverlay({super.key});

  /// Shows the overlay as a full-screen, non-dismissible dialog.
  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Data Refresh',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const DataRefreshOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<DataInitBloc, DataInitBlocState>(
      listener: (context, state) {
        if (state is DataInitSuccess) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        } else if (state is DataInitFailure) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gagal memperbarui data'),
              action: SnackBarAction(
                label: 'Coba lagi',
                onPressed: () => DataRefreshOverlay.show(context),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: BlocBuilder<DataInitBloc, DataInitBlocState>(
          builder: (context, state) {
            final statusText = state is DataInitInProgress
                ? dataInitStatusText(state.status)
                : state is DataInitSuccess
                ? 'Data siap!'
                : state is DataInitFailure
                ? 'Gagal memuat data'
                : 'Menyiapkan...';

            final isCompleted = state is DataInitSuccess;

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
                      statusText,
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

                    // Error message
                    if (state is DataInitFailure)
                      Padding(
                        padding: EdgeInsets.only(
                          top: sp(context, AppDimens.space16),
                        ),
                        child: Text(
                          state.message,
                          style: TextStyle(
                            color: cs.error,
                            fontSize: responsiveFontSize(
                              context,
                              AppDimens.textSM,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
