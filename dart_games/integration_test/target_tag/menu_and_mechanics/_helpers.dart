import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

// Game configuration for Target Tag
final config = GameUIConfig.targetTag();

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

/// Click DARTS REMOVED button on emulator
Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Verify dart indicator border color
/// Dart indicators are identified by TargetTagGameKeys constants
void verifyDartIndicatorColor(WidgetTester tester, Key dartKey, int expectedColorValue) {
  final indicatorFinder = find.byKey(dartKey);
  expect(indicatorFinder, findsOneWidget);

  final container = tester.widget<Container>(indicatorFinder);
  final decoration = container.decoration as BoxDecoration?;
  expect(decoration, isNotNull);

  expect(decoration!.border, isNotNull);

  final border = decoration!.border as Border;
  final actualColor = border.top.color.value;

  expect(actualColor, expectedColorValue,
      reason: 'Dart $dartKey should have border color 0x${expectedColorValue.toRadixString(16)}');
}
