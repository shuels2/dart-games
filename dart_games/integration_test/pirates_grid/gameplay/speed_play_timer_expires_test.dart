import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

// Speed Play timer implementation notes (from pirates_grid_game_screen.dart):
//   - Budget: 25 seconds per turn (int _speedPlaySecondsRemaining = 25)
//   - Mechanism: dart:async Timer.periodic(Duration(seconds: 1), ...) in widget state
//   - On expiry: _onSpeedPlayTimerExpired() is called:
//       * provider.skipTurn() → _waitingForTakeout = true, remaining darts skipped
//       * If dartsThrown > 0: fires simulateTakeoutStarted() after 3500 ms
//         (the DARTS REMOVED UI button then fires simulateTakeoutFinished to
//          actually advance the turn — the player must still tap DARTS REMOVED)
//       * If dartsThrown == 0: fires simulateTakeoutFinished() after 500 ms
//         (turn auto-advances with no human interaction required)
//
// This test verifies the case where P1 has thrown 1 dart when the timer fires:
//   - Timer expires → provider.skipTurn()
//   - shouldPromptTakeout becomes true → DARTS REMOVED button appears
//   - After clicking DARTS REMOVED, turn advances to P2

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: Speed Play — timer visible at start; expires after 25s → skipTurn triggered; DARTS REMOVED advances to P2',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        speedPlay: true,
        difficulty: 'Easy',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    // ── 1. Timer widget is visible at game start ───────────────────────────
    expect(ElementFinders.getPiratesGridSpeedPlayTimer(), findsOneWidget,
        reason:
            'Speed Play timer widget should be visible when speedPlay=true');

    // ── 2. Verify P1 is the active player ────────────────────────────────
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
        reason: 'P1 should be active at game start');

    // ── 3. Throw 1 miss dart so dartsThrown = 1 for P1 ───────────────────
    //
    // We throw a miss (score=0) to guarantee the dart does not claim any
    // cell. This leaves P1 with 1 dart thrown and 2 remaining.
    await throwMissViaMock(tester);

    expect(provider.getCurrentPlayerDartsThrown(), 1,
        reason: 'P1 should have 1 dart thrown after the miss');
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
        reason: 'P1 should still be active after 1 dart (turn not over yet)');

    // ── 4. Advance fake-async clock past the 25-second timer budget ───────
    //
    // Flutter test uses fake async: tester.pump(Duration) advances the fake
    // clock, causing dart:async Timer.periodic callbacks to fire.
    // After 25 one-second ticks, _speedPlaySecondsRemaining reaches 0 →
    // timer.cancel() + _onSpeedPlayTimerExpired() fires.
    //
    // With 1 dart thrown: _onSpeedPlayTimerExpired calls:
    //   provider.skipTurn()         → _waitingForTakeout = true
    //   [1500 ms] announceRemoveDarts (audio only — no UI gate)
    //   [3500 ms] _mockApi.simulateTakeoutStarted() (emits takeout_started;
    //             the game screen does NOT handle takeout_started — only
    //             takeout_finished triggers advanceToNextPlayer)
    //
    // After the timer expires, shouldPromptTakeout = true and the DARTS
    // REMOVED button is visible in the emulator. We click it to complete
    // the takeout (simulateTakeoutFinished → advanceToNextPlayer → P2 active).
    for (int i = 0; i < 26; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    // Process any micro-tasks scheduled by the timer expiry
    await tester.pump();
    await tester.pump();

    // ── 5. After timer expiry, shouldPromptTakeout = true ─────────────────
    expect(provider.shouldPromptTakeout, isTrue,
        reason:
            'shouldPromptTakeout should be true after timer expiry triggers skipTurn');

    // P1's darts thrown count is still 1 (skipTurn marks remaining as skipped
    // in the segments, but does not zero out dartsThrown — zeroed on next turn)
    expect(provider.currentGame!.dartsThrown[p1Id], 1,
        reason:
            'P1 dart count should still be 1 — skipTurn does not reset dartsThrown mid-turn');

    // Active player is still P1 (takeout not yet confirmed)
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
        reason:
            'P1 should still be the nominal current player until takeout confirmed');

    // ── 6. Complete the takeout by clicking DARTS REMOVED ─────────────────
    //
    // This fires simulateTakeoutFinished → takeout_finished event →
    // _handleTakeoutFinished() → provider.handleTakeoutFinished() →
    // advanceToNextPlayer() → currentPlayerIndex switches to P2.
    await clickDartsRemoved(tester);
    await tester.pump();
    await tester.pump();

    // ── 7. Verify the turn has advanced to P2 ────────────────────────────
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p2Id,
        reason:
            'Active player should be P2 after P1\'s timer expired and DARTS REMOVED clicked');

    // ── 8. Timer should now be visible for P2's fresh turn ────────────────
    expect(ElementFinders.getPiratesGridSpeedPlayTimer(), findsOneWidget,
        reason:
            'Speed Play timer widget should still be visible on P2\'s turn');
  });
}
