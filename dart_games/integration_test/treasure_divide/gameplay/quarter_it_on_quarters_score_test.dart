// integration_test/treasure_divide/gameplay/quarter_it_on_quarters_score_test.dart
//
// Group B – Test 11: Quarter It ON. P1 scores 3×20=60 in round 0, then misses
// all of round 1. After round 1 takeout, P1 score = floor(60/4) = 15.
// Also verifies QUARTER IT badge is visible.
//
// NOTE: Uses throwDartDirect() for P1's hits — see min_player_count_test.dart
// for the full explanation of the MockScoliaApiService payload limitation.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Quarter It ON — wipeout divides score by 4',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        quarterItEnabled: true,
        playerNames: ['QtrP1', 'QtrP2']);

    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p1Id = players[0].id;

    // ── Quarter It badge should be visible on game screen ─────────────────
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.byKey(TreasureDivideGameKeys.quarterItBadge), findsWidgets,
        reason: '[DIAG quarter_it] QUARTER IT badge should be visible when option is ON');

    // ── Round 0: P1 hits S20×3 = 60 gold ─────────────────────────────────
    // Default 7-round sequence[0] = 20
    final target = getCurrentRoundTarget(tester);
    expect(target, equals(20),
        reason: '[DIAG quarter_it] Round 0 target should be 20');

    // Use throwDartDirect for non-zero scores (mock payload limitation)
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // P1 score = 60
    final p1ScoreAfterRound0 =
        ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id);
    expect(p1ScoreAfterRound0, equals(60),
        reason: '[DIAG quarter_it] P1 score should be 60 after 3×S20');

    // ── Round 0: P2 misses ────────────────────────────────────────────────
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // ── Round 1: P1 misses all (quarter wipeout) ──────────────────────────
    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester), equals(1),
        reason: '[DIAG quarter_it] Should be on round 1 now');
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // P1 score = floor(60 / 4) = 15
    final p1ScoreAfterRound1 =
        ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id);
    expect(p1ScoreAfterRound1, equals(15),
        reason: '[DIAG quarter_it] P1 score should be floor(60/4)=15 after quarter wipeout');

  });
}
