import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../results/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Change Settings preserves settings and players after victory',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await completeGameToVictory(tester);
    await PumpSequences.fullRebuild(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Click Change Settings on results screen
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify menu with settings preserved
    expect(config.getStartButton(), findsOneWidget);
    expect(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(), findsOneWidget);
    expect(ElementFinders.getClockworkQuestSpeedModeCheckbox(), findsOneWidget);

    // Verify players are still present via provider
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    expect(playerProvider.selectedPlayers.length, 2);

    // Verify players are visible in the UI
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  });
}
