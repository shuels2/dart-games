import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: changing dart and saving updates altitude',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, playerNames: ['Player A', 'Player B']);

    // Get current player and record initial altitude
    final playerId = ProviderHelpers.getLunarLanderCurrentPlayerId(tester)!;
    final initialAlt = ProviderHelpers.getLunarLanderAltitude(tester, playerId);

    // Throw 3 darts so the RemoveDartsModal appears (Edit Score button lives
    // inside the modal). One scoring dart (10) + two misses keeps the math
    // simple: altitude drops by 10, the misses add 0.
    await throwDartViaMock(tester, 10);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    final altAfterDart = ProviderHelpers.getLunarLanderAltitude(tester, playerId);
    expect(altAfterDart, initialAlt - 10);

    // Open edit score and change dart 1 to single 5
    await openEditScore(tester);
    await EditScoreHelpers.setDart1(tester, 'S5');
    await updateScore(tester);

    // Altitude should now be initialAlt - 5 (dart 1 changed; darts 2,3 are misses)
    final altAfterEdit = ProviderHelpers.getLunarLanderAltitude(tester, playerId);
    expect(altAfterEdit, initialAlt - 5);
  });
}
