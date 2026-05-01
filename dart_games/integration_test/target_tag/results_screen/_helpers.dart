import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/providers/player_provider.dart';

import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

// Game configuration for Target Tag
final config = GameUIConfig.targetTag();

// ==========================================================================
// MOCK API DART THROWING HELPERS
// ==========================================================================

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

/// Click DARTS REMOVED button on emulator
Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

// ==========================================================================
// HELPER FUNCTIONS
// ==========================================================================

/// Set shield max value by programmatically calling the slider's onChanged callback
/// Shield max range: 1-10, divisions: 9
Future<void> setShieldMax(WidgetTester tester, int shieldMax) async {
  final sliderFinder = find.byType(Slider);
  expect(sliderFinder, findsWidgets); // May have multiple sliders

  // Find the Shield Max slider specifically
  final shieldMaxLabel = find.textContaining('Shield Max:');
  expect(shieldMaxLabel, findsOneWidget);

  // Find the slider that's a sibling/descendant of the Shield Max container
  final shieldMaxContainer = find.ancestor(
    of: shieldMaxLabel,
    matching: find.byType(Container),
  );

  final shieldMaxSlider = find.descendant(
    of: shieldMaxContainer.first,
    matching: find.byType(Slider),
  );
  expect(shieldMaxSlider, findsOneWidget);

  // Get the slider widget
  Slider sliderWidget = tester.widget<Slider>(shieldMaxSlider);
  final currentValue = sliderWidget.value.toInt();

  if (currentValue == shieldMax) {
    return; // Already at target value
  }

  // Programmatically call the slider's onChanged callback with the target value
  if (sliderWidget.onChanged != null) {
    sliderWidget.onChanged!(shieldMax.toDouble());
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

/// Extract target number from a player's tile on game screen
String? getTargetNumberFromPlayerTile(WidgetTester tester, String playerName) {
  final playerFinder = find.text(playerName);
  if (playerFinder.evaluate().isEmpty) return null;

  final playerTileContainer = find.ancestor(
    of: playerFinder.first,
    matching: find.byType(Container),
  );
  if (playerTileContainer.evaluate().isEmpty) return null;

  final allTextInTile = find.descendant(
    of: playerTileContainer.first,
    matching: find.byType(Text),
  );

  final targetLabel = find.descendant(
    of: playerTileContainer.first,
    matching: find.text('Target number: '),
  );
  if (targetLabel.evaluate().isEmpty) return null;

  int targetLabelIndex = -1;
  for (int i = 0; i < allTextInTile.evaluate().length; i++) {
    final textWidget = allTextInTile.evaluate().elementAt(i).widget as Text;
    if (textWidget.data == 'Target number: ') {
      targetLabelIndex = i;
      break;
    }
  }

  if (targetLabelIndex >= 0 && targetLabelIndex + 1 < allTextInTile.evaluate().length) {
    final targetNumWidget = allTextInTile.evaluate().elementAt(targetLabelIndex + 1).widget as Text;
    return targetNumWidget.data ?? '';
  }
  return null;
}

/// Quickly complete a solo game and reach results screen
/// Player 1 gets tagged in with triple, Player 2 builds 2 shields, Player 1 eliminates Player 2
/// Uses dynamic target lookup and 3 shields max
Future<void> completeGameToVictory(WidgetTester tester, String player1Name, String player2Name) async {
  // Get dynamic target numbers for both players
  final target1Str = getTargetNumberFromPlayerTile(tester, player1Name);
  final target2Str = getTargetNumberFromPlayerTile(tester, player2Name);

  if (target1Str == null || target2Str == null) {
    throw Exception('Could not find target numbers for players');
  }

  final target1 = int.parse(target1Str);
  final target2 = int.parse(target2Str);

  // Turn 1: Player 1 throws TRIPLE on own target = 3 shields = TAGGED IN!
  await throwDartViaMock(tester, target1, multiplier: 'triple'); // 3 shields - TAGGED IN!
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 2: Player 2 builds 2 shields (not tagged in yet - need 3)
  await throwDartViaMock(tester, target2, multiplier: 'single'); // Shield 1
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, target2, multiplier: 'single'); // Shield 2
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 3: Player 1 attacks Player 2's target (3 hits: 2->1->0, Player 2 vulnerable)
  await throwDartViaMock(tester, target2, multiplier: 'single'); // Attack! (shields 2->1)
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, target2, multiplier: 'single'); // Attack! (shields 1->0, vulnerable)
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, target2, multiplier: 'single'); // Attack! (shields 0, eliminated next hit)
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 4: Player 2 misses (still vulnerable at 0 shields)
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 5: Player 1 eliminates Player 2 with hit at 0 shields
  await throwDartViaMock(tester, target2, multiplier: 'single'); // Elimination!
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);

  // Extended wait for victory screen and confetti animation
  await tester.pump(const Duration(seconds: 4)); // Wait for victory announcements
  await tester.pump();
  await tester.pump(const Duration(seconds: 3)); // Wait for navigation to results screen
  await tester.pump();
  await tester.pump(const Duration(seconds: 2)); // Wait for confetti controller to initialize
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}

/// Complete a team mode game and reach results screen
/// Teams share targets - Team 1 gets tagged in, then attacks Team 2 target
Future<void> completeGameToVictoryTeamMode(WidgetTester tester, String team1Player, String team2Player) async {
  // Access the provider to get team and game information
  final provider = Provider.of<TargetTagProvider>(tester.element(find.byType(Scaffold).first), listen: false);
  final game = provider.currentGame!;

  // Get current player (first in turn order - should be Team 1 Player 1)
  final currentPlayerId = game.getCurrentPlayerId();
  final currentTeamId = game.playerToTeam![currentPlayerId]!;
  final teamTargetNum = game.targetNumbers[currentPlayerId]!;

  // Turn 1 (Team1 Player1): Get tagged in immediately with triple on own target
  await throwDartViaMock(tester, teamTargetNum, multiplier: 'triple'); // 3 shields - TAGGED IN!
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Find opponent team target (any player not on current team)
  int? opponentTargetNum;
  final playerProvider = Provider.of<PlayerProvider>(tester.element(find.byType(Scaffold).first), listen: false);
  final allPlayers = playerProvider.allPlayers;
  final currentTeamPlayers = game.teamPlayers![currentTeamId]!;

  for (final player in allPlayers) {
    if (!currentTeamPlayers.contains(player.id)) {
      opponentTargetNum = game.targetNumbers[player.id];
      break;
    }
  }

  if (opponentTargetNum == null) {
    throw Exception('Could not find opponent target number');
  }

  // Turn 2 (Team2 Player1): Miss all 3 throws - stay at 0 shields
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss'); // Miss
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 3 (Team1 Player2): Attack opponent (Team 2 at 0 shields, eliminate with 1 hit)
  await throwDartViaMock(tester, opponentTargetNum, multiplier: 'single'); // Elimination!
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Extended wait for team mode victory processing and results screen
  await tester.pump(const Duration(seconds: 5)); // Victory announcements
  await tester.pump();
  await tester.pump(const Duration(seconds: 3)); // Navigation to results screen
  await tester.pump();
  await tester.pump(const Duration(seconds: 2)); // Confetti controller initialization
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // Final render
  await tester.pump();
}
