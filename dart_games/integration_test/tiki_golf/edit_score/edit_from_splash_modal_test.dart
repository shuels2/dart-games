import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

/// Edit Score from the Splash/Mulligan modal.
///
/// With Mulligan ON, a Splash replaces the RemoveDartsModal with the
/// splash/mulligan modal — which carries its own "Edit Player Score" button.
/// The existing edit-score tests all run with Mulligan OFF, so they exercise
/// the RemoveDartsModal button only; this covers the splash modal's copy,
/// whose onSubmit was previously a no-op that silently discarded the edit.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: editing from the Splash modal updates the recorded score',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        maxStrokes: 3, mulliganEnabled: true, playerNames: ['Alice', 'Bob']);

    final playerId = ProviderHelpers.getTikiGolfCurrentPlayerId(tester)!;
    final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
    final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);

    // Miss every dart → Splash → splash/mulligan modal (not RemoveDartsModal).
    await throwAllMissesToSplash(tester, maxStrokes: 3);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole), 4,
        reason: 'Splash should record strokes = maxStrokes + 1 before the edit');
    expect(ElementFinders.getTikiGolfUseMulliganButton(), findsOneWidget,
        reason: 'The splash/mulligan modal should be the visible modal here');

    // Edit dart 1 to the hole target → Birdie (strokes = 1).
    await EditScoreHelpers.editScoreAndSave(tester, config, dart1: 'S$target');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(ProviderHelpers.getTikiGolfPlayerHoleScore(tester, playerId, hole), 1,
        reason:
            'Editing from the splash modal must reach the provider — a no-op '
            'onSubmit leaves the Splash score of 4 in place');
    expect(ElementFinders.getTikiGolfUseMulliganButton(), findsNothing,
        reason:
            'With the Splash edited away the mulligan modal should dismiss');
  });
}
