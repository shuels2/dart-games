// integration_test/tiki_golf/gameplay/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf gameplay tests.
// Game-specific helpers: driving to a specific hole, splash sequences, etc.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';

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
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  bool teamMode = false,
  bool manualAssignment = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      teamMode: teamMode,
      manualAssignment: manualAssignment,
      playerNames: playerNames,
    );

// ===== TIKI GOLF-SPECIFIC HELPERS =====

/// Get the current hole's target number from the provider.
int getCurrentHoleTarget(WidgetTester tester) {
  final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
  return ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
}

/// Hit the current hole's target (birdie if first dart, otherwise varies).
///
/// Uses the provider to discover the target number, then throws it.
Future<void> throwTargetDart(WidgetTester tester) async {
  final target = getCurrentHoleTarget(tester);
  await throwDartViaMock(tester, target);
}

/// Throw all [maxStrokes] darts as misses (Splash). Does NOT simulate takeout.
Future<void> throwAllMissesToSplash(WidgetTester tester,
    {int maxStrokes = 3}) async {
  for (int i = 0; i < maxStrokes; i++) {
    await throwMissViaMock(tester);
  }
}

/// Complete the current player's turn with a Splash and simulate takeout.
Future<void> splashAndTakeout(WidgetTester tester, {int maxStrokes = 3}) async {
  await throwAllMissesToSplash(tester, maxStrokes: maxStrokes);
  await clickDartsRemoved(tester);
}
