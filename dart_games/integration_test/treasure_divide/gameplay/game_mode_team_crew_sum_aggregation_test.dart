// integration_test/treasure_divide/gameplay/game_mode_team_crew_sum_aggregation_test.dart
//
// Group B – Test 6: Team mode (Random), 4 players → 2 crews × 2.
// After crew B's P1 hits and P2 misses, crew B's totalForTeam = P1's haul
// (SUM, not halved, because at least one member hit).
//
// We play crew A first (all misses) so that crew B becomes active. Once crew B
// starts, game.currentPlayerId is guaranteed to be teamPlayers[crewBId][0]
// (set by _advanceTeamPlayer line 580: currentPlayerId = nextPlayers.first).
// This avoids the model initialization quirk where game.create() sets
// currentPlayerId = playerIds[0] (first added) which may not be in activeTeamId.
//
// NOTE: Uses throwDartDirect() for crew B P1's hits — see min_player_count_test.dart
// for the full explanation of the MockScoliaApiService payload limitation.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Team mode — crew haul is SUM when any member hit',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // 4 players → random dist → 2 crews of 2
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        teamMode: true,
        playerNames: ['CrewA_P1', 'CrewA_P2', 'CrewB_P1', 'CrewB_P2']);

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final game = provider.currentGame!;

    final teamIds = game.teamPlayers.keys.toList();
    expect(teamIds.length, equals(2),
        reason: '[DIAG team_sum] Should have 2 crews for 4 players');

    // ── Play crew A completely (all misses) to advance to crew B ──────────
    // activeTeamId starts as 'team_1' (crew A). Both members miss.
    final crewAId = game.activeTeamId!;
    final crewAMembers = game.teamPlayers[crewAId]!;
    expect(crewAMembers.length, equals(2),
        reason: '[DIAG team_sum] Crew A should have 2 members');

    // Crew A turn 1 (all misses)
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Crew A turn 2 (all misses)
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // ── Now crew B is active ───────────────────────────────────────────────
    // After _advanceTeamPlayer advances past crew A, activeTeamId = 'team_2'
    // and currentPlayerId = teamPlayers['team_2'][0] (guaranteed by line 580).
    final crewBId = game.activeTeamId!;
    expect(crewBId, isNot(equals(crewAId)),
        reason: '[DIAG team_sum] Crew B should be different from crew A');
    final crewBMembers = game.teamPlayers[crewBId]!;
    expect(crewBMembers.length, equals(2),
        reason: '[DIAG team_sum] Crew B should have 2 members');

    // After crew A completes, currentPlayerId = crewBMembers[0] (guaranteed)
    expect(provider.currentPlayerId, equals(crewBMembers[0]),
        reason: '[DIAG team_sum] Crew B P1 should be active after crew A finishes');

    // ── Crew B's P1 throws 3 hits ─────────────────────────────────────────
    final target = getCurrentRoundTarget(tester);

    // Use throwDartDirect for non-zero scores (mock payload limitation)
    await throwDartDirect(tester, target);
    await throwDartDirect(tester, target);
    await throwDartDirect(tester, target);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // ── Crew B's P2 throws 3 misses ───────────────────────────────────────
    expect(provider.currentPlayerId, equals(crewBMembers[1]),
        reason: '[DIAG team_sum] Crew B P2 should be next active player');

    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // ── After crew B completes round 0: crew haul = P1's hits + P2's 0 ────
    // totalForTeam includes committed round scores (after takeout).
    final crewBTreasure = game.totalForTeam(crewBId);
    // P1 hit 3×target, P2 missed: crew haul = 3*target (no halving — P1 contributed)
    expect(crewBTreasure, equals(target * 3),
        reason: '[DIAG team_sum] Crew B treasure should be sum=${target * 3} (P1 hit + P2 miss = no wipeout)');

  });
}
