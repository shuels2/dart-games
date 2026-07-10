// integration_test/treasure_divide/visual_validation/treasure_divide_screenshot_results_test.dart
//
// Screenshot test for Treasure Divide — team gameplay, endgame, and results screens.
// Menu + early-game states live in `treasure_divide_screenshot_test.dart`.
// The split is necessary because the parallel UI runner has a 600s per-file
// poll timeout (run_ui_tests_parallel_worker.bat).
//
// Driver: test_driver/screenshot_test.dart (NEVER integration_test.dart)
// DO NOT use pumpAndSettle() — splash CircularProgressIndicator prevents settling.
//
// Structure: ONE `testWidgets` block per file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/main.dart' show overflowTrapMessages;
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

// Helpers are inlined below — both their interface AND their bodies. Past
// failures showed that even importing shared/dart_throw_helpers.dart or
// shared/game_setup_helpers.dart from a screenshot test (under parallel
// `-d web-server` mode) triggers the same `SocketException` at
// `WebDriver.quit` ~14s in that we saw with `_helpers.dart` and with multiple
// `testWidgets`. The screenshot-driver web-compile path has a cache hazard
// with helper imports that the integration_test driver doesn't share. Every
// other game's screenshot test (Gladiator, Pirate's Grid, Tiki Golf, etc.)
// inlines helper BODIES — talking directly to `mock_scolia_api_service` —
// and passes in parallel. Match that pattern.

// ==========================================================================
// HELPER METHODS (inline for screenshot test)
// ==========================================================================

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
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
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
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
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

/// Simulate takeout (darts removed) via the mock API. Treasure Divide fires the
/// RemoveDartsModal on turn-end; this helper confirms `shouldPromptTakeout`
/// before triggering so screenshots don't try to dismiss a modal that never appeared.
Future<void> simulateTakeout(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();

  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  if (provider.shouldPromptTakeout) {
    // ignore: avoid_print
    print('SCREENSHOT: Simulating takeout via mock API...');
    final mockApi = getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  } else {
    // ignore: avoid_print
    print('SCREENSHOT: WARNING - shouldPromptTakeout is false, skipping takeout');
  }
}

/// Throw all 3 darts as misses (wipeout turn). Leaves `shouldPromptTakeout = true`.
Future<void> throwAllMissesToWipeout(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await throwMissViaMock(tester);
  }
}

/// Throw exactly 3 hit darts for the current player's turn.
/// After 3 darts, shouldPromptTakeout becomes true.
Future<void> throwFullTurnHit(WidgetTester tester, int target) async {
  for (int i = 0; i < 3; i++) {
    await throwDartViaMock(tester, target);
  }
}

/// Navigate to the Treasure Divide menu, apply settings, add the given players,
/// and start the game. Inlined from `GameSetupHelpers.setupAndStartTreasureDivide`
/// (importing shared/game_setup_helpers.dart from a screenshot test triggers
/// the parallel-mode webdriver crash — see header note).
Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  bool teamMode = false,
  bool manualAssignment = false,
  List<String>? playerNames,
}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (teamMode) {
    await SettingsHelpers.setTreasureDivideGameModeTeam(tester);
    await PumpSequences.fullRebuild(tester);
    if (manualAssignment) {
      await SettingsHelpers.setTreasureDivideAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
    }
  }
  if (numberOfRounds != 9) {
    await SettingsHelpers.selectTreasureDivideRounds(tester, numberOfRounds);
  }
  if (quarterItEnabled) {
    await SettingsHelpers.toggleTreasureDivideQuarterIt(tester);
  }
  if (customTargetsEnabled) {
    await SettingsHelpers.toggleTreasureDivideCustomTargets(tester);
  }

  final names = playerNames ?? ['Player A', 'Player B'];
  for (final name in names) {
    await UITestHelpers.addPlayer(tester, name, config);
  }

  await UITestHelpers.startGame(tester, config);
}

/// Take screenshot with extra pumps to ensure rendering is current.
/// CRITICAL: Uses binding.takeScreenshot() — must use screenshot_test.dart driver.
/// Do NOT use pumpAndSettle() — continuous animations prevent settling.
Future<void> screenshot(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  // ignore: avoid_print
  print('SCREENSHOT: Taking screenshot: $name');
  await binding.takeScreenshot(name);
}

/// Poll for the results screen Play Again button (up to 90s).
/// After hasWinner=true, _handleGameWon queues _audioQueue.whenIdle +
/// 250ms before Navigator.pushReplacement fires. This pattern is required
/// to let the async navigation complete before capturing results screenshots.
Future<void> pumpUntilResults(WidgetTester tester) async {
  for (int i = 0; i < 300; i++) {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    if (find.byKey(TreasureDivideResultsKeys.playAgainButton).evaluate().isNotEmpty) {
      break;
    }
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

// ==========================================================================
// MAIN
// ==========================================================================

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = GameUIConfig.treasureDivide();

  group('Treasure Divide - Results Screenshot Capture', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    // Single continuous flow capturing team gameplay, halved state, and results.
    // See file header for why this is one testWidgets instead of many.
    testWidgets('Results screenshot flow', (WidgetTester tester) async {
      // ======================================================================
      // PART 5: TEAM GAMEPLAY STATES
      // ======================================================================
      print('SCREENSHOT: === PART 5: TEAM GAMEPLAY STATES ===');

      await UITestHelpers.resetServerState();

      // Team mode: 4 players, Random assignment (spec: 4 players → 2 crews of 2)
      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 7,
        teamMode: true,
        playerNames: ['Jack', 'Anne', 'Calico', 'Mary'],
      );

      expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

      final round1Target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, 0);
      print('SCREENSHOT: Team game round 1 target = $round1Target');

      // --- Team active player panel: crew crest + name + active player ---
      await screenshot(binding, tester,
          '15_game_team_crew_active_panel');

      // --- Team scoreboard: per-crew tiles in bottom strip ---
      await screenshot(binding, tester,
          '16_game_team_scoreboard_per_crew_tiles');

      // Advance Team 1's first player (throw 3 darts + takeout)
      await throwFullTurnHit(tester, round1Target);
      await simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      print('SCREENSHOT: === PART 5 COMPLETE ===');

      // ======================================================================
      // PART 6: TEAM SOLO CREW (3 players → 2 crews: 2+1)
      // ======================================================================
      print('SCREENSHOT: === PART 6: TEAM SOLO CREW (3 PLAYERS) ===');

      await UITestHelpers.resetServerState();

      // 3 players, Random → spec Section 5: 2 crews (2+1 — one solo crew)
      // Solo crew member gets 6 darts instead of 3.
      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 7,
        teamMode: true,
        playerNames: ['Jack', 'Anne', 'Calico'],
      );

      expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

      // Advance through crew 1 (2 players × 3 darts + takeout each)
      // then we'll be on the solo crew.
      final tdProvider = ProviderHelpers.getTreasureDivideProvider(tester);
      final r6Target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, 0);

      // Complete crew 1 (2 players, each throws 3 darts then takeout)
      {
        final crewId = tdProvider.currentTeamId;
        while (tdProvider.currentTeamId == crewId &&
            !tdProvider.hasWinner) {
          await throwFullTurnHit(tester, r6Target);
          await simulateTakeout(tester);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
        }
      }

      // Now on the solo crew (1 player, 6 darts)
      // Throw 4 darts and capture mid-turn
      if (!tdProvider.hasWinner) {
        await throwDartViaMock(tester, r6Target);
        await throwDartViaMock(tester, r6Target);
        await throwDartViaMock(tester, r6Target);
        await throwDartViaMock(tester, r6Target);
        await screenshot(binding, tester,
            '14_game_team_solo_crew_6_darts');
        // Throw remaining 2 darts and takeout
        await throwDartViaMock(tester, r6Target);
        await throwDartViaMock(tester, r6Target);
        await simulateTakeout(tester);
      }

      print('SCREENSHOT: === PART 6 COMPLETE ===');

      // ======================================================================
      // PART 7: HALVED / WIPEOUT STATES
      // ======================================================================
      print('SCREENSHOT: === PART 7: HALVED/WIPEOUT STATES ===');

      await UITestHelpers.resetServerState();

      // Solo game — build score then wipeout to trigger halved animation
      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 7,
        playerNames: ['Jack', 'Anne'],
      );

      expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

      // Round 1: both players hit to build some score (3 darts each)
      final r7Target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, 0);
      await throwFullTurnHit(tester, r7Target);
      await simulateTakeout(tester);
      await throwFullTurnHit(tester, r7Target);
      await simulateTakeout(tester);

      // Round 2: P1 wipes out (misses all 3) → halved penalty
      await throwAllMissesToWipeout(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await screenshot(binding, tester,
          '17_game_solo_halved_animation');
      await simulateTakeout(tester);

      // --- Team mode: crew wipeout (crew misses all darts → treasure spills) ---
      await UITestHelpers.resetServerState();

      // 4-player team wipeout — 7 rounds, 2 crews of 2
      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 7,
        teamMode: true,
        playerNames: ['Jack', 'Anne', 'Calico', 'Mary'],
      );

      expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

      // First build some crew score across 1 round (3 darts + takeout per player)
      final r7tTarget =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, 0);
      final wipeProvider = ProviderHelpers.getTreasureDivideProvider(tester);

      // Complete round 1 for all crews with hits (3 darts per player)
      while (!wipeProvider.hasWinner) {
        final roundIdx =
            ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
        if (roundIdx >= 1) break;
        await throwFullTurnHit(tester, r7tTarget);
        await simulateTakeout(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // Round 2 for Crew 1 — wipe out all players
      if (!wipeProvider.hasWinner) {
        final crew1Id = wipeProvider.currentTeamId;
        while (wipeProvider.currentTeamId == crew1Id &&
            !wipeProvider.hasWinner) {
          await throwAllMissesToWipeout(tester);
          await simulateTakeout(tester);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
        }
        await screenshot(binding, tester,
            '18_game_team_crew_wipeout');
      }

      print('SCREENSHOT: === PART 7 COMPLETE ===');

      // ======================================================================
      // PART 8: RESULTS SCREENS
      // ======================================================================
      print('SCREENSHOT: === PART 8: RESULTS SCREENS ===');

      await UITestHelpers.resetServerState();

      // --- Solo end-of-game, 2 players ---
      // Both players hit every round so there are non-zero scores.
      // Player 1 gets 3 hits per round = higher total → clear winner.
      // Player 2 gets 1 hit per round = lower total.
      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 7,
        playerNames: ['Jack', 'Anne'],
      );

      expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

      // Rapid-complete: each player throws 3 darts per turn (all hits).
      // With matching targets both players score equally → tie is fine for
      // visual coverage (the results screen still shows winner card + rankings).
      // To create differentiation: player 1 always hits (3 darts), player 2
      // always misses (3 darts). This ensures Jack wins clearly.
      {
        final soloProvider = ProviderHelpers.getTreasureDivideProvider(tester);
        int turnCount = 0; // 0-indexed turn across ALL players
        while (!soloProvider.hasWinner) {
          final roundIdx =
              ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
          final rTarget =
              ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);

          // Even turns = player 1 (Jack) → hits. Odd turns = player 2 (Anne) → misses.
          // This creates a clear winner (Jack) and a loser (Anne).
          if (turnCount % 2 == 0) {
            await throwFullTurnHit(tester, rTarget);
          } else {
            await throwAllMissesToWipeout(tester);
          }
          await simulateTakeout(tester);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
          turnCount++;
        }
      }

      // Poll for results screen (up to 90s). The game-screen calls
      // _audioQueue.whenIdle then 250ms before Navigator.pushReplacement,
      // which completes asynchronously after the last takeout.
      print('SCREENSHOT: Waiting for solo results screen...');
      await pumpUntilResults(tester);

      final soloResultsVisible =
          find.byKey(TreasureDivideResultsKeys.playAgainButton).evaluate().isNotEmpty;
      print('SCREENSHOT: Solo results visible: $soloResultsVisible');

      await screenshot(binding, tester, '19_results_solo_winner');

      // Same results screen — capture ranked layout (close finish annotation)
      await screenshot(binding, tester,
          '21_results_solo_2players_close_finish');

      print('SCREENSHOT: === PART 8a SOLO RESULTS COMPLETE ===');

      // --- Team end-of-game results ---
      // 4 players × 7 rounds = 28 throw/takeout cycles (vs 56 for 8p×7r).
      // 4 players → 2 crews; results screen shows crew crest + ranking layout.
      await UITestHelpers.resetServerState();

      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 7,
        teamMode: true,
        playerNames: ['Jack', 'Anne', 'Calico', 'Mary'],
      );

      expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

      // Rapid-complete all rounds (every player throws 3 darts and hits).
      {
        final teamResultsProvider =
            ProviderHelpers.getTreasureDivideProvider(tester);
        int teamTurnCount = 0;
        while (!teamResultsProvider.hasWinner) {
          final roundIdx =
              ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
          final rTarget =
              ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);
          // Alternate: crew 1 players hit, crew 2 players miss → crew 1 wins.
          // teamTurnCount tracks individual player turns.
          // With 4 players, 2 crews of 2: turns 0,1 = crew1; turns 2,3 = crew2.
          // After round reset, crew1 goes first again.
          // Simple: first 2 turns per round are crew1 → hit; last 2 are crew2 → miss.
          final turnInRound = teamTurnCount % 4;
          if (turnInRound < 2) {
            await throwFullTurnHit(tester, rTarget);
          } else {
            await throwAllMissesToWipeout(tester);
          }
          await simulateTakeout(tester);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
          teamTurnCount++;
        }
      }

      // Poll for team results screen
      print('SCREENSHOT: Waiting for team results screen...');
      await pumpUntilResults(tester);

      final teamResultsVisible =
          find.byKey(TreasureDivideResultsKeys.playAgainButton).evaluate().isNotEmpty;
      print('SCREENSHOT: Team results visible: $teamResultsVisible');

      await screenshot(binding, tester,
          '20_results_team_winner_crest_roster');

      // Same 2-crew results — capture full rankings view
      await screenshot(binding, tester,
          '22_results_team_2crews_full_rankings');

      print('SCREENSHOT: === PART 8 COMPLETE ===');
      print('SCREENSHOT: File 2 complete.');

      // Overflow trap — see treasure_divide_screenshot_test.dart for the
      // rationale. Drains the framework's exception queue so the
      // aggregate "Multiple exceptions (N)" report doesn't shadow the
      // consolidated dump — the errors are already captured in
      // overflowTrapMessages verbatim.
      if (overflowTrapMessages.isNotEmpty) {
        while (tester.binding.takeException() != null) {}
        final dump = overflowTrapMessages
            .asMap()
            .entries
            .map((e) => '[${e.key}] ${e.value}')
            .join('\n---\n');
        throw Exception(
            'OVERFLOW_TRAP ${overflowTrapMessages.length} errors:\n$dump');
      }
    });
  });
}
