// integration_test/treasure_divide/gameplay/game_mode_team_crew_wipeout_test.dart
//
// Group B – Test 7: Team mode (Random), 4 players → 2 crews × 2.
//
// Round 0: EVERY player scores (all 4 hit the round target on all
// darts) so both crews walk into round 1 with positive treasure.
// Round 1: crew A misses everything → halving fires because the crew
// has real treasure to halve. timesHalvedPerTeam[crewA] becomes 1
// and totalForTeam(crewA) drops to floor(pre / 2).
//
// The earlier version of this test had crew A miss round 0 with 0
// prior treasure. The provider's no-op guard (see 39e in the
// provider tests) correctly declines to bump the halve counter when
// there's nothing to halve, so that spec was wrong; this version
// seeds real treasure before triggering the halving event.
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

    // Use activeTeamId as the authoritative active crew.
    final crewAId = game.activeTeamId!;
    final crewAMembers = game.teamPlayers[crewAId]!;
    expect(crewAMembers.length, equals(2),
        reason: '[DIAG team_wipeout] Active crew should have 2 members');

    // Verify halve counter starts at 0
    expect(game.timesHalvedPerTeam[crewAId] ?? 0, equals(0),
        reason: '[DIAG team_wipeout] Crew A halve counter should start at 0');

    // ── Round 0: every player hits the target on all 3 darts ─────────────
    // Crew A gets treasure; crew B gets treasure; round 1 begins. Now
    // both crews have positive treasure that a wipeout would halve.
    Future<void> hitFullTurn() async {
      final target = getCurrentRoundTarget(tester);
      await throwDartDirect(tester, target);
      await throwDartDirect(tester, target);
      await throwDartDirect(tester, target);
      await simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      drainExceptions(tester);
    }

    // 4 turns in round 0: crew A P1, crew A P2, crew B P1, crew B P2.
    await hitFullTurn();
    await hitFullTurn();
    await hitFullTurn();
    await hitFullTurn();

    // Round 0 committed → crew A has real treasure.
    expect(game.currentRoundIndex, equals(1),
        reason: '[DIAG team_wipeout] Round should have advanced to 1');
    final crewATreasureBefore = game.totalForTeam(crewAId);
    expect(crewATreasureBefore, greaterThan(0),
        reason:
            '[DIAG team_wipeout] Setup: crew A must have positive treasure '
            'walking into round 1 so the halving event has something to halve');

    // ── Round 1: crew A both members miss all darts ──────────────────────
    // Turn 1: current crew A player misses 3 darts + takeout
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

    // ── After crew A round-1 wipeout ─────────────────────────────────────
    // timesHalvedPerTeam[crewA] should be 1
    expect(game.timesHalvedPerTeam[crewAId] ?? 0, equals(1),
        reason:
            '[DIAG team_wipeout] Crew A halve counter should be 1 after '
            'round-1 wipeout with prior treasure');

    // totalForTeam should be floor(prior / 2) (Halve It divisor is 2).
    final crewATreasureAfter = game.totalForTeam(crewAId);
    expect(crewATreasureAfter, equals(crewATreasureBefore ~/ 2),
        reason:
            '[DIAG team_wipeout] Crew A treasure should be halved '
            '(was $crewATreasureBefore, now $crewATreasureAfter)');

    // Suppress layout exceptions during cleanup pump (TD game screen layout bug).
    suppressLayoutExceptionsForCleanup();
  });
}
