import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 24: Results - Change Settings Navigation
  // Features: Return to menu with preserved settings
  // UI Elements: Change game players and settings button, menu navigation
  // Validates: Return to menu with Change Settings button, menu displays with target score and player preselected. Note: Does NOT verify Perfect Finish setting preserved - only confirms menu navigation and player/target display
  testWidgets('Test 24: Change Settings', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Player1', config);

    await setTargetScore(tester, 180);

    await startGame(tester);

    // Quick win
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');

    await clickDartsRemoved(tester);

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    // Click Change Settings
    final changeSettingsButton = config.getChangeSettingsButton();
    await tester.ensureVisible(changeSettingsButton);
    await tester.pump();
    await tester.tap(changeSettingsButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();

    // Should navigate back to menu with preselected settings
    expect(find.textContaining('Target score:'), findsOneWidget);
    // Player1 appears twice: once in Available Players, once in Selected Players (preselected)
    expect(find.text('Player1'), findsWidgets);
  });
}
