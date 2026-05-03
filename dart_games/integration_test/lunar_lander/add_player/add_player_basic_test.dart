import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player: basic add player flow works', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add a player via the dialog
    await UITestHelpers.addPlayer(tester, 'Buzz Aldrin', config);

    // Verify player appears in the list
    expect(find.text('Buzz Aldrin'), findsWidgets);

    // Add a second player
    await UITestHelpers.addPlayer(tester, 'Neil Armstrong', config);
    expect(find.text('Neil Armstrong'), findsWidgets);

    // Start button should now be enabled (2 players)
    final startButton = ElementFinders.getLunarLanderStartButton();
    expect(startButton, findsOneWidget);

    await PumpSequences.simpleUpdate(tester);
  });
}
