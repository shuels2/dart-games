// integration_test/treasure_divide/edit_score/miss_dart_preselected_in_edit_test.dart
//
// Edit-2 (Rule §6b) — When a turn includes a miss dart, the EditScoreDialog
// pre-selects "Miss" for that dart position.
// Flow: P1 throws hit/miss/hit → RemoveDartsModal → open Edit Score dialog →
// verify dart 2 section is rendered and contains the "Miss" ring option.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: miss dart is pre-selected in edit dialog',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 9, playerNames: ['MissP1', 'MissP2']);

    // Round 0, target = 20.
    // Throw: dart1=hit target, dart2=miss, dart3=hit target
    final roundIdx =
        ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
    final target =
        ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);

    await throwDartViaMock(tester, target); // dart 1: hit
    await throwMissViaMock(tester);         // dart 2: miss
    await throwDartViaMock(tester, target); // dart 3: hit

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Open the EditScoreDialog from the RemoveDartsModal
    await EditScoreHelpers.openEditScore(tester, config);
    EditScoreHelpers.verifyDialogOpen();

    // Verify all three dart sections are present
    final dart1Section = ElementFinders.getEditScoreDart1Dropdown();
    final dart2Section = ElementFinders.getEditScoreDart2Dropdown();
    final dart3Section = ElementFinders.getEditScoreDart3Dropdown();
    expect(dart1Section, findsOneWidget,
        reason: '[DIAG td_edit_miss_presel] Dart 1 section not found');
    expect(dart2Section, findsOneWidget,
        reason: '[DIAG td_edit_miss_presel] Dart 2 section not found');
    expect(dart3Section, findsOneWidget,
        reason: '[DIAG td_edit_miss_presel] Dart 3 section not found');

    // Dart 2 was a miss — the "Miss" ring button should be present in dart-2
    // section (pre-populated from initialSegments).
    final missInDart2 = find.descendant(
      of: dart2Section,
      matching: find.text('Miss'),
    );
    expect(missInDart2, findsOneWidget,
        reason:
            '[DIAG td_edit_miss_presel] "Miss" ring button not found in dart 2 '
            'section — miss dart not pre-selected from initialSegments');

    // Cancel without saving
    await EditScoreHelpers.cancelEditScore(tester);
    EditScoreHelpers.verifyDialogClosed();
  });
}
