// integration_test/treasure_divide/visual_validation/custom_badge_visible_test.dart
//
// Programmatic visual test — NOT a screenshot test.
//
// Part A: Solo 2 players + Custom Targets ON → start game.
//         Assert TreasureDivideGameKeys.customBadge is in the widget tree.
//         Assert find.descendant(of: badge, matching: find.text('CUSTOM')) finds text.
//
// Part B: Solo 2 players + Custom Targets OFF (default) → verify badge absent.
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
      'Visual Validation: CUSTOM badge visible with Custom Targets ON; absent with OFF',
      (WidgetTester tester) async {

    // ── Part A: Custom Targets ON ─────────────────────────────────────────
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      customTargetsEnabled: true,
    );

    // CUSTOM badge should be visible
    final badgeFinder = find.byKey(TreasureDivideGameKeys.customBadge);
    expect(badgeFinder, findsOneWidget,
        reason:
            'CUSTOM badge should be visible in the badge row when '
            'Custom Targets is enabled');

    // The badge should contain the text "CUSTOM"
    final textInsideBadge = find.descendant(
      of: badgeFinder,
      matching: find.text('CUSTOM'),
    );
    expect(textInsideBadge, findsOneWidget,
        reason:
            'CUSTOM badge should display the text "CUSTOM" as its label');


    // ── Part B: Custom Targets OFF (fresh game) ───────────────────────────
    // Start a completely new game without Custom Targets enabled.
    // resetServerState clears all state; setupAndStartTreasureDivide navigates
    // back home and starts a new game with default (OFF) settings.
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      // customTargetsEnabled = false (default)
    );

    // CUSTOM badge should NOT be visible
    final badgeFinderOff = find.byKey(TreasureDivideGameKeys.customBadge);
    expect(badgeFinderOff, findsNothing,
        reason:
            'CUSTOM badge should NOT be visible when Custom Targets is disabled '
            '(default OFF)');

  });
}
