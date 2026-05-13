import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Menu: start with all options changed reflects correct game state',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 300,
      doubleFinishEnabled: false,
      shieldRoundEnabled: true,
      speedPlayEnabled: true,
    );

    // Verify game screen loaded
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);

    // Verify all settings applied
    expect(ProviderHelpers.getGladiatorArenaTargetScore(tester), 300);
    expect(ProviderHelpers.isGladiatorArenaDoubleFinishEnabled(tester),
        isFalse);

    // Speed play timer should be visible
    expect(ElementFinders.getGladiatorArenaTimerDisplay(), findsOneWidget);

    // Double badge should NOT be present (DF is OFF)
    expect(ElementFinders.getGladiatorArenaDoubleBadge(), findsNothing);
  });
}
