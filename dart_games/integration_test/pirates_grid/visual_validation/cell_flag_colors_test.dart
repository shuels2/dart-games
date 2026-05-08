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

// Implementation values from pirates_grid_game_screen.dart
const Color _bloodRed = Color(0xFF8B0000);   // P1 flag color
const Color _seaFoamTeal = Color(0xFF2E8B8B); // P2 flag color
const Color _compassBronze = Color(0xFFCD7F32); // unclaimed border base color

bool _colorMatches(Color a, Color b) =>
    a.red == b.red && a.green == b.green && a.blue == b.blue;

// ---------------------------------------------------------------------------
// Helpers — inspect cell BoxDecoration
// ---------------------------------------------------------------------------

/// Returns the Border.all color from the BoxDecoration of the grid cell at
/// [row],[col].  The Container key is PiratesGridGameKeys.gridCell(row, col).
Color? _cellBorderColor(WidgetTester tester, int row, int col) {
  final cellFinder = ElementFinders.getPiratesGridGridCell(row, col);
  if (cellFinder.evaluate().isEmpty) return null;
  final container = tester.widget<Container>(cellFinder);
  final deco = container.decoration as BoxDecoration?;
  final border = deco?.border as Border?;
  return border?.top.color;
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid — cell flag border color visual validation", () {
    testWidgets(
        'P1 claimed cell has Blood Red border; P2 claimed cell has Sea Foam Teal; '
        'unclaimed cell border is neither',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      final provider = ProviderHelpers.getPiratesGridProvider(tester);

      // ── Verify initial state: [0,0] is unclaimed, border is not P1 or P2 ──
      final initialBorder = _cellBorderColor(tester, 0, 0);
      expect(initialBorder, isNotNull,
          reason: 'Cell [0,0] should have a BoxDecoration border');
      expect(
        _colorMatches(initialBorder!, _bloodRed),
        isFalse,
        reason: 'Unclaimed cell [0,0] should NOT have Blood Red border initially',
      );
      expect(
        _colorMatches(initialBorder, _seaFoamTeal),
        isFalse,
        reason:
            'Unclaimed cell [0,0] should NOT have Sea Foam Teal border initially',
      );

      // ── P1 claims [0,0] ──────────────────────────────────────────────────
      final target00 = ProviderHelpers.getPiratesGridCellTargetNumber(
          tester, 0, 0);
      await throwDartViaMock(tester, target00);
      await tester.pump();
      await tester.pump();

      // Confirm the claim registered in the provider
      expect(
        ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0),
        equals(provider.currentGame!.playerIds[0]),
        reason: 'P1 should have claimed [0,0] after hitting its target',
      );

      // P1's claimed cell should now have a Blood Red border
      final p1Border = _cellBorderColor(tester, 0, 0);
      expect(p1Border, isNotNull,
          reason: 'Cell [0,0] should still have a border after P1 claim');
      expect(
        _colorMatches(p1Border!, _bloodRed),
        isTrue,
        reason:
            'P1 claimed cell [0,0] border should be Blood Red '
            '(R=${_bloodRed.red} G=${_bloodRed.green} B=${_bloodRed.blue}); '
            'got R=${p1Border.red} G=${p1Border.green} B=${p1Border.blue}',
      );

      // ── Complete P1's turn (2 more misses + DARTS REMOVED) ───────────────
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // ── P2 claims [0,2] ──────────────────────────────────────────────────
      final target02 = ProviderHelpers.getPiratesGridCellTargetNumber(
          tester, 0, 2);
      await throwDartViaMock(tester, target02);
      await tester.pump();
      await tester.pump();

      // Confirm P2's claim
      expect(
        ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 2),
        equals(provider.currentGame!.playerIds[1]),
        reason: 'P2 should have claimed [0,2] after hitting its target',
      );

      // P2's claimed cell should have Sea Foam Teal border
      final p2Border = _cellBorderColor(tester, 0, 2);
      expect(p2Border, isNotNull,
          reason: 'Cell [0,2] should have a border after P2 claim');
      expect(
        _colorMatches(p2Border!, _seaFoamTeal),
        isTrue,
        reason:
            'P2 claimed cell [0,2] border should be Sea Foam Teal '
            '(R=${_seaFoamTeal.red} G=${_seaFoamTeal.green} B=${_seaFoamTeal.blue}); '
            'got R=${p2Border.red} G=${p2Border.green} B=${p2Border.blue}',
      );

      // ── Unclaimed cell [1,1] should have neither P1 nor P2 color ─────────
      final emptyBorder = _cellBorderColor(tester, 1, 1);
      expect(emptyBorder, isNotNull,
          reason: 'Unclaimed cell [1,1] should have a border');
      expect(
        _colorMatches(emptyBorder!, _bloodRed),
        isFalse,
        reason: 'Unclaimed cell [1,1] should not have Blood Red border',
      );
      expect(
        _colorMatches(emptyBorder, _seaFoamTeal),
        isFalse,
        reason: 'Unclaimed cell [1,1] should not have Sea Foam Teal border',
      );
    });
  });
}
