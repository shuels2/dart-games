import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// maxStrokes=6: miss darts 1-4, hit target on dart 5 → strokes = 5.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: maxStrokes=6, hit target on dart 5 records strokes=5',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, maxStrokes: 6,
        playerNames: ['Alice', 'Bob']);

    final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;
    final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);

    // Miss darts 1–4
    for (int i = 0; i < 4; i++) {
      await throwMissViaMock(tester);
    }

    // Dart 5: hit target → turn ends
    await throwTargetDart(tester);

    // Strokes = 5
    final score =
        ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
    expect(score, 5,
        reason: 'Hit on dart 5 with maxStrokes=6 should record strokes=5');
  });
}
