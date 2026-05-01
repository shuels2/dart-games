import 'package:flutter/material.dart' show Slider;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../results_screen/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Change Settings preserves health max and players after victory',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Low health for quick game
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await completeGameToVictory(tester);

    // Click Change Settings on results screen
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify menu with settings preserved
    expect(config.getStartButton(), findsOneWidget);
    final slider = tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
    expect(slider.value.toInt(), 10,
        reason: 'Health Max should still be 10 after Change Settings');

    // Verify players are still present
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  });
}
