import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/widgets/scroll_hide_controller.dart';

void main() {
  group('ScrollHideConfig', () {
    test('defaults have expected values', () {
      const cfg = ScrollHideConfig.defaults;
      expect(cfg.duration, const Duration(milliseconds: 250));
      expect(cfg.curve, Curves.easeOut);
      expect(cfg.ignorePointerThreshold, 0.5);
    });

    test('custom values are preserved', () {
      const cfg = ScrollHideConfig(
        duration: Duration(milliseconds: 400),
        curve: Curves.linear,
        ignorePointerThreshold: 0.3,
      );
      expect(cfg.duration, const Duration(milliseconds: 400));
      expect(cfg.curve, Curves.linear);
      expect(cfg.ignorePointerThreshold, 0.3);
    });
  });

  group('ScrollHideController', () {
    testWidgets('starts at value 0 (visible)', (tester) async {
      await _withController(tester, (ctrl, _) {
        expect(ctrl.value, 0.0);
      });
    });

    testWidgets('isIgnored is false at start', (tester) async {
      await _withController(tester, (ctrl, _) {
        expect(ctrl.isIgnored, isFalse);
      });
    });

    testWidgets('show() resets to 0', (tester) async {
      await _withController(tester, (ctrl, _) {
        ctrl.show();
        expect(ctrl.value, 0.0);
      });
    });

    testWidgets('animation is not null', (tester) async {
      await _withController(tester, (ctrl, _) {
        expect(ctrl.animation, isNotNull);
      });
    });

    testWidgets('handleScroll returns false (never consumes)', (tester) async {
      await _withController(tester, (ctrl, ctx) {
        final consumed = ctrl.handleScroll(_scrollEnd(ctx: ctx));
        expect(consumed, isFalse);
      });
    });
  });

  group(
    'ScrollHideController — animation forward/reverse via handleScroll',
    () {
      testWidgets('scroll down hides navbar (value increases)', (tester) async {
        await _withController(tester, (ctrl, ctx) async {
          expect(ctrl.value, 0.0);

          // Simulate scroll-down: pixel delta > 0 with dragDetails present.
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 10.0, deltaY: -10.0),
          );
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 30.0, deltaY: -10.0),
          );

          // Pump enough frames for the 250ms animation to complete.
          await tester.pumpAndSettle();

          expect(ctrl.value, greaterThan(0.0));
        });
      });

      testWidgets('scroll up shows navbar (value decreases back)', (
        tester,
      ) async {
        await _withController(tester, (ctrl, ctx) async {
          // Scroll down first.
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 10.0, deltaY: -10.0),
          );
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 50.0, deltaY: -10.0),
          );
          await tester.pumpAndSettle();
          final midValue = ctrl.value;
          expect(midValue, greaterThan(0.0));

          // Scroll up (delta < 0).
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 30.0, deltaY: 10.0),
          );
          await tester.pumpAndSettle();
          expect(ctrl.value, lessThan(midValue));
        });
      });

      testWidgets('show() resets navbar to visible', (tester) async {
        await _withController(tester, (ctrl, ctx) async {
          // Scroll down.
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 10.0, deltaY: -10.0),
          );
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 50.0, deltaY: -10.0),
          );
          await tester.pumpAndSettle();
          expect(ctrl.value, greaterThan(0.0));

          // Tab switch calls show().
          ctrl.show();
          await tester.pumpAndSettle();
          expect(ctrl.value, 0.0);
        });
      });

      testWidgets('custom config is applied', (tester) async {
        await _withController(
          tester,
          (ctrl, ctx) async {
            ctrl.handleScroll(
              _scrollUpdate(ctx: ctx, pixels: 10.0, deltaY: -10.0),
            );
            // After 250ms of a 500ms animation, value should be about halfway.
            // Pump exactly 250ms.
            for (int i = 0; i < 9; i++) {
              await tester.pump(const Duration(milliseconds: 30));
            }
            expect(ctrl.value, greaterThan(0.0));
            expect(ctrl.value, lessThan(1.0));
          },
          config: const ScrollHideConfig(duration: Duration(milliseconds: 500)),
        );
      });

      testWidgets('ignore pointer threshold is respected', (tester) async {
        await _withController(tester, (ctrl, ctx) async {
          expect(ctrl.isIgnored, isFalse);

          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 10.0, deltaY: -10.0),
          );
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 30.0, deltaY: -10.0),
          );
          // Let animation complete.
          await tester.pumpAndSettle();

          // With threshold 0.3, value should exceed it.
          expect(ctrl.value, greaterThan(0.3));
          expect(ctrl.isIgnored, isTrue);
        }, config: const ScrollHideConfig(ignorePointerThreshold: 0.3));
      });

      testWidgets('scroll end notification updates lastPixels', (tester) async {
        await _withController(tester, (ctrl, ctx) async {
          ctrl.handleScroll(
            _scrollUpdate(ctx: ctx, pixels: 50.0, deltaY: -10.0),
          );
          ctrl.handleScroll(_scrollEnd(ctx: ctx, pixels: 50.0));
          await tester.pumpAndSettle();
          expect(ctrl.value, greaterThan(0.0));
        });
      });

      testWidgets('non-drag scroll updates are ignored', (tester) async {
        await _withController(tester, (ctrl, ctx) async {
          ctrl.handleScroll(_scrollUpdateNoDrag(ctx: ctx, pixels: 100.0));
          await tester.pumpAndSettle();
          expect(ctrl.value, 0.0);
        });
      });
    },
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a controller inside a test shell and calls [body].
/// [body] receives the controller and a [BuildContext] for notification params.
Future<void> _withController(
  WidgetTester tester,
  FutureOr<void> Function(ScrollHideController c, BuildContext ctx) body, {
  ScrollHideConfig? config,
}) async {
  final key = GlobalKey();
  late ScrollHideController ctrl;
  await tester.pumpWidget(
    MaterialApp(
      home: _TickerHost(
        key: key,
        config: config,
        onCreated: (c) => ctrl = c,
        child: const SizedBox.expand(),
      ),
    ),
  );
  final ctx = key.currentContext!;
  await body(ctrl, ctx);
}

/// Minimal host that creates a [ScrollHideController] using its own
/// [TickerProvider].
class _TickerHost extends StatefulWidget {
  const _TickerHost({
    super.key,
    required this.child,
    required this.onCreated,
    this.config,
  });

  final Widget child;
  final void Function(ScrollHideController c) onCreated;
  final ScrollHideConfig? config;

  @override
  State<_TickerHost> createState() => _TickerHostState();
}

class _TickerHostState extends State<_TickerHost>
    with SingleTickerProviderStateMixin {
  late final ScrollHideController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollHideController(
      vsync: this,
      config: widget.config ?? ScrollHideConfig.defaults,
    );
    // ignore: avoid_dynamic_calls
    widget.onCreated(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Creates a [FixedScrollMetrics] snapshot for test notifications.
FixedScrollMetrics _metrics({required double pixels}) {
  return FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: 500,
    pixels: pixels,
    viewportDimension: 800,
    axisDirection: AxisDirection.down,
    devicePixelRatio: 1.0,
  );
}

/// Creates a [ScrollUpdateNotification] with [dragDetails] present
/// (user-initiated drag).
ScrollUpdateNotification _scrollUpdate({
  required BuildContext ctx,
  required double pixels,
  required double deltaY,
}) {
  return ScrollUpdateNotification(
    metrics: _metrics(pixels: pixels),
    context: ctx,
    dragDetails: DragUpdateDetails(
      globalPosition: Offset(0, pixels),
      delta: Offset(0, deltaY),
      primaryDelta: deltaY,
    ),
  );
}

/// Creates a [ScrollUpdateNotification] WITHOUT dragDetails (programmatic).
ScrollUpdateNotification _scrollUpdateNoDrag({
  required BuildContext ctx,
  required double pixels,
}) {
  return ScrollUpdateNotification(
    metrics: _metrics(pixels: pixels),
    context: ctx,
  );
}

/// Creates a [ScrollEndNotification] at [pixels].
ScrollEndNotification _scrollEnd({
  required BuildContext ctx,
  double pixels = 0,
}) {
  return ScrollEndNotification(
    metrics: _metrics(pixels: pixels),
    context: ctx,
  );
}
