// integration_test/treasure_divide/gameplay/game_mode_team_crew_wipeout_test.dart
//
// Group B – Test 7: Team mode (Random), 4 players → 2 crews × 2.
// Crew A: both members miss all darts in round 0.
// → timesHalvedPerTeam[crewA] increments to 1; totalForTeam = 0 (half of 0 = 0).
//
// NOTE: In team mode with random assignment, game.currentPlayerId is initialized
// to playerIds[0] (first added player) which may NOT be in game.activeTeamId.
// We use game.activeTeamId as the authoritative active team identifier and play
// TWO consecutive turns (both crew members), relying on _advanceTeamPlayer to
// manage the within-crew pointer correctly.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Team mode — crew wipeout increments halve counter',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // 4 players → random dist → 2 crews of 2
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        teamMode: true,
        playerNames: ['WipeA_P1', 'WipeA_P2', 'WipeB_P1', 'WipeB_P2']);

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final game = provider.currentGame!;

    final teamIds = game.teamPlayers.keys.toList();
    expect(teamIds.length, equals(2),
        reason: '[DIAG team_wipeout] Should have 2 crews for 4 players');

    // Use activeTeamId as the authoritative active crew (not currentPlayerId).
    // game.create() sets currentPlayerId = playerIds[0] which can differ from
    // activeTeamId's first member when random assignment shuffles players.
    final crewAId = game.activeTeamId!;
    final crewAMembers = game.teamPlayers[crewAId]!;
    expect(crewAMembers.length, equals(2),
        reason: '[DIAG team_wipeout] Active crew should have 2 members');

    // Verify halve counter starts at 0
    expect(game.timesHalvedPerTeam[crewAId] ?? 0, equals(0),
        reason: '[DIAG team_wipeout] Crew A halve counter should start at 0');

    // ── Crew A: play both turns as misses ─────────────────────────────────
    // Turn 1: current player (whoever game says) misses 3 darts + takeout
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    drainExceptions(tester);

    // Turn 2: next player in crew A misses 3 darts + takeout
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    drainExceptions(tester);

    // ── After crew A wipeout ──────────────────────────────────────────────
    // timesHalvedPerTeam[crewA] should be 1
    expect(game.timesHalvedPerTeam[crewAId] ?? 0, equals(1),
        reason: '[DIAG team_wipeout] Crew A halve counter should be 1 after round wipeout');

    // totalForTeam = 0 (halving 0 = 0)
    final crewATreasure = game.totalForTeam(crewAId);
    expect(crewATreasure, equals(0),
        reason: '[DIAG team_wipeout] Crew A treasure should still be 0 after halving 0');

    // Suppress layout exceptions during cleanup pump (TD game screen layout bug).
    suppressLayoutExceptionsForCleanup();
  });
}
