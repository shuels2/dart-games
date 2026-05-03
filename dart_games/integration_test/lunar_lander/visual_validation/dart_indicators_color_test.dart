import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Color constants from lunar_lander_game_screen.dart
  const moonDustGray = Color(0xFFD4C5A9); // skip/miss path
  const missionGreen = Color(0xFF52B788); // scoring dart fill

  final config = GameUIConfig.lunarLander();

  // Verifies the AppBar D1/D2/D3 dart indicators show the correct color
  // (and label) for empty / scoring / skip states across a single turn.
  testWidgets('Visual: dart indicators reflect score state with correct colors',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(tester, config,
        playerNames: ['Player A', 'Player B']);

    // ----- Initial state: all 3 indicators empty -----
    for (int i = 0; i < 3; i++) {
      final indicator = tester.widget<Container>(
        find.byKey(LunarLanderGameKeys.dartIndicator(i)),
      );
      final decoration = indicator.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent,
          reason: 'Empty indicator $i should have transparent fill');
    }
    // Empty indicators show "—"
    expect(find.text('—'), findsWidgets,
        reason: 'Empty indicators should display the em-dash placeholder');

    // ----- Throw a scoring dart (single 20) -> D1 = mission green -----
    await DartThrowHelpers.throwDartViaMock(tester, 20);

    final d0 = tester.widget<Container>(
      find.byKey(LunarLanderGameKeys.dartIndicator(0)),
    );
    final d0Decoration = d0.decoration as BoxDecoration;
    // Filled-state color is `slotColor.withOpacity(0.25)` and border is slotColor.
    expect(d0Decoration.color, missionGreen.withOpacity(0.25),
        reason: 'D1 fill should be mission-green at 25% opacity for a scoring dart');
    expect((d0Decoration.border as Border).top.color, missionGreen,
        reason: 'D1 border should be solid mission-green for a scoring dart');
    // Score "20" should be visible inside D1
    expect(
      find.descendant(
        of: find.byKey(LunarLanderGameKeys.dartIndicator(0)),
        matching: find.text('20'),
      ),
      findsOneWidget,
      reason: 'D1 should display "20"',
    );

    // ----- Throw a miss -> D2 = moon-dust gray (skip path) -----
    await DartThrowHelpers.throwMissViaMock(tester);

    final d1 = tester.widget<Container>(
      find.byKey(LunarLanderGameKeys.dartIndicator(1)),
    );
    final d1Decoration = d1.decoration as BoxDecoration;
    final d1SlotColor = moonDustGray.withOpacity(0.5);
    expect(d1Decoration.color, d1SlotColor.withOpacity(0.25),
        reason: 'D2 (miss) fill should be moon-dust gray at 25% opacity');
    expect((d1Decoration.border as Border).top.color, d1SlotColor,
        reason: 'D2 (miss) border should be moon-dust gray');
    // Miss/skip indicators show "—"
    expect(
      find.descendant(
        of: find.byKey(LunarLanderGameKeys.dartIndicator(1)),
        matching: find.text('—'),
      ),
      findsOneWidget,
      reason: 'D2 (miss) should display the em-dash placeholder',
    );

    // ----- Throw another scoring dart (single 10) -> D3 = mission green -----
    await DartThrowHelpers.throwDartViaMock(tester, 10);

    final d2 = tester.widget<Container>(
      find.byKey(LunarLanderGameKeys.dartIndicator(2)),
    );
    final d2Decoration = d2.decoration as BoxDecoration;
    expect(d2Decoration.color, missionGreen.withOpacity(0.25),
        reason: 'D3 fill should be mission-green at 25% opacity for a scoring dart');
    expect((d2Decoration.border as Border).top.color, missionGreen,
        reason: 'D3 border should be solid mission-green for a scoring dart');
    expect(
      find.descendant(
        of: find.byKey(LunarLanderGameKeys.dartIndicator(2)),
        matching: find.text('10'),
      ),
      findsOneWidget,
      reason: 'D3 should display "10"',
    );
  });
}
