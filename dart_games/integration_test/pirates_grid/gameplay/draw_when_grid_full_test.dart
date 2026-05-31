import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Full grid with no 3-in-a-row shows STALEMATE results',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy',
        bestOf: '1',
        playerNames: ['Player A', 'Player B']);

    // Programmatically fill grid for draw
    await fillGridForDraw(tester);

    // Trigger takeout (game is now in round-end draw state)
    await clickDartsRemoved(tester);
    await ResultsHelpers.pumpUntilResults(tester, config);

    // Results screen should show (Bo1 match ended in draw = match draw)
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should show after draw');

    // Verify STALEMATE headline
    expect(find.text('STALEMATE!'), findsOneWidget,
        reason: 'Draw should show STALEMATE! headline');
  });
}
