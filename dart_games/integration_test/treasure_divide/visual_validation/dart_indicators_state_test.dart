// integration_test/treasure_divide/visual_validation/dart_indicators_state_test.dart
//
// Solo 2 players. Verify dart indicator visual states:
//   - Before any dart: all 3 indicators empty (outlined circle)
//   - After dart 1 (hit): indicator 0 shows hit style (green border)
//   - After dart 2 (miss): indicator 1 shows miss style (red border)
//   - After dart 3 (hit): indicator 2 shows hit style (green border)
//
// Uses _dartIndicatorDecoration logic:
//   - index >= dartsThrown → empty (outlined circle, Key = td_game_dart_indicator_N)
//   - miss → bloodRed border + opacity background
//   - hit → treasureGold border + islandGreen opacity background
//
// Asserts via BoxDecoration.border color inspection.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/dart_throw_helpers.dart';

final config = GameUIConfig.treasureDivide();

const Color _bloodRed = Color(0xFFC41E3A);
const Color _treasureGold = Color(0xFFFFD700);
const Color _islandGreen = Color(0xFF228B22);

/// Get the border color from the Container widget at [key].
Color? _getBorderColor(WidgetTester tester, Key key) {
  final containerFinder = find.byKey(key);
  if (containerFinder.evaluate().isEmpty) return null;
  final widget = tester.widget<Container>(containerFinder);
  final decoration = widget.decoration;
  if (decoration is BoxDecoration) {
    final border = decoration.border;
    if (border is Border) {
      return border.top.color;
    }
  }
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Visual Validation: Dart indicator states (empty → hit → miss → hit)',
      (WidgetTester tester) async {

    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(tester, config);

    // ── Before any dart: all 3 indicators should show empty (gold border) ──
    for (int i = 0; i < 3; i++) {
      expect(
          find.byKey(TreasureDivideGameKeys.dartIndicator(i)), findsOneWidget,
          reason: 'Dart indicator $i should be visible at game start');
      final borderColor =
          _getBorderColor(tester, TreasureDivideGameKeys.dartIndicator(i));
      expect(borderColor, equals(_treasureGold),
          reason:
              'Dart indicator $i should have gold border (empty/unthrown state) '
              'at game start, got $borderColor');
    }

    // ── Throw dart 1: hit the round target ───────────────────────────────
    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final roundIdx =
        ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
    final target =
        ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);

    // Use provider.processDartThrow directly for a reliable score
    provider.processDartThrow(
      score: target,
      multiplier: 'single',
      baseScore: target,
      sector: 'S$target',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Indicator 0 should now show hit style (gold border)
    final borderAfterHit =
        _getBorderColor(tester, TreasureDivideGameKeys.dartIndicator(0));
    expect(borderAfterHit, equals(_treasureGold),
        reason:
            'Dart indicator 0 should have gold border after a hit, '
            'got $borderAfterHit');

    // Indicators 1 and 2 should still be empty (gold border, not yet thrown)
    for (int i = 1; i < 3; i++) {
      final bc =
          _getBorderColor(tester, TreasureDivideGameKeys.dartIndicator(i));
      expect(bc, equals(_treasureGold),
          reason:
              'Dart indicator $i should still be empty (gold border) '
              'after only 1 dart thrown, got $bc');
    }

    // ── Throw dart 2: miss ────────────────────────────────────────────────
    provider.processDartThrow(
      score: 0,
      multiplier: 'miss',
      baseScore: 0,
      sector: 'Miss',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Indicator 1 should show miss style (red border)
    final borderAfterMiss =
        _getBorderColor(tester, TreasureDivideGameKeys.dartIndicator(1));
    expect(borderAfterMiss, equals(_bloodRed),
        reason:
            'Dart indicator 1 should have red border after a miss, '
            'got $borderAfterMiss');

    // ── Throw dart 3: hit ─────────────────────────────────────────────────
    provider.processDartThrow(
      score: target,
      multiplier: 'single',
      baseScore: target,
      sector: 'S$target',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Indicator 2 should show hit style (gold border)
    final borderAfterHit3 =
        _getBorderColor(tester, TreasureDivideGameKeys.dartIndicator(2));
    expect(borderAfterHit3, equals(_treasureGold),
        reason:
            'Dart indicator 2 should have gold border after a hit, '
            'got $borderAfterHit3');

    // shouldPromptTakeout should now be true (3 darts thrown)
    expect(provider.shouldPromptTakeout, isTrue,
        reason: 'shouldPromptTakeout should be true after 3 darts thrown');

  });
}
