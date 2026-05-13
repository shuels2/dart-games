import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

/// Gap-coverage test (cross-game audit). When Speed Play expires mid-turn,
/// the provider fills remaining dart slots with `'X'` markers (value 0). The
/// game screen's `_buildInitialSegments` then maps both `'Skip'` and `'X'`
/// to `'Miss'` when opening the Edit Score modal, so the player can replace
/// the unrolled-from-X slots with real dart values. This test verifies the
/// end-to-end flow:
///   1. Throw 1 dart (S20=20) under Speed Play
///   2. Let the timer expire — provider pads X markers, turn commits at 20
///   3. Open Edit Score — must show dart slots editable (no crash, no stuck
///      "X" labels), and Edit Score can replace the post-expiry X markers
///      with real darts that re-commit the score.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: opening after a Speed Play timeout (X-padded turn) lets '
      'the player replace X markers with real darts',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 500,
      speedPlayEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    final p1Id = ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Throw 1 dart, then let the 25s timer expire.
    await throwDartViaMock(tester, 20); // S20 = 20 pts
    await tester.pump(const Duration(seconds: 26));
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // Post-expiry commit: 20 pts. Two X markers padded.
    expect(ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id), 20,
        reason: 'Speed Play expiry commits prospective at 1 real dart');

    // Open Edit Score from the remove-darts modal flow.
    await openEditScore(tester, config);
    expect(ElementFinders.getEditScoreDart1Dropdown(), findsOneWidget);
    expect(ElementFinders.getEditScoreDart2Dropdown(), findsOneWidget,
        reason: 'X-padded dart 2 slot must be editable post-expiry');
    expect(ElementFinders.getEditScoreDart3Dropdown(), findsOneWidget,
        reason: 'X-padded dart 3 slot must be editable post-expiry');

    // Replace the X markers with real darts: keep dart 1 = S20, set dart 2/3
    // to S10 + S5. Re-commit and verify new score (35 = 20+10+5).
    await setDart2(tester, 'S10');
    await setDart3(tester, 'S5');
    await updateScore(tester);
    await PumpSequences.fullRebuild(tester);

    expect(ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id), 35,
        reason:
            'Edit-Score replay must re-commit with the replaced darts after '
            'a Speed Play X-padded turn');
  });
}
