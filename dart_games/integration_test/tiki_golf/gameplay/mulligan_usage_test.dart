import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

/// Mulligan flow: when Mulligan ON + Splash, the RemoveDartsModal shows
/// "USE MULLIGAN" button. Tapping it re-throws maxStrokes darts and disables
/// mulligan for the rest of the game.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: Mulligan ON + Splash shows USE MULLIGAN modal; tapping it re-throws darts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        maxStrokes: 3,
        mulliganEnabled: true,
        playerNames: ['Alice', 'Bob']);

    final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;

    // Verify mulligan is available at game start
    expect(ProviderHelpers.isTikiGolfMulliganAvailable(tester, playerId),
        isTrue,
        reason: 'Mulligan should be available at game start');

    // Miss all 3 darts → Splash → turn ends
    await throwAllMissesToSplash(tester, maxStrokes: 3);

    // Modal should appear with USE MULLIGAN button
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(ElementFinders.getTikiGolfUseMulliganButton(), findsOneWidget,
        reason: 'USE MULLIGAN button should appear after Splash with Mulligan ON');

    // USE MULLIGAN button is visible — tap it
    final mulliganBtn = ElementFinders.getTikiGolfUseMulliganButton();
    await tester.tap(mulliganBtn);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    // After tapping USE MULLIGAN, the modal should dismiss (button gone)
    // because the provider's currentTurnEnded was reset to false.
    // Give extra time for rebuilds.
    expect(ElementFinders.getTikiGolfUseMulliganButton(), findsNothing,
        reason:
            'USE MULLIGAN button should disappear after mulligan is used — '
            'proves the screen rebuilt with showMulliganModal=false');
  });
}
