import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.carnivalDerby();

// ==================== DELEGATES TO SHARED HELPERS ====================

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> throwOuterBullViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwOuterBullViaMock(tester);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> setTargetScore(WidgetTester tester, int targetScore) =>
    GameSetupHelpers.setCarnivalDerbyTargetScoreSlider(tester, targetScore);

// ==================== GAME-SPECIFIC HELPERS ====================

Future<void> navigateToCarnivalDerbyMenu(WidgetTester tester) async {
  await UITestHelpers.resetServerState();
  await UITestHelpers.navigateToGameMenu(tester, config);
  expect(find.textContaining('Target score:'), findsOneWidget);
}

Future<void> togglePerfectFinish(WidgetTester tester) async {
  final yesButton = find.text('Yes');
  await tester.ensureVisible(yesButton.first);
  await tester.pump();
  await tester.tap(yesButton.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

Future<void> startGame(WidgetTester tester) async {
  await UITestHelpers.startGame(tester, config);
  expect(find.text('Carnival Derby Race'), findsOneWidget);
}

Future<void> completeGameToVictory(WidgetTester tester) async {
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await clickDartsRemoved(tester);

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}

Future<void> openEditScore(WidgetTester tester) async {
  final editButton = config.getEditScoreButton();
  expect(editButton, findsOneWidget);
  await tester.tap(editButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  expect(find.text('Update score'), findsOneWidget);
}

Future<void> setDartInEditScore(WidgetTester tester, int dartIndex, String ring, {int? number}) async {
  final ringButton = find.text(ring);
  if (ringButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(ringButton.first);
    await tester.pump();
    await tester.tap(ringButton.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
  }

  if (number != null && ring != 'Bullseye' && ring != 'Outer bull (25)' && ring != 'Miss') {
    final numberText = find.descendant(
      of: find.byType(Dialog),
      matching: find.text(number.toString()),
    );
    final actualIndex = dartIndex + 1;
    if (numberText.evaluate().length > actualIndex) {
      await tester.ensureVisible(numberText.at(actualIndex));
      await tester.pump();
      await tester.tap(numberText.at(actualIndex), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
    }
  }
}

Future<void> updateScore(WidgetTester tester) async {
  final updateButton = ElementFinders.getEditScoreSaveButton();
  await tester.tap(updateButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  expect(find.text('Update score'), findsNothing);
}

int getCurrentPlayerScore(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
  final currentPlayerId = horseRaceProvider.getCurrentPlayerId();
  if (currentPlayerId == null) return 0;
  return horseRaceProvider.getPlayerScore(currentPlayerId);
}

bool hasWinner(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
  return horseRaceProvider.hasWinner;
}

bool currentPlayerBusted(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
  return horseRaceProvider.currentPlayerBusted;
}

int getPlayerCount(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
  return playerProvider.allPlayers.length;
}

int getSelectedPlayerCount(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
  return playerProvider.selectedPlayers.length;
}

void verifyDartDisplay(WidgetTester tester, String d1, String d2, String d3) {
  expect(find.text('D1'), findsOneWidget);
  if (d1 != '-') {
    expect(find.text(d1), findsWidgets, reason: 'Expected D1 score to show "$d1"');
  }
  expect(find.text('D2'), findsOneWidget);
  if (d2 != '-') {
    expect(find.text(d2), findsWidgets, reason: 'Expected D2 score to show "$d2"');
  }
  expect(find.text('D3'), findsOneWidget);
  if (d3 != '-') {
    expect(find.text(d3), findsWidgets, reason: 'Expected D3 score to show "$d3"');
  }
}

void verifyGameSettings(WidgetTester tester, int targetScore, bool perfectFinish) {
  expect(find.text('Race to $targetScore points'), findsOneWidget);
  final expectedText = perfectFinish
      ? 'Perfect Finish Required'
      : 'Perfect Finish Not Required';
  expect(find.text(expectedText), findsOneWidget);
}

void verifyCurrentPlayerScoreDisplay(WidgetTester tester, int currentScore, int targetScore) {
  expect(
    find.text('Score: $currentScore / $targetScore'),
    findsOneWidget,
    reason: 'Expected current player section to show "Score: $currentScore / $targetScore"',
  );
}

void verifyRaceTrackScore(WidgetTester tester, int currentScore, int targetScore) {
  expect(
    find.text('$currentScore / $targetScore'),
    findsWidgets,
    reason: 'Expected race track to show "$currentScore / $targetScore"',
  );
}
