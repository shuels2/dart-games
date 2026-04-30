import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/models/monster_mash_game.dart';

import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

// Game configuration for Monster Mash
final config = GameUIConfig.monsterMash();

// ===== MOCK API DART THROWING HELPERS =====

/// Get MockScoliaApiService from the widget tree
MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

/// Simulate hitting a specific dartboard number using mock API
Future<void> throwDartViaMock(WidgetTester tester, int number, {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: number * (multiplier == 'double' ? 2 : multiplier == 'triple' ? 3 : 1),
      multiplier: multiplier,
      playerName: 'Player',
      baseScore: number,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Simulate throwing a bullseye (50 points)
Future<void> throwBullseyeViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 50,
      multiplier: 'bullseye',
      playerName: 'Player',
      baseScore: 50,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Simulate throwing an outer bull (25 points)
Future<void> throwOuterBullViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 25,
      multiplier: 'outer_bull',
      playerName: 'Player',
      baseScore: 25,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Simulate a miss
Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'single',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Click DARTS REMOVED button on emulator
Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Set the active buff programmatically on the provider's current game
Future<void> setActiveBuff(WidgetTester tester, BonusBuff buff) async {
  final provider = ProviderHelpers.getMonsterMashProvider(tester);
  provider.currentGame!.activeBuff = buff;
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  provider.notifyListeners();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}
