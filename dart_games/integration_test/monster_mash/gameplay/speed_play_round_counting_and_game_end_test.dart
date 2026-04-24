import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 15: Speed play - round counting and game end - Round limit=2, play through -> game ends automatically', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set high health and speed play with 2 round limit
    await SettingsHelpers.setMonsterMashHealthMax(tester, 50);
    await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    await SettingsHelpers.setMonsterMashRoundLimit(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Verify round 1
    expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 1);

    // Play through round 1 (both players throw 3 darts each)
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Should be round 2 now
    expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 2);

    // Play through round 2
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Round 3
    expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 3);

    // Play through round 3
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Game should end after round limit reached
    expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);
  });
}
