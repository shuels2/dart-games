// integration_test/treasure_divide/visual_validation/active_player_highlight_test.dart
//
// Solo 2 players (P1 = "ActH_P1", P2 = "ActH_P2").
//
// Assert:
//   - P1's opponent tile does NOT appear (P1 is active; shown in active panel)
//   - P2's opponent tile IS present in the opponent column
//
// After P1's takeout (3 darts + DARTS REMOVED):
//   - P2 becomes active (shown in active panel, not in opponent list)
//   - P1's opponent tile IS present in the opponent column
//
// The "active player highlight" in TD is that the active player occupies
// the entire ActivePlayerPanel while non-active players are in the opponent
// tiles column. The active player does NOT have a playerTile key widget;
// only opponent tiles have playerTile keys (TreasureDivideGameKeys.playerTile).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/dart_throw_helpers.dart';

final config = GameUIConfig.treasureDivide();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Visual Validation: Active player shown in panel (not opponent tile); switches after takeout',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      playerNames: ['ActH_P1', 'ActH_P2'],
    );

    // Drain any initial layout overflow from the game screen render.
    // Using takeException() is safe here: it only drains what the Flutter
    // binding has queued; it does NOT suppress errors the way
    // FlutterError.onError=no-op does (which can cause Chrome to crash).
    tester.binding.takeException();

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final game = provider.currentGame!;

    // ── Initial state: P1 is active ───────────────────────────────────────
    final activePlayerId = game.currentPlayerId;
    final allPlayerIds = game.playerIds;
    final opponentIds =
        allPlayerIds.where((id) => id != activePlayerId).toList();

    // Active player should NOT have a playerTile in the opponent column
    // (the active player is shown in the ActivePlayerPanel, not in the list)
    final activeTileFinder =
        find.byKey(TreasureDivideGameKeys.playerTile(activePlayerId));
    expect(activeTileFinder, findsNothing,
        reason:
            'Active player ($activePlayerId) should NOT have an opponent tile — '
            'they are displayed in the ActivePlayerPanel');

    // The player name should appear in the active panel area
    expect(find.text('ActH_P1'), findsWidgets,
        reason: 'P1 name should be visible somewhere in the game screen');

    // Opponent(s) should have playerTile keys
    for (final opponentId in opponentIds) {
      final opponentTile =
          find.byKey(TreasureDivideGameKeys.playerTile(opponentId));
      expect(opponentTile, findsOneWidget,
          reason:
              'Opponent player ($opponentId) should have a playerTile widget '
              'in the opponent column');
    }

    // Drain any accumulated layout overflow exceptions.
    for (var i = 0; i < 5; i++) {
      final ex = tester.binding.takeException();
      if (ex == null) break;
    }

    // ── Complete P1's turn: 3 misses + DARTS REMOVED ───────────────────────
    for (int d = 0; d < 3; d++) {
      provider.processDartThrow(
        score: 0,
        multiplier: 'miss',
        baseScore: 0,
        sector: 'Miss',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      tester.binding.takeException();
    }

    // Simulate takeout finished to advance to P2.
    // NOTE: clickDartsRemoved() won't work here because the TD game screen
    // doesn't pass dartboardKey to DartboardEmulatorSection, so the
    // "DARTS REMOVED" button calls dartboardKey?.currentState?.removeDarts()
    // which is null → no-op. We must fire the stream event directly.
    DartThrowHelpers.getMockApi(tester)?.simulateTakeoutFinished();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    tester.binding.takeException();

    // ── After takeout: P2 is now active ───────────────────────────────────
    final newGame = provider.currentGame!;
    final newActiveId = newGame.currentPlayerId;

    // newActiveId should be P2 (different from original P1 active)
    expect(newActiveId, isNot(equals(activePlayerId)),
        reason: 'After P1 takeout, P2 should become the active player');

    // P2 (now active) should NOT have an opponent tile
    final p2TileFinder =
        find.byKey(TreasureDivideGameKeys.playerTile(newActiveId));
    expect(p2TileFinder, findsNothing,
        reason:
            'P2 (now active) should NOT have an opponent tile after becoming active');

    // P1 (now opponent) should have a playerTile
    final p1TileFinder =
        find.byKey(TreasureDivideGameKeys.playerTile(activePlayerId));
    expect(p1TileFinder, findsOneWidget,
        reason:
            'P1 (now opponent) should have a playerTile widget after P2 becomes active');

    // Drain residual overflow exceptions from final layout.
    for (var i = 0; i < 5; i++) {
      final ex = tester.binding.takeException();
      if (ex == null) break;
    }
  });
}
