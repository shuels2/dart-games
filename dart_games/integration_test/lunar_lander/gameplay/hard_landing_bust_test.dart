import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Hard Landing ON — bust reverts altitude to turn-start value',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // Start with altitude=50 so we can easily test bust
    await setupAndStartGame(tester, config,
        altitude: 100, hardLanding: true, playerNames: ['Player A', 'Player B']);

    final playerId = getCurrentPlayerId(tester)!;
    final startAlt = getAltitude(tester, playerId);
    expect(startAlt, 100);

    // Throw 3 singles of 20 = 60 total descent, so altitude = 40
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    final altAfterRound1 = getAltitude(tester, playerId);
    // Player A should be at 40 (100 - 60)
    // (Player B's turn now — skip to get back to Player A)
    await completeTurnWithMisses(tester);

    // Player A's turn again — altitude should be 40
    expect(getAltitude(tester, playerId), altAfterRound1);

    // Now throw a dart that would overshoot (e.g. triple 20 = 60, but altitude is only 40)
    final altBeforeBust = getAltitude(tester, playerId);
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // triple 20 = 60 > 40 = BUST

    // With Hard Landing ON, altitude should REVERT to pre-turn value (altBeforeBust)
    expect(getAltitude(tester, playerId), altBeforeBust,
        reason: 'Hard Landing bust should revert altitude to turn-start value');
  });
}
