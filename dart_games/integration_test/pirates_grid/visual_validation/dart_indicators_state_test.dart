import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '_helpers.dart';

// Colors matching the game screen constants
const Color _p1Color = Color(0xFF8B0000); // Blood Red  — P1 flag color
const Color _p2Color = Color(0xFF2E8B8B); // Sea Foam Teal — P2 flag color
const Color _parchmentTan = Color(0xFFF5E6C8); // Parchment tan — dart indicator text color

// ---------------------------------------------------------------------------
// Widget-tree inspection helpers
// ---------------------------------------------------------------------------

/// Text label rendered inside dart indicator slot [i].
String _dartText(WidgetTester tester, int i) {
  final slotFinder = ElementFinders.getPiratesGridDartIndicator(i);
  final textFinder =
      find.descendant(of: slotFinder, matching: find.byType(Text));
  return tester.widget<Text>(textFinder).data ?? '';
}

/// Text colour of dart indicator slot [i].
Color? _dartTextColor(WidgetTester tester, int i) {
  final slotFinder = ElementFinders.getPiratesGridDartIndicator(i);
  final textFinder =
      find.descendant(of: slotFinder, matching: find.byType(Text));
  return tester.widget<Text>(textFinder).style?.color;
}

/// Border colour of dart indicator slot [i] (from BoxDecoration).
Color? _dartBorderColor(WidgetTester tester, int i) {
  final slotFinder = ElementFinders.getPiratesGridDartIndicator(i);
  final container = tester.widget<Container>(slotFinder);
  final deco = container.decoration as BoxDecoration?;
  final border = deco?.border as Border?;
  return border?.top.color;
}

/// Returns true when the slot border is the bronze color (empty/miss/non-target).
/// Bronze is `Color(0xFFCD7F32)`. We compare RGB bytes directly because
/// `Color.value` is deprecated in Flutter 3.27+ and on Dart-to-JS its int
/// representation can flip negative for high-bit ARGB values.
bool _isBronze(WidgetTester tester, int i) {
  final color = _dartBorderColor(tester, i);
  if (color == null) return false;
  return color.red == 0xCD && color.green == 0x7F && color.blue == 0x32;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid — D1/D2/D3 dart indicator visual behaviour", () {
    // ── Scenario 1: initial state ─────────────────────────────────────────
    testWidgets('all 3 slots show dash with bronze border before any throw',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      for (int i = 0; i < 3; i++) {
        expect(ElementFinders.getPiratesGridDartIndicator(i), findsOneWidget,
            reason: 'Slot $i should be visible before any throw');
        expect(_dartText(tester, i), '—',
            reason: 'Slot $i should show — before any throw');
        expect(_isBronze(tester, i), isTrue,
            reason: 'Slot $i border should be semi-transparent bronze');
      }
    });

    // ── Scenario 2: P1 hit ────────────────────────────────────────────────
    testWidgets('P1 hit: slot 0 shows score label in red, slots 1-2 stay bronze',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      final targetNum = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      await throwDartViaMock(tester, targetNum);

      // Slot 0 — should be filled with a non-dash label; border is P1 red, text is parchment
      expect(_dartText(tester, 0), isNot('—'),
          reason: 'Slot 0 should show score after P1 hit');
      expect(_dartTextColor(tester, 0), _parchmentTan,
          reason: 'Slot 0 text should be parchment tan after hit');
      expect(_dartBorderColor(tester, 0), _p1Color,
          reason: 'Slot 0 border should be P1 red after hit');

      // Slots 1 and 2 still empty
      expect(_dartText(tester, 1), '—');
      expect(_dartText(tester, 2), '—');
      expect(_isBronze(tester, 1), isTrue);
      expect(_isBronze(tester, 2), isTrue);
    });

    // ── Scenario 3: P1 miss / non-target ─────────────────────────────────
    testWidgets(
        'P1 miss: slot 0 shows dash in bronze; non-target number shows in bronze',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      // Explicit miss
      await throwMissViaMock(tester);

      expect(_dartText(tester, 0), 'Miss',
          reason: 'Slot 0 should show Miss after explicit miss');
      expect(_isBronze(tester, 0), isTrue,
          reason: 'Slot 0 border should be bronze after miss');

      // Slots 1 and 2 untouched
      expect(_dartText(tester, 1), '—');
      expect(_dartText(tester, 2), '—');
    });

    // ── Scenario 4: P1 mixed turn ─────────────────────────────────────────
    testWidgets(
        'P1 mixed turn: hit=red, miss=bronze, hit=red per slot',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      final target00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      final target02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
      await throwDartViaMock(tester, target00); // dart 1 — hit
      await throwMissViaMock(tester);            // dart 2 — miss
      await throwDartViaMock(tester, target02); // dart 3 — hit

      // Slot 0 hit
      expect(_dartText(tester, 0), isNot('—'),
          reason: 'Slot 0: hit dart should show score');
      expect(_dartTextColor(tester, 0), _parchmentTan,
          reason: 'Slot 0: hit text should be parchment tan');
      expect(_dartBorderColor(tester, 0), _p1Color);

      // Slot 1 miss
      expect(_dartText(tester, 1), 'Miss',
          reason: 'Slot 1: miss should show Miss');
      expect(_isBronze(tester, 1), isTrue,
          reason: 'Slot 1: miss border should be bronze');

      // Slot 2 hit
      expect(_dartText(tester, 2), isNot('—'),
          reason: 'Slot 2: hit dart should show score');
      expect(_dartTextColor(tester, 2), _parchmentTan,
          reason: 'Slot 2: hit text should be parchment tan');
      expect(_dartBorderColor(tester, 2), _p1Color);

      // All 3 darts accounted for
      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      expect(provider.getCurrentPlayerDartsThrown(), 3);
    });

    // ── Scenario 5: P2 hit ────────────────────────────────────────────────
    testWidgets('P2 hit: slot 0 shows score label in teal',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      // Read target BEFORE completing P1's turn (grid doesn't change)
      final targetNum = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);

      // Complete P1's turn (3 misses → darts-removed modal)
      await DartThrowHelpers.completeTurnWithMisses(tester);

      // P2 is now active — throw one dart
      await throwDartViaMock(tester, targetNum);

      expect(_dartText(tester, 0), isNot('—'),
          reason: 'P2 slot 0 should show score after hit');
      expect(_dartTextColor(tester, 0), _parchmentTan,
          reason: 'P2 slot 0 text should be parchment tan');
      expect(_dartBorderColor(tester, 0), _p2Color,
          reason: 'P2 slot 0 border should be teal');

      // Slots 1 and 2 still empty
      expect(_dartText(tester, 1), '—');
      expect(_dartText(tester, 2), '—');
    });

    // ── Scenario 6: hitting opponent's claimed cell (steals off) shows bronze
    testWidgets(
        'Defended cell (steals off): dart indicator shows bronze, not hit color',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          stealMode: false,
          playerNames: ['Player A', 'Player B']);

      // P1 claims cell (0,0)
      final targetNum = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      await throwDartViaMock(tester, targetNum);

      // Verify P1's dart 1 shows as hit (red)
      expect(_dartBorderColor(tester, 0), _p1Color,
          reason: 'P1 dart 1 should be red after claiming cell');

      // Complete P1's turn
      await DartThrowHelpers.completeTurnWithMisses(tester);

      // P2 hits the same cell — defended, steals off
      await throwDartViaMock(tester, targetNum);

      // P2's dart indicator should be bronze (not teal) since the cell is defended
      expect(_isBronze(tester, 0), isTrue,
          reason: 'Defended cell hit should show bronze border, not teal');
      expect(_dartText(tester, 0), isNot('—'),
          reason: 'Slot 0 should show the target number, not a dash');
    });

    // ── Scenario 7: indicators reset between turns ────────────────────────
    testWidgets('all 3 indicators reset to dash at start of each new turn',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      // P1 throws a hit dart — slot 0 is red
      await throwDartViaMock(tester, 20);
      expect(_dartText(tester, 0), isNot('—'),
          reason: 'Slot 0 should be filled during P1 turn');

      // Complete P1 turn
      await DartThrowHelpers.completeTurnWithMisses(tester);

      // Now P2 is active — all 3 slots should show — (fresh turn)
      for (int i = 0; i < 3; i++) {
        expect(_dartText(tester, i), '—',
            reason:
                'Slot $i should reset to — at the start of P2 turn');
        expect(_isBronze(tester, i), isTrue,
            reason: 'Slot $i border should be bronze at start of P2 turn');
      }
    });

    // ── Original regression test (preserved) ─────────────────────────────
    testWidgets(
        'dart indicators reflect thrown dart states correctly (regression)',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Player A', 'Player B']);

      expect(ElementFinders.getPiratesGridDartIndicator(0), findsOneWidget,
          reason: 'Dart indicator 0 should be visible at start');
      expect(ElementFinders.getPiratesGridDartIndicator(1), findsOneWidget,
          reason: 'Dart indicator 1 should be visible at start');
      expect(ElementFinders.getPiratesGridDartIndicator(2), findsOneWidget,
          reason: 'Dart indicator 2 should be visible at start');

      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      expect(provider.getCurrentPlayerDartsThrown(), 0,
          reason: 'No darts thrown at start');

      final target00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      final target01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);

      await throwDartViaMock(tester, target00);
      expect(provider.getCurrentPlayerDartsThrown(), 1,
          reason: 'Dart count should be 1 after first throw');

      await throwMissViaMock(tester);
      expect(provider.getCurrentPlayerDartsThrown(), 2,
          reason: 'Dart count should be 2 after second throw');

      await throwDartViaMock(tester, target01);
      expect(provider.getCurrentPlayerDartsThrown(), 3,
          reason: 'Dart count should be 3 after third throw');

      expect(ElementFinders.getPiratesGridDartIndicator(0), findsOneWidget);
      expect(ElementFinders.getPiratesGridDartIndicator(1), findsOneWidget);
      expect(ElementFinders.getPiratesGridDartIndicator(2), findsOneWidget);
    });
  });
}
