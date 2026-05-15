// integration_test/tiki_golf/randomization/_helpers.dart
//
// Shared helpers for Tiki Golf randomization tests.
// Tests verify that hole targets and hole image paths are randomized per game
// and that the game screen correctly reflects the provider's randomized state.
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

Future<void> setupAndStartGame(
  WidgetTester tester, {
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      playerNames: playerNames ?? ['Player A', 'Player B'],
    );

// ===== RANDOMIZATION-SPECIFIC HELPERS =====

/// Get hole targets for the current game (length-9 list, 0-indexed).
List<int> getHoleTargets(WidgetTester tester) {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);
  return List<int>.from(provider.currentGame?.holeTargets ?? []);
}

/// Get hole image paths for the current game (length-9 list, 0-indexed).
List<String> getHoleImagePaths(WidgetTester tester) {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);
  return List<String>.from(provider.currentGame?.holeImagePaths ?? []);
}

/// Advance hole: throw a hit on the target for each active player, then takeout.
/// Repeats for all players in a 2-player game to advance one hole.
Future<void> completeHoleForAllPlayers(WidgetTester tester) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);
  final game = provider.currentGame;
  if (game == null) return;

  for (int i = 0; i < game.playerIds.length; i++) {
    final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
    final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }
}
