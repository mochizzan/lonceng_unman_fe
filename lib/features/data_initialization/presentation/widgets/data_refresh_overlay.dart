import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_progress_view.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_bloc.dart';
import 'package:lonceng_unman_fe/features/home/presentation/bloc/home_event.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_bloc.dart';
import 'package:lonceng_unman_fe/features/jadwal/presentation/bloc/jadwal_event.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';

/// Full-screen blocking overlay for data refresh progress.
/// Shows [DataInitProgressView] over a semi-transparent barrier.
/// Auto-dismisses on completion or shows error snackbar on failure.
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

  /// Triggers data-init pipeline and shows overlay.
  /// Handles credential loading, state reset, and error display.
  /// Each page can dispatch its own refresh event after calling this.
  static Future<void> triggerRefresh(BuildContext context) async {
    debugPrint('[DATA_REFRESH] triggerRefresh() START');

    final academicCache = Services.get<AcademicCacheService>();
    final credentials = await academicCache.loadCredentials();
    if (credentials == null || !context.mounted) {
      debugPrint(
        '[DATA_REFRESH] No credentials found or context unmounted — abort',
      );
      return;
    }

    final npm = credentials['npm'] ?? '';
    final password = credentials['password'] ?? '';
    debugPrint('[DATA_REFRESH] Credentials loaded: npm=$npm');

    // Show progress overlay
    if (context.mounted) {
      debugPrint('[DATA_REFRESH] Showing overlay');
      show(context);
    }

    // Reset then trigger pipeline
    if (context.mounted) {
      debugPrint(
        '[DATA_REFRESH] Dispatching DataInitReset + DataInitStarted(forceRefresh: true)',
      );
      context.read<DataInitBloc>().add(const DataInitReset());
      context.read<DataInitBloc>().add(
        DataInitStarted(npm: npm, password: password, forceRefresh: true),
      );
    }

    debugPrint('[DATA_REFRESH] triggerRefresh() END');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<DataInitBloc, DataInitBlocState>(
      listener: (context, state) {
        // Only log on status changes, not every DataInitInProgress emission.
        final logState = state is DataInitInProgress
            ? state.status.name
            : state.runtimeType;
        debugPrint(
          '[DATA_REFRESH] State → $logState${state is DataInitInProgress ? ' (${state.detail ?? ''})' : ''}',
        );
        if (state is DataInitSuccess) {
          debugPrint('[DATA_REFRESH] Success — dismissing overlay in 500ms');
          // Trigger all BLoCs re-fetch after refresh
          try {
            context.read<JadwalBloc>().add(const JadwalFetchRequested());
            context.read<HomeBloc>().add(const HomeFetchRequested());
            context.read<ProfileBloc>().add(const ProfileFetchRequested());
            debugPrint(
              '[DATA_REFRESH] All BLoC refresh dispatched after refresh',
            );
          } catch (e) {
            debugPrint('[DATA_REFRESH] BLoC dispatch failed: $e');
          }
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        } else if (state is DataInitFailure) {
          debugPrint(
            '[DATA_REFRESH] Failure: ${state.message} — auto-dismiss in 3s',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(seconds: 3), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      child: Material(
        color: cs.surface,
        child: const DataInitProgressView(isFreshLogin: false),
      ),
    );
  }
}
