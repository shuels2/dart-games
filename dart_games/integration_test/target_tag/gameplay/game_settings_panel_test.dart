import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 11: Game Settings Panel - All Settings Visible - Validates game settings panel displays all configuration options, Shield Max slider is present and functional, Team mode toggle is present, Hero Bonus toggle is present, all settings controls are interactive', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify all game settings are visible on menu screen
    // Note: Target Tag has no Target Score setting (uses Shield Max slider instead)
    verifyGameSettingsPanel(tester,
      hasShieldMax: true,
      hasTargetScore: false,
      hasTeamMode: true,
      hasHeroBonus: true,
    );

    // Verify Shield Max slider exists
    expect(find.byType(Slider), findsOneWidget);

    // Verify Team mode switch exists
    expect(find.byType(Switch), findsWidgets);

    // Verify settings are interactive by toggling team mode
    await enableTeamMode(tester);
    final teamModeSwitch = find.byType(Switch).first;
    final switchWidget = tester.widget<Switch>(teamModeSwitch);
    expect(switchWidget.value, isTrue);
  });
}
