import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: skip turn advances to next player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final p1Id = getCurrentPlayerId(tester)!;

    // Tap skip turn button
    final skipButton = ElementFinders.getLunarLanderSkipTurnButton();
    expect(skipButton, findsOneWidget);
    await tester.tap(skipButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Remove darts after skip
    await clickDartsRemoved(tester);

    // Should be Player B's turn
    final p2Id = getCurrentPlayerId(tester)!;
    expect(p2Id, isNot(p1Id));
  });
}
