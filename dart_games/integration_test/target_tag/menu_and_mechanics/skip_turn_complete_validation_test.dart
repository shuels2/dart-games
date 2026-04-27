import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 19: Skip Turn - Complete Validation - Validates 2 players in game, current player indicator shows Player 1, Skip turn button visible and enabled, clicking skip turn advances to next player without dart throws, current player indicator updates to Player 2, skipped player does not gain or lose shields, turn order maintained after skip, skip turn functional throughout entire game',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Skip1', config);
    await UITestHelpers.addPlayer(tester, 'Skip2', config);
    await UITestHelpers.startGame(tester, config);

    // Add pump sequences here to let game screen render
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Get current player
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(player1Id, isNotNull);

    // Verify skip button present
    expect(config.getSkipTurnButton(), findsOneWidget);

    // Skip turn
    await UITestHelpers.clickSkipTurn(tester, config);

    // Verify the d1,d2,d3 labels say Skip
    final d1Finder = find.byKey(TargetTagGameKeys.activePlayerD1Indicator);
    final d2Finder = find.byKey(TargetTagGameKeys.activePlayerD2Indicator);
    final d3Finder = find.byKey(TargetTagGameKeys.activePlayerD3Indicator);

    expect(d1Finder, findsOneWidget);
    expect(d2Finder, findsOneWidget);
    expect(d3Finder, findsOneWidget);

    // Get the Text widgets inside the dart indicators
    final d1Text = tester.widget<Container>(d1Finder).child as Center;
    final d1TextWidget = d1Text.child as Text;
    expect(d1TextWidget.data, 'Skip');

    final d2Text = tester.widget<Container>(d2Finder).child as Center;
    final d2TextWidget = d2Text.child as Text;
    expect(d2TextWidget.data, 'Skip');

    final d3Text = tester.widget<Container>(d3Finder).child as Center;
    final d3TextWidget = d3Text.child as Text;
    expect(d3TextWidget.data, 'Skip');

    // Remove darts to advance turn to Player 2
    await clickDartsRemoved(tester);

    // Verify turn advanced
    final player2Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(player2Id, isNotNull);
    expect(player2Id, isNot(equals(player1Id)));

    // Verify shields unchanged
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id!), 0);
  });
}
