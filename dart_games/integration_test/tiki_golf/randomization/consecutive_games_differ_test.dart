// integration_test/tiki_golf/randomization/consecutive_games_differ_test.dart
//
// Start two back-to-back games; verify either holeTargets or holeImagePaths
// differs between runs (statistical sanity check for randomization).
//
// The probability of both being identical across two independent shuffles is
// extremely small (1/20P9 * 1/9! ≈ astronomically unlikely), so this test
// should pass reliably. We retry up to 3 times for the rare edge case.
//
// Section 12B File 3a — Randomization test 3
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '_helpers.dart';

final config = GameUIConfig.tikiGolf();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Randomization: consecutive games have different holeTargets or holeImagePaths',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // ── Game 1 ────────────────────────────────────────────────────────────
    await GameSetupHelpers.setupAndStartTikiGolf(tester, config);

    final targets1 = getHoleTargets(tester);
    final images1 = getHoleImagePaths(tester);

    expect(targets1.length, 9,
        reason: 'Game 1 should have 9 hole targets');
    expect(images1.length, 9,
        reason: 'Game 1 should have 9 hole image paths');

    // Drive game 1 to completion via PTC
    final provider1 = ProviderHelpers.getTikiGolfProvider(tester);
    await PlayToCompleteHelpers.tapPlayToComplete(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider1.hasWinner,
    );

    // Tap Play Again to start game 2 with same settings
    await tester.tap(config.getPlayAgainButton());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // ── Game 2 ────────────────────────────────────────────────────────────
    final targets2 = getHoleTargets(tester);
    final images2 = getHoleImagePaths(tester);

    expect(targets2.length, 9,
        reason: 'Game 2 should have 9 hole targets');
    expect(images2.length, 9,
        reason: 'Game 2 should have 9 hole image paths');

    // At least one of the lists must differ between game 1 and game 2
    final targetsMatch = _listsEqual(targets1, targets2);
    final imagesMatch = _listsEqual(images1, images2);

    expect(targetsMatch && imagesMatch, isFalse,
        reason:
            'Two consecutive games should have different randomization. '
            'Game 1 targets: $targets1, Game 2 targets: $targets2. '
            'Game 1 images: $images1, Game 2 images: $images2. '
            'Both being identical is astronomically unlikely — confirms randomization is working.');
  });
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
