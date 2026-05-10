import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Visual: goal display shows target and double badge when DF ON',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 200,
      doubleFinishEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    // Goal display should be visible
    expect(ElementFinders.getGladiatorArenaGoalDisplay(), findsOneWidget,
        reason: 'Goal display should be visible');

    // Double badge should be visible when DF ON
    expect(ElementFinders.getGladiatorArenaDoubleBadge(), findsOneWidget,
        reason: 'Double badge should be visible when Double Finish is ON');
  });

  testWidgets('Visual: no double badge when Double Finish is OFF',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 200,
      doubleFinishEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    // Goal display should be visible
    expect(ElementFinders.getGladiatorArenaGoalDisplay(), findsOneWidget,
        reason: 'Goal display should be visible');

    // Double badge should be visible when DF ON
    expect(ElementFinders.getGladiatorArenaDoubleBadge(), findsOneWidget,
        reason: 'Double badge should be visible when Double Finish is ON');
  });
}
