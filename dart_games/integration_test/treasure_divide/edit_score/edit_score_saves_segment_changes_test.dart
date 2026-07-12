// integration_test/treasure_divide/edit_score/edit_score_saves_segment_changes_test.dart
//
// Edit-5 — Editing all 3 darts in a turn saves the new segment values and
// the provider reflects the updated total.
//
// Strategy (9-round game, P1 target round 0 = 20):
//   P1 throws S5, S5, S5 (round 0, target=20 → all miss since 5≠20 → 0 gold).
//   Open Edit Score, change all 3 to T20 (triple=60 gold for 20-target round).
//   Save. Verify provider.currentGame.totalForPlayer(P1) = 60 before takeout.
//   Click DARTS REMOVED → round advances normally.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: changing all 3 darts saves and provider reflects updated total',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // 9-round game, round 0 target = 20
    await setupAndStartGame(tester,
        numberOfRounds: 9, playerNames: ['SegP1', 'SegP2']);

    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p1Id = players.firstWhere((p) => p.name == 'SegP1').id;

    // Round 0 target should be 20
    final roundIdx =
        ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
    final target = ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);
    expect(target, 20,
        reason:
            '[DIAG td_edit_saves] Round 0 target should be 20 (default 9-round sequence)');

    // Throw S5, S5, S5 — all miss since target=20, not 5 → 0 gold
    await throwDartViaMock(tester, 5, multiplier: 'single');
    await throwDartViaMock(tester, 5, multiplier: 'single');
    await throwDartViaMock(tester, 5, multiplier: 'single');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    expect(provider.shouldPromptTakeout, isTrue,
        reason: '[DIAG td_edit_saves] shouldPromptTakeout should be true after 3 darts');

    // Current total before edit: 0 (3 misses on non-target segments)
    // (totalForPlayer reflects committed rounds, not the current turn yet)
    // Current turn haul is 0.

    // Open Edit Score, change all 3 darts to T20
    // T20 against target=20: base=20, multiplier='triple' → score=20*3=60.
    // _computeHitScore for target=20: segBase=T20→base=20 == target=20 → returns score=60.
    await EditScoreHelpers.editScoreAndSave(
      tester,
      config,
      dart1: 'T20',
      dart2: 'T20',
      dart3: 'T20',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // After edit: the provider should have updated the current turn haul.
    // editPlayerScore updates playerRoundScores[p1Id][0] = 60*3 = 180.
    // Wait — editPlayerScore re-computes: 3 × T20 against target=20 =
    //   T20 → base=20, multiplier='triple', score=60 per dart → 3×60=180.
    // But actually the haul is summed: newHaul += hitScore for each segment.
    // Each T20 against target=20: _extractBase('T20')=20 == target=20 → score=60.
    // newHaul = 60+60+60 = 180.
    //
    // But editPlayerScore with game.state == playing also sets
    // _currentTurnHaul = newHaul (if roundIndex == currentRoundIndex AND
    // currentPlayerId == playerId).
    //
    // totalForPlayer sums playerRoundScores which only has committed rounds.
    // editPlayerScore writes the haul to playerRoundScores[p1][0] = 180.
    // So totalForPlayer(p1) should return 180 now (even before takeout).
    final totalAfterEdit =
        ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id);
    expect(totalAfterEdit, 180,
        reason:
            '[DIAG td_edit_saves] P1 total should be 180 after editing 3×T20 '
            '(3 × 60 gold from T20 against target=20); actual: $totalAfterEdit');

    // Simulate takeout (commit edited haul, round advances).
    // NOTE: Use direct mock API call — DartboardEmulatorSection's DARTS REMOVED
    // button delegates via dartboardKey?.currentState?.removeDarts() which is a
    // no-op when dartboardKey is null (TD game screen doesn't pass dartboardKey).
    if (provider.shouldPromptTakeout) {
      getMockApi(tester)?.simulateTakeoutFinished();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }

    // After takeout: total should still be 180 (committed to round 0)
    final totalAfterTakeout =
        ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id);
    expect(totalAfterTakeout, 180,
        reason:
            '[DIAG td_edit_saves] P1 total should remain 180 after DARTS REMOVED; '
            'actual: $totalAfterTakeout');

    // Game should not be over (P2 still needs to play round 0 + 8 more rounds)
    expect(provider.hasWinner, isFalse,
        reason: '[DIAG td_edit_saves] Game should not be over after round 0');
  });
}
