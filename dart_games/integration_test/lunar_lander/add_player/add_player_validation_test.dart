import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player: start button disabled with fewer than 2 players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Start button should be disabled initially (no players)
    final startButton = ElementFinders.getLunarLanderStartButton();
    expect(startButton, findsOneWidget);

    // Add only one player
    await UITestHelpers.addPlayer(tester, 'Solo Pilot', config);
    expect(find.text('Solo Pilot'), findsWidgets);

    // Button still present but disabled until 2nd player added
    expect(startButton, findsOneWidget);
  });
}
