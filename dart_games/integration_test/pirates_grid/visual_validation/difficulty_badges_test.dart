import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

// ---------------------------------------------------------------------------
// Color constants — RGB byte comparison (Color.value is deprecated on web)
// ---------------------------------------------------------------------------

// Implementation values from pirates_grid_game_screen.dart
const Color _treasureGold = Color(0xFFDAA520); // actual screen constant
const Color _seaFoamTeal = Color(0xFF2E8B8B);
const Color _bloodRed = Color(0xFF8B0000);

bool _colorMatches(Color a, Color b) =>
    a.red == b.red && a.green == b.green && a.blue == b.blue;

// ---------------------------------------------------------------------------
// Helpers — inspect target label text inside a grid cell
// ---------------------------------------------------------------------------

/// Returns the text content of the target-label Text widget inside the cell
/// at [row],[col].  Returns null if the cell or its label cannot be found.
String? _cellLabelText(WidgetTester tester, int row, int col) {
  final cellFinder = ElementFinders.getPiratesGridGridCell(row, col);
  if (cellFinder.evaluate().isEmpty) return null;
  // The cell contains a keyed Text for the target label:
  // PiratesGridGameKeys.gridCellTargetLabel(row, col).
  // We find it as a descendant Text widget.
  final textFinder =
      find.descendant(of: cellFinder, matching: find.byType(Text));
  if (textFinder.evaluate().isEmpty) return null;
  // There may be multiple Text widgets (e.g., flag image caption); the target
  // label is the last Center child.  Use firstWhere to find the label we want.
  final texts = tester.widgetList<Text>(textFinder).toList();
  // The target label is always present; return the text of the first Text found.
  return texts.isNotEmpty ? texts.first.data : null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid — difficulty target label visual validation", () {
    // ── Scenario 1: Easy — labels are plain numbers, no D/T/Bull prefix ─────
    testWidgets(
        'Easy difficulty: all 9 cells show plain number labels (no D/T/Bull badges)',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          difficulty: 'Easy',
          playerNames: ['Player A', 'Player B']);

      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final label = _cellLabelText(tester, row, col);
          expect(label, isNotNull,
              reason: 'Cell [$row,$col] should have a target label');
          // Easy: label must be a plain integer — no "D"/"T"/"Bull" prefix
          expect(label!.startsWith('D'), isFalse,
              reason:
                  'Easy cell [$row,$col] label "$label" must not start with D');
          expect(label.startsWith('T'), isFalse,
              reason:
                  'Easy cell [$row,$col] label "$label" must not start with T');
          expect(label, isNot('Bull'),
              reason:
                  'Easy cell [$row,$col] should never show "Bull" at center');
          // Label must parse as an integer
          expect(int.tryParse(label), isNotNull,
              reason:
                  'Easy cell [$row,$col] label "$label" should be a plain integer');
        }
      }
    });

    // ── Scenario 2: Medium — labels show "D/T{n}" prefix (no separate badge)
    testWidgets(
        'Medium difficulty: all 9 cells show "D/T{n}" labels',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          difficulty: 'Medium',
          playerNames: ['Player A', 'Player B']);

      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final label = _cellLabelText(tester, row, col);
          expect(label, isNotNull,
              reason: 'Cell [$row,$col] should have a target label');
          // Two-line format: "D{n}\nT{n}"
          expect(label!.contains('\n'), isTrue,
              reason:
                  'Medium cell [$row,$col] label "$label" should have two lines');
          final lines = label.split('\n');
          expect(lines.length, 2,
              reason:
                  'Medium cell [$row,$col] label should have exactly 2 lines');
          expect(lines[0].startsWith('D'), isTrue,
              reason:
                  'Medium cell [$row,$col] first line "${lines[0]}" should start with D');
          expect(lines[1].startsWith('T'), isTrue,
              reason:
                  'Medium cell [$row,$col] second line "${lines[1]}" should start with T');
          final num1 = lines[0].substring(1);
          final num2 = lines[1].substring(1);
          expect(num1, equals(num2),
              reason:
                  'Medium cell [$row,$col] D and T numbers should match');

          // No separate badge — requirement is shown in the label
          final badgeFinder =
              find.byKey(Key('pirates_grid_medium_badge_${row}_$col'));
          expect(badgeFinder, findsNothing,
              reason:
                  'Medium cell [$row,$col] should NOT have a separate badge');
        }
      }
    });

    // ── Scenario 3: Hard — corners "T{n}", edges "D{n}", center "Bull" ──────
    testWidgets(
        'Hard difficulty: corners T-prefix, edges D-prefix, center Bull',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          difficulty: 'Hard',
          playerNames: ['Player A', 'Player B']);

      // Corners: [0,0], [0,2], [2,0], [2,2] → "T{n}"
      const corners = [
        (0, 0),
        (0, 2),
        (2, 0),
        (2, 2),
      ];
      for (final (row, col) in corners) {
        final label = _cellLabelText(tester, row, col);
        expect(label, isNotNull,
            reason: 'Corner cell [$row,$col] should have a label');
        expect(label!.startsWith('T'), isTrue,
            reason:
                'Hard corner [$row,$col] label "$label" should start with T');
        // The rest should be a valid dart number
        final numStr = label.substring(1);
        expect(int.tryParse(numStr), isNotNull,
            reason:
                'Hard corner [$row,$col] T-label "$label" should be T+integer');
      }

      // Edges: [0,1], [1,0], [1,2], [2,1] → "D{n}"
      const edges = [
        (0, 1),
        (1, 0),
        (1, 2),
        (2, 1),
      ];
      for (final (row, col) in edges) {
        final label = _cellLabelText(tester, row, col);
        expect(label, isNotNull,
            reason: 'Edge cell [$row,$col] should have a label');
        expect(label!.startsWith('D'), isTrue,
            reason:
                'Hard edge [$row,$col] label "$label" should start with D');
        final numStr = label.substring(1);
        expect(int.tryParse(numStr), isNotNull,
            reason:
                'Hard edge [$row,$col] D-label "$label" should be D+integer');
      }

      // Center: [1,1] → "Bull"
      final centerLabel = _cellLabelText(tester, 1, 1);
      expect(centerLabel, isNotNull,
          reason: 'Center cell [1,1] should have a label');
      expect(centerLabel, equals('Bull'),
          reason:
              'Hard center [1,1] label should be "Bull" but was "$centerLabel"');

      // Verify label TEXT color — for an unclaimed cell the label is Treasure
      // Gold (#DAA520 per screen constants).
      final cellFinder = ElementFinders.getPiratesGridGridCell(1, 1);
      final textFinder =
          find.descendant(of: cellFinder, matching: find.byType(Text));
      final textWidget = tester.widget<Text>(textFinder.first);
      final labelColor = textWidget.style?.color;
      expect(labelColor, isNotNull,
          reason: 'Center Bull label should have an explicit color');
      expect(
        _colorMatches(labelColor!, _treasureGold),
        isTrue,
        reason:
            'Center Bull label color should be Treasure Gold '
            '(0xFFDAA520) for unclaimed cell; got '
            'R=${labelColor.red} G=${labelColor.green} B=${labelColor.blue}',
      );
    });
  });
}
