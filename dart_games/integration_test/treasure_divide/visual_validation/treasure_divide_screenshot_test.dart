// integration_test/treasure_divide/visual_validation/treasure_divide_screenshot_test.dart
//
// Screenshot test for Treasure Divide — captures menu + early-game visual states.
// The remaining states (team gameplay, endgame, results) live in
// `treasure_divide_screenshot_results_test.dart`. The split is necessary
// because the parallel UI runner has a 600s per-file poll timeout
// (run_ui_tests_parallel_worker.bat).
//
// Driver: test_driver/screenshot_test.dart (NEVER integration_test.dart)
// DO NOT use pumpAndSettle() — splash CircularProgressIndicator prevents settling.
//
// Structure: ONE `testWidgets` block per file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/main.dart' show overflowTrapMessages;
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';

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

// ==========================================================================
// MAIN
// ==========================================================================

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = GameUIConfig.treasureDivide();

  group('Treasure Divide - Screenshot Capture', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    // Single continuous flow capturing all spec §12C visual states (menu + early game).
    // See file header for why this is one testWidgets instead of many.
    testWidgets('Full screenshot flow', (WidgetTester tester) async {
      // ======================================================================
      // PART 1: MENU SCREEN STATES
      // ======================================================================
      print('SCREENSHOT: === PART 1: MENU SCREEN STATES ===');

      // --- Solo default (2 players, default settings) ---
      await UITestHelpers.navigateToGameMenu(tester, config);
      print('SCREENSHOT: Navigated to menu');

      await UITestHelpers.addPlayer(tester, 'Jack', config);
      await UITestHelpers.addPlayer(tester, 'Anne', config);

      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedPlayers.length, greaterThanOrEqualTo(2));

      await screenshot(binding, tester, '01_menu_solo_default_2players');

      // --- Solo ready (4 players, 7 rounds, Quarter It ON) ---
      await UITestHelpers.addPlayer(tester, 'Calico', config);
      await UITestHelpers.addPlayer(tester, 'Mary', config);

      await SettingsHelpers.selectTreasureDivideRounds(tester, 7);
      await SettingsHelpers.toggleTreasureDivideQuarterIt(tester);
      await screenshot(binding, tester,
          '02_menu_solo_ready_4players_rounds7_quarteritON');

      // Reset rounds to default for subsequent screenshots
      await SettingsHelpers.selectTreasureDivideRounds(tester, 9);
      // Reset Quarter It back to OFF
      await SettingsHelpers.toggleTreasureDivideQuarterIt(tester);

      // --- Team mode + Random (4 players) ---
      await SettingsHelpers.setTreasureDivideGameModeTeam(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '03_menu_team_random_default');

      // --- Team Manual 4 players, 2 crews ---
      await SettingsHelpers.setTreasureDivideAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      // Set crew count to 2
      final teamCntFinder =
          ElementFinders.getTreasureDivideTeamCountDropdown();
      if (teamCntFinder.evaluate().isNotEmpty) {
        await tester.tap(teamCntFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final opt2 = find.text('2').last;
        if (opt2.evaluate().isNotEmpty) {
          await tester.tap(opt2);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      await screenshot(binding, tester,
          '04_menu_team_manual_4players_2crews');

      print('SCREENSHOT: === PART 1 COMPLETE ===');

      // ======================================================================
      // PART 2: MORE MENU STATES
      // ======================================================================
      print('SCREENSHOT: === PART 2: MORE MENU STATES ===');

      await UITestHelpers.resetServerState();
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add 5 players for solo-crew (5 players → spec Section 5: 2 crews of 2 + 1 solo crew)
      await UITestHelpers.addPlayer(tester, 'Jack', config);
      await UITestHelpers.addPlayer(tester, 'Anne', config);
      await UITestHelpers.addPlayer(tester, 'Calico', config);
      await UITestHelpers.addPlayer(tester, 'Mary', config);
      await UITestHelpers.addPlayer(tester, 'Blackbeard', config);

      await SettingsHelpers.setTreasureDivideGameModeTeam(tester);
      await PumpSequences.fullRebuild(tester);
      // Random mode — 5 players → 3 crews (2+2+1)
      await screenshot(binding, tester,
          '05_menu_team_random_5players_solo_crew');

      // --- Solo mode — Team Assignment greyed out ---
      await SettingsHelpers.setTreasureDivideGameModeSolo(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester,
          '06_menu_solo_team_assignment_greyed_out');

      // --- Custom Targets ON ---
      await SettingsHelpers.toggleTreasureDivideCustomTargets(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '07_menu_custom_targets_ON');
      // Reset Custom Targets
      await SettingsHelpers.toggleTreasureDivideCustomTargets(tester);

      print('SCREENSHOT: === PART 2 COMPLETE ===');

      // ======================================================================
      // PART 3: GAME SCREEN STATES (SOLO)
      // ======================================================================
      print('SCREENSHOT: === PART 3: GAME SCREEN SOLO STATES ===');

      await UITestHelpers.resetServerState();

      // --- Solo, start of game, Round 1 ---
      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 9,
        playerNames: ['Jack', 'Anne'],
      );

      final gameActive =
          ProviderHelpers.isTreasureDivideGameActive(tester);
      expect(gameActive, isTrue,
          reason: 'Game should be active after starting');

      final round1Target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, 0);
      print('SCREENSHOT: Round 1 target = $round1Target');

      await screenshot(binding, tester,
          '08_game_solo_round1_target$round1Target');

      // --- Round 1: after one dart hitting target ---
      await throwDartViaMock(tester, round1Target);
      await screenshot(binding, tester,
          '09_game_solo_round1_dart1_hit');

      // --- Round 1: all 3 darts thrown, RemoveDartsModal visible ---
      await throwDartViaMock(tester, round1Target);
      await throwDartViaMock(tester, round1Target);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await screenshot(binding, tester,
          '10_game_solo_round1_3darts_thrown');

      // --- Takeout, Round 2 ---
      await simulateTakeout(tester);
      // P2 round 1 — hit then takeout
      await throwDartViaMock(tester, round1Target);
      await simulateTakeout(tester);

      final round2Target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, 1);
      print('SCREENSHOT: Round 2 target = $round2Target');
      await screenshot(binding, tester,
          '11_game_solo_round2_target$round2Target');

      print('SCREENSHOT: === PART 3 COMPLETE ===');

      // ======================================================================
      // PART 4: SPECIAL OPTION STATES
      // ======================================================================
      print('SCREENSHOT: === PART 4: SPECIAL OPTION STATES ===');

      await UITestHelpers.resetServerState();

      // --- Quarter It ON ---
      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 9,
        quarterItEnabled: true,
        playerNames: ['Jack', 'Anne'],
      );

      expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

      // Advance to round 3 (so some score has built up)
      for (int r = 0; r < 2; r++) {
        final target = ProviderHelpers.getTreasureDivideRoundTarget(
            tester, r);
        // P1 hits
        await throwDartViaMock(tester, target);
        await simulateTakeout(tester);
        // P2 hits
        await throwDartViaMock(tester, target);
        await simulateTakeout(tester);
      }

      await screenshot(binding, tester,
          '12_game_solo_quarter_it_on_round3');

      // --- Custom Targets ON (future islands show ???) ---
      await UITestHelpers.resetServerState();

      await setupAndStartGame(
        tester,
        config,
        numberOfRounds: 9,
        customTargetsEnabled: true,
        playerNames: ['Jack', 'Anne'],
      );

      expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

      await screenshot(binding, tester,
          '13_game_solo_custom_targets_round1');

      print('SCREENSHOT: === PART 4 COMPLETE ===');
      print('SCREENSHOT: File 1 complete.');

      // Overflow trap — dump every layout-error captured by main.dart's
      // FlutterError.onError wrapper (enabled via
      // --dart-define=OVERFLOW_TRAP=1). Throwing surfaces the list in
      // the parallel worker log's `failureDetails` field so we can
      // pinpoint the exact overflowing widget instead of just seeing
      // "Multiple exceptions (N)".
      if (overflowTrapMessages.isNotEmpty) {
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
