import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 17: Start game with 3 Laps',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.selectClockworkQuestLaps(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Lap1', config);
    await UITestHelpers.addPlayer(tester, 'Lap2', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final p1 = players.firstWhere((p) => p.name == 'Lap1');
    final p2 = players.firstWhere((p) => p.name == 'Lap2');
    await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

    await UITestHelpers.startGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    expect(provider.currentGame!.numberOfLaps, 3);
  });
}
