import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Birdie: hitting the target on dart 1 ends the turn with strokes = 1.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: hitting target on dart 1 records strokes=1 (Birdie)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, maxStrokes: 3,
        playerNames: ['Alice', 'Bob']);

    final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;
    final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);

    // Dart 1 hits the target → turn ends immediately (Birdie)
    await throwTargetDart(tester);

    // Strokes = 1
    final score =
        ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole);
    expect(score, 1,
        reason: 'Hitting target on dart 1 should record strokes=1 (Birdie)');
  });
}
