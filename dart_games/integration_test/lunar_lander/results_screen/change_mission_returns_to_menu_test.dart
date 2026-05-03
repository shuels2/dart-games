import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: CHANGE MISSION button returns to menu screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);
    await PumpSequences.fullRebuild(tester);

    // Click Change Settings (CHANGE MISSION)
    await UITestHelpers.clickChangeSettings(tester, config);

    // Should be on menu screen
    expect(ElementFinders.getLunarLanderStartButton(), findsOneWidget);
    expect(ElementFinders.getLunarLanderAltitudeSlider(), findsOneWidget);
  });
}
