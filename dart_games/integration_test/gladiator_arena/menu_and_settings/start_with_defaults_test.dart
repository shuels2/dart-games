import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: start game with default settings navigates to game screen',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Verify game screen loaded
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);
    expect(ElementFinders.getGladiatorArenaGoalDisplay(), findsOneWidget);

    // Verify target score is default 200
    expect(ProviderHelpers.getGladiatorArenaTargetScore(tester), 200);

    // Double Finish should be ON by default
    expect(
        ProviderHelpers.isGladiatorArenaDoubleFinishEnabled(tester), isTrue);
  });
}
