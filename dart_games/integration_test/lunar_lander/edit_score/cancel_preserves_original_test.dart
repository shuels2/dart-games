import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: cancel preserves original altitude',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, playerNames: ['Player A', 'Player B']);

    final playerId = ProviderHelpers.getLunarLanderCurrentPlayerId(tester)!;

    // Throw 3 darts so the RemoveDartsModal appears (Edit Score button lives
    // inside the modal). One scoring dart + two misses fills the turn.
    await throwDartViaMock(tester, 10);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    final altAfterDart = ProviderHelpers.getLunarLanderAltitude(tester, playerId);

    // Open edit, change value, then CANCEL
    await openEditScore(tester);
    await EditScoreHelpers.setDart1(tester, 'S20');
    await cancelEditScore(tester);

    // Altitude should be unchanged (still reflects original dart value)
    final altAfterCancel = ProviderHelpers.getLunarLanderAltitude(tester, playerId);
    expect(altAfterCancel, altAfterDart);
  });
}
