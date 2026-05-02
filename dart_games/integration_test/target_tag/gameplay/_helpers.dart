import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.targetTag();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

int getCurrentPlayerTargetNumber(WidgetTester tester) =>
    GameSetupHelpers.getCurrentPlayerTargetNumber(tester);

Future<void> enableHeroBonus(WidgetTester tester) async {
  await SettingsHelpers.toggleTargetTagHeroBonus(tester);
  await PumpSequences.simpleUpdate(tester);
}

Future<void> enableTeamMode(WidgetTester tester) =>
    GameSetupHelpers.enableTargetTagTeamMode(tester);

// ===== GAME-SPECIFIC HELPERS =====

Future<void> navigateBackToMenu(WidgetTester tester) async {
  final backButton = find.byKey(TargetTagGameKeys.backButton);

  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await PumpSequences.navigation(tester);

    final dontSaveButton = find.byKey(SaveGameModalKeys.dontSaveButton);
    if (dontSaveButton.evaluate().isNotEmpty) {
      await tester.tap(dontSaveButton);
      await PumpSequences.dialogClose(tester);
    }

    final startNewButton = find.byKey(ResumeGameModalKeys.startNewGameButton);
    if (startNewButton.evaluate().isNotEmpty) {
      await tester.tap(startNewButton);
      await PumpSequences.dialogClose(tester);
    }
  }
}

String? getHeroBuffFromActivePanel(WidgetTester tester) {
  final buffValueFinder = find.byKey(TargetTagGameKeys.activePlayerBuffValue);

  if (buffValueFinder.evaluate().isEmpty) {
    return null;
  }

  final textWidget = tester.widget<Text>(buffValueFinder.first);
  final buffValue = textWidget.data ?? '';
  return buffValue.isNotEmpty ? buffValue : null;
}

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
