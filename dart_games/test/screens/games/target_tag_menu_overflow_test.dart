// WS05 §5.2b PROTOTYPE — deliberately SKIPPED. Read this before enabling it.
//
// The plan said to prototype the overflow sweep on one screen before
// committing to it, because pumping a full game screen in a widget test was
// unproven here. That was the right call: the prototype works mechanically and
// its output is NOT yet trustworthy.
//
// ─── WHAT WORKS ────────────────────────────────────────────────────────────
// The mechanism is sound. RenderFlex overflows are FlutterErrors, a widget
// test traps them, and a full menu screen pumps in ~1s per size with three
// providers wired up. No chromedriver. The harness is in
// test/shared/overflow_harness.dart and is ready to use.
//
// ─── WHY IT IS SKIPPED ─────────────────────────────────────────────────────
// It reports overflows on a screen that is demonstrably FINE in production.
// At 1920x1080 — the exact viewport the UI suites drive and where the
// screenshot reviews show correct layout — this test reports
// "A RenderFlex overflowed by 97 pixels on the right."
//
// So the finding is almost certainly an artifact of the test environment, and
// two candidates are in play. I have not isolated which, and it would be wrong
// to assert one:
//
//   1. FONT METRICS. GoogleFonts cannot fetch in tests, so every text style
//      silently falls back to the platform font. Different glyph widths change
//      how much horizontal space a Row's children demand, which is exactly
//      what produces a phantom right-overflow. This is the leading candidate.
//
//   2. PROVIDER STATE. The sweep also records `ApiException(400)` from the
//      player load against MockApiServer, so the screen may be laying out an
//      error/empty state rather than the populated one the screenshots show.
//
// ─── WHY NOT JUST BASELINE THE FAILURES ────────────────────────────────────
// Because a suite of ten screens each reporting overflows that are not real
// teaches everyone to ignore it, and then it catches nothing when a genuine
// one appears. An overflow sweep is only worth having if a red result means
// something. Shipping it red would be worse than not shipping it.
//
// ─── TO ENABLE ─────────────────────────────────────────────────────────────
//   1. Bundle the real font files as test assets so GoogleFonts resolves them
//      locally with allowRuntimeFetching: false, and confirm this screen then
//      reports clean at 1920x1080.
//   2. Seed MockApiServer so the player load succeeds and the screen lays out
//      its populated state.
//   3. Only once a KNOWN-GOOD screen reports clean should the sweep be rolled
//      out — and it should first be validated against a screen with a KNOWN
//      overflow, so a green result is proven to mean something too.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/screens/games/target_tag/target_tag_menu_screen.dart';

import '../../shared/mock_api_helpers.dart';
import '../../shared/overflow_harness.dart';

void main() {
  configureOverflowSweep();

  late MockApiServer server;

  setUp(() {
    server = MockApiServer();
  });

  Widget build() => MultiProvider(
        providers: [
          ChangeNotifierProvider<DartboardProvider>(
              create: (_) => DartboardProvider()),
          ChangeNotifierProvider<PlayerProvider>(
              create: (_) => PlayerProvider()..initialize(server.apiClient)),
          ChangeNotifierProvider<TargetTagProvider>(
              create: (_) => TargetTagProvider()),
        ],
        child: const MaterialApp(home: TargetTagMenuScreen()),
      );

  testWidgets('Target Tag menu does not overflow at any target size',
      (tester) async {
    await expectNoOverflowAcrossSizes(tester, build);
    // SKIPPED: reports phantom overflows on a screen that is correct in
    // production. Read the file header before flipping this to false — a
    // green result has to be proven meaningful first.
  }, skip: true);
}
