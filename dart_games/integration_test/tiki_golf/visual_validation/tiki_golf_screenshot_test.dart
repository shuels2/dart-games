// integration_test/tiki_golf/visual_validation/tiki_golfscreenshot_test.dart
//
// Screenshot test for Tiki Golf — captures all spec Section 12C visual states.
// Driver: test_driver/screenshot_test.dart (NEVER integration_test.dart)
// DO NOT use pumpAndSettle() — splash CircularProgressIndicator prevents settling.
//
// Structure: ONE `testWidgets` block containing all screenshot capture phases.
// Multiple `testWidgets` in a screenshot test break the
// `integration_test_driver_extended` request/response protocol under
// `-d web-server` (parallel runner) — the driver protocol expects one test
// per file, and 10+ separate testWidgets cause DWDS/webdriver session
// disconnects that surface as `SocketException` at `WebDriver.quit`.
// Match the structure of every other game's screenshot test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

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
// other game's screenshot test (Gladiator, Pirate's Grid, Lunar Lander,
// Reef Royale, Clockwork Quest) inlines helper BODIES — talking directly to
// `mock_scolia_api_service` — and passes in parallel. Match that pattern.

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

/// Simulate takeout (darts removed) via the mock API. Tiki Golf fires the
/// RemoveDartsModal only on turn-end; this helper confirms
/// `shouldPromptTakeout` before triggering so screenshots don't try to
/// dismiss a modal that never appeared.
Future<void> simulateTakeout(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();

  final provider = ProviderHelpers.getTikiGolfProvider(tester);
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
  final config = GameUIConfig.tikiGolf();

  group('Tiki Golf - Screenshot Capture', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    // Single continuous flow capturing all spec §12C visual states.
    // See file header for why this is one testWidgets instead of many.
    testWidgets('Full screenshot flow', (WidgetTester tester) async {
      // ======================================================================
      // PART 1: MENU SCREEN STATES
      // ======================================================================
      print('SCREENSHOT: === PART 1: MENU SCREEN STATES ===');

      // --- Solo default (2 players, default settings) ---
      await UITestHelpers.navigateToGameMenu(tester, config);
      print('SCREENSHOT: Navigated to menu');

      await UITestHelpers.addPlayer(tester, 'Moana', config);
      await UITestHelpers.addPlayer(tester, 'Maui', config);

      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      expect(selectedPlayers.length, greaterThanOrEqualTo(2));
      final p1Id = selectedPlayers[0].id;
      final p2Id = selectedPlayers[1].id;
      print('SCREENSHOT: P1=$p1Id P2=$p2Id');

      await screenshot(binding, tester, '01_menu_solo_default_2players');

      // --- Solo ready (4 players, Max Strokes 4) ---
      await UITestHelpers.addPlayer(tester, 'Lilo', config);
      await UITestHelpers.addPlayer(tester, 'Stitch', config);

      await SettingsHelpers.setTikiGolfMaxStrokes(tester, 4);
      await screenshot(binding, tester, '02_menu_solo_ready_4players_maxstrokes4');

      // Reset max strokes
      await SettingsHelpers.setTikiGolfMaxStrokes(tester, 3);

      // --- Team mode toggled (Random default, no team boxes) ---
      await SettingsHelpers.setTikiGolfGameModeTeam(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '03_menu_team_random_default');

      // --- Team Manual 4 players (4 team boxes + per-player crests + Team Count) ---
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '04_menu_team_manual_4players_team_boxes');

      // --- Team Random 4 players (single list, no team boxes) ---
      await SettingsHelpers.setTikiGolfAssignmentRandom(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '05_menu_team_random_4players_no_boxes');

      // --- Toggling Team Assignment Manual → Random (two back-to-back shots) ---
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '06_menu_toggle_to_manual');

      await SettingsHelpers.setTikiGolfAssignmentRandom(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '07_menu_toggle_back_to_random');

      // --- Solo mode + Team Assignment greyed out ---
      await SettingsHelpers.setTikiGolfGameModeSolo(tester);
      await PumpSequences.fullRebuild(tester);
      await screenshot(binding, tester, '08_menu_solo_team_assignment_greyed_out');

      // --- Team mode + 3 players + Team Count = 2 (minimum config) ---
      await SettingsHelpers.setTikiGolfGameModeTeam(tester);
      await PumpSequences.fullRebuild(tester);
      await SettingsHelpers.setTikiGolfAssignmentManual(tester);
      await PumpSequences.fullRebuild(tester);
      // Team Count = 2: find the dropdown and select 2
      final teamCntFinder = ElementFinders.getTikiGolfTeamCountDropdown();
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
      await screenshot(binding, tester, '09_menu_team_manual_3players_team_count_2');

      print('SCREENSHOT: === PART 1 COMPLETE ===');
    });
  });
}
