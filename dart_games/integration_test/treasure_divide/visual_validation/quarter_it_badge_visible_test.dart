// integration_test/treasure_divide/visual_validation/quarter_it_badge_visible_test.dart
//
// Programmatic visual test — NOT a screenshot test.
//
// Part A: Solo 2 players + Quarter It ON → start game.
//         Assert TreasureDivideGameKeys.quarterItBadge is in the widget tree.
//         Assert find.descendant(of: badge, matching: find.text('QUARTER IT')) finds text.
//
// Part B: Solo 2 players + Quarter It OFF (default) → verify badge absent.
//         Done by checking same game screen without PTC navigation.
//         (Part B verifies the default game — badge should NOT appear.)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';

final config = GameUIConfig.treasureDivide();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Visual Validation: QUARTER IT badge visible with Quarter It ON; absent with OFF',
      (WidgetTester tester) async {

    // ── Part A: Quarter It ON ─────────────────────────────────────────────
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      quarterItEnabled: true,
    );

    // QUARTER IT badge should be visible
    final badgeFinder =
        find.byKey(TreasureDivideGameKeys.quarterItBadge);
    expect(badgeFinder, findsOneWidget,
        reason:
            'QUARTER IT badge should be visible in the badge row when '
            'Quarter It is enabled');

    // The badge should contain the text "QUARTER IT"
    final textInsideBadge = find.descendant(
      of: badgeFinder,
      matching: find.text('QUARTER IT'),
    );
    expect(textInsideBadge, findsOneWidget,
        reason:
            'QUARTER IT badge should display the text "QUARTER IT" '
            'as its label');


    // ── Part B: Quarter It OFF (fresh game) ──────────────────────────────
    // Start a completely new game without Quarter It enabled.
    // resetServerState clears all state; setupAndStartTreasureDivide navigates
    // back home and starts a new game with default (OFF) settings.
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      // quarterItEnabled = false (default)
    );

    // QUARTER IT badge should NOT be visible
    final badgeFinderOff =
        find.byKey(TreasureDivideGameKeys.quarterItBadge);
    expect(badgeFinderOff, findsNothing,
        reason:
            'QUARTER IT badge should NOT be visible when Quarter It is disabled '
            '(default OFF)');

  });
}
