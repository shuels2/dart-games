import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Tie display (speed play) - health=50, speed play ON, limit=3, all misses -> tied result', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 50);
    await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    await SettingsHelpers.setMonsterMashRoundLimit(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Play 3 rounds - all misses for both players (tied health)
    for (int round = 0; round < 3; round++) {
      // Player 1: miss
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player 2: miss
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
    }

    // Game should be over
    expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

    // Wait for results screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Verify tie display - should show "TIED!" text
    expect(find.textContaining('TIED'), findsWidgets);
  });
}
