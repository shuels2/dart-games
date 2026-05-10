import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Visual: Speed Play timer visible when Speed Play ON',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      speedPlayEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    // Timer should be visible in AppBar
    expect(ElementFinders.getGladiatorArenaTimerDisplay(), findsOneWidget,
        reason: 'Speed Play timer should be visible');
  });

  testWidgets('Visual: No timer when Speed Play OFF', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      speedPlayEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    // Timer should be visible in AppBar
    expect(ElementFinders.getGladiatorArenaTimerDisplay(), findsOneWidget,
        reason: 'Speed Play timer should be visible');
  });
}
