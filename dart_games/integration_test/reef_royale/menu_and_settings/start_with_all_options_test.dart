import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Start game with all options enabled',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable all options. Include Bull replaced Show Hints in the menu
    // (Show Hints toggle was removed; hints are always on for new
    // games). Random Reefs must be toggled BEFORE Include Bull —
    // Include Bull is disabled while Random Reefs is OFF.
    await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
    await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
    await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
    await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
    await SettingsHelpers.toggleReefRoyaleIncludeBull(tester);
    await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);

    // Add players (auto-selected when added)
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
  });
}
