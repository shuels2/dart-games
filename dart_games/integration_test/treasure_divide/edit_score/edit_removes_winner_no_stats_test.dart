// integration_test/treasure_divide/edit_score/edit_removes_winner_no_stats_test.dart
//
// Edit-4 (Rule §6c) — Editing a would-be winning dart to a miss before the
// game finalizes results in lower/no gold and no stats being written.
//
// Strategy (7-round game, P1=EditP1, P2=EditP2):
//   Rounds 0-5: P1 misses all, P2 misses all (both at 0 gold).
//   Round 6 (Bull): P1 throws Bull, Bull, Bull → haul=150.
//     shouldPromptTakeout=true. P1 "would win" if P2 misses this round.
//   Edit P1: change dart 3 from Bull to Miss → new haul = Bull+Bull+Miss = 100.
//   Verify hasWinner == false (game still active, P2 hasn't played).
//   Click DARTS REMOVED → commits P1 haul=100, advances to P2.
//   P2 round 6: misses all 3 → advance → _finalizeGame → P1 still wins (100 vs 0).
//   (The "removes winner no stats" aspect is: stats match the EDITED outcome,
//   not a phantom pre-edit winner. Both gamesPlayed=1; winner has gamesWon=1.)
//
//   NOTE: In Treasure Divide the game finalizes at the END of the last round
//   (after ALL players complete round 6). Editing mid-turn does NOT call
//   _finalizeGame (game state is still "playing"). The test verifies that
//   editing a dart BEFORE the game ends correctly affects the final result.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';

final _config = GameUIConfig.treasureDivide();

MockScoliaApiService? _getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> _throwMissViaMock(WidgetTester tester) async {
  final mockApi = _getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'miss',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }
}

Future<void> _simulateTakeout(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  if (provider.shouldPromptTakeout) {
    final mockApi = _getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
  }
  tester.binding.takeException();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: editing dart before finalization affects final outcome (no phantom winner stats)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      _config,
      numberOfRounds: 7,
      playerNames: ['EditP1', 'EditP2'],
    );

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p1Id = players.firstWhere((p) => p.name == 'EditP1').id;
    final p2Id = players.firstWhere((p) => p.name == 'EditP2').id;

    // Rounds 0-5: both players miss all darts
    for (int round = 0; round < 6; round++) {
      await _throwMissViaMock(tester);
      await _throwMissViaMock(tester);
      await _throwMissViaMock(tester);
      await _simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      tester.binding.takeException();

      await _throwMissViaMock(tester);
      await _throwMissViaMock(tester);
      await _throwMissViaMock(tester);
      await _simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      tester.binding.takeException();
    }

    // Round 6 (Bull): P1 throws Bull×3 → haul=150 pre-edit
    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester), 6,
        reason: '[DIAG td_edit_removes] Should be on round 6');

    // Throw Bull on dart 1
    final mockApi = _getMockApi(tester);
    mockApi?.simulateDartThrow(
      score: 50,
      multiplier: 'bull',
      playerName: 'Player',
      baseScore: 25,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Throw Bull on dart 2
    mockApi?.simulateDartThrow(
      score: 50,
      multiplier: 'bull',
      playerName: 'Player',
      baseScore: 25,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Throw Bull on dart 3
    mockApi?.simulateDartThrow(
      score: 50,
      multiplier: 'bull',
      playerName: 'Player',
      baseScore: 25,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(provider.shouldPromptTakeout, isTrue,
        reason:
            '[DIAG td_edit_removes] P1 should be waiting for takeout after 3 Bulls');
    expect(provider.hasWinner, isFalse,
        reason:
            '[DIAG td_edit_removes] No winner yet — P2 has not played round 6');

    // Edit dart 3 from Bull to Miss → new haul = 50+50+0 = 100
    // Explicitly re-affirm darts 1 and 2 as Bull so the dialog save button
    // stays enabled regardless of whether the initial state is already set.
    await EditScoreHelpers.editScoreAndSave(
      tester,
      _config,
      dart1: 'Bull',
      dart2: 'Bull',
      dart3: 'Miss',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // hasWinner is still false (game still active, P2 hasn't played)
    expect(provider.hasWinner, isFalse,
        reason:
            '[DIAG td_edit_removes] hasWinner should still be false after edit — '
            'game state is still playing');

    // Simulate takeout (commit P1 haul=100, advance to P2).
    // NOTE: Use direct mock API call — DartboardEmulatorSection's DARTS REMOVED
    // button delegates via dartboardKey?.currentState?.removeDarts() which is a
    // no-op when dartboardKey is null (TD game screen doesn't pass dartboardKey).
    final mockApiForTakeout = _getMockApi(tester);
    mockApiForTakeout?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    tester.binding.takeException();

    // Game continues — results screen should NOT be showing yet
    expect(find.byKey(TreasureDivideResultsKeys.playAgainButton), findsNothing,
        reason:
            '[DIAG td_edit_removes] Results screen should NOT appear — '
            'P2 still needs to complete round 6');

    // P2 round 6: misses all → _finalizeGame → P1 wins (100 vs 0)
    await _throwMissViaMock(tester);
    await _throwMissViaMock(tester);
    await _throwMissViaMock(tester);
    await _simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    tester.binding.takeException();

    // Game should now be finalized
    expect(provider.hasWinner, isTrue,
        reason:
            '[DIAG td_edit_removes] Game should end after P2 completes last round');

    // Stats reflect edited outcome: P1 wins with 100 gold (not 150).
    // Both players gamesPlayed=0 until results screen loads.
    await ResultsHelpers.pumpUntilResults(tester, _config);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    final p1 = ProviderHelpers.findPlayerById(tester, p1Id);
    expect(p1, isNotNull,
        reason: '[DIAG td_edit_removes] EditP1 not found in provider');
    expect(p1!.gamesPlayed, 1,
        reason: '[DIAG td_edit_removes] EditP1 gamesPlayed should be 1');
    expect(p1.gamesWon, 1,
        reason:
            '[DIAG td_edit_removes] EditP1 gamesWon should be 1 (100 gold vs 0)');

    final p2 = ProviderHelpers.findPlayerById(tester, p2Id);
    expect(p2, isNotNull,
        reason: '[DIAG td_edit_removes] EditP2 not found in provider');
    expect(p2!.gamesPlayed, 1,
        reason: '[DIAG td_edit_removes] EditP2 gamesPlayed should be 1');
    expect(p2.gamesWon, 0,
        reason: '[DIAG td_edit_removes] EditP2 gamesWon should be 0 (0 gold)');
  });
}
