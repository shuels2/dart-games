import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Change Settings preserves target score and players after victory',
      (WidgetTester tester) async {
    await navigateToCarnivalDerbyMenu(tester);

    // Set target score for quick win
    await setTargetScore(tester, 180);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await startGame(tester);

    await completeGameToVictory(tester);
    await PumpSequences.fullRebuild(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Click Change Settings on results screen
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify menu with settings preserved
    expect(config.getStartButton(), findsOneWidget);
    expect(find.textContaining('180'), findsOneWidget);

    // Verify players are still present
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  });
}
