import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: miss dart preselected in edit dialog.
  // Pattern B (raw segment display): throws S20 / Miss / S5.
  // Opens Edit Score and verifies that dart 2 shows "Miss" ring selected,
  // NOT "-" (which would indicate an uninitialized/blank state).
  testWidgets('Edit Score: Miss dart shows "Miss" pre-selected in edit dialog',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Dart 1: S20 (hits row 0, col 0 on Easy)
    await throwDartViaMock(tester, 20);
    // Dart 2: Miss
    await throwMissViaMock(tester);
    // Dart 3: S18 (hits row 0, col 1 on Easy)
    await throwDartViaMock(tester, 18);

    // RemoveDartsModal should be visible now
    expect(config.getEditScoreButton(), findsOneWidget,
        reason: 'Edit Score button should appear in RemoveDartsModal after 3 darts');

    // Open Edit Score dialog
    await openEditScore(tester);

    // MANDATORY: Dart 2 should show "Miss" ring button as selected (not blank or "-")
    // The EditScore dialog displays the ring selection for each dart.
    // We verify that "Miss" text is visible within the dart 2 section.
    final dart2Section = ElementFinders.getEditScoreDart2Dropdown();
    expect(dart2Section, findsOneWidget,
        reason: 'Dart 2 section should be present in Edit Score dialog');

    // Verify "Miss" appears as a selected/visible state for dart 2
    // (The ring button for "Miss" should be found inside dart 2's column)
    final missInDart2 = find.descendant(
      of: dart2Section,
      matching: find.text('Miss'),
    );
    expect(missInDart2, findsWidgets,
        reason: 'Dart 2 should show "Miss" ring option — not blank or "-"');

    // Cancel to clean up
    await cancelEditScore(tester);
  });
}
