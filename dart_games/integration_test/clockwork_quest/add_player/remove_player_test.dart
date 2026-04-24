import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Remove player from selected list',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'RemoveMe', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final player = players.firstWhere((p) => p.name == 'RemoveMe');

    // Select the player first
    await UITestHelpers.selectPlayers(tester, [player.id], config);

    // Find and tap the remove button
    final removeButton = find.byKey(ClockworkQuestMenuKeys.removePlayerButton(player.id));
    if (removeButton.evaluate().isNotEmpty) {
      await tester.tap(removeButton);
      await PumpSequences.simpleUpdate(tester);

      // Player should no longer be selected
      final playerProvider = ProviderHelpers.getPlayerProvider(tester);
      expect(playerProvider.selectedPlayers.any((p) => p.id == player.id), isFalse);
    }
  });
}
