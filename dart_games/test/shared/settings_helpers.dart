import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart' show Slider, Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
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

  /// Full server reset: assigns a unique DB session, wipes data, configures
  /// dartboard.
  ///
  /// Each browser instance gets its own isolated database via the
  /// `X-DB-Session` header, so the duplicate browser spawned by Flutter
  /// bug #67090 cannot create duplicate saves.
  static Future<void> resetServerState({bool useEmulator = true}) async {
    // Generate a unique session ID so this browser instance gets its
    // own isolated database on the server.
    if (ApiConfig.dbSession == null) {
      final sessionId = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      ApiConfig.setDbSession('session-$sessionId');
    }

    await _waitForServer();

    VictoryMusicService().resetForTesting();

    // Wipe all server-side user data
    final requestId = _generateRequestId();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Request-Id': requestId,
    };
    final session = ApiConfig.dbSession;
    if (session != null) {
      headers['X-DB-Session'] = session;
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

    // Verify the reset took effect
    final sessionHeaders = _sessionHeaders();
    final verifyResponse = await http.get(
      _bustCache('/api/v1/players'),
      headers: sessionHeaders,
    );
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
      headers: sessionHeaders,
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
    final dartboardHeaders = <String, String>{'Content-Type': 'application/json'};
    if (session != null) {
      dartboardHeaders['X-DB-Session'] = session;
    }
    final dartboardResponse = await http.put(
      Uri.parse(ApiConfig.url('/api/v1/dartboard')),
      headers: dartboardHeaders,
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

    // Disable voice announcements for the test run. Event-driven victory
    // navigation (_handleGameWon waits on _audioQueue.whenIdle before
    // pushing the results screen) hangs in the test environment because
    // the speech-engine onend / setCompletionHandler callbacks don't
    // fire reliably under flutter_drive + DDC web — each queued
    // announcement falls back to its wordCount-based timeout (~5-7 s),
    // and tiki golf / gladiator arena accumulate enough announcements
    // mid-game to exceed pumpUntilResults's 90 s budget. With voice
    // off, DartAnnouncerService.speak() short-circuits, the queue
    // drains instantly, whenIdle resolves, and navigation fires.
    // Game logic (provider state, scoring, hasWinner) is unaffected.
    final voiceResponse = await http.put(
      Uri.parse(ApiConfig.url('/api/v1/settings/voice_enabled')),
      headers: dartboardHeaders,
      body: jsonEncode({'value': 'false'}),
    );
    if (voiceResponse.statusCode != 200) {
      print('WARNING: Failed to disable voice for test '
          '(status ${voiceResponse.statusCode}): ${voiceResponse.body}');
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

  static Map<String, String>? _sessionHeaders() {
    final session = ApiConfig.dbSession;
    if (session == null) return null;
    return {'X-DB-Session': session};
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
      final session = ApiConfig.dbSession;
      if (session != null) {
        headers['X-DB-Session'] = session;
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

  /// Reef Royale: Toggle Include Bull (only enabled when Random Reefs is ON).
  static Future<void> toggleReefRoyaleIncludeBull(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getReefRoyaleIncludeBullSwitch());
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
  // LUNAR LANDER SETTINGS
  // ==========================================================================

  /// Lunar Lander: Set Starting Altitude (slider)
  ///
  /// Valid values: 100-500 (increments of 10)
  static Future<void> setLunarLanderAltitude(
    WidgetTester tester,
    int value,
  ) async {
    final sliderFinder = ElementFinders.getLunarLanderAltitudeSlider();
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
        reason: 'Altitude should be set to $value');
  }

  /// Lunar Lander: Set Hard Landing toggle
  static Future<void> setLunarLanderHardLanding(
    WidgetTester tester, {
    required bool enabled,
  }) async {
    final switchFinder = ElementFinders.getLunarLanderHardLandingSwitch();
    expect(switchFinder, findsOneWidget);

    // Check current state and only tap if we need to change it
    final switchWidget = tester.widget<Switch>(switchFinder);
    if (switchWidget.value != enabled) {
      await toggleSwitch(tester, switchFinder);
    }
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

  // ==========================================================================
  // PIRATE'S GRID SETTINGS
  // ==========================================================================

  /// Pirate's Grid: Set Target Difficulty (dropdown)
  ///
  /// Valid values: 'Easy', 'Medium', 'Hard'
  static Future<void> setPiratesGridDifficulty(
    WidgetTester tester,
    String difficulty,
  ) async {
    await setDropdownValue(
      tester,
      ElementFinders.getPiratesGridDifficultyDropdown(),
      difficulty,
    );
  }

  /// Pirate's Grid: Set Best Of (dropdown)
  ///
  /// Valid values: '1', '3', '5'
  static Future<void> setPiratesGridBestOf(
    WidgetTester tester,
    String bestOf,
  ) async {
    await setDropdownValue(
      tester,
      ElementFinders.getPiratesGridBestOfDropdown(),
      bestOf,
    );
  }

  /// Pirate's Grid: Toggle Steal Mode switch
  static Future<void> togglePiratesGridStealMode(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getPiratesGridStealModeSwitch());
  }

  /// Pirate's Grid: Toggle Speed Play switch
  static Future<void> togglePiratesGridSpeedPlay(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getPiratesGridSpeedPlaySwitch());
  }

  // ==========================================================================
  // GLADIATOR ARENA SETTINGS
  // ==========================================================================

  /// Gladiator Arena: Set Target Score (slider)
  ///
  /// Valid values: 100-500 (step 25)
  static Future<void> setGladiatorArenaTargetScore(
    WidgetTester tester,
    int value,
  ) async {
    final sliderFinder = ElementFinders.getGladiatorArenaTargetScoreSlider();
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
        reason: 'Target Score should be set to $value');
  }

  /// Gladiator Arena: Toggle Double Finish switch
  static Future<void> toggleGladiatorArenaDoubleFinish(
      WidgetTester tester) async {
    await toggleSwitch(
        tester, ElementFinders.getGladiatorArenaDoubleFinishSwitch());
  }

  /// Gladiator Arena: Toggle Shield Round switch
  static Future<void> toggleGladiatorArenaShieldRound(
      WidgetTester tester) async {
    await toggleSwitch(
        tester, ElementFinders.getGladiatorArenaShieldRoundSwitch());
  }

  /// Gladiator Arena: Toggle Speed Play switch
  static Future<void> toggleGladiatorArenaSpeedPlay(
      WidgetTester tester) async {
    await toggleSwitch(
        tester, ElementFinders.getGladiatorArenaSpeedPlaySwitch());
  }

  // ==========================================================================
  // TIKI GOLF SETTINGS HELPERS
  // ==========================================================================

  /// Tiki Golf: Tap the TEAM segment of the Game Mode toggle
  static Future<void> setTikiGolfGameModeTeam(WidgetTester tester) async {
    final teamSegment = ElementFinders.getTikiGolfGameModeTeam();
    await tester.tap(teamSegment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  /// Tiki Golf: Tap the SOLO segment of the Game Mode toggle
  static Future<void> setTikiGolfGameModeSolo(WidgetTester tester) async {
    final soloSegment = ElementFinders.getTikiGolfGameModeSolo();
    await tester.tap(soloSegment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  /// Tiki Golf: Tap the MANUAL segment of the Team Assignment toggle
  static Future<void> setTikiGolfAssignmentManual(WidgetTester tester) async {
    final manualSegment = ElementFinders.getTikiGolfAssignmentModeManual();
    await tester.tap(manualSegment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  /// Tiki Golf: Tap the RANDOM segment of the Team Assignment toggle
  static Future<void> setTikiGolfAssignmentRandom(WidgetTester tester) async {
    final randomSegment = ElementFinders.getTikiGolfAssignmentModeRandom();
    await tester.tap(randomSegment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  /// Tiki Golf: Select Max Strokes from the dropdown (3, 4, 5, or 6)
  static Future<void> setTikiGolfMaxStrokes(
      WidgetTester tester, int maxStrokes) async {
    await setDropdownValue(
      tester,
      ElementFinders.getTikiGolfMaxStrokesDropdown(),
      '$maxStrokes',
    );
  }

  /// Tiki Golf: Toggle the Mulligan switch
  static Future<void> toggleTikiGolfMulligan(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getTikiGolfMulliganSwitch());
  }

  // ==========================================================================
  // TREASURE DIVIDE SETTINGS HELPERS
  // ==========================================================================

  /// Treasure Divide: Tap the TEAM segment of the Game Mode toggle
  static Future<void> setTreasureDivideGameModeTeam(WidgetTester tester) async {
    final teamSegment = ElementFinders.getTreasureDivideGameModeTeam();
    await tester.tap(teamSegment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  /// Treasure Divide: Tap the SOLO segment of the Game Mode toggle
  static Future<void> setTreasureDivideGameModeSolo(WidgetTester tester) async {
    final soloSegment = ElementFinders.getTreasureDivideGameModeSolo();
    await tester.tap(soloSegment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  /// Treasure Divide: Tap the MANUAL segment of the Team Assignment toggle
  static Future<void> setTreasureDivideAssignmentManual(WidgetTester tester) async {
    final manualSegment = ElementFinders.getTreasureDivideAssignmentModeManual();
    await tester.tap(manualSegment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  /// Treasure Divide: Tap the RANDOM segment of the Team Assignment toggle
  static Future<void> setTreasureDivideAssignmentRandom(WidgetTester tester) async {
    final randomSegment = ElementFinders.getTreasureDivideAssignmentModeRandom();
    await tester.tap(randomSegment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  /// Treasure Divide: Select number of rounds from the dropdown (7, 9, or 12)
  static Future<void> selectTreasureDivideRounds(
      WidgetTester tester, int rounds) async {
    await setDropdownValue(
      tester,
      ElementFinders.getTreasureDivideRoundsDropdown(),
      '$rounds',
    );
  }

  /// Treasure Divide: Toggle the Quarter It switch
  static Future<void> toggleTreasureDivideQuarterIt(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getTreasureDivideQuarterItSwitch());
  }

  /// Treasure Divide: Toggle the Custom Targets switch
  static Future<void> toggleTreasureDivideCustomTargets(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getTreasureDivideCustomTargetsSwitch());
  }

  /// Treasure Divide: Select number of crews from the Team Count dropdown
  /// (only visible in Team + Manual mode)
  static Future<void> selectTreasureDivideCrews(
      WidgetTester tester, int crews) async {
    await setDropdownValue(
      tester,
      ElementFinders.getTreasureDivideTeamCountDropdown(),
      '$crews',
    );
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
