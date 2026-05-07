import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dart_games/constants/test_keys.dart';

/// Test diagnostics — emit a one-line snapshot of which screen / modal is
/// currently visible. Output goes to the per-test parallel-runner log so we
/// can pinpoint where a navigation got stuck without re-running with extra
/// instrumentation.
///
/// Call right before a `findsOneWidget` assertion that's failing
/// mysteriously. The `label` is included in the print so multiple calls in
/// one test are distinguishable in the log.
class TestDiagnostics {
  /// Print a one-line widget-tree snapshot. Counts of each marker key tell
  /// us which screen is currently mounted at the top of the navigator stack
  /// (e.g. `menuStart=1` ⇒ menu is on top).
  static void dumpRoute(WidgetTester tester, String label) {
    int count(Finder f) => f.evaluate().length;

    final scaffolds = count(find.byType(Scaffold));
    final dialogs = count(find.byType(Dialog));
    final menuStart =
        count(find.byKey(PiratesGridMenuKeys.startGameButton));
    final menuBack = count(find.byKey(PiratesGridMenuKeys.backButton));
    final gameSkip =
        count(find.byKey(PiratesGridGameKeys.skipTurnButton));
    final gameBack = count(find.byKey(PiratesGridGameKeys.backButton));
    final resultsPlayAgain =
        count(find.byKey(PiratesGridResultsKeys.playAgainButton));
    final resultsBackToMenu =
        count(find.byKey(PiratesGridResultsKeys.backToMenuButton));
    final homeCarnival = count(find.byKey(HomeKeys.carnivalDerbyCard));
    final saveModal = count(find.byKey(SaveGameModalKeys.container));
    final resumeModal = count(find.byKey(ResumeGameModalKeys.overlay));

    // ignore: avoid_print
    print('[DIAG $label] '
        'scaffolds=$scaffolds dialogs=$dialogs '
        'menuStart=$menuStart menuBack=$menuBack '
        'gameSkip=$gameSkip gameBack=$gameBack '
        'resultsPlayAgain=$resultsPlayAgain resultsBackToMenu=$resultsBackToMenu '
        'homeCarnival=$homeCarnival '
        'saveModal=$saveModal resumeModal=$resumeModal');
  }
}
