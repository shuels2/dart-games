import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Results screen shows winner with "GOLDEN TIKI CHAMPION" heading and name.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: winner display shows name and Golden Tiki Champion heading',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_results_winner_display',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester,
            maxStrokes: 3, playerNames: ['Alice', 'Bob']);

        await driveToCompletion(tester, playerNames: ['Alice', 'Bob']);

        // Results screen should be visible
        expect(ElementFinders.getTikiGolfPlayAgainButton(), findsOneWidget,
            reason: 'Results screen should be visible after game completion');

        // Winner name widget should be present
        expect(ElementFinders.getTikiGolfWinnerName(), findsOneWidget,
            reason: 'Winner name widget should be shown on results screen');

        // "GOLDEN TIKI CHAMPION" heading text
        expect(find.textContaining('GOLDEN TIKI CHAMPION'), findsWidgets,
            reason: 'Results screen should show GOLDEN TIKI CHAMPION heading');

        // Provider confirms winner
        expect(ProviderHelpers.tikiGolfHasWinner(tester), isTrue,
            reason: 'Provider should confirm game has a winner');
      },
    );
  });
}
