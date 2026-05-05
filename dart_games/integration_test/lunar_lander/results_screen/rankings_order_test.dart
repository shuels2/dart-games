import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: all players appear in rankings',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B', 'Player C']);
    await completeGameToVictory(tester, numOpponents: 2);

    // All three players should appear in results rankings
    expect(find.textContaining('Player A'), findsWidgets);
    expect(find.textContaining('Player B'), findsWidgets);
    expect(find.textContaining('Player C'), findsWidgets);
  });
}
