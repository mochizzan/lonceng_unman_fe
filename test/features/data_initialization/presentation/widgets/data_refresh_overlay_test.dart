// Verifies the failure-path lifecycle of DataRefreshOverlay:
//   1. Pull-to-refresh failure auto-closes the overlay after 3 seconds.
//   2. Login-flow failure does NOT auto-close (no timer arms).
//   3. Success still auto-closes within ~500 ms (existing behavior preserved).
//
// The widget is pumped directly (not through show() / triggerRefresh() which
// wrap showGeneralDialog) to keep the test synchronous and free of credentials.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/repositories/data_initialization_repository.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_progress_view.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_refresh_overlay.dart';

/// Minimal no-op repository — never invoked because the test never
/// dispatches `DataInitStarted`. Required to satisfy `DataInitBloc`'s
/// constructor signature.
class _NoOpRepo implements DataInitializationRepository {
  @override
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
  }) {
    return const Stream<DataInitProgress>.empty();
  }
}

class _FakeDataInitBloc extends DataInitBloc {
  _FakeDataInitBloc() : super(GetDataInitialization(_NoOpRepo()));

  /// Emit an arbitrary state for the test to drive the overlay's listener.
  void emitNow(DataInitBlocState state) => emit(state);
}

Future<_FakeDataInitBloc> _pumpOverlay(
  WidgetTester tester, {
  required DataInitBlocState initial,
}) async {
  final bloc = _FakeDataInitBloc();
  addTearDown(bloc.close);

  // Establish the test's intended initial state before any widget builds so
  // the BlocListener observes it on the first frame.
  bloc.emitNow(initial);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<DataInitBloc>.value(
        value: bloc,
        child: const DataRefreshOverlay(),
      ),
    ),
  );
  return bloc;
}

void main() {
  testWidgets('pull-to-refresh failure auto-closes overlay after 3 seconds', (
    tester,
  ) async {
    // 1. Mount the overlay. State starts as in-progress (spinner visible).
    final bloc = await _pumpOverlay(
      tester,
      initial: const DataInitInProgress(DataInitStatus.downloadingKrs),
    );
    expect(find.byType(DataInitProgressView), findsOneWidget);

    // 2. Pipeline fails.
    bloc.emitNow(
      const DataInitFailure(
        'Server sedang tidak tersedia',
        failedStep: 'downloadingKrs',
      ),
    );
    await tester.pump();

    // 3. Error view is rendered.
    expect(
      find.text('Server sedang tidak tersedia'),
      findsOneWidget,
      reason: 'Error message from DataInitFailure should be shown.',
    );

    // 4. After 2 seconds the overlay is still visible.
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(DataInitProgressView), findsOneWidget);

    // 5. After 3 seconds total, the overlay has been popped.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.byType(DataInitProgressView),
      findsNothing,
      reason: 'Overlay should auto-close 3 seconds after DataInitFailure.',
    );
  });

  testWidgets(
    'login failure (isFreshLogin: true) does NOT auto-close the view',
    (tester) async {
      // Mount DataInitProgressView directly in login mode (the actual login
      // path uses this widget, not DataRefreshOverlay).
      final bloc = _FakeDataInitBloc();
      bloc.emitNow(const DataInitInProgress(DataInitStatus.scrapingProfile));
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DataInitBloc>.value(
            value: bloc,
            child: DataInitProgressView(
              isFreshLogin: true,
              onRetry: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Pipeline fails.
      bloc.emitNow(
        const DataInitFailure('Gagal memuat profil', failedStep: 'profile'),
      );
      await tester.pump();

      // Error view is rendered. Only the Retry button is built — login_page
      // wires onCancel (not onClose), so the Tutup button is intentionally
      // absent in the real flow.
      expect(find.text('Gagal memuat profil'), findsOneWidget);
      expect(
        find.text('Coba Lagi'),
        findsOneWidget,
        reason: 'Login flow keeps the Retry button.',
      );

      // After 5 seconds the view is still on screen — no auto-close in
      // login mode. This is the behavior the spec requires to stay
      // byte-for-byte unchanged.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(
        find.byType(DataInitProgressView),
        findsOneWidget,
        reason: 'Login failure must not auto-close.',
      );
    },
  );

  testWidgets('success auto-closes the overlay within ~500 ms', (tester) async {
    final bloc = await _pumpOverlay(
      tester,
      initial: const DataInitInProgress(DataInitStatus.downloadingKrs),
    );

    // Pipeline succeeds.
    bloc.emitNow(const DataInitSuccess());
    await tester.pump();

    // After 1 second (well past the 500 ms delay) the overlay is gone.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.byType(DataInitProgressView),
      findsNothing,
      reason: 'Success path must still auto-dismiss within 500 ms.',
    );
  });
}
