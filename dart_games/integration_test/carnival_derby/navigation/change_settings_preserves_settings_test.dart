import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../ui/_helpers.dart';

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

    // Win in one turn: 3x T20 = 180
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Wait for results screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

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
