import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Bullseye heals to full - Reduce health first, throw Bullseye -> heals to healthMax', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Healer', config);
    await UITestHelpers.addPlayer(tester, 'Opponent', config);

    await UITestHelpers.startGame(tester, config);

    final healer = ProviderHelpers.findPlayerByName(tester, 'Healer')!;
    final opponent = ProviderHelpers.findPlayerByName(tester, 'Opponent')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final firstPlayerId = currentPlayerId;

    // Miss 3 darts, advance turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Opponent attacks first player to reduce health
    final firstPlayerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, firstPlayerId)!;
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
    await clickDartsRemoved(tester);

    // First player's turn again - health should be 11 (20 - 9)
    final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, firstPlayerId);
    expect(healthBefore, 11);

    // Throw bullseye to heal to full
    await throwBullseyeViaMock(tester);

    // Verify healed to max
    final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, firstPlayerId);
    expect(healthAfter, 20); // healed to healthMax
  });
}
