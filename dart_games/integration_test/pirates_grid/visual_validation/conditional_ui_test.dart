import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY programmatic visual test: conditional UI elements.
  // Verifies that STEAL MODE badge, Speed Play timer, and round tracker
  // only appear when the corresponding option is enabled.
  testWidgets(
      'Visual: conditional UI — badges absent by default, present when enabled',
      (WidgetTester tester) async {
    // ========================================================
    // Part 1: Default settings — no conditional badges visible
    // ========================================================
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy',
        bestOf: '1',
        stealMode: false,
        speedPlay: false,
        playerNames: ['Player A', 'Player B']);

    // Steal Mode badge should NOT be visible
    expect(ElementFinders.getPiratesGridStealModeBadge(), findsNothing,
        reason: 'STEAL MODE badge should be absent when Steal Mode is OFF');

    // Speed Play timer should NOT be visible
    expect(ElementFinders.getPiratesGridSpeedPlayTimer(), findsNothing,
        reason: 'Speed Play timer should be absent when Speed Play is OFF');

    // Round tracker should NOT be visible (Bo1)
    expect(ElementFinders.getPiratesGridRoundTracker(), findsNothing,
        reason: 'Round tracker should be absent for Best Of 1');

    // Navigate back to menu (no darts thrown, no save modal)
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // ========================================================
    // Part 2: Bo3 + Steal + Speed — all conditional badges visible
    // ========================================================
    await setupAndStartGame(tester, config,
        difficulty: 'Easy',
        bestOf: '3',
        stealMode: true,
        speedPlay: true,
        playerNames: ['Player A', 'Player B']);

    // Steal Mode badge SHOULD be visible
    expect(ElementFinders.getPiratesGridStealModeBadge(), findsOneWidget,
        reason: 'STEAL MODE badge should be visible when Steal Mode is ON');

    // Speed Play timer SHOULD be visible
    expect(ElementFinders.getPiratesGridSpeedPlayTimer(), findsOneWidget,
        reason: 'Speed Play timer should be visible when Speed Play is ON');

    // Round tracker SHOULD be visible (Bo3)
    expect(ElementFinders.getPiratesGridRoundTracker(), findsOneWidget,
        reason: 'Round tracker should be visible for Best Of 3');
  });
}
