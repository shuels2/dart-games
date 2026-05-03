import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: reaching exactly 0 altitude wins the game',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // Use altitude=100 so Player A can win within a single 3-dart turn:
    //   triple 20 = 60 → alt=40
    //   single 20 = 20 → alt=20
    //   single 20 = 20 → alt=0 → TOUCHDOWN!
    await setupAndStartGame(tester, config,
        altitude: 100, playerNames: ['Player A', 'Player B']);

    final playerId = getCurrentPlayerId(tester)!;

    // Three darts in Player A's turn, winning on the third
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    expect(hasWinner(tester), isTrue,
        reason: 'Exactly reaching 0 altitude should win the game');
    expect(getAltitude(tester, playerId), 0);
  });
}
