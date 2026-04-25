import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart' show Slider;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/api/api_config.dart';
import 'package:dart_games/services/victory_music_service.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';

/// Helpers for interacting with game settings controls and test setup.
class SettingsHelpers {
  // ==========================================================================
  // TEST INITIALIZATION HELPERS
  // ==========================================================================

  /// Full server reset: wipes all data, advances epoch, configures dartboard.
  ///
  /// With one-test-per-process architecture, each test gets its own Dart
  /// isolate — no phantom callbacks, no epoch token gating needed.
  static Future<void> resetServerState({bool useEmulator = true}) async {
    await _waitForServer();

    VictoryMusicService().resetForTesting();

    // Wipe all server-side user data
    final requestId = _generateRequestId();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Request-Id': requestId,
    };
    final currentEpoch = ApiConfig.testEpoch;
    if (currentEpoch != null) {
      headers['X-Test-Epoch'] = currentEpoch.toString();
    }
    final resetResponse = await http.post(
      Uri.parse(ApiConfig.url('/api/v1/test/reset')),
      headers: headers,
    );

    if (resetResponse.statusCode != 200) {
      throw Exception(
        'Test reset failed (status ${resetResponse.statusCode}): '
        '${resetResponse.body}',
      );
    }

    final resetBody = jsonDecode(resetResponse.body) as Map<String, dynamic>;
    ApiConfig.setTestEpoch(resetBody['test_epoch'] as int?);
    print('[resetServerState] Reset OK (id=$requestId, '
        'epoch=${resetBody['test_epoch']})');

    // Verify the reset took effect
    final verifyResponse = await http.get(_bustCache('/api/v1/players'));
    if (verifyResponse.statusCode != 200) {
      throw Exception(
        'Player verification after reset failed '
        '(status ${verifyResponse.statusCode}): ${verifyResponse.body}',
      );
    }
    final verifyBody = jsonDecode(verifyResponse.body) as List<dynamic>;
    if (verifyBody.isNotEmpty) {
      throw Exception(
        'Test reset did not clear players: '
        '${verifyBody.length} player(s) still present',
      );
    }

    final verifySavedGamesResponse = await http.get(
      _bustCache('/api/v1/games'),
    );
    if (verifySavedGamesResponse.statusCode != 200) {
      throw Exception(
        'Saved games verification after reset failed '
        '(status ${verifySavedGamesResponse.statusCode}): '
        '${verifySavedGamesResponse.body}',
      );
    }
    final verifySavedGamesBody =
        jsonDecode(verifySavedGamesResponse.body) as List<dynamic>;
    if (verifySavedGamesBody.isNotEmpty) {
      throw Exception(
        'Test reset did not clear saved games: '
        '${verifySavedGamesBody.length} saved game(s) still present',
      );
    }

    // Configure dartboard for emulator mode
    final dartboardResponse = await http.put(
      Uri.parse(ApiConfig.url('/api/v1/dartboard')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': 'Test Dartboard',
        'serialNumber': 'TEST-001',
        'useEmulator': useEmulator,
      }),
    );
    if (dartboardResponse.statusCode != 200) {
      print('WARNING: Failed to initialize dartboard settings via API '
          '(status ${dartboardResponse.statusCode}): '
          '${dartboardResponse.body}');
    }
  }

  static Future<bool> _checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.url('/api/v1/health/')),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _waitForServer({int maxAttempts = 10}) async {
    for (var i = 1; i <= maxAttempts; i++) {
      if (await _checkServerHealth()) return;
      print('  Server health check attempt $i/$maxAttempts failed, retrying...');
      await Future.delayed(const Duration(seconds: 1));
    }
    throw Exception(
      'Server at ${ApiConfig.baseUrl} did not become reachable '
      'after $maxAttempts attempts',
    );
  }

  static final Random _rng = Random();
  static String _generateRequestId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rnd = _rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$ts-$rnd';
  }

  static Uri _bustCache(String path) {
    final base = Uri.parse(ApiConfig.url(path));
    return base.replace(queryParameters: {
      ...base.queryParameters,
      '_': DateTime.now().microsecondsSinceEpoch.toString(),
    });
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
      final headers = <String, String>{'Content-Type': 'application/json'};
      final epoch = ApiConfig.testEpoch;
      if (epoch != null) {
        headers['X-Test-Epoch'] = epoch.toString();
      }
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'id': player.id,
          'name': player.name,
          'createdAt': player.createdAt.toIso8601String(),
        }),
      );
      if (response.statusCode == 409) {
        print('[savePlayersToApi] Player "${player.name}" REJECTED (409) — '
            'stale epoch=$epoch');
        continue;
      }
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

  /// Generic: Toggle checkbox
  static Future<void> toggleCheckbox(WidgetTester tester, Finder checkboxFinder) async {
    expect(checkboxFinder, findsOneWidget);
    await tester.tap(checkboxFinder);
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
