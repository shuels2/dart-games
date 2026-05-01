import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test_helpers.dart';
import 'settings_helpers.dart';
import 'pump_sequences.dart';
import 'provider_helpers.dart';
import 'game_ui_config.dart';

class GameSetupHelpers {
  // ===== Clockwork Quest =====

  static Future<void> setupAndStartClockworkQuest(
    WidgetTester tester,
    GameUIConfig config, {
    bool includeBullseye = false,
    bool speedMode = false,
    int laps = 1,
    List<String>? playerNames,
  }) async {
    await UITestHelpers.navigateToGameMenu(tester, config);

    if (includeBullseye) {
      await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
    }
    if (speedMode) {
      await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
    }
    if (laps > 1) {
      await SettingsHelpers.selectClockworkQuestLaps(tester, laps);
    }

    final names = playerNames ?? ['Player A', 'Player B'];
    for (final name in names) {
      await UITestHelpers.addPlayer(tester, name, config);
    }

    await UITestHelpers.startGame(tester, config);
  }

  // ===== Target Tag =====

  static Future<void> setupAndStartTargetTag(
    WidgetTester tester,
    GameUIConfig config, {
    int? shieldMax,
    bool teamMode = false,
    bool heroBonus = false,
    List<String>? playerNames,
  }) async {
    await UITestHelpers.navigateToGameMenu(tester, config);

    if (shieldMax != null) {
      await SettingsHelpers.setTargetTagShieldMax(tester, shieldMax);
    }
    if (teamMode) {
      await SettingsHelpers.toggleTargetTagTeamMode(tester);
      await PumpSequences.fullRebuild(tester);
    }
    if (heroBonus) {
      await SettingsHelpers.toggleTargetTagHeroBonus(tester);
    }

    final names = playerNames ?? ['Player A', 'Player B'];
    for (final name in names) {
      await UITestHelpers.addPlayer(tester, name, config);
    }

    await UITestHelpers.startGame(tester, config);
  }

  // ===== Carnival Derby =====

  static Future<void> setupAndStartCarnivalDerby(
    WidgetTester tester,
    GameUIConfig config, {
    int? targetScore,
    bool perfectFinish = false,
    List<String>? playerNames,
  }) async {
    await UITestHelpers.navigateToGameMenu(tester, config);

    if (targetScore != null) {
      await setCarnivalDerbyTargetScoreSlider(tester, targetScore);
    }
    if (perfectFinish) {
      await SettingsHelpers.toggleCarnivalDerbyPerfectFinish(tester);
    }

    final names = playerNames ?? ['Player A', 'Player B'];
    for (final name in names) {
      await UITestHelpers.addPlayer(tester, name, config);
    }

    await UITestHelpers.startGame(tester, config);
  }

  // ===== Monster Mash =====

  static Future<void> setupAndStartMonsterMash(
    WidgetTester tester,
    GameUIConfig config, {
    int? healthMax,
    int? roundLimit,
    bool bonusBuffs = false,
    bool speedPlay = false,
    List<String>? playerNames,
  }) async {
    await UITestHelpers.navigateToGameMenu(tester, config);

    if (healthMax != null) {
      await SettingsHelpers.setMonsterMashHealthMax(tester, healthMax);
    }
    if (roundLimit != null) {
      await SettingsHelpers.setMonsterMashRoundLimit(tester, roundLimit);
    }
    if (bonusBuffs) {
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);
    }
    if (speedPlay) {
      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    }

    final names = playerNames ?? ['Player A', 'Player B'];
    for (final name in names) {
      await UITestHelpers.addPlayer(tester, name, config);
    }

    await UITestHelpers.startGame(tester, config);
  }

  // ===== Reef Royale =====

  static Future<void> setupAndStartReefRoyale(
    WidgetTester tester,
    GameUIConfig config, {
    bool easyClaim = false,
    bool neighborNumbers = false,
    bool cursedTide = false,
    bool bonusBuffs = false,
    bool speedPlay = false,
    int? roundLimit,
    bool randomReefs = false,
    bool showHints = false,
    List<String>? playerNames,
  }) async {
    await UITestHelpers.navigateToGameMenu(tester, config);

    if (cursedTide) {
      await SettingsHelpers.setReefRoyaleGameMode(tester, 'Cursed Tide');
    }
    if (showHints) {
      await SettingsHelpers.toggleReefRoyaleShowHints(tester);
    }
    if (easyClaim) {
      await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
    }
    if (neighborNumbers) {
      await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
    }
    if (randomReefs) {
      await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
    }
    if (bonusBuffs) {
      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
    }
    if (speedPlay) {
      await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);
    }
    if (roundLimit != null) {
      await SettingsHelpers.setReefRoyaleRoundLimit(tester, roundLimit);
    }

    final names = playerNames ?? ['Player A', 'Player B'];
    for (final name in names) {
      await UITestHelpers.addPlayer(tester, name, config);
    }

    await UITestHelpers.startGame(tester, config);
  }

  // ===== Carnival Derby =====

  static Future<void> setCarnivalDerbyTargetScoreSlider(
    WidgetTester tester,
    int targetScore,
  ) async {
    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);

    Slider sliderWidget = tester.widget<Slider>(sliderFinder);
    final currentValue = sliderWidget.value.toInt();

    if (currentValue == targetScore) return;

    if (sliderWidget.onChanged != null) {
      sliderWidget.onChanged!(targetScore.toDouble());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // ===== Target Tag =====

  static int getCurrentPlayerTargetNumber(WidgetTester tester) {
    final currentPlayerId =
        ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    if (currentPlayerId == null) return 20;
    final targetNumber =
        ProviderHelpers.getTargetTagPlayerTarget(tester, currentPlayerId);
    return targetNumber ?? 20;
  }

  static Future<void> enableTargetTagTeamMode(WidgetTester tester) async {
    await SettingsHelpers.toggleTargetTagTeamMode(tester);
    await PumpSequences.fullRebuild(tester);
  }
}
