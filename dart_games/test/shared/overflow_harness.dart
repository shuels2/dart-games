import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// WS05 §5.2b — catch RenderFlex overflows in widget tests, where they are
/// cheap, instead of letting "sizing/spacing wrong" reach a screenshot review.
///
/// A `RenderFlex overflowed by N pixels` is a `FlutterError`, so a widget test
/// can trap it. No chromedriver, no browser, ~1s per screen per size.
///
/// ─── SIZES ─────────────────────────────────────────────────────────────────
/// The app targets tablets and desktop browsers. 1366x768 is the common
/// laptop/kiosk shape, 1024x768 the small landscape tablet, and 800x1280 a
/// portrait tablet — the one that actually finds overflows, because every
/// screen here is designed landscape-first.
const kOverflowSweepSizes = <Size>[
  Size(1366, 768),
  Size(1024, 768),
  Size(800, 1280),
];

/// Call once in `main()` before any of these tests.
///
/// GoogleFonts otherwise tries to FETCH font files over the network mid-test.
/// With fetching disabled it falls back to the platform font, which is fine
/// here: this harness measures LAYOUT overflow, and a fallback font of roughly
/// the same metrics still exercises the flex arithmetic. It does mean a
/// glyph-width-driven overflow specific to the real font would be missed —
/// stated so nobody reads a green sweep as "no overflow in production".
void configureOverflowSweep() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Pumps [buildScreen] at each of [sizes] and fails on any overflow.
///
/// Overflow errors are collected rather than rethrown so ALL sizes report,
/// instead of the first failure hiding the rest.
Future<void> expectNoOverflowAcrossSizes(
  WidgetTester tester,
  Widget Function() buildScreen, {
  List<Size> sizes = kOverflowSweepSizes,
  Duration settle = const Duration(seconds: 1),
}) async {
  final failures = <String>[];

  for (final size in sizes) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final captured = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = captured.add;
    try {
      await tester.pumpWidget(buildScreen());
      // A fixed pump rather than pumpAndSettle: these screens run continuous
      // animations, so pumpAndSettle would never return. This is the same
      // hazard the UI suites document.
      await tester.pump(settle);
    } finally {
      FlutterError.onError = previous;
    }

    final overflows = captured
        .map((d) => d.exception.toString())
        .where((e) => e.contains('overflowed by'))
        .toSet();
    for (final o in overflows) {
      failures.add('${size.width.toInt()}x${size.height.toInt()}: '
          '${o.split('\n').first}');
    }

    // Anything else that blew up is worth surfacing too — a screen that
    // throws during layout is not passing an overflow sweep either.
    final others = captured
        .map((d) => d.exception.toString())
        .where((e) => !e.contains('overflowed by'))
        .toSet();
    for (final e in others) {
      failures.add('${size.width.toInt()}x${size.height.toInt()}: '
          'non-overflow error: ${e.split('\n').first}');
    }
  }

  expect(failures, isEmpty,
      reason: 'Layout problems found by the overflow sweep:\n'
          '${failures.join('\n')}');
}
