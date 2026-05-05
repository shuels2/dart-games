import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: after 3 darts and darts removed, turn advances to next player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final p1Id = getCurrentPlayerId(tester)!;

    // Throw 3 darts for Player A
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);

    // Remove darts to advance turn
    await clickDartsRemoved(tester);

    // Should now be Player B's turn
    final p2Id = getCurrentPlayerId(tester)!;
    expect(p2Id, isNot(p1Id));
  });
}
