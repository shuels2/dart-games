import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 14: Start game with default settings',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Cog1', config);
    await UITestHelpers.addPlayer(tester, 'Cog2', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final p1 = players.firstWhere((p) => p.name == 'Cog1');
    final p2 = players.firstWhere((p) => p.name == 'Cog2');
    await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

    await UITestHelpers.startGame(tester, config);

    // Should navigate to game screen with game active
    expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);

    // Verify default settings were applied
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    expect(provider.currentGame!.includeBullseye, isFalse);
    expect(provider.currentGame!.speedMode, isFalse);
    expect(provider.currentGame!.numberOfLaps, 1);
  });
}
