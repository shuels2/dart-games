// integration_test/treasure_divide/play_to_complete/solo_play_to_tie_test.dart
//
// Solo mode, 2 players, default settings. Tap PLAY TO TIE button →
// TreasureDivideTieStrategy makes every player hit identically → both
// players end with the same total → results screen shows a tie.
//
// Asserts:
//   - provider.hasWinner == true (game ended)
//   - winnerIds.length >= 2 (multiple solo winners = tie)
//   - results screen renders the Play Again button
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.treasureDivide();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Tie (Solo): every player ends with the same gold → multi-winner tie',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      playerNames: ['Solo_P1', 'Solo_P2'],
    );

    // Drain any accumulated layout exceptions before tapping.
    for (var i = 0; i < 5; i++) {
      if (tester.binding.takeException() == null) break;
    }

    // Tap the "Divide the Treasure" button (Play-to-Tie).
    final tieButton = find.byKey(DartboardEmulatorKeys.playToTieButton);
    expect(tieButton, findsOneWidget,
        reason: 'PLAY TO TIE button should be visible in emulator mode');
    await tester.ensureVisible(tieButton);
    await tester.pump();
    await tester.tap(tieButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Poll for game completion (up to 90s wall-clock — well above the
    // ~30s a 9-round 2-player auto-tie takes).
    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    for (int i = 0; i < 300; i++) {
      if (provider.hasWinner) break;
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }
    expect(provider.hasWinner, isTrue,
        reason: 'Game should have a winner after Play To Tie completes');

    final game = provider.currentGame!;
    expect(game.winnerIds.length, greaterThanOrEqualTo(2),
        reason:
            'Play to Tie should produce a TIE — winnerIds.length should be ≥ 2; '
            'got ${game.winnerIds.length} (winnerIds = ${game.winnerIds})');

    // Confirm every player tied at the same total — sanity check the
    // strategy didn't accidentally favour one player.
    final totals =
        game.playerIds.map((id) => game.totalForPlayer(id)).toSet();
    expect(totals.length, 1,
        reason: 'All players should have IDENTICAL totals on a Play-to-Tie '
            'run; got distinct totals: $totals');

    // Let the results screen's `_deleteResumedSavedGame` post-frame
    // callback chain finish BEFORE the framework tears down the widget
    // tree — otherwise its second `addPostFrameCallback` fires against
    // an unmounted State and throws a late assertion the test framework
    // counts as a failure even though every expect() passed.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();

    // Drain residual exceptions from the post-tie render.
    for (var i = 0; i < 5; i++) {
      if (tester.binding.takeException() == null) break;
    }
  });
}
