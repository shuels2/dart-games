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

// Round tracker now uses Text.rich with per-player colors:
//   P1 name + score → Blood Red (#8B0000)
//   P2 name + score → Sea Foam Teal (#2E8B8B)
//   prefix / separator → Parchment Tan (#F5E6C8)
const Color _bloodRed = Color(0xFF8B0000);
const Color _seaFoamTeal = Color(0xFF2E8B8B);
const Color _parchmentTan = Color(0xFFF5E6C8);

bool _colorMatches(Color a, Color b) =>
    a.red == b.red && a.green == b.green && a.blue == b.blue;

// ---------------------------------------------------------------------------
// Helpers — inspect round tracker Text.rich / RichText spans
// ---------------------------------------------------------------------------

/// Returns the top-level [Text] widget inside the round tracker.
/// The tracker uses [Text.rich], so [Text.data] is null; use [Text.textSpan].
Text? _roundTrackerTextWidget(WidgetTester tester) {
  final trackerFinder = ElementFinders.getPiratesGridRoundTracker();
  if (trackerFinder.evaluate().isEmpty) return null;
  final textFinder =
      find.descendant(of: trackerFinder, matching: find.byType(Text));
  if (textFinder.evaluate().isEmpty) return null;
  return tester.widget<Text>(textFinder.first);
}

/// Flattens a [TextSpan] tree to a plain string (for substring checks).
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

/// Recursively collects all [TextSpan] leaf nodes (those with [text] != null)
/// from [root] into [out].
void _collectLeafSpans(InlineSpan span, List<TextSpan> out) {
  if (span is TextSpan) {
    if (span.text != null && span.text!.isNotEmpty) {
      out.add(span);
    }
    if (span.children != null) {
      for (final child in span.children!) {
        _collectLeafSpans(child, out);
      }
    }
  }
}

/// Returns the text color of a [TextSpan] leaf, walking up the parent
/// [TextStyle] chain if the leaf's own style is null.
/// Since we have a flat two-level tree (root style + child style), each child
/// span carries its own explicit color — no inheritance walk needed here.
Color? _spanColor(TextSpan span) => span.style?.color;

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid — round tracker text visual validation", () {
    testWidgets(
        'Round tracker uses Text.rich: P1 segment in Blood Red, '
        'P2 segment in Sea Foam Teal; score updates after round win',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          bestOf: '3',
          playerNames: ['Alice', 'Bob']);

      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      final p1Id = provider.currentGame!.playerIds[0];

      // ── Verify round tracker is visible for Bo3 ───────────────────────────
      expect(ElementFinders.getPiratesGridRoundTracker(), findsOneWidget,
          reason: 'Round tracker should be visible for Best Of 3');

      // ── Get the Text.rich widget and inspect the span structure ───────────
      final textWidget = _roundTrackerTextWidget(tester);
      expect(textWidget, isNotNull,
          reason: 'Round tracker should contain a Text widget');

      // Text.rich sets textSpan, not data
      expect(textWidget!.textSpan, isNotNull,
          reason: 'Round tracker Text widget should use textSpan (Text.rich)');

      // Flatten to verify overall content
      final flatContent = _flattenSpan(textWidget.textSpan!);
      expect(flatContent.contains('Round 1/3'), isTrue,
          reason:
              'Round tracker should contain "Round 1/3"; got: "$flatContent"');
      expect(flatContent.contains('Alice'), isTrue,
          reason: 'Round tracker should contain "Alice"; got: "$flatContent"');
      expect(flatContent.contains('Bob'), isTrue,
          reason: 'Round tracker should contain "Bob"; got: "$flatContent"');

      // ── Inspect leaf spans for per-player colors ─────────────────────────
      final leaves = <TextSpan>[];
      _collectLeafSpans(textWidget.textSpan!, leaves);

      // Find the span that contains P1 name "Alice"
      final aliceSpan = leaves.firstWhere(
        (s) => s.text?.contains('Alice') ?? false,
        orElse: () => const TextSpan(),
      );
      expect(aliceSpan.text, isNotNull,
          reason: 'Should find a leaf span containing "Alice"');
      final aliceColor = _spanColor(aliceSpan);
      expect(aliceColor, isNotNull,
          reason: 'P1 (Alice) span should have an explicit color');
      expect(
        _colorMatches(aliceColor!, _bloodRed),
        isTrue,
        reason:
            'P1 (Alice) span should be Blood Red '
            '(R=${_bloodRed.red} G=${_bloodRed.green} B=${_bloodRed.blue}); '
            'got R=${aliceColor.red} G=${aliceColor.green} B=${aliceColor.blue}',
      );

      // Find the span that contains P2 name "Bob"
      final bobSpan = leaves.firstWhere(
        (s) => s.text?.contains('Bob') ?? false,
        orElse: () => const TextSpan(),
      );
      expect(bobSpan.text, isNotNull,
          reason: 'Should find a leaf span containing "Bob"');
      final bobColor = _spanColor(bobSpan);
      expect(bobColor, isNotNull,
          reason: 'P2 (Bob) span should have an explicit color');
      expect(
        _colorMatches(bobColor!, _seaFoamTeal),
        isTrue,
        reason:
            'P2 (Bob) span should be Sea Foam Teal '
            '(R=${_seaFoamTeal.red} G=${_seaFoamTeal.green} B=${_seaFoamTeal.blue}); '
            'got R=${bobColor.red} G=${bobColor.green} B=${bobColor.blue}',
      );

      // ── P1 wins round 1 by claiming entire top row ────────────────────────
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

      // Confirm round winner
      expect(provider.currentGame?.winnerId, equals(p1Id),
          reason: 'P1 should have won round 1');
      expect(provider.currentGame?.roundsWon[p1Id], equals(1),
          reason: 'P1 roundsWon should be 1 after winning round 1');

      // Dismiss overlay and advance to round 2
      await tester.pump(const Duration(seconds: 3, milliseconds: 500));
      await clickDartsRemoved(tester);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // ── After round advance, verify tracker shows updated score ───────────
      final updatedWidget = _roundTrackerTextWidget(tester);
      expect(updatedWidget, isNotNull,
          reason: 'Round tracker Text widget should still be present');

      final updatedFlat = updatedWidget!.textSpan != null
          ? _flattenSpan(updatedWidget.textSpan!)
          : updatedWidget.data ?? '';

      expect(updatedFlat.contains('Round 2/3'), isTrue,
          reason:
              'Round tracker should show "Round 2/3" after first round; '
              'got: "$updatedFlat"');
      expect(updatedFlat.contains('Alice: 1'), isTrue,
          reason:
              'Round tracker should show "Alice: 1" after P1 wins round 1; '
              'got: "$updatedFlat"');
      expect(updatedFlat.contains('Bob: 0'), isTrue,
          reason:
              'Round tracker should show "Bob: 0" after round 1; '
              'got: "$updatedFlat"');

      // ── P1 score span should still be Blood Red after round advance ───────
      final updatedLeaves = <TextSpan>[];
      if (updatedWidget.textSpan != null) {
        _collectLeafSpans(updatedWidget.textSpan!, updatedLeaves);
      }
      final aliceSpan2 = updatedLeaves.firstWhere(
        (s) => s.text?.contains('Alice') ?? false,
        orElse: () => const TextSpan(),
      );
      if (aliceSpan2.text != null) {
        final aliceColor2 = _spanColor(aliceSpan2);
        if (aliceColor2 != null) {
          expect(
            _colorMatches(aliceColor2, _bloodRed),
            isTrue,
            reason:
                'P1 (Alice) span should remain Blood Red after round advance; '
                'got R=${aliceColor2.red} G=${aliceColor2.green} B=${aliceColor2.blue}',
          );
        }
      }
    });
  });
}
