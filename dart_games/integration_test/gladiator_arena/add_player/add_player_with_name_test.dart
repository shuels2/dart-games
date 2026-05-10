import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player: add player with name appears in list',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Gladiator1', config);

    // Player should be in provider
    final player = ProviderHelpers.findPlayerByName(tester, 'Gladiator1');
    expect(player, isNotNull);

    // Start button still disabled with only 1 player
    expect(ElementFinders.getGladiatorArenaStartButton(), findsOneWidget);
  });
}
