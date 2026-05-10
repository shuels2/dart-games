import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: skip turn with no darts scores 0 and auto-advances',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Skip turn without throwing any darts
    final skipButton = ElementFinders.getGladiatorArenaSkipTurnButton();
    await tester.tap(skipButton);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    // Score should remain 0
    final score =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id);
    expect(score, 0, reason: 'Score should remain 0 after skip with no darts');

    // Turn should have advanced (no RemoveDartsModal needed)
    final nextId =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;
    expect(nextId, isNot(equals(p1Id)),
        reason: 'Turn should advance after skip with no darts');
  });
}
