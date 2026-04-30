import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/models/reef_royale_game.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 9: Game mode dropdown changes to Cursed Tide',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Select Cursed Tide from dropdown
    await SettingsHelpers.setReefRoyaleGameMode(tester, 'Cursed Tide');

    // Add players and start to verify the mode was applied
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    expect(ProviderHelpers.getReefRoyaleGameMode(tester),
        ReefRoyaleGameMode.cursedTide);
  });
}
