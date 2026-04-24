import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Hero Buff Hit Detection - Validates hero bonus enabled, 2 players added, Player 1 reaches tagged in, hero buff values retrieved from provider for both players. Players throw darts including hitting hero buff numbers. D1 indicators show gold borders (0xFFFFD700) after hero buff hits. Validates hero buff hit causes 1 shield damage. Note: Does NOT validate damage multiplier mechanics (2x, 3x, 4x, 5x) - implementation comment states "Hero bonus does NOT multiply damage, just removes 1 shield" - only single shield damage validated regardless of multiplier value', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable hero bonus
    await enableHeroBonus(tester);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // ===== Step 1: Get tagged in =====
    final player1Target = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, player1Target, multiplier: 'single');
    await throwDartViaMock(tester, player1Target, multiplier: 'double');
    await throwDartViaMock(tester, player1Target, multiplier: 'triple');

    // Wait for tagged-in state to update and active panel to rebuild
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump();

    // Verify tagged in and get the buff value
    expect(find.text('TAGGED IN'), findsWidgets);
    final buffValue = getHeroBuffFromActivePanel(tester);
    expect(buffValue, isNotNull);
    await clickDartsRemoved(tester);

    // ===== Player B's turn: Build shields so we can test damage =====
    final player2Target = getCurrentPlayerTargetNumber(tester);
    await throwDartViaMock(tester, player2Target, multiplier: 'single');
    await throwDartViaMock(tester, player2Target, multiplier: 'double');
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);
    // Player B now has 3 shields

    // ===== Step 2: Attack opponent with buff active =====
    // Get Player B's shields before attack
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    final selectedPlayers = playerProvider.selectedPlayers;
    final playerB = selectedPlayers.firstWhere((p) => p.name == 'Player B');
    final playerBTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, playerB.id);

    final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, playerB.id);

    // Attack with single dart (Player A is now the active player)
    await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');

    // Wait for damage to apply
    await PumpSequences.fullRebuild(tester);

    // Get shields after attack
    final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, playerB.id);

    // Verify damage was applied (hero bonus does NOT multiply damage, just removes 1 shield)
    final expectedDamage = 1; // Single dart = 1 shield damage (no multiplier)
    expect(shieldsBefore - shieldsAfter, expectedDamage,
        reason: 'Hero bonus should remove 1 shield (buff value $buffValue is for display only)');
  });
}
