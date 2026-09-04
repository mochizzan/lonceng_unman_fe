import 'dart:async';

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
/// On success, auto-dismisses in 500 ms.
/// On failure (pull-to-refresh), shows the error view for 3 seconds then
/// auto-closes — no SnackBar. Login flow uses [DataInitProgressView]
/// directly with `isFreshLogin: true` and is unaffected.
class DataRefreshOverlay extends StatefulWidget {
  const DataRefreshOverlay({
    super.key,
    this.npm,
    this.password,
    this.onPipelineSuccess,
  });

  /// Optional credentials captured by [show]. When provided, the overlay
  /// dispatches the data-init pipeline itself once mounted — this guarantees
  /// the [BlocListener] below is alive before any state is emitted, so a
  /// fast-failing pipeline can still close the overlay.
  final String? npm;
  final String? password;

  /// Optional callback invoked when the pipeline succeeds. Retained for
  /// source compatibility; the overlay already dispatches BLoC refetches
  /// internally on success.
  final VoidCallback? onPipelineSuccess;

  /// Shows the overlay as a full-screen, non-dismissible dialog.
  ///
  /// Returns a [Future] that completes when the overlay is dismissed
  /// (success or failure). Optional [npm]/[password] are forwarded to the
  /// dialog so it can drive the pipeline after mount.
  static Future<void> show(
    BuildContext context, {
    String? npm,
    String? password,
    VoidCallback? onPipelineSuccess,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Data Refresh',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return DataRefreshOverlay(
          npm: npm,
          password: password,
          onPipelineSuccess: onPipelineSuccess,
        );
      },
    );
  }

  /// Triggers data-init pipeline and shows overlay.
  ///
  /// Credentials are loaded up-front, then the overlay is awaited (so the
  /// [BlocListener] is guaranteed to be mounted) before the pipeline events
  /// are dispatched. This fixes a race where a fast-failing pipeline would
  /// emit [DataInitFailure] before the listener attached, leaving the
  /// overlay stuck on screen.
  static Future<void> triggerRefresh(
    BuildContext context, {
    VoidCallback? onPipelineSuccess,
  }) async {
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

    if (context.mounted) {
      debugPrint('[DATA_REFRESH] Showing overlay (awaiting mount)');
      // Await show so the dialog route is fully built and its BlocListener
      // is mounted before we dispatch any events. The overlay owns the
      // pipeline lifecycle from this point on.
      await show(
        context,
        npm: npm,
        password: password,
        onPipelineSuccess: onPipelineSuccess,
      );
    }

    debugPrint('[DATA_REFRESH] triggerRefresh() END');
  }

  @override
  State<DataRefreshOverlay> createState() => _DataRefreshOverlayState();
}

class _DataRefreshOverlayState extends State<DataRefreshOverlay> {
  /// Auto-close timer armed when [DataInitFailure] arrives. Cancelled in
  /// [dispose] and defensively in the success branch.
  Timer? _autoCloseTimer;

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _dispatchPipeline(BuildContext innerContext) {
    if (widget.npm == null || widget.password == null) return;
    debugPrint(
      '[DATA_REFRESH] Dispatching DataInitReset + DataInitStarted from overlay',
    );
    innerContext.read<DataInitBloc>().add(const DataInitReset());
    innerContext.read<DataInitBloc>().add(
      DataInitStarted(
        npm: widget.npm!,
        password: widget.password!,
        forceRefresh: true,
        isPullRefresh: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<DataInitBloc, DataInitBlocState>(
      listener: (listenerContext, state) {
        // Only log on status changes, not every DataInitInProgress emission.
        final logState = state is DataInitInProgress
            ? state.status.name
            : state.runtimeType;
        debugPrint(
          '[DATA_REFRESH] State → $logState${state is DataInitInProgress ? ' (${state.detail ?? ''})' : ''}',
        );
        if (state is DataInitSuccess) {
          // Defensive: cancel any pending auto-close in case a Success
          // arrives after a Failure (would not happen today, but safe).
          _autoCloseTimer?.cancel();
          debugPrint('[DATA_REFRESH] Success — dismissing overlay in 500ms');
          // Trigger all BLoCs re-fetch after refresh
          try {
            listenerContext.read<JadwalBloc>().add(
              const JadwalFetchRequested(),
            );
            listenerContext.read<HomeBloc>().add(const HomeFetchRequested());
            listenerContext.read<ProfileBloc>().add(
              const ProfileFetchRequested(),
            );
            debugPrint(
              '[DATA_REFRESH] All BLoC refresh dispatched after refresh',
            );
          } catch (e) {
            debugPrint('[DATA_REFRESH] BLoC dispatch failed: $e');
          }
          // Notify optional success listener before dismissing.
          widget.onPipelineSuccess?.call();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (listenerContext.mounted) {
              Navigator.of(listenerContext).pop();
            }
          });
        } else if (state is DataInitFailure) {
          // Pull-to-refresh failure path: show the error view for 3 seconds
          // then auto-close. The overlay IS the error feedback; no SnackBar.
          // Login flow is unaffected because LoginPage does not instantiate
          // this widget — it mounts DataInitProgressView(isFreshLogin: true)
          // directly and that view still shows Retry/Cancel buttons.
          debugPrint(
            '[DATA_REFRESH] Failure (pull-to-refresh): ${state.message} '
            'step=${state.failedStep} — auto-closing in 3s',
          );
          _autoCloseTimer?.cancel();
          _autoCloseTimer = Timer(const Duration(seconds: 3), () {
            if (!mounted) return;
            Navigator.of(context).pop();
          });
        }
      },
      child: Builder(
        builder: (innerContext) {
          // Kick off the pipeline from the first build of the overlay.
          // At this point BlocListener is already attached, so any state
          // emitted by the pipeline (including an instant DataInitFailure)
          // is guaranteed to be observed.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!innerContext.mounted) return;
            if (widget.npm == null || widget.password == null) return;
            _dispatchPipeline(innerContext);
          });

          return Material(
            color: cs.surface,
            child: DataInitProgressView(
              isFreshLogin: false,
              onRetry: null,
              onClose: null,
            ),
          );
        },
      ),
    );
  }
}
