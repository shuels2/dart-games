import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

// Game configuration for Target Tag
final config = GameUIConfig.targetTag();

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

/// Get current player's target number from provider
int getCurrentPlayerTargetNumber(WidgetTester tester) {
  final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
  if (currentPlayerId == null) return 20;
  final targetNumber = ProviderHelpers.getTargetTagPlayerTarget(tester, currentPlayerId);
  return targetNumber ?? 20;
}

/// Enable Hero Bonus by tapping the hero bonus switch
Future<void> enableHeroBonus(WidgetTester tester) async {
  await SettingsHelpers.toggleTargetTagHeroBonus(tester);
  await PumpSequences.simpleUpdate(tester);
}

/// Enable Team Mode by tapping the team mode switch
Future<void> enableTeamMode(WidgetTester tester) async {
  await SettingsHelpers.toggleTargetTagTeamMode(tester);
  await PumpSequences.fullRebuild(tester);
}

/// Navigate back to menu from game screen
Future<void> navigateBackToMenu(WidgetTester tester) async {
  // Use the proper keyed back button
  final backButton = find.byKey(TargetTagGameKeys.backButton);

  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await PumpSequences.navigation(tester);

    // Handle Save Game Modal (appears when leaving active game)
    final dontSaveButton = find.byKey(SaveGameModalKeys.dontSaveButton);
    if (dontSaveButton.evaluate().isNotEmpty) {
      await tester.tap(dontSaveButton);
      await PumpSequences.dialogClose(tester);
    }

    // Handle Resume Game Modal (appears when returning to menu with saved games)
    final startNewButton = find.byKey(ResumeGameModalKeys.startNewGameButton);
    if (startNewButton.evaluate().isNotEmpty) {
      await tester.tap(startNewButton);
      await PumpSequences.dialogClose(tester);
    }
  }
}

/// Extract hero buff value from active panel using key
/// Returns the buff value found in the buff value widget
String? getHeroBuffFromActivePanel(WidgetTester tester) {
  final buffValueFinder = find.byKey(TargetTagGameKeys.activePlayerBuffValue);

  if (buffValueFinder.evaluate().isEmpty) {
    return null;
  }

  final textWidget = tester.widget<Text>(buffValueFinder.first);
  final buffValue = textWidget.data ?? '';
  return buffValue.isNotEmpty ? buffValue : null;
}

/// Verify dart indicator border color
/// Dart indicators are identified by TargetTagGameKeys constants
void verifyDartIndicatorColor(WidgetTester tester, Key dartKey, int expectedColorValue) {
  final indicatorFinder = find.byKey(dartKey);
  expect(indicatorFinder, findsOneWidget);

  final container = tester.widget<Container>(indicatorFinder);
  final decoration = container.decoration as BoxDecoration?;
  expect(decoration, isNotNull);

  expect(decoration!.border, isNotNull);

  final border = decoration!.border as Border;
  final actualColor = border.top.color.value;

  expect(actualColor, expectedColorValue,
      reason: 'Dart $dartKey should have border color 0x${expectedColorValue.toRadixString(16)}');
}

/// Verify game settings panel content
void verifyGameSettingsPanel(WidgetTester tester, {
  required bool hasShieldMax,
  required bool hasTargetScore,
  required bool hasTeamMode,
  required bool hasHeroBonus,
}) {
  if (hasShieldMax) {
    expect(find.textContaining('Shield Max:'), findsOneWidget);
  }
  if (hasTargetScore) {
    expect(find.textContaining('Target Score:'), findsOneWidget);
  }
  if (hasTeamMode) {
    expect(find.textContaining('Team mode'), findsOneWidget);
  }
  if (hasHeroBonus) {
    expect(find.textContaining('Hero Bonus'), findsOneWidget);
  }
}
