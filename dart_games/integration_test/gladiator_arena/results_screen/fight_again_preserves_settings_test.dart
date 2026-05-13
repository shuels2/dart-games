import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: Fight Again preserves settings and starts new game',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      shieldRoundEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    await completeGameToVictory(tester);

    // Tap Fight Again
    final playAgainButton =
        ElementFinders.getGladiatorArenaPlayAgainButton();
    await tester.ensureVisible(playAgainButton);
    await tester.tap(playAgainButton);
    await PumpSequences.navigation(tester);

    // Should be on game screen again
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);

    // Settings should be preserved
    expect(ProviderHelpers.getGladiatorArenaTargetScore(tester), 100);
    expect(
        ProviderHelpers.isGladiatorArenaDoubleFinishEnabled(tester), isFalse);
  });
}
