import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '_helpers.dart';

// ---------------------------------------------------------------------------
// Color constants — RGB byte comparison (Color.value is deprecated on web)
// ---------------------------------------------------------------------------

// Screen constant: _treasureGold = Color(0xFFDAA520)
const Color _treasureGold = Color(0xFFDAA520);
const Color _parchmentTan = Color(0xFFF5E6C8);

bool _colorMatches(Color a, Color b) =>
    a.red == b.red && a.green == b.green && a.blue == b.blue;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Collects all descendant text content from the round tracker (handles both
/// plain Text widgets and Text.rich / RichText widgets).
String _roundTrackerText(WidgetTester tester) {
  final trackerFinder = ElementFinders.getPiratesGridRoundTracker();
  if (trackerFinder.evaluate().isEmpty) return '';

  // Collect from Text widgets (plain text via .data)
  final textFinder =
      find.descendant(of: trackerFinder, matching: find.byType(Text));
  final buffer = StringBuffer();
  for (final textWidget in tester.widgetList<Text>(textFinder)) {
    if (textWidget.data != null) {
      buffer.write(textWidget.data);
      buffer.write(' ');
    } else if (textWidget.textSpan != null) {
      // Text.rich — flatten the TextSpan tree
      buffer.write(_flattenSpan(textWidget.textSpan!));
      buffer.write(' ');
    }
  }
  return buffer.toString();
}

/// Recursively flattens a [TextSpan] tree into a plain string.
String _flattenSpan(InlineSpan span) {
  if (span is TextSpan) {
    final buf = StringBuffer();
    if (span.text != null) buf.write(span.text);
    if (span.children != null) {
      for (final child in span.children!) {
        buf.write(_flattenSpan(child));
      }
    }
    return buf.toString();
  }
  return '';
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid — round complete overlay visual validation", () {
    testWidgets(
        'After P1 wins round 1: "Round 1 Complete!" overlay appears in Treasure Gold '
        'for ~3 seconds, then disappears; round tracker advances to Round 2/3',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          bestOf: '3',
          playerNames: ['Alice', 'Bob']);

      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      final p1Id = provider.currentGame!.playerIds[0];

      // ── P1 wins round 1 by claiming top row ──────────────────────────────
      final target00 =
          ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      final target01 =
          ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
      final target02 =
          ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);

      await throwDartViaMock(tester, target00);
      await throwDartViaMock(tester, target01);
      await throwDartViaMock(tester, target02);

      await tester.pump();
      await tester.pump();

      // Confirm round winner in provider
      expect(provider.currentGame?.winnerId, equals(p1Id),
          reason: 'P1 should have won round 1');

      // ── Assert: "Round 1 Complete!" overlay IS visible ───────────────────
      // The overlay uses a Text widget keyed 'pirates_grid_round_complete_overlay'
      // with text 'Round 1 Complete!' and color Treasure Gold (#DAA520).
      expect(find.textContaining('Round 1 Complete!'), findsOneWidget,
          reason:
              '"Round 1 Complete!" overlay should be visible immediately '
              'after P1 wins round 1 (bestOf=3, non-final round).');

      // Verify the overlay text color is Treasure Gold (#DAA520)
      final overlayFinder = find.textContaining('Round 1 Complete!');
      final overlayText = tester.widget<Text>(overlayFinder);
      final overlayColor = overlayText.style?.color;
      expect(overlayColor, isNotNull,
          reason: 'Overlay text should have an explicit color');
      expect(
        _colorMatches(overlayColor!, _treasureGold),
        isTrue,
        reason:
            'Overlay text should be Treasure Gold '
            '(R=${_treasureGold.red} G=${_treasureGold.green} B=${_treasureGold.blue}); '
            'got R=${overlayColor.red} G=${overlayColor.green} B=${overlayColor.blue}',
      );

      // ── Pump 3.5 seconds — overlay should auto-dismiss ───────────────────
      await tester.pump(const Duration(seconds: 3, milliseconds: 500));

      expect(find.textContaining('Round 1 Complete!'), findsNothing,
          reason:
              '"Round 1 Complete!" overlay should have auto-dismissed after '
              '3 seconds.');

      // ── Click DARTS REMOVED to advance to round 2 ────────────────────────
      await clickDartsRemoved(tester);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // ── Confirm we are now in round 2 ────────────────────────────────────
      expect(provider.currentGame?.currentRound, equals(2),
          reason: 'Game should advance to round 2 after takeout');
      expect(provider.currentGame?.roundsWon[p1Id], equals(1),
          reason: 'P1 roundsWon should be 1 after winning round 1');

      // ── Round tracker should now show "Round 2/3" ─────────────────────────
      expect(ElementFinders.getPiratesGridRoundTracker(), findsOneWidget,
          reason: 'Round tracker should be visible for Bo3');

      final trackerText = _roundTrackerText(tester);
      expect(trackerText.contains('Round 2/3'), isTrue,
          reason:
              'Round tracker should display "Round 2/3" after round 1 ends; '
              'got: "$trackerText"');

      // Alice (P1) should now show 1 win
      expect(trackerText.contains('Alice: 1'), isTrue,
          reason:
              'Round tracker should show "Alice: 1" after P1 wins round 1; '
              'got: "$trackerText"');

      // Bob (P2) should show 0 wins
      expect(trackerText.contains('Bob: 0'), isTrue,
          reason:
              'Round tracker should show "Bob: 0" after P1 wins round 1; '
              'got: "$trackerText"');
    });
  });
}
