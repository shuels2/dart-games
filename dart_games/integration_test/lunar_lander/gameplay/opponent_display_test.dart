import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Verifies that opponent (non-active) players' descent tracks render BOTH
  // initially AND after they take their turn — proving opponent altitudes
  // visually update across turns. With the new layout the active player's
  // pill key (altitudeReadout) moves between players, so we check the
  // provider state to assert the underlying data backs the visible pill.
  testWidgets('Gameplay: opponent tracks render and altitudes update across turns',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['P1', 'P2', 'P3']);

    final provider = ProviderHelpers.getLunarLanderProvider(tester);
    final playerIds = provider.currentGame!.playerIds;
    expect(playerIds.length, 3);

    final p1Id = playerIds[0];
    final p2Id = playerIds[1];
    final p3Id = playerIds[2];

    final startingAlt = ProviderHelpers.getLunarLanderStartingAltitude(tester);

    // BEFORE any darts: all 3 descent tracks are visible
    expect(find.byKey(LunarLanderGameKeys.descentTrack(p1Id)), findsOneWidget);
    expect(find.byKey(LunarLanderGameKeys.descentTrack(p2Id)), findsOneWidget);
    expect(find.byKey(LunarLanderGameKeys.descentTrack(p3Id)), findsOneWidget);

    // All three players should start at the starting altitude
    expect(getAltitude(tester, p1Id), startingAlt);
    expect(getAltitude(tester, p2Id), startingAlt);
    expect(getAltitude(tester, p3Id), startingAlt);

    // P1's turn: throw 20, 10, 5 -> total descent = 35
    expect(getCurrentPlayerId(tester), p1Id);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 10);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);

    // Now P2 active. P1 is now an opponent — its altitude should reflect the
    // 35-point descent (it's visible on its descent track pill).
    expect(getCurrentPlayerId(tester), p2Id);
    expect(getAltitude(tester, p1Id), startingAlt - 35,
        reason: 'P1 (opponent) altitude should reflect the 35-point descent');
    expect(getAltitude(tester, p3Id), startingAlt,
        reason: 'P3 (opponent) altitude should still equal starting altitude');

    // Tracks for all 3 players still rendered
    expect(find.byKey(LunarLanderGameKeys.descentTrack(p1Id)), findsOneWidget);
    expect(find.byKey(LunarLanderGameKeys.descentTrack(p2Id)), findsOneWidget);
    expect(find.byKey(LunarLanderGameKeys.descentTrack(p3Id)), findsOneWidget);

    // P2's turn: throw 15, 5, miss -> total descent = 20
    await throwDartViaMock(tester, 15);
    await throwDartViaMock(tester, 5);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Now P3 active. P2's opponent pill should reflect the 20-point descent.
    expect(getCurrentPlayerId(tester), p3Id);
    expect(getAltitude(tester, p2Id), startingAlt - 20,
        reason: 'P2 (opponent) altitude should reflect the 20-point descent');
    expect(getAltitude(tester, p1Id), startingAlt - 35,
        reason: 'P1 altitude should remain at -35 from prior turn');
    expect(getAltitude(tester, p3Id), startingAlt,
        reason: 'P3 (active) still at starting altitude');
  });
}
