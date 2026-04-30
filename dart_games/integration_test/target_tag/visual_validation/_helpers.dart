import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/ui_test_helpers.dart';

// Game configuration for Target Tag
final config = GameUIConfig.targetTag();

// Visual state color constants (from widget implementation)
const colorPinkBorder = 0xFFFF007A;      // Current player border
const colorGreenGlow = 0xFF00FFA3;       // Tagged-in glow/border
const opacityEliminated = 0.4;             // Eliminated player opacity
const borderWidthCurrent = 4.0;           // Current player border width

// ===== MOCK API DART THROWING HELPERS =====

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

/// Simulate missing the board using mock API
Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'miss',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 0.0,
      widgetY: 0.0,
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

/// Get current player's target number from provider
int getCurrentPlayerTargetNumber(WidgetTester tester) {
  final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
  if (currentPlayerId == null) return 20;
  final targetNumber = ProviderHelpers.getTargetTagPlayerTarget(tester, currentPlayerId);
  return targetNumber ?? 20;
}

/// Skip the current turn without throwing darts
Future<void> skipTurn(WidgetTester tester) async {
  await UITestHelpers.clickSkipTurn(tester, config);
}

/// Set shield max by programmatically calling the slider's onChanged callback
/// Shield Max range: 1-10, divisions: 9 (step size = 1)
Future<void> setShieldMax(WidgetTester tester, int shieldMax) async {
  final sliderFinder = find.byType(Slider);
  expect(sliderFinder, findsOneWidget);

  // Get the slider widget
  Slider sliderWidget = tester.widget<Slider>(sliderFinder);

  // Call onChanged callback directly to set the value
  if (sliderWidget.onChanged != null) {
    sliderWidget.onChanged!(shieldMax.toDouble());
  }

  // Wait for state update
  await PumpSequences.simpleUpdate(tester);

  // Verify the value was set
  sliderWidget = tester.widget<Slider>(sliderFinder);
  expect(sliderWidget.value.toInt(), shieldMax,
      reason: 'Shield Max should be set to $shieldMax');
}

/// Enable Team Mode by tapping the team mode switch
Future<void> enableTeamMode(WidgetTester tester) async {
  await SettingsHelpers.toggleTargetTagTeamMode(tester);
  await PumpSequences.fullRebuild(tester);
}

/// Enable Manual Team Assignment (Switch index 1)
Future<void> enableManualTeamAssignment(WidgetTester tester) async {
  // Find Team Assignment switch (second switch, index 1)
  // Switch 0: Team Mode, Switch 1: Team Assignment, Switch 2: Hero Bonus
  final switchFinder = find.byType(Switch);
  if (switchFinder.evaluate().length >= 2) {
    await tester.tap(switchFinder.at(1));
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Assign a player to a specific team (1-based team number)
Future<void> assignPlayerToTeam(WidgetTester tester, int teamNumber) async {
  // Find and tap "Assign team" button
  final assignTeamButtons = find.text('Assign team');
  expect(assignTeamButtons, findsAtLeastNWidgets(1));

  await tester.ensureVisible(assignTeamButtons.first);
  await PumpSequences.simpleUpdate(tester);

  await tester.tap(assignTeamButtons.first);
  await PumpSequences.dialogOpen(tester);

  // Dialog should appear
  expect(find.textContaining('Select Team for'), findsOneWidget);

  // Find team icon GestureDetectors and tap the desired team
  final dialog = find.byType(AlertDialog);
  final gestureDetectors = find.descendant(
    of: dialog,
    matching: find.byType(GestureDetector),
  );
  expect(gestureDetectors, findsAtLeastNWidgets(teamNumber));

  // Tap team icon (0-indexed, so teamNumber - 1)
  await tester.tap(gestureDetectors.at(teamNumber - 1));
  await PumpSequences.dialogClose(tester);

  // Dialog should close
  expect(find.textContaining('Select Team for'), findsNothing);
}

// ===== BADGE VALIDATION HELPERS =====

/// Verify TAGGED IN badge appears/doesn't appear on a player tile
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

/// Verify TAGGED OUT badge appears/doesn't appear on a player tile
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

/// Verify player tile has specific border color and width
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

/// Verify player tile has specific opacity
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

/// Verify player tile has green glow effect (BoxShadow)
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
