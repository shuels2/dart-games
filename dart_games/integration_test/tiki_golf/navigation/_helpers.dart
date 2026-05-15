// integration_test/tiki_golf/navigation/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf navigation tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/settings_helpers.dart';

final config = GameUIConfig.tikiGolf();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> setupAndStartGame(
  WidgetTester tester, {
  List<String>? playerNames,
  int maxStrokes = 3,
  bool mulliganEnabled = false,
}) =>
    GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      playerNames: playerNames,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
    );

Future<void> setMaxStrokes(WidgetTester tester, int maxStrokes) =>
    SettingsHelpers.setTikiGolfMaxStrokes(tester, maxStrokes);

Future<void> toggleMulligan(WidgetTester tester) =>
    SettingsHelpers.toggleTikiGolfMulligan(tester);

// ===== GAME-SPECIFIC HELPERS =====

/// Get the current hole's target number from the provider.
int getCurrentHoleTarget(WidgetTester tester) {
  final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
  return ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
}

/// Drive a 2-player solo game to completion (all 9 holes, all birdies).
///
/// Every player hits the hole's target on dart 1. After all 9 holes,
/// hasWinner becomes true and the results screen navigates into view.
Future<void> playGameToCompletion(WidgetTester tester) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);

  while (!provider.hasWinner) {
    final target = getCurrentHoleTarget(tester);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Wait for results navigation (3s victory delay + animation)
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
}
