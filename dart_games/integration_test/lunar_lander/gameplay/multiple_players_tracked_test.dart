import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: multiple players have independently tracked altitudes',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B', 'Player C']);

    // Get initial state
    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    expect(selectedPlayers.length, 3);

    final p1Id = selectedPlayers[0].id;
    final p2Id = selectedPlayers[1].id;
    final p3Id = selectedPlayers[2].id;

    final initialAlt = getAltitude(tester, p1Id);

    // Player A: throw 20+10+5 = 35 descent
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 10);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);

    // Player B: throw 15 only (skip rest)
    await throwDartViaMock(tester, 15);
    await completeTurnWithMisses(tester);

    // Player C: all misses
    await completeTurnWithMisses(tester);

    // Verify each player has their own altitude
    expect(getAltitude(tester, p1Id), initialAlt - 35,
        reason: 'Player A should have descended 35');
    expect(getAltitude(tester, p2Id), initialAlt - 15,
        reason: 'Player B should have descended 15');
    expect(getAltitude(tester, p3Id), initialAlt,
        reason: 'Player C should still be at initial altitude (all misses)');
  });
}
