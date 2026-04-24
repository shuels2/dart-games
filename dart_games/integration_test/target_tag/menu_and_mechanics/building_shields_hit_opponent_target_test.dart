import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 6: Building Shields - Hit Opponent Target (Not Tagged In) - Validates player not tagged in initially, hitting opponent target while building shields does not add shields to attacking player (game logic verified). Note: Does NOT validate visual dart border colors (pink 0xFFFF007A mentioned in original description) - only game logic tested',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Shield1', config);
    await UITestHelpers.addPlayer(tester, 'Shield2', config);
    await UITestHelpers.startGame(tester, config);

    // Get current player and verify not tagged in
    final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayerId, isNotNull);
    final isTaggedIn = ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentPlayerId!);
    expect(isTaggedIn, isFalse);

    // Get opponent player
    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    final opponentPlayer = selectedPlayers.firstWhere((p) => p.id != currentPlayerId);
    final opponentTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, opponentPlayer.id);
    expect(opponentTarget, isNotNull);

    // Hit opponent target (should be invalid - pink)
    final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
    await throwDartViaMock(tester, opponentTarget!);

    // Shields should NOT increase
    final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
    expect(shieldsAfter, equals(shieldsBefore));
  });
}
