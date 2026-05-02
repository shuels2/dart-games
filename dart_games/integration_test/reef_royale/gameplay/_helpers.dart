import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.reefRoyale();

// ===== DELEGATES TO SHARED HELPERS =====

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

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  bool easyClaim = false,
  bool neighborNumbers = false,
  bool cursedTide = false,
  bool bonusBuffs = false,
  bool speedPlay = false,
  int? roundLimit,
  bool randomReefs = false,
}) =>
    GameSetupHelpers.setupAndStartReefRoyale(
      tester,
      config,
      easyClaim: easyClaim,
      neighborNumbers: neighborNumbers,
      cursedTide: cursedTide,
      bonusBuffs: bonusBuffs,
      speedPlay: speedPlay,
      roundLimit: roundLimit,
      randomReefs: randomReefs,
    );

// ===== GAME-SPECIFIC HELPERS =====

void verifyDartIndicatorColor(WidgetTester tester, Key dartKey, int expectedColorValue) {
  final indicatorFinder = find.byKey(dartKey);
  expect(indicatorFinder, findsOneWidget);

  final container = tester.widget<Container>(indicatorFinder);
  final decoration = container.decoration as BoxDecoration?;
  expect(decoration, isNotNull);

  expect(decoration!.border, isNotNull);

  final border = decoration.border as Border;
  final actualColor = border.top.color.value;

  expect(actualColor, expectedColorValue,
      reason: 'Dart $dartKey should have border color 0x${expectedColorValue.toRadixString(16)}, '
          'but got 0x${actualColor.toRadixString(16)}');
}
