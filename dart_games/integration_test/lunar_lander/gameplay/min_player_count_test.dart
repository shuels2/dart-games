import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Verifies the game starts and runs correctly with the MINIMUM player count (2).
  // Asserts both descent tracks render, characters are visible, altitude pills
  // exist, and turns cycle P1 -> P2 -> P1.
  testWidgets('Gameplay: minimum player count (2) — both tracks render and turns cycle',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    expect(selectedPlayers.length, 2, reason: 'Min player count is 2');

    final p1Id = selectedPlayers[0].id;
    final p2Id = selectedPlayers[1].id;

    // Both descent tracks should render
    expect(find.byKey(LunarLanderGameKeys.descentTrack(p1Id)), findsOneWidget,
        reason: 'P1 descent track should render');
    expect(find.byKey(LunarLanderGameKeys.descentTrack(p2Id)), findsOneWidget,
        reason: 'P2 descent track should render');

    // Both characters should render — active player uses playerAvatar key,
    // inactive uses characterOnTrack(playerId).
    expect(find.byKey(LunarLanderGameKeys.playerAvatar), findsOneWidget,
        reason: 'Active player character should render');
    expect(find.byKey(LunarLanderGameKeys.characterOnTrack(p2Id)), findsOneWidget,
        reason: 'Inactive player character should render');

    // Active player's altitude pill (the readout) should be visible
    expect(find.byKey(LunarLanderGameKeys.altitudeReadout), findsOneWidget,
        reason: 'Active player altitude readout should be visible');

    // P1 is current player at start
    expect(getCurrentPlayerId(tester), p1Id);

    // P1 throws 3 darts and finishes turn
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);

    // Now P2 should be current player
    expect(getCurrentPlayerId(tester), p2Id,
        reason: 'After P1 turn ends, P2 should be current');

    // P2 throws 3 darts and finishes turn
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);

    // Should cycle back to P1
    expect(getCurrentPlayerId(tester), p1Id,
        reason: 'After P2 turn ends, turn should cycle back to P1');
  });
}
