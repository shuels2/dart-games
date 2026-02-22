import 'package:flutter/material.dart' show Slider;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/models/player.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';

/// Helpers for interacting with game settings controls and test setup.
class SettingsHelpers {
  // ==========================================================================
  // TEST INITIALIZATION HELPERS
  // ==========================================================================

  /// Initialize SharedPreferences for tests (clears data, sets emulator mode)
  ///
  /// NOTE: For integration tests, we need to actually set values in SharedPreferences
  /// (which persists to browser's IndexedDB), not use setMockInitialValues which
  /// only works in widget tests.
  static Future<void> initializeSettings({
    bool useEmulator = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Set emulator mode and mock dartboard info for integration tests
    await prefs.setBool('use_emulator', useEmulator);
    await prefs.setString('dartboard_name', 'Test Dartboard');
    await prefs.setString('dartboard_serial', 'TEST-001');
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

  /// Save players to SharedPreferences for test setup
  static Future<void> savePlayersToPrefs(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    final playersJson = players.map((p) => p.toJson()).toList();
    await prefs.setString('players_roster', playersJson.toString());
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
    await toggleSwitch(tester, ElementFinders.getTargetTagHeroBonusToggle());
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
    await toggleSwitch(tester, ElementFinders.getMonsterMashSpeedPlaySwitch());
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
}
