import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_status_text.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

/// Full-screen blocking overlay for data refresh progress.
///
/// Listens to [DataInitBloc] and auto-shows/dismisses the overlay
/// based on state transitions. Place this widget in the tree root
/// (e.g. above [MaterialApp]) so the overlay can cover the entire screen.
///
/// This replaces the home-only [DataRefreshOverlay] with a centralized,
/// globally-available overlay that works from any screen.
class GlobalRefreshOverlay extends StatefulWidget {
  final Widget child;

  const GlobalRefreshOverlay({super.key, required this.child});

  @override
  State<GlobalRefreshOverlay> createState() => _GlobalRefreshOverlayState();
}

class _GlobalRefreshOverlayState extends State<GlobalRefreshOverlay> {
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Subscribe to DataInitBloc to auto-show/dismiss the overlay.
    final bloc = context.read<DataInitBloc>();
    _subscription = bloc.stream.listen(_onBlocStateChange);
    // Check current state in case the bloc is already in progress.
    _onBlocStateChange(bloc.state);
  }

  StreamSubscription<dynamic>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onBlocStateChange(DataInitBlocState state) {
    if (state is DataInitInProgress) {
      _showOverlay(dataInitStatusText(state.status, detail: state.detail));
    } else if (state is DataInitSuccess) {
      _updateOverlay('Data siap!');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _dialogShowing) {
          Navigator.of(context).pop();
          _dialogShowing = false;
        }
      });
    } else if (state is DataInitFailure) {
      if (_dialogShowing) {
        Navigator.of(context).pop();
        _dialogShowing = false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal memperbarui data')));
    }
  }

  void _showOverlay(String statusText) {
    if (_dialogShowing) {
      // Already showing — update status text.
      _updateOverlay(statusText);
      return;
    }
    _dialogShowing = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Data Refresh',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _OverlayContent(statusText: statusText);
      },
    ).then((_) {
      // Dialog was dismissed externally (shouldn't happen, but handle it).
      _dialogShowing = false;
    });
  }

  void _updateOverlay(String statusText) {
    // The overlay uses BlocBuilder so it updates automatically.
    // No manual update needed since we pass the latest state via the builder.
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// The actual overlay content displayed inside the dialog.
class _OverlayContent extends StatelessWidget {
  final String statusText;

  const _OverlayContent({required this.statusText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<DataInitBloc, DataInitBlocState>(
      builder: (context, state) {
        final currentStatusText = state is DataInitInProgress
            ? dataInitStatusText(state.status, detail: state.detail)
            : state is DataInitSuccess
            ? 'Data siap!'
            : state is DataInitFailure
            ? 'Gagal memuat data'
            : 'Menyiapkan...';

        final isCompleted = state is DataInitSuccess;

        return Scaffold(
          backgroundColor: cs.surface,
          body: Center(
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
                    currentStatusText,
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
          ),
        );
      },
    );
  }
}
