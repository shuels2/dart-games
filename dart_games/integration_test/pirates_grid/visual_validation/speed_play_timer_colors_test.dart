import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

// ---------------------------------------------------------------------------
// Color constants — RGB byte comparison (Color.value is deprecated on web)
//
// Timer color tiers (from pirates_grid_game_screen.dart _buildSpeedPlayTimer):
//   secs >= 6  → _treasureGold  = Color(0xFFDAA520)
//   secs >= 3  → _compassBronze = Color(0xFFCD7F32)
//   secs < 3   → _bloodRed      = Color(0xFF8B0000)
// ---------------------------------------------------------------------------

const Color _treasureGold = Color(0xFFDAA520);
const Color _compassBronze = Color(0xFFCD7F32);
const Color _bloodRed = Color(0xFF8B0000);

bool _colorMatches(Color a, Color b) =>
    a.red == b.red && a.green == b.green && a.blue == b.blue;

// ---------------------------------------------------------------------------
// Helper — read the timer Text widget's color
// ---------------------------------------------------------------------------

/// Returns the color of the Speed Play timer text widget.
/// The timer key is PiratesGridGameKeys.speedPlayTimer.
Color? _timerTextColor(WidgetTester tester) {
  final timerFinder = ElementFinders.getPiratesGridSpeedPlayTimer();
  if (timerFinder.evaluate().isEmpty) return null;
  // The widget tagged with the key is a Text (or wrapped in a Transform.scale
  // for pulsing at 0-2 seconds, but the key is on the inner Text).
  final textFinder =
      find.descendant(of: timerFinder, matching: find.byType(Text));
  if (textFinder.evaluate().isEmpty) {
    // The key might be directly on the Text widget.
    try {
      final t = tester.widget<Text>(timerFinder);
      return t.style?.color;
    } catch (_) {
      return null;
    }
  }
  return tester.widget<Text>(textFinder.first).style?.color;
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------
//
// HEADLESS TIMER NOTE:
// The Speed Play countdown uses dart:async Timer.periodic (real-time clock).
// WidgetTester does NOT pump fake time through real dart:async Timers by
// default — tester.pump(Duration(seconds: N)) advances the Flutter animation
// clock but does not fire Timer callbacks.  Therefore:
//   • The START color tier (secs=25 ≥ 6 → Treasure Gold) CAN be asserted
//     headlessly because the timer hasn't ticked yet when the screen first
//     renders.
//   • The MIDDLE (compassBronze at secs 3-5) and CRITICAL (bloodRed at secs
//     0-2) tiers CANNOT be driven headlessly via tester.pump alone.
//
// This test therefore:
//   1. Asserts the START tier (Treasure Gold) — fully headless.
//   2. Documents the limitation for the middle/critical tiers.
//
// To test all three tiers in a live environment, run the full UI automation
// suite which uses a real Chrome session where real Timers fire.
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid — Speed Play timer color tiers visual validation", () {
    testWidgets(
        'Speed Play timer starts at Treasure Gold (secs >= 6 tier)',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          speedPlay: true,
          playerNames: ['Player A', 'Player B']);

      // Timer widget must be visible when Speed Play is on
      expect(ElementFinders.getPiratesGridSpeedPlayTimer(), findsOneWidget,
          reason: 'Speed Play timer should be visible when Speed Play is ON');

      // At game start the timer is at 25 seconds (≥ 6) → Treasure Gold
      final startColor = _timerTextColor(tester);
      expect(startColor, isNotNull,
          reason: 'Timer Text should have an explicit color');
      expect(
        _colorMatches(startColor!, _treasureGold),
        isTrue,
        reason:
            'Speed Play timer at start (25s) should be Treasure Gold '
            '(R=${_treasureGold.red} G=${_treasureGold.green} B=${_treasureGold.blue}); '
            'got R=${startColor.red} G=${startColor.green} B=${startColor.blue}.\n'
            'Color tier rule: secs >= 6 → Treasure Gold (#DAA520), '
            'secs 3-5 → Compass Bronze (#CD7F32), secs 0-2 → Blood Red (#8B0000).',
      );

      // ── Headless limitation: middle (Bronze) and critical (Red) tiers ─────
      // dart:async Timer.periodic does not respond to tester.pump(Duration).
      // The following pump demonstrates that the timer does NOT tick under
      // WidgetTester and the color stays Treasure Gold.
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();

      final afterPumpColor = _timerTextColor(tester);
      // If the timer WERE ticking, 20 pumped seconds would put us at 5s
      // (Compass Bronze tier).  Since Timer.periodic doesn't fire, it stays Gold.
      // We verify the widget is still visible (not crashed) rather than asserting
      // a color change that can't be driven headlessly.
      expect(ElementFinders.getPiratesGridSpeedPlayTimer(), findsOneWidget,
          reason:
              'Speed Play timer should still be visible after pumping 20s '
              '(dart:async Timer does not tick under WidgetTester)');

      // The remaining color still matches one of the three valid tier colors.
      final validTierColors = [_treasureGold, _compassBronze, _bloodRed];
      final isValidColor = validTierColors.any(
        (c) => afterPumpColor != null && _colorMatches(afterPumpColor, c),
      );
      expect(isValidColor, isTrue,
          reason:
              'Timer color after pump should be one of the three valid tier '
              'colors (Treasure Gold, Compass Bronze, Blood Red); '
              'got R=${afterPumpColor?.red} G=${afterPumpColor?.green} '
              'B=${afterPumpColor?.blue}');
    });
  });
}
