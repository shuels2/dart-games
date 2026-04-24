import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 11: Caused Elimination (GOLD) - Validates Player 1 tagged in with max shields, Player 2 has partial shields, Player 1 attacks Player 2 repeatedly, final dart that reduces opponent to 0 shields shows gold border (0xFFFFD700), opponent eliminated and receives TAGGED OUT badge, elimination dart correctly highlighted as successful attack',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Eliminator', config);
    await UITestHelpers.addPlayer(tester, 'Victim', config);
    await UITestHelpers.startGame(tester, config);

    // Player 1 reaches tagged in
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

    await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

    // Throw 2 more darts to end the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to Player 2
    await clickDartsRemoved(tester);

    // Player 2 builds 1 shield
    final player2 = ProviderHelpers.getSelectedPlayers(tester).firstWhere((p) => p.id != player1Id);
    final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

    await throwDartViaMock(tester, player2Target!);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 1);

    // Remove darts to advance turn to Player 1
    await clickDartsRemoved(tester);

    // Player 1 eliminates Player 2 by taking shields to 0 and then elimination
    await throwDartViaMock(tester, player2Target);
    await throwDartViaMock(tester, player2Target);

    // Verify elimination
    final isEliminated = ProviderHelpers.isTargetTagPlayerEliminated(tester, player2.id);
    expect(isEliminated, isTrue);

    // Verify TAGGED OUT badge
    expect(find.text('TAGGED OUT'), findsAtLeastNWidgets(1));

    // Verify D1 indicator has gold border (0xFFFFD700) for elimination dart
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD2Indicator, 0xFFFFD700);
  });
}
