import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';

/// Shared configuration for all Carnival Derby UI tests
final config = GameUIConfig.carnivalDerby();

// ==================== MOCK API DART THROWING HELPERS ====================

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

/// Simulate hitting bullseye (50 points) using mock API
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

/// Simulate hitting outer bull (25 points) using mock API
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

/// Simulate missing the dartboard using mock API
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
    await PumpSequences.simpleUpdate(tester);
  }
}

// ==================== HELPER FUNCTIONS ====================

/// Navigate to Carnival Derby menu using shared helper
Future<void> navigateToCarnivalDerbyMenu(WidgetTester tester) async {
  await UITestHelpers.resetServerState();
  await UITestHelpers.navigateToGameMenu(tester, config);

  // Verify we're on the menu screen
  expect(find.textContaining('Target score:'), findsOneWidget);
}

/// Set target score by programmatically calling the slider's onChanged callback
/// Target score range: 20-250, divisions: 46 (step size = 5)
Future<void> setTargetScore(WidgetTester tester, int targetScore) async {
  final sliderFinder = find.byType(Slider);
  expect(sliderFinder, findsOneWidget);

  // Get the slider widget
  Slider sliderWidget = tester.widget<Slider>(sliderFinder);
  final currentValue = sliderWidget.value.toInt();

  if (currentValue == targetScore) {
    return; // Already at target value
  }

  // Programmatically call the slider's onChanged callback with the target value
  if (sliderWidget.onChanged != null) {
    sliderWidget.onChanged!(targetScore.toDouble());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();
  }

  // Extra pumps to ensure UI is fully updated
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

/// Toggle Perfect Finish mode (Radio buttons: Yes/No)
Future<void> togglePerfectFinish(WidgetTester tester) async {
  // Find and tap the "Yes" radio button for Perfect Finish mode
  final yesButton = find.text('Yes');
  await tester.ensureVisible(yesButton.first);
  await tester.pump();
  await tester.tap(yesButton.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

/// Start the game using shared helper
Future<void> startGame(WidgetTester tester) async {
  await UITestHelpers.startGame(tester, config);

  // Verify we're on the game screen
  expect(find.text('Carnival Derby Race'), findsOneWidget);
}

/// Click DARTS REMOVED button on emulator
Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }
}

/// Complete a game to victory with target score 180 (3x T20)
/// Assumes game is already started with target score 180
Future<void> completeGameToVictory(WidgetTester tester) async {
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await clickDartsRemoved(tester);

  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}

/// Open edit score dialog
Future<void> openEditScore(WidgetTester tester) async {
  final editButton = config.getEditScoreButton();
  expect(editButton, findsOneWidget);
  await tester.tap(editButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();

  // Verify dialog opened
  expect(find.text('Update score'), findsOneWidget);
}

/// Set dart in edit score dialog
/// dartIndex: 0, 1, or 2 for D1, D2, D3
/// ring: 'Single (inner)', 'Double', 'Triple', 'Bullseye', 'Outer bull (25)', 'Miss', 'Single (outer)'
/// number: 1-20 (ignored for Bullseye, Outer bull, Miss)
Future<void> setDartInEditScore(WidgetTester tester, int dartIndex, String ring, {int? number}) async {
  // Tap the ring button
  final ringButton = find.text(ring);
  if (ringButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(ringButton.first);
    await tester.pump();
    await tester.tap(ringButton.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
  }

  // If number is needed, tap the number button.
  // The score display at the top shows the number too, so it's always at index 0.
  // Dart buttons (D1, D2, D3) are at indices 1, 2, 3, so we use dartIndex+1.
  if (number != null && ring != 'Bullseye' && ring != 'Outer bull (25)' && ring != 'Miss') {
    final numberText = find.descendant(
      of: find.byType(Dialog),
      matching: find.text(number.toString()),
    );
    // Skip the first match (score display) by using dartIndex+1
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

/// Update score (click Update button in edit dialog)
Future<void> updateScore(WidgetTester tester) async {
  final updateButton = ElementFinders.getEditScoreSaveButton();
  await tester.tap(updateButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();

  // Verify dialog closed
  expect(find.text('Update score'), findsNothing);
}

/// Get current player score from provider
int getCurrentPlayerScore(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
  final currentPlayerId = horseRaceProvider.getCurrentPlayerId();
  if (currentPlayerId == null) return 0;
  return horseRaceProvider.getPlayerScore(currentPlayerId);
}

/// Check if game has winner
bool hasWinner(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
  return horseRaceProvider.hasWinner;
}

/// Check if current player busted (Perfect Finish mode)
bool currentPlayerBusted(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final horseRaceProvider = Provider.of<HorseRaceProvider>(context, listen: false);
  return horseRaceProvider.currentPlayerBusted;
}

/// Get player count from PlayerProvider
int getPlayerCount(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
  return playerProvider.allPlayers.length;
}

/// Get selected player count
int getSelectedPlayerCount(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
  return playerProvider.selectedPlayers.length;
}

/// Verify dart display text (D1, D2, D3 indicators on screen)
/// The UI shows: D1 label above the score, D2 label above the score, D3 label above the score
/// Expected values: '20', '40', 'Miss', '50', '25', '-' (for un-thrown), etc.
void verifyDartDisplay(WidgetTester tester, String d1, String d2, String d3) {
  // Verify D1 label exists
  expect(find.text('D1'), findsOneWidget);
  // Verify D1 score (separate Text widget below the label)
  if (d1 != '-') {
    expect(find.text(d1), findsWidgets, reason: 'Expected D1 score to show "$d1"');
  }

  // Verify D2 label exists
  expect(find.text('D2'), findsOneWidget);
  // Verify D2 score (separate Text widget below the label)
  if (d2 != '-') {
    expect(find.text(d2), findsWidgets, reason: 'Expected D2 score to show "$d2"');
  }

  // Verify D3 label exists
  expect(find.text('D3'), findsOneWidget);
  // Verify D3 score (separate Text widget below the label)
  if (d3 != '-') {
    expect(find.text(d3), findsWidgets, reason: 'Expected D3 score to show "$d3"');
  }
}

/// Verify game settings are displayed correctly on game screen
/// targetScore: expected target score (20-250)
/// perfectFinish: true if Perfect Finish mode is ON, false if OFF
void verifyGameSettings(WidgetTester tester, int targetScore, bool perfectFinish) {
  // Verify target score display
  expect(find.text('Race to $targetScore points'), findsOneWidget);

  // Verify Perfect Finish mode display
  final expectedText = perfectFinish
      ? 'Perfect Finish Required'
      : 'Perfect Finish Not Required';
  expect(find.text(expectedText), findsOneWidget);
}

/// Verify current player score is displayed in the current player section
/// Shows as "Score: X / Y" where X is current score, Y is target
void verifyCurrentPlayerScoreDisplay(WidgetTester tester, int currentScore, int targetScore) {
  expect(
    find.text('Score: $currentScore / $targetScore'),
    findsOneWidget,
    reason: 'Expected current player section to show "Score: $currentScore / $targetScore"',
  );
}

/// Verify player score is displayed on the race track
/// Shows as "X / Y" where X is current score, Y is target
/// This appears in each player's race lane
void verifyRaceTrackScore(WidgetTester tester, int currentScore, int targetScore) {
  expect(
    find.text('$currentScore / $targetScore'),
    findsWidgets,
    reason: 'Expected race track to show "$currentScore / $targetScore"',
  );
}
