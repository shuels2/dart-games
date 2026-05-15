import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

/// Play Again preserves settings: after completing a game with maxStrokes=6
/// and mulligan ON, tapping PLAY AGAIN restarts with the same settings.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: PLAY AGAIN restarts game preserving Max Strokes and Mulligan settings',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        maxStrokes: 6,
        mulliganEnabled: true,
        playerNames: ['Alice', 'Bob']);

    // Record original settings
    final originalMaxStrokes =
        ProviderHelpers.getTikiGolfMaxStrokes(tester);
    final originalMulligan =
        ProviderHelpers.isTikiGolfMulliganEnabled(tester);

    expect(originalMaxStrokes, 6);
    expect(originalMulligan, isTrue);

    await driveToCompletion(tester, playerNames: ['Alice', 'Bob']);

    // Tap PLAY AGAIN
    await ResultsHelpers.clickPlayAgain(tester, config);

    // Wait for new game to start
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // New game settings preserved
    final newMaxStrokes = ProviderHelpers.getTikiGolfMaxStrokes(tester);
    final newMulligan = ProviderHelpers.isTikiGolfMulliganEnabled(tester);

    expect(newMaxStrokes, originalMaxStrokes,
        reason: 'Max Strokes should be preserved after PLAY AGAIN');
    expect(newMulligan, originalMulligan,
        reason: 'Mulligan setting should be preserved after PLAY AGAIN');

    // New game is active
    expect(ProviderHelpers.isTikiGolfGameActive(tester), isTrue,
        reason: 'A new game should be active after PLAY AGAIN');
  });
}
