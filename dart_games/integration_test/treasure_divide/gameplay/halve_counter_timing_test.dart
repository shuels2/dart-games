// integration_test/treasure_divide/gameplay/halve_counter_timing_test.dart
//
// Regression: opponent tile for the player who JUST missed their round
// must display "Halved 1 time" (or "Quartered 1 time") immediately —
// NOT wait until every player has finished the round.
//
// Manual repro that motivated the fix:
//   Round 0: P1 hits 20/20/20, P2 hits 20/20/20.
//   Round 1: P1 misses everything → their opponent tile should read
//            "Halved 1 time" before P2 has thrown a dart.
//   Previously the counter only incremented at end-of-round, so P1's
//   tile still read "0 halved" while P2 was taking their turn, and
//   only ticked once P2 also finished round 1.
//
// This test covers both Halve It (default, /2) and Quarter It (/4)
// variants so the two label strings ("Halved N …" / "Quartered N …")
// both regress against the same timing bug.
//
// NOTE: Uses throwDartDirect() for scored throws — see
// min_player_count_test.dart for the MockScoliaApiService payload
// limitation.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Returns the "Halved 1 time" (or "Quartered 1 time") Text widget nested
/// inside the opponent tile for [playerId]. Fails the test with a rich
/// diag prefix if not found.
Finder _halveTextInOpponentTile(String playerId, {required bool quarterIt}) {
  final label = quarterIt ? 'Quartered 1 time' : 'Halved 1 time';
  return find.descendant(
    of: find.byKey(TreasureDivideGameKeys.playerTile(playerId)),
    matching: find.text(label),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: opponent tile shows "Halved 1 time" IMMEDIATELY after '
      'P1 all-miss, before P2 has thrown round 1',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7, playerNames: ['HalveP1', 'HalveP2']);

    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p1 = players[0];
    final p2 = players[1];

    // ── Round 0: both players hit the target three times ──────────────
    // Default 7-round sequence[0] = 20 (verified in quarter_it_on_quarters
    // test), so each dart scores 20 gold.
    final round0Target = getCurrentRoundTarget(tester);
    expect(round0Target, equals(20),
        reason: '[DIAG halve_timing] round 0 target should be 20');

    // P1 hits 3× 20
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester),
        equals(p1.id));
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, p1.id),
        equals(60),
        reason: '[DIAG halve_timing] P1 = 60 after 3× S20');

    // P2 hits 3× 20 → round advances to 1
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester),
        equals(p2.id));
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester),
        equals(1),
        reason: '[DIAG halve_timing] round should have advanced to 1');
    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, p2.id),
        equals(60),
        reason: '[DIAG halve_timing] P2 = 60 after 3× S20');

    // ── Round 1: P1 misses everything ─────────────────────────────────
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester),
        equals(p1.id),
        reason: '[DIAG halve_timing] P1 should be active for round 1');
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Provider-level checks: round NOT yet advanced, P2 now active, P1's
    // halve counter already 1.
    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester),
        equals(1),
        reason:
            '[DIAG halve_timing] round must not advance until P2 finishes');
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester),
        equals(p2.id),
        reason: '[DIAG halve_timing] P2 should be active after P1 takeout');
    expect(
        ProviderHelpers.getTreasureDivideTimesHalvedPerPlayer(tester, p1.id),
        equals(1),
        reason:
            '[DIAG halve_timing] BUG REGRESSION: P1 halve counter must be 1 '
            'immediately after their all-miss turn, not wait for P2');
    expect(
        ProviderHelpers.getTreasureDivideTimesHalvedPerPlayer(tester, p2.id),
        equals(0),
        reason:
            '[DIAG halve_timing] P2 has not thrown round 1 yet — counter still 0');

    // Widget-level check: P1's opponent tile visibly shows "Halved 1 time".
    expect(_halveTextInOpponentTile(p1.id, quarterIt: false), findsOneWidget,
        reason:
            '[DIAG halve_timing] P1 opponent tile must display "Halved 1 time" '
            'immediately, before P2 throws round 1');
    // P2 has not missed yet, no halving label anywhere for P2.
    expect(_halveTextInOpponentTile(p2.id, quarterIt: false), findsNothing,
        reason: '[DIAG halve_timing] P2 has no halving label yet');

    // P1's gold visibly dropped from 60 → 30 in the tile too.
    // Opponent tile renders `Text.rich` with a "N gold" span PLUS a
    // "(+N)" / "(–)" round-score span, so the plain text is longer
    // than "30 gold". textContaining works against Text.rich's
    // concatenated plaintext.
    expect(
        find.descendant(
          of: find.byKey(TreasureDivideGameKeys.playerTile(p1.id)),
          matching: find.textContaining('30 gold'),
        ),
        findsWidgets,
        reason:
            '[DIAG halve_timing] P1 opponent tile gold must read "30 gold" after halve');

    // ── P2 also misses everything → round advances, P1 becomes active ─
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester),
        equals(2),
        reason: '[DIAG halve_timing] round should now be 2');
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester),
        equals(p1.id),
        reason: '[DIAG halve_timing] P1 active for round 2');
    // P2's counter now ticks (also had treasure).
    expect(
        ProviderHelpers.getTreasureDivideTimesHalvedPerPlayer(tester, p2.id),
        equals(1),
        reason: '[DIAG halve_timing] P2 halve counter must be 1 after miss');
    // P2's opponent tile now visibly shows "Halved 1 time".
    expect(_halveTextInOpponentTile(p2.id, quarterIt: false), findsOneWidget,
        reason:
            '[DIAG halve_timing] P2 opponent tile must display "Halved 1 time" '
            'after P2 all-miss turn');

  });

  testWidgets(
      'Gameplay: Quarter It — opponent tile shows "Quartered 1 time" '
      'IMMEDIATELY after P1 all-miss',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        quarterItEnabled: true,
        playerNames: ['QtrP1', 'QtrP2']);

    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p1 = players[0];
    final p2 = players[1];

    // ── Round 0: both hit 20 three times ──────────────────────────────
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await throwDartDirect(tester, 20);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester),
        equals(1));

    // ── Round 1: P1 misses everything ─────────────────────────────────
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Provider: counter = 1 immediately, round has NOT advanced.
    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester),
        equals(1));
    expect(
        ProviderHelpers.getTreasureDivideTimesHalvedPerPlayer(tester, p1.id),
        equals(1),
        reason:
            '[DIAG halve_timing/qtr] P1 Quarter counter must be 1 immediately');
    expect(
        ProviderHelpers.getTreasureDivideTimesHalvedPerPlayer(tester, p2.id),
        equals(0));

    // Widget: opponent tile reads "Quartered 1 time" (not "Halved …").
    expect(_halveTextInOpponentTile(p1.id, quarterIt: true), findsOneWidget,
        reason:
            '[DIAG halve_timing/qtr] P1 opponent tile must show "Quartered 1 time" '
            'immediately after their all-miss turn');
    // No stray "Halved" wording under Quarter It.
    expect(
        find.descendant(
          of: find.byKey(TreasureDivideGameKeys.playerTile(p1.id)),
          matching: find.text('Halved 1 time'),
        ),
        findsNothing,
        reason:
            '[DIAG halve_timing/qtr] Under Quarter It, label must read "Quartered", not "Halved"');

    // P1's gold visibly dropped from 60 → floor(60/4) = 15.
    // textContaining because the opponent tile renders Text.rich
    // with "N gold" + a "(+N)" / "(–)" round-score span appended.
    expect(
        find.descendant(
          of: find.byKey(TreasureDivideGameKeys.playerTile(p1.id)),
          matching: find.textContaining('15 gold'),
        ),
        findsWidgets,
        reason:
            '[DIAG halve_timing/qtr] P1 opponent tile gold must read "15 gold" after quartering');

  });
}
