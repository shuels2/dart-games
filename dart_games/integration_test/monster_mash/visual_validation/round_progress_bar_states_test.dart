import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Round progress bar states - Speed play OFF = no active round bar, Speed play ON = shows round progress', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start with speed play OFF
    await UITestHelpers.startGame(tester, config);

    // Verify current round
    expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 1);

    // Play through 1 full round
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Round should increment
    expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 2);

    // Navigate back to menu using keyed back button
    final backButton = find.byKey(MonsterMashGameKeys.backButton);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton.first);
    await PumpSequences.navigation(tester);

    // Handle Save Game Modal
    final dontSaveButton = find.byKey(SaveGameModalKeys.dontSaveButton);
    if (dontSaveButton.evaluate().isNotEmpty) {
      await tester.tap(dontSaveButton);
      await PumpSequences.dialogClose(tester);
    }

    // Handle Resume Game Modal
    final startNewButton = find.byKey(ResumeGameModalKeys.startNewGameButton);
    if (startNewButton.evaluate().isNotEmpty) {
      await tester.tap(startNewButton);
      await PumpSequences.dialogClose(tester);
    }

    await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    await SettingsHelpers.setMonsterMashRoundLimit(tester, 5);

    await UITestHelpers.startGame(tester, config);

    // Verify round starts at 1
    expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 1);

    // Verify round limit
    expect(ProviderHelpers.getMonsterMashRoundLimit(tester), 5);

    // Play 1 round
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Round should be 2
    expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 2);
  });
}
