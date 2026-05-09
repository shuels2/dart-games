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

// Implementation value from pirates_grid_game_screen.dart:
// static const Color _treasureGold = Color(0xFFDAA520);
// NOTE: The spec cites #FFD700 but the implementation uses #DAA520 (goldenrod).
const Color _treasureGold = Color(0xFFDAA520);

bool _colorMatches(Color a, Color b) =>
    a.red == b.red && a.green == b.green && a.blue == b.blue;

// ---------------------------------------------------------------------------
// Helpers — inspect cell BoxDecoration for winning state
// ---------------------------------------------------------------------------

/// Returns the BoxDecoration border color for the cell at [row],[col].
Color? _cellBorderColor(WidgetTester tester, int row, int col) {
  final cellFinder = ElementFinders.getPiratesGridGridCell(row, col);
  if (cellFinder.evaluate().isEmpty) return null;
  final container = tester.widget<Container>(cellFinder);
  final deco = container.decoration as BoxDecoration?;
  final border = deco?.border as Border?;
  return border?.top.color;
}

/// Returns true if the cell at [row],[col] has at least one BoxShadow whose
/// color matches Treasure Gold (the winning row glow).
bool _hasGoldBoxShadow(WidgetTester tester, int row, int col) {
  final cellFinder = ElementFinders.getPiratesGridGridCell(row, col);
  if (cellFinder.evaluate().isEmpty) return false;
  final container = tester.widget<Container>(cellFinder);
  final deco = container.decoration as BoxDecoration?;
  final shadows = deco?.boxShadow;
  if (shadows == null || shadows.isEmpty) return false;
  for (final shadow in shadows) {
    final c = shadow.color;
    // The shadow is _treasureGold.withOpacity(0.4) — RGB bytes match
    if (c.red == _treasureGold.red &&
        c.green == _treasureGold.green &&
        c.blue == _treasureGold.blue) {
      return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid — winning row Treasure Gold glow visual validation", () {
    testWidgets(
        'Winning row cells get Treasure Gold border and glow; non-winning cells do not',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      final provider = ProviderHelpers.getPiratesGridProvider(tester);

      // ── P1 claims entire top row: [0,0], [0,1], [0,2] ────────────────────
      // Dart 1: claim [0,0]
      final target00 =
          ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      await throwDartViaMock(tester, target00);

      // Dart 2: claim [0,1]
      final target01 =
          ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
      await throwDartViaMock(tester, target01);

      // Dart 3: claim [0,2] — this is the winning move
      final target02 =
          ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
      await throwDartViaMock(tester, target02);

      // Pump to let the setState() rebuild propagate
      await tester.pump();
      await tester.pump();

      // Confirm round winner set in provider
      expect(
        provider.currentGame?.winnerId,
        equals(provider.currentGame!.playerIds[0]),
        reason:
            'P1 should be the round winner after claiming all 3 cells in row 0',
      );

      // Confirm winningLine populated
      expect(
        provider.currentGame?.winningLine,
        isNotNull,
        reason: 'winningLine should be set after P1 wins',
      );

      // ── Winning cells [0,0], [0,1], [0,2] should have Treasure Gold border
      for (int col = 0; col < 3; col++) {
        final borderColor = _cellBorderColor(tester, 0, col);
        expect(borderColor, isNotNull,
            reason: 'Winning cell [0,$col] should have a border');
        expect(
          _colorMatches(borderColor!, _treasureGold),
          isTrue,
          reason:
              'Winning cell [0,$col] border should be Treasure Gold '
              '(R=${_treasureGold.red} G=${_treasureGold.green} B=${_treasureGold.blue}); '
              'got R=${borderColor.red} G=${borderColor.green} B=${borderColor.blue}',
        );
      }

      // ── Winning cells should also have a gold BoxShadow glow ─────────────
      for (int col = 0; col < 3; col++) {
        expect(
          _hasGoldBoxShadow(tester, 0, col),
          isTrue,
          reason:
              'Winning cell [0,$col] should have a Treasure Gold BoxShadow glow',
        );
      }

      // ── Non-winning cells should NOT have the gold glow ───────────────────
      // Row 1 and Row 2 cells are not in the winning line.
      for (int row = 1; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          expect(
            _hasGoldBoxShadow(tester, row, col),
            isFalse,
            reason:
                'Non-winning cell [$row,$col] should NOT have a Treasure Gold '
                'BoxShadow glow',
          );
          final borderColor = _cellBorderColor(tester, row, col);
          if (borderColor != null) {
            expect(
              _colorMatches(borderColor, _treasureGold),
              isFalse,
              reason:
                  'Non-winning cell [$row,$col] border should NOT be Treasure Gold',
            );
          }
        }
      }
    });
  });
}
