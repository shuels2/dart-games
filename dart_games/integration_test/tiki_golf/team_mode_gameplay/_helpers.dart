// integration_test/tiki_golf/team_mode_gameplay/_helpers.dart
//
// Shared helpers for Tiki Golf team mode gameplay tests.
// All tests use Team mode with various player/team configurations.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

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

/// Tiki Golf: simulate takeout via MockScoliaApiService.
Future<void> clickDartsRemoved(WidgetTester tester) async {
  final mockApi = DartThrowHelpers.getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateTakeoutFinished();
    await PumpSequences.simpleUpdate(tester);
  } else {
    await DartThrowHelpers.clickDartsRemoved(tester);
  }
}

/// Set up and start a team mode game (Random assignment by default).
Future<void> setupAndStartTeamGame(
  WidgetTester tester, {
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  bool manualAssignment = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      teamMode: true,
      manualAssignment: manualAssignment,
      playerNames: playerNames,
    );

// ===== TIKI GOLF TEAM GAMEPLAY HELPERS =====

/// Get the current hole's target number from the provider.
int getCurrentHoleTarget(WidgetTester tester) {
  final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
  return ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
}

/// Hit the current hole's target (birdie).
Future<void> throwTargetDart(WidgetTester tester) async {
  final target = getCurrentHoleTarget(tester);
  await throwDartViaMock(tester, target);
}

/// Complete the current player's turn with a Splash.
Future<void> splashAndTakeout(WidgetTester tester, {int maxStrokes = 3}) async {
  for (int i = 0; i < maxStrokes; i++) {
    await throwMissViaMock(tester);
  }
  await clickDartsRemoved(tester);
}

/// Complete one full hole for all players in a 2-team game.
/// Each player on team 1 hits, then team 2 players miss (or vice versa).
Future<void> completeOneHoleWithBirdiesForAll(WidgetTester tester,
    {int playerCount = 4}) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);
  final game = provider.currentGame;
  if (game == null) return;

  for (int i = 0; i < playerCount; i++) {
    final target = getCurrentHoleTarget(tester);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }
}
