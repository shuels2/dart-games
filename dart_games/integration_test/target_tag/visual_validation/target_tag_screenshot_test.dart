import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

// ==========================================================================
// WHY THIS FILE EXISTS
// ==========================================================================
// Target Tag was one of the games with NO screenshot test, so a layout change
// to its player grid could not be visually validated at all. WS04 §4.8 asks
// for the per-row IntrinsicHeight to be replaced with a fixed tile height,
// and CLAUDE.md requires screenshots captured AND evaluated for any visual
// change — which was impossible here until now.
//
// The captures are chosen to exercise the GRID specifically, because that is
// what the change touches: 2 players (one row, short), 5 players (one full
// row), 6 players (TWO rows — the case IntrinsicHeight was equalising), and
// a mid-turn state where tile content differs in height between tiles.
//
// ==========================================================================
// HELPER METHODS — defined FULLY inline per CLAUDE.md's screenshot rules.
// Do NOT import _helpers.dart or shared/dart_throw_helpers.dart here.
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

/// Take screenshot with extra pumps so rendering is current.
/// CRITICAL: uses binding.takeScreenshot() — requires the
/// test_driver/screenshot_test.dart driver. Never pumpAndSettle() here: the
/// screen runs continuous animations and would never settle.
Future<void> screenshot(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  print('SCREENSHOT: Taking screenshot: $name');
  await binding.takeScreenshot(name);
}

Future<void> startWith(
  WidgetTester tester,
  GameUIConfig config,
  List<String> names,
) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await SettingsHelpers.setTargetTagShieldMax(tester, 3);
  for (final n in names) {
    await UITestHelpers.addPlayer(tester, n, config);
  }
  await UITestHelpers.startGame(tester, config);
  await PumpSequences.fullRebuild(tester);
}

// ==========================================================================
// MAIN TEST — ONE testWidgets, per the screenshot-test protocol.
// ==========================================================================

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = GameUIConfig.targetTag();

  group('Target Tag - Screenshot Capture', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('Full screenshot flow', (WidgetTester tester) async {
      // === PART 1: two players — single short row ===
      await startWith(tester, config, ['Alice', 'Bob']);
      await screenshot(binding, tester, 'tt_01_grid_2players');

      // Mid-turn: one tile now shows dart segments while the other does not,
      // which is exactly the height difference IntrinsicHeight was equalising.
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await screenshot(binding, tester, 'tt_02_grid_2players_midturn');

      // === PART 2: five players — one FULL row ===
      await UITestHelpers.resetServerState();
      await startWith(
          tester, config, ['Alice', 'Bob', 'Carol', 'Dan', 'Erin']);
      await screenshot(binding, tester, 'tt_03_grid_5players_full_row');

      // === PART 3: six players — TWO rows, the case the change affects ===
      await UITestHelpers.resetServerState();
      await startWith(tester, config,
          ['Alice', 'Bob', 'Carol', 'Dan', 'Erin', 'Frank']);
      await screenshot(binding, tester, 'tt_04_grid_6players_two_rows');

      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await screenshot(binding, tester, 'tt_05_grid_6players_midturn');
    });
  });
}
