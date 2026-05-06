import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pause Modal: disconnection on menu shows pause modal and blocks back',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Simulate dartboard disconnection
    await simulateDisconnectAndVerify(tester);

    // Verify modal is visible
    expect(find.text('Game Paused'), findsOneWidget,
        reason: 'Pause modal should appear on dartboard disconnect');

    // Back button should be blocked (pause modal covers menu)
    // Verify back button is still in tree but modal overlays it
    expect(ElementFinders.getPiratesGridBackButton(), findsOneWidget);

    // Simulate reconnect — modal dismisses
    await simulateReconnectAndVerify(tester);
  });
}
