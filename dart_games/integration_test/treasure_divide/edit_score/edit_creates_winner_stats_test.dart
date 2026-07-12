// integration_test/treasure_divide/edit_score/edit_creates_winner_stats_test.dart
//
// Edit-3 (Rule §6c) — Editing a low-scoring turn to a high-scoring turn causes
// the player to win, and winner stats are persisted correctly.
//
// Strategy (7-round game, P1=GoldWinner, P2=GoldLoser):
//   Rounds 0-5: P1 misses all 3 darts, P2 misses all 3 darts (both at 0).
//   Round 6 (Bull): P1 throws S1, S1, S1 (non-Bull, non-target → 0 gold).
//     shouldPromptTakeout=true for P1.
//   Open Edit Score on P1's turn, change all 3 darts to T20.
//     newHaul = 20*3 = 60 gold, state still playing.
//   Click DARTS REMOVED → handleTakeoutFinished → commits P1 haul=60, advance to P2.
//   P2 round 6: throw 3 misses → shouldPromptTakeout=true.
//   Click DARTS REMOVED → handleTakeoutFinished → advance → _finalizeGame.
//   P1 wins (60 vs 0). Verify hasWinner=true, pumpUntilResults, check stats.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/services/victory_music_service.dart';
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

Future<void> _throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final mockApi = _getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: number *
          (multiplier == 'double'
              ? 2
              : multiplier == 'triple'
                  ? 3
                  : 1),
      multiplier: multiplier,
      playerName: 'Player',
      baseScore: number,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }
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
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: editing low-score turn to high-score creates winner and persists stats',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // 7-round sequence: [20,19,18,D(-1),17,T(-2),Bull(25)]
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      _config,
      numberOfRounds: 7,
      playerNames: ['GoldWinner', 'GoldLoser'],
    );

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p1Id = players.firstWhere((p) => p.name == 'GoldWinner').id;
    final p2Id = players.firstWhere((p) => p.name == 'GoldLoser').id;

    // Rounds 0-5: both miss all darts → both at 0 gold
    for (int round = 0; round < 6; round++) {
      // P1 misses
      await _throwMissViaMock(tester);
      await _throwMissViaMock(tester);
      await _throwMissViaMock(tester);
      await _simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // P2 misses
      await _throwMissViaMock(tester);
      await _throwMissViaMock(tester);
      await _throwMissViaMock(tester);
      await _simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    // Round 6 (Bull): P1 should be active now
    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester), 6,
        reason:
            '[DIAG td_edit_creates_winner] Should be on round 6 (last round)');
    expect(provider.hasWinner, isFalse,
        reason:
            '[DIAG td_edit_creates_winner] Should not have winner before last round');

    // P1 throws S1, S1, S1 (not Bull → 0 gold for this round)
    await _throwDartViaMock(tester, 1, multiplier: 'single');
    await _throwDartViaMock(tester, 1, multiplier: 'single');
    await _throwDartViaMock(tester, 1, multiplier: 'single');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(provider.shouldPromptTakeout, isTrue,
        reason:
            '[DIAG td_edit_creates_winner] P1 should be waiting for takeout after 3 darts');
    expect(provider.hasWinner, isFalse,
        reason:
            '[DIAG td_edit_creates_winner] No winner yet — P2 still needs to play');

    // Edit P1's turn: change all 3 darts to T20 (20×3=60 gold)
    // T20 is NOT the Bull target, but the provider scores it as 20*3=60.
    // For round 6 (target=Bull=25): T20 base=20, multiplier=triple, score=60.
    // _computeHitScore checks if this hits target=kTargetBull(25):
    //   Bull target requires multiplier='bull' or base=25. T20 won't score.
    // So T20 against Bull target = 0 gold.
    //
    // Use T19 which is also 0 for Bull round. We need a dart that DOES score.
    // For Bull round: any dart with base=25 (outer bull) or multiplier='bull'
    // scores. 'Bull' sector = base=25, multiplier='bull', score=50.
    //
    // Edit all 3 to 'Bull' (50 gold each = 150 total for this round).
    await EditScoreHelpers.editScoreAndSave(
      tester,
      _config,
      dart1: 'Bull',  // 50 gold (Bull = bullseye, base=25, multiplier='bull')
      dart2: 'Bull',  // 50 gold
      dart3: 'Bull',  // 50 gold (total = 150 for this round)
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Still no winner — game is still active, P2 hasn't played round 6
    expect(provider.hasWinner, isFalse,
        reason:
            '[DIAG td_edit_creates_winner] Still no winner after edit — P2 has not played yet');

    // Simulate takeout (commit P1 haul=150, advance to P2).
    // NOTE: Use direct mock API call — DartboardEmulatorSection's DARTS REMOVED
    // button delegates via dartboardKey?.currentState?.removeDarts() which is a
    // no-op when dartboardKey is null (TD game screen doesn't pass dartboardKey).
    final mockApiForTakeout = _getMockApi(tester);
    mockApiForTakeout?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // P2 round 6: throw 3 misses
    await _throwMissViaMock(tester);
    await _throwMissViaMock(tester);
    await _throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // P2's takeout → _finalizeGame → P1 wins (150 vs 0)
    await _simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(provider.hasWinner, isTrue,
        reason:
            '[DIAG td_edit_creates_winner] hasWinner should be true after P2 completes last round');

    // Navigate to results
    await ResultsHelpers.pumpUntilResults(tester, _config);
    // Wait for async stat updates
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    expect(VictoryMusicService().isInitialized, isTrue,
        reason: '[DIAG td_edit_creates_winner] VictoryMusicService should be initialized');

    // GoldWinner should have gamesPlayed=1, gamesWon=1
    final winner = ProviderHelpers.findPlayerById(tester, p1Id);
    expect(winner, isNotNull,
        reason: '[DIAG td_edit_creates_winner] GoldWinner not found');
    expect(winner!.gamesPlayed, 1,
        reason: '[DIAG td_edit_creates_winner] GoldWinner gamesPlayed should be 1');
    expect(winner.gamesWon, 1,
        reason: '[DIAG td_edit_creates_winner] GoldWinner gamesWon should be 1');
    expect(winner.gameHistory.length, 1,
        reason: '[DIAG td_edit_creates_winner] GoldWinner should have 1 game in history');
    expect(winner.gameHistory.first.gameName, 'Treasure Divide',
        reason: '[DIAG td_edit_creates_winner] Game name should be "Treasure Divide"');

    // GoldLoser should have gamesPlayed=1, gamesWon=0
    final loser = ProviderHelpers.findPlayerById(tester, p2Id);
    expect(loser, isNotNull,
        reason: '[DIAG td_edit_creates_winner] GoldLoser not found');
    expect(loser!.gamesPlayed, 1,
        reason: '[DIAG td_edit_creates_winner] GoldLoser gamesPlayed should be 1');
    expect(loser.gamesWon, 0,
        reason: '[DIAG td_edit_creates_winner] GoldLoser gamesWon should be 0');
  });
}
