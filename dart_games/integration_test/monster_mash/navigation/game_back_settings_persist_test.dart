import 'package:flutter/material.dart' show Slider;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../results_screen/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Game back button returns to menu with settings preserved',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set health to 10 for quick game completion
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    // Complete game then Play Again to get fresh game screen
    await completeGameToVictory(tester);
    await PumpSequences.fullRebuild(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);
    await UITestHelpers.clickPlayAgain(tester, config);

    // Wait for game screen to fully render after Play Again
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Tap game back button (0 darts thrown in new game, no save modal)
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    // Verify back on menu with settings preserved
    expect(config.getStartButton(), findsOneWidget);
    final slider = tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
    expect(slider.value.toInt(), 10,
        reason: 'Health Max should still be 10 after returning from game');
  });
}
