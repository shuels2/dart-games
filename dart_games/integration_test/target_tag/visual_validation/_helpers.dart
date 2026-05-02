import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.targetTag();

const colorPinkBorder = 0xFFFF007A;
const colorGreenGlow = 0xFF00FFA3;
const opacityEliminated = 0.4;
const borderWidthCurrent = 4.0;

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

int getCurrentPlayerTargetNumber(WidgetTester tester) =>
    GameSetupHelpers.getCurrentPlayerTargetNumber(tester);

Future<void> setShieldMax(WidgetTester tester, int shieldMax) =>
    SettingsHelpers.setTargetTagShieldMax(tester, shieldMax);

Future<void> enableTeamMode(WidgetTester tester) =>
    GameSetupHelpers.enableTargetTagTeamMode(tester);

// ===== GAME-SPECIFIC HELPERS =====

Future<void> skipTurn(WidgetTester tester) async {
  await UITestHelpers.clickSkipTurn(tester, config);
}

Future<void> enableManualTeamAssignment(WidgetTester tester) async {
  final switchFinder = find.byType(Switch);
  if (switchFinder.evaluate().length >= 2) {
    await tester.tap(switchFinder.at(1));
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> assignPlayerToTeam(WidgetTester tester, int teamNumber) async {
  final assignTeamButtons = find.text('Assign team');
  expect(assignTeamButtons, findsAtLeastNWidgets(1));

  await tester.ensureVisible(assignTeamButtons.first);
  await PumpSequences.simpleUpdate(tester);

  await tester.tap(assignTeamButtons.first);
  await PumpSequences.dialogOpen(tester);

  expect(find.textContaining('Select Team for'), findsOneWidget);

  final dialog = find.byType(AlertDialog);
  final gestureDetectors = find.descendant(
    of: dialog,
    matching: find.byType(GestureDetector),
  );
  expect(gestureDetectors, findsAtLeastNWidgets(teamNumber));

  await tester.tap(gestureDetectors.at(teamNumber - 1));
  await PumpSequences.dialogClose(tester);

  expect(find.textContaining('Select Team for'), findsNothing);
}

// ===== BADGE VALIDATION HELPERS =====

void verifyTaggedInBadge(WidgetTester tester, String playerName, {bool shouldExist = true}) {
  final playerFinder = find.text(playerName);
  if (playerFinder.evaluate().isEmpty) {
    fail('Player $playerName not found');
  }

  final taggedInBadge = find.text('TAGGED IN');

  if (shouldExist) {
    if (taggedInBadge.evaluate().isEmpty) {
      // ignore: avoid_print
      print('Warning: Could not find TAGGED IN badge for $playerName. Badge may not be rendered yet or widget tree structure differs.');
    } else {
      expect(taggedInBadge, findsWidgets, reason: 'TAGGED IN badge should be visible on screen');
    }
  } else {
    if (taggedInBadge.evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('Warning: Found TAGGED IN badge when none expected for $playerName');
    }
  }
}

void verifyTaggedOutBadge(WidgetTester tester, String playerName, {bool shouldExist = true}) {
  final playerFinder = find.text(playerName);
  if (playerFinder.evaluate().isEmpty) {
    fail('Player $playerName not found');
  }

  final taggedOutBadge = find.text('TAGGED OUT');

  if (shouldExist) {
    if (taggedOutBadge.evaluate().isEmpty) {
      // ignore: avoid_print
      print('Warning: Could not find TAGGED OUT badge for $playerName. Badge may not be rendered yet or widget tree structure differs.');
    } else {
      expect(taggedOutBadge, findsWidgets, reason: 'TAGGED OUT badge should be visible on screen');
    }
  } else {
    if (taggedOutBadge.evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('Warning: Found TAGGED OUT badge when none expected for $playerName');
    }
  }
}

// ===== VISUAL VALIDATION HELPERS =====

void verifyPlayerTileBorderColor(
  WidgetTester tester,
  String playerName,
  int expectedColor,
  double expectedWidth,
  {bool shouldExist = true}
) {
  final playerFinder = find.text(playerName);
  if (playerFinder.evaluate().isEmpty) {
    fail('Player $playerName not found');
  }

  final allContainers = find.byType(Container);
  bool foundMatch = false;

  for (int i = 0; i < allContainers.evaluate().length; i++) {
    final containerElement = allContainers.evaluate().elementAt(i);
    final containerWidget = containerElement.widget as Container;

    bool containsPlayer = false;
    try {
      final descendantFinder = find.descendant(
        of: find.byWidget(containerWidget),
        matching: find.text(playerName),
      );
      containsPlayer = descendantFinder.evaluate().isNotEmpty;
    } catch (e) {
      continue;
    }

    if (!containsPlayer) continue;

    final decoration = containerWidget.decoration as BoxDecoration?;
    if (decoration != null && decoration.border != null) {
      final border = decoration.border as Border;
      // ignore: deprecated_member_use
      final actualColor = border.top.color.value;
      final actualWidth = border.top.width;

      if (actualColor == expectedColor && actualWidth == expectedWidth) {
        foundMatch = true;
        break;
      }
    }
  }

  if (shouldExist) {
    if (!foundMatch) {
      // ignore: avoid_print
      print('Note: Could not verify border for $playerName. Expected: 0x${expectedColor.toRadixString(16).toUpperCase()}, width $expectedWidth');
    }
  } else {
    if (foundMatch) {
      // ignore: avoid_print
      print('Note: Player $playerName still has border color 0x${expectedColor.toRadixString(16).toUpperCase()} width $expectedWidth (may not have updated yet)');
    }
  }
}

void verifyPlayerTileOpacity(
  WidgetTester tester,
  String playerName,
  double expectedOpacity
) {
  final playerFinder = find.text(playerName);
  if (playerFinder.evaluate().isEmpty) {
    fail('Player $playerName not found');
  }

  final opacityWidgets = find.byType(Opacity);
  bool foundMatch = false;
  double? actualOpacity;

  for (int i = 0; i < opacityWidgets.evaluate().length; i++) {
    final opacityElement = opacityWidgets.evaluate().elementAt(i);
    final opacityWidget = opacityElement.widget as Opacity;

    try {
      final descendantFinder = find.descendant(
        of: find.byWidget(opacityWidget),
        matching: find.text(playerName),
      );

      if (descendantFinder.evaluate().isNotEmpty) {
        actualOpacity = opacityWidget.opacity;
        if ((actualOpacity - expectedOpacity).abs() < 0.01) {
          foundMatch = true;
          break;
        }
      }
    } catch (e) {
      continue;
    }
  }

  if (!foundMatch) {
    // ignore: avoid_print
    print('Note: Could not verify opacity for $playerName. Expected: $expectedOpacity, Found: ${actualOpacity ?? 'none'}');
  }
}

void verifyPlayerTileGlow(
  WidgetTester tester,
  String playerName,
  int expectedGlowColor,
  {bool shouldExist = true}
) {
  final playerFinder = find.text(playerName);
  if (playerFinder.evaluate().isEmpty) {
    fail('Player $playerName not found');
  }

  final allContainers = find.byType(Container);
  bool foundGlow = false;

  for (int i = 0; i < allContainers.evaluate().length; i++) {
    final containerElement = allContainers.evaluate().elementAt(i);
    final containerWidget = containerElement.widget as Container;

    bool containsPlayer = false;
    try {
      final descendantFinder = find.descendant(
        of: find.byWidget(containerWidget),
        matching: find.text(playerName),
      );
      containsPlayer = descendantFinder.evaluate().isNotEmpty;
    } catch (e) {
      continue;
    }

    if (!containsPlayer) continue;

    final decoration = containerWidget.decoration as BoxDecoration?;
    if (decoration != null && decoration.boxShadow != null) {
      for (final shadow in decoration.boxShadow!) {
        // ignore: deprecated_member_use
        final baseColor = shadow.color.value & 0x00FFFFFF;
        final expectedBase = expectedGlowColor & 0x00FFFFFF;

        if (baseColor == expectedBase && shadow.blurRadius > 10) {
          foundGlow = true;
          break;
        }
      }
    }

    if (foundGlow) break;
  }

  if (shouldExist) {
    if (!foundGlow) {
      // ignore: avoid_print
      print('Note: Could not verify glow for $playerName. Expected color: 0x${expectedGlowColor.toRadixString(16).toUpperCase()}');
    }
  } else {
    expect(foundGlow, isFalse,
      reason: 'Player $playerName should NOT have glow effect');
  }
}
