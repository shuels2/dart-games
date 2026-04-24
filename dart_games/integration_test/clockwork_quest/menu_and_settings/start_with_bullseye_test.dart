import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 15: Start game with Bullseye enabled',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);

    await UITestHelpers.addPlayer(tester, 'Bull1', config);
    await UITestHelpers.addPlayer(tester, 'Bull2', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final p1 = players.firstWhere((p) => p.name == 'Bull1');
    final p2 = players.firstWhere((p) => p.name == 'Bull2');
    await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

    await UITestHelpers.startGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    expect(provider.currentGame!.includeBullseye, isTrue);
    expect(provider.currentGame!.maxTarget, 21);
  });
}
