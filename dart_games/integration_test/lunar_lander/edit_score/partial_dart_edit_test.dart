import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Verifies that editing only a single dart (dart 2) leaves darts 1 and 3
  // untouched and recalculates altitude correctly. Throw 3 darts (20, 10, 5)
  // -> total 35 from starting altitude 200 -> 165. Edit only dart 2 from 10
  // to Bull (25). New total = 20 + 25 + 5 = 50 -> altitude 150.
  testWidgets('Edit Score: partial change (only dart 2) recalculates altitude correctly',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // setupAndStartGame in edit_score/_helpers.dart does not accept altitude;
    // navigate via game_setup_helpers directly to set a custom starting altitude.
    await UITestHelpers.navigateToGameMenu(tester, config);
    // (Default altitude=200 is fine; the edit_score helper uses defaults.)
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    final playerId =
        ProviderHelpers.getLunarLanderCurrentPlayerId(tester)!;
    final startingAlt =
        ProviderHelpers.getLunarLanderStartingAltitude(tester);
    expect(startingAlt, 200, reason: 'Default starting altitude should be 200');

    // Throw 3 darts: 20, 10, 5 (total descent = 35)
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 10);
    await throwDartViaMock(tester, 5);

    final altBefore = ProviderHelpers.getLunarLanderAltitude(tester, playerId);
    expect(altBefore, startingAlt - 35,
        reason: 'Altitude after 20+10+5 should be 200 - 35 = 165');

    // Edit ONLY dart 2: change 10 -> Bull (25). Leave dart 1 (20) and
    // dart 3 (5) untouched.
    await openEditScore(tester);
    await EditScoreHelpers.setDart2(tester, 'Bull');
    await updateScore(tester);

    // New total descent = 20 + 25 + 5 = 50. Altitude = 200 - 50 = 150.
    final altAfter = ProviderHelpers.getLunarLanderAltitude(tester, playerId);
    expect(altAfter, startingAlt - 50,
        reason: 'After editing only dart 2 from 10 to Bull(25), altitude should be 150');
  });
}
