import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Verifies the Edit Score button is HIDDEN before 3 darts are thrown,
  // and only becomes visible AFTER the third dart triggers the takeout flow
  // (RemoveDartsModal hosts the Edit Score button per spec §10B).
  testWidgets('Edit Score: button visibility timing — hidden until 3rd dart triggers takeout',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Before any darts: button NOT visible
    expect(config.getEditScoreButton(), findsNothing,
        reason: 'Edit Score button should be hidden before any darts thrown');

    // After 1st dart: still NOT visible
    await throwDartViaMock(tester, 5);
    expect(config.getEditScoreButton(), findsNothing,
        reason: 'Edit Score button should remain hidden after 1 dart');

    // After 2nd dart: still NOT visible
    await throwDartViaMock(tester, 5);
    expect(config.getEditScoreButton(), findsNothing,
        reason: 'Edit Score button should remain hidden after 2 darts');

    // 3rd dart triggers the takeout flow; the RemoveDartsModal (which hosts
    // the Edit Score button) renders once shouldPromptTakeout flips to true.
    await throwDartViaMock(tester, 5);

    // Pump enough for the modal to render
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(config.getEditScoreButton(), findsOneWidget,
        reason: 'Edit Score button should be visible after the 3rd dart');
  });
}
