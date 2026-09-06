import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/khs_timeline_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('KhsTimelineView', () {
    testWidgets('renders empty map as SizedBox.shrink', (tester) async {
      await tester.pumpWidget(_wrap(const KhsTimelineView(items: {})));
      expect(find.byType(KhsTimelineView), findsOneWidget);
      // No semester rows.
      expect(find.textContaining('—'), findsNothing);
    });

    testWidgets('renders two semesters with correct labels', (tester) async {
      final a = KhsSemesterTimeline(
        tahunAjaran: '2022/2023',
        semester: 'Ganjil',
      );
      a.download = KhsSemesterSubStepStatus.success;
      a.extract = KhsSemesterSubStepStatus.success;
      a.fetch = KhsSemesterSubStepStatus.success;

      final b = KhsSemesterTimeline(
        tahunAjaran: '2022/2023',
        semester: 'Genap',
      );
      b.download = KhsSemesterSubStepStatus.progress;

      final map = <String, KhsSemesterTimeline>{
        '2022/2023|Ganjil': a,
        '2022/2023|Genap': b,
      };

      await tester.pumpWidget(_wrap(KhsTimelineView(items: map)));

      expect(find.text('2022/2023 — Ganjil'), findsOneWidget);
      expect(find.text('2022/2023 — Genap'), findsOneWidget);
      expect(find.text('DOWNLOAD'), findsAtLeastNWidgets(1));
      expect(find.text('EXTRACT'), findsAtLeastNWidgets(1));
      expect(find.text('GET'), findsAtLeastNWidgets(1));
    });

    testWidgets('light semester shows Dilewati for DOWNLOAD and EXTRACT', (
      tester,
    ) async {
      final light =
          KhsSemesterTimeline(tahunAjaran: '2023/2024', semester: 'Ganjil')
            ..download = KhsSemesterSubStepStatus.skipped
            ..extract = KhsSemesterSubStepStatus.skipped
            ..fetch = KhsSemesterSubStepStatus.progress;

      final map = <String, KhsSemesterTimeline>{'2023/2024|Ganjil': light};

      await tester.pumpWidget(_wrap(KhsTimelineView(items: map)));

      // DOWNLOAD and EXTRACT chips should show Dilewati, not DOWNLOAD/EXTRACT.
      expect(find.text('Dilewati'), findsNWidgets(2));
      expect(find.text('DOWNLOAD'), findsNothing);
      expect(find.text('EXTRACT'), findsNothing);
      expect(find.text('GET'), findsOneWidget);
      // Remove icon should appear for skipped chips.
      expect(find.byIcon(Icons.remove), findsNWidgets(2));
    });

    testWidgets('has Semantics label per semester', (tester) async {
      final tl =
          KhsSemesterTimeline(tahunAjaran: '2022/2023', semester: 'Ganjil')
            ..download = KhsSemesterSubStepStatus.success
            ..extract = KhsSemesterSubStepStatus.success
            ..fetch = KhsSemesterSubStepStatus.success;

      final map = <String, KhsSemesterTimeline>{'2022/2023|Ganjil': tl};

      await tester.pumpWidget(_wrap(KhsTimelineView(items: map)));

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'KHS 2022/2023 — Ganjil, success',
        ),
        findsOneWidget,
      );
    });

    testWidgets('progress chip pulses (FadeTransition present)', (
      tester,
    ) async {
      final tl = KhsSemesterTimeline(
        tahunAjaran: '2022/2023',
        semester: 'Genap',
      )..download = KhsSemesterSubStepStatus.progress;

      final map = <String, KhsSemesterTimeline>{'2022/2023|Genap': tl};

      await tester.pumpWidget(_wrap(KhsTimelineView(items: map)));

      // Progress chip is wrapped in FadeTransition via _PulsingChip.
      // Route transitions also use FadeTransition, so scope to the timeline.
      expect(
        find.descendant(
          of: find.byType(KhsTimelineView),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
    });
  });

  group('KhsSemesterTimeline model', () {
    test('overall is error if any sub-step is error', () {
      final tl =
          KhsSemesterTimeline(tahunAjaran: '2022/2023', semester: 'Ganjil')
            ..download = KhsSemesterSubStepStatus.success
            ..extract = KhsSemesterSubStepStatus.error
            ..fetch = KhsSemesterSubStepStatus.idle;
      expect(tl.overall, KhsSemesterSubStepStatus.error);
    });

    test('overall is progress if any sub-step is progress and no error', () {
      final tl =
          KhsSemesterTimeline(tahunAjaran: '2022/2023', semester: 'Genap')
            ..download = KhsSemesterSubStepStatus.success
            ..extract = KhsSemesterSubStepStatus.progress
            ..fetch = KhsSemesterSubStepStatus.idle;
      expect(tl.overall, KhsSemesterSubStepStatus.progress);
    });

    test('overall is success if any success and no error/progress', () {
      final tl =
          KhsSemesterTimeline(tahunAjaran: '2022/2023', semester: 'Ganjil')
            ..download = KhsSemesterSubStepStatus.success
            ..extract = KhsSemesterSubStepStatus.idle
            ..fetch = KhsSemesterSubStepStatus.idle;
      expect(tl.overall, KhsSemesterSubStepStatus.success);
    });

    test('isLight true only when download and extract are skipped', () {
      final tl =
          KhsSemesterTimeline(tahunAjaran: '2023/2024', semester: 'Ganjil')
            ..download = KhsSemesterSubStepStatus.skipped
            ..extract = KhsSemesterSubStepStatus.skipped
            ..fetch = KhsSemesterSubStepStatus.progress;
      expect(tl.isLight, isTrue);

      tl.download = KhsSemesterSubStepStatus.success;
      expect(tl.isLight, isFalse);
    });
  });
}
