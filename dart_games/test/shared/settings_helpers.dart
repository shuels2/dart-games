import 'dart:convert';
import 'package:flutter/material.dart' show Slider;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/api/api_config.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';

/// Helpers for interacting with game settings controls and test setup.
class SettingsHelpers {
  // ==========================================================================
  // TEST INITIALIZATION HELPERS
  // ==========================================================================

  /// Initialize test settings via the backend API.
  ///
  /// Configures the dartboard for emulator mode by calling the backend server
  /// API. The server must be running before tests start (handled by run_ui_tests.bat).
  static Future<void> initializeSettings({
    bool useEmulator = true,
  }) async {
    // Configure dartboard via the backend API
    final url = Uri.parse(ApiConfig.url('/api/v1/dartboard'));
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': 'Test Dartboard',
        'serialNumber': 'TEST-001',
        'useEmulator': useEmulator,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to initialize dartboard settings via API '
        '(status ${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Create test players with IDs and names
  static List<Player> createTestPlayers(List<String> names) {
    return names
        .map((name) => Player(
              id: 'player_${name.toLowerCase()}',
              name: name,
              createdAt: DateTime.now(),
            ))
        .toList();
  }

  /// Save players via the backend API for test setup.
  ///
  /// Creates each player via POST /api/v1/players.
  static Future<void> savePlayersToApi(List<Player> players) async {
    for (final player in players) {
      final url = Uri.parse(ApiConfig.url('/api/v1/players'));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': player.name,
        }),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to create player "${player.name}" via API '
          '(status ${response.statusCode}): ${response.body}',
        );
      }
    }
  }

  // ==========================================================================
  // TOGGLE HELPERS
  // ==========================================================================

  /// Toggle switch (generic)
  static Future<void> toggleSwitch(WidgetTester tester, Finder switchFinder) async {
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Target Tag: Toggle Team Mode
  static Future<void> toggleTargetTagTeamMode(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getTargetTagTeamModeToggle());
  }

  /// Target Tag: Toggle Hero Bonus
  static Future<void> toggleTargetTagHeroBonus(WidgetTester tester) async {
    final finder = ElementFinders.getTargetTagHeroBonusToggle();
    await tester.ensureVisible(finder);
    await tester.pump();
    await toggleSwitch(tester, finder);
  }

  /// Carnival Derby: Toggle Perfect Finish
  static Future<void> toggleCarnivalDerbyPerfectFinish(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getCarnivalDerbyPerfectFinishToggle());
  }

  /// Monster Mash: Toggle Bonus Buffs
  static Future<void> toggleMonsterMashBonusBuffs(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getMonsterMashBonusBuffsSwitch());
  }

  /// Monster Mash: Toggle Speed Play
  static Future<void> toggleMonsterMashSpeedPlay(WidgetTester tester) async {
    final finder = ElementFinders.getMonsterMashSpeedPlaySwitch();
    await tester.ensureVisible(finder);
    await tester.pump();
    await toggleSwitch(tester, finder);
  }

  /// Monster Mash: Set Health Max (slider)
  ///
  /// Valid values: 10-50
  static Future<void> setMonsterMashHealthMax(
    WidgetTester tester,
    int value,
  ) async {
    final sliderFinder = ElementFinders.getMonsterMashHealthPointsSlider();
    expect(sliderFinder, findsOneWidget);

    Slider sliderWidget = tester.widget<Slider>(sliderFinder);
    if (sliderWidget.onChanged != null) {
      sliderWidget.onChanged!(value.toDouble());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    await PumpSequences.simpleUpdate(tester);

    sliderWidget = tester.widget<Slider>(sliderFinder);
    expect(sliderWidget.value.toInt(), value,
        reason: 'Health Max should be set to $value');
  }

  /// Monster Mash: Set Round Limit (slider)
  ///
  /// Valid values: 3-20
  static Future<void> setMonsterMashRoundLimit(
    WidgetTester tester,
    int value,
  ) async {
    final sliderFinder = ElementFinders.getMonsterMashRoundLimitSlider();
    expect(sliderFinder, findsOneWidget);

    Slider sliderWidget = tester.widget<Slider>(sliderFinder);
    if (sliderWidget.onChanged != null) {
      sliderWidget.onChanged!(value.toDouble());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    await PumpSequences.simpleUpdate(tester);

    sliderWidget = tester.widget<Slider>(sliderFinder);
    expect(sliderWidget.value.toInt(), value,
        reason: 'Round Limit should be set to $value');
  }

  /// Monster Mash: Select player
  static Future<void> selectMonsterMashPlayer(
    WidgetTester tester,
    String playerId,
  ) async {
    await selectPlayer(
      tester,
      playerId,
      ElementFinders.getMonsterMashPlayerTile,
    );
  }

  /// Monster Mash: Full flow to add a player
  static Future<void> addMonsterMashPlayer(
    WidgetTester tester,
    String playerName,
  ) async {
    await openAddPlayerDialog(tester, ElementFinders.getMonsterMashAddPlayerButton());
    await addPlayerViaDialog(tester, playerName);
  }

  /// Reef Royale: Set Game Mode (dropdown)
  ///
  /// Valid values: 'Standard', 'Cursed Tide'
  static Future<void> setReefRoyaleGameMode(
    WidgetTester tester,
    String modeText,
  ) async {
    await setDropdownValue(
      tester,
      ElementFinders.getReefRoyaleGameModeDropdown(),
      modeText,
    );
  }

  /// Reef Royale: Toggle Easy Claim
  static Future<void> toggleReefRoyaleEasyClaim(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getReefRoyaleEasyClaimSwitch());
  }

  /// Reef Royale: Toggle Neighbor Numbers
  static Future<void> toggleReefRoyaleNeighborNumbers(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getReefRoyaleNeighborNumbersSwitch());
  }

  /// Reef Royale: Toggle Random Reefs
  static Future<void> toggleReefRoyaleRandomReefs(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getReefRoyaleRandomReefsSwitch());
  }

  /// Reef Royale: Toggle Bonus Buffs
  static Future<void> toggleReefRoyaleBonusBuffs(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getReefRoyaleBonusBuffsSwitch());
  }

  /// Reef Royale: Toggle Show Hints
  static Future<void> toggleReefRoyaleShowHints(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getReefRoyaleShowHintsSwitch());
  }

  /// Reef Royale: Toggle Speed Play
  static Future<void> toggleReefRoyaleSpeedPlay(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getReefRoyaleSpeedPlaySwitch());
  }

  /// Reef Royale: Set Round Limit (slider)
  ///
  /// Valid values: 5-20
  static Future<void> setReefRoyaleRoundLimit(
    WidgetTester tester,
    int value,
  ) async {
    final sliderFinder = ElementFinders.getReefRoyaleRoundLimitSlider();
    expect(sliderFinder, findsOneWidget);

    Slider sliderWidget = tester.widget<Slider>(sliderFinder);
    if (sliderWidget.onChanged != null) {
      sliderWidget.onChanged!(value.toDouble());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    await PumpSequences.simpleUpdate(tester);

    sliderWidget = tester.widget<Slider>(sliderFinder);
    expect(sliderWidget.value.toInt(), value,
        reason: 'Round Limit should be set to $value');
  }

  /// Reef Royale: Select player
  static Future<void> selectReefRoyalePlayer(
    WidgetTester tester,
    String playerId,
  ) async {
    await selectPlayer(
      tester,
      playerId,
      ElementFinders.getReefRoyalePlayerTile,
    );
  }

  /// Reef Royale: Full flow to add a player
  static Future<void> addReefRoyalePlayer(
    WidgetTester tester,
    String playerName,
  ) async {
    await openAddPlayerDialog(tester, ElementFinders.getReefRoyaleAddPlayerButton());
    await addPlayerViaDialog(tester, playerName);
  }

  // ==========================================================================
  // DROPDOWN HELPERS
  // ==========================================================================

  /// Set dropdown value (generic)
  ///
  /// Opens dropdown and selects item by text
  static Future<void> setDropdownValue(
    WidgetTester tester,
    Finder dropdownFinder,
    String valueText,
  ) async {
    expect(dropdownFinder, findsOneWidget);

    // Tap dropdown to open it
    await tester.tap(dropdownFinder);
    await PumpSequences.dialogOpen(tester);

    // Find and tap the dropdown item
    final itemFinder = find.text(valueText).last;
    expect(itemFinder, findsOneWidget);
    await tester.tap(itemFinder);
    await PumpSequences.dialogClose(tester);
  }

  /// Target Tag: Set Shield Max (slider)
  ///
  /// Valid values: 1-10
  static Future<void> setTargetTagShieldMax(
    WidgetTester tester,
    int value,
  ) async {
    final sliderFinder = ElementFinders.getTargetTagShieldMaxSlider();
    expect(sliderFinder, findsOneWidget);

    // Programmatically call the slider's onChanged callback with the target value
    Slider sliderWidget = tester.widget<Slider>(sliderFinder);
    if (sliderWidget.onChanged != null) {
      sliderWidget.onChanged!(value.toDouble());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    await PumpSequences.simpleUpdate(tester);

    // Verify the value was set correctly
    sliderWidget = tester.widget<Slider>(sliderFinder);
    expect(sliderWidget.value.toInt(), value,
        reason: 'Shield Max should be set to $value');
  }

  /// Carnival Derby: Set Target Score (dropdown)
  ///
  /// Valid values: 101, 201, 301, 501 (as strings)
  static Future<void> setCarnivalDerbyTargetScore(
    WidgetTester tester,
    String targetScore,
  ) async {
    await setDropdownValue(
      tester,
      ElementFinders.getCarnivalDerbyTargetScoreDropdown(),
      targetScore,
    );
  }

  // ==========================================================================
  // BUTTON HELPERS
  // ==========================================================================

  /// Tap button (generic with pump sequence)
  static Future<void> tapButton(WidgetTester tester, Finder buttonFinder) async {
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Target Tag: Tap Start Game button
  static Future<void> tapTargetTagStartGame(WidgetTester tester) async {
    await tester.tap(ElementFinders.getTargetTagStartButton());
    await PumpSequences.navigation(tester);
  }

  /// Carnival Derby: Tap Start Game button
  static Future<void> tapCarnivalDerbyStartGame(WidgetTester tester) async {
    await tester.tap(ElementFinders.getCarnivalDerbyStartButton());
    await PumpSequences.navigation(tester);
  }

  /// Target Tag: Open Assign Teams dialog
  static Future<void> openTargetTagAssignTeamsDialog(WidgetTester tester) async {
    await tester.tap(ElementFinders.getTargetTagAssignTeamsButton());
    await PumpSequences.dialogOpen(tester);
  }

  // ==========================================================================
  // PLAYER SELECTION HELPERS
  // ==========================================================================

  /// Select player by tapping their tile
  static Future<void> selectPlayer(
    WidgetTester tester,
    String playerId,
    Finder Function(String) playerTileFinder,
  ) async {
    final tileFinder = playerTileFinder(playerId);
    expect(tileFinder, findsOneWidget);
    await tester.tap(tileFinder);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Target Tag: Select player
  static Future<void> selectTargetTagPlayer(
    WidgetTester tester,
    String playerId,
  ) async {
    await selectPlayer(
      tester,
      playerId,
      ElementFinders.getTargetTagPlayerTile,
    );
  }

  /// Carnival Derby: Select player
  static Future<void> selectCarnivalDerbyPlayer(
    WidgetTester tester,
    String playerId,
  ) async {
    await selectPlayer(
      tester,
      playerId,
      ElementFinders.getCarnivalDerbyPlayerTile,
    );
  }

  // ==========================================================================
  // DIALOG HELPERS
  // ==========================================================================

  /// Open Add Player dialog
  static Future<void> openAddPlayerDialog(
    WidgetTester tester,
    Finder addPlayerButtonFinder,
  ) async {
    await tester.tap(addPlayerButtonFinder);
    await PumpSequences.dialogOpen(tester);
  }

  /// Add player via dialog (name only, no photo)
  static Future<void> addPlayerViaDialog(
    WidgetTester tester,
    String playerName,
  ) async {
    // Enter name
    await tester.enterText(ElementFinders.getAddPlayerNameField(), playerName);
    await PumpSequences.textEntry(tester);

    // Tap Add button
    await tester.tap(ElementFinders.getAddPlayerAddButton());
    await PumpSequences.dialogClose(tester);
  }

  /// Cancel Add Player dialog
  static Future<void> cancelAddPlayerDialog(WidgetTester tester) async {
    await tester.tap(ElementFinders.getAddPlayerCancelButton());
    await PumpSequences.dialogClose(tester);
  }

  /// Target Tag: Full flow to add a player
  static Future<void> addTargetTagPlayer(
    WidgetTester tester,
    String playerName,
  ) async {
    await openAddPlayerDialog(tester, ElementFinders.getTargetTagAddPlayerButton());
    await addPlayerViaDialog(tester, playerName);
  }

  /// Carnival Derby: Full flow to add a player
  static Future<void> addCarnivalDerbyPlayer(
    WidgetTester tester,
    String playerName,
  ) async {
    await openAddPlayerDialog(tester, ElementFinders.getCarnivalDerbyAddPlayerButton());
    await addPlayerViaDialog(tester, playerName);
  }

  /// Generic: Toggle checkbox
  static Future<void> toggleCheckbox(WidgetTester tester, Finder checkboxFinder) async {
    expect(checkboxFinder, findsOneWidget);
    await tester.tap(checkboxFinder);
    await PumpSequences.simpleUpdate(tester);
  }

  // ==========================================================================
  // CLOCKWORK QUEST SETTINGS
  // ==========================================================================

  /// Clockwork Quest: Toggle Include Bullseye
  static Future<void> toggleClockworkQuestIncludeBullseye(WidgetTester tester) async {
    await toggleCheckbox(tester, ElementFinders.getClockworkQuestIncludeBullseyeCheckbox());
  }

  /// Clockwork Quest: Toggle Speed Mode
  static Future<void> toggleClockworkQuestSpeedMode(WidgetTester tester) async {
    await toggleCheckbox(tester, ElementFinders.getClockworkQuestSpeedModeCheckbox());
  }

  /// Clockwork Quest: Select Number of Laps
  static Future<void> selectClockworkQuestLaps(
    WidgetTester tester,
    int laps,
  ) async {
    final dropdownFinder = ElementFinders.getClockworkQuestNumberOfLapsDropdown();
    await setDropdownValue(tester, dropdownFinder, laps.toString());
  }

  /// Clockwork Quest: Full flow to add a player
  static Future<void> addClockworkQuestPlayer(
    WidgetTester tester,
    String playerName,
  ) async {
    await openAddPlayerDialog(tester, ElementFinders.getClockworkQuestAddPlayerButton());
    await addPlayerViaDialog(tester, playerName);
  }
}
