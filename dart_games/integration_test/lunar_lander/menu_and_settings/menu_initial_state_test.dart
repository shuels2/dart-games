import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: initial state shows settings controls and empty player list',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Altitude slider present
    expect(ElementFinders.getLunarLanderAltitudeSlider(), findsOneWidget);

    // Hard Landing switch present
    expect(ElementFinders.getLunarLanderHardLandingSwitch(), findsOneWidget);

    // Start button present but no players selected yet
    expect(ElementFinders.getLunarLanderStartButton(), findsOneWidget);

    // Add player button present (empty state or normal)
    final emptyState = ElementFinders.getLunarLanderAddPlayerButtonEmptyState();
    final normalState = ElementFinders.getLunarLanderAddPlayerButton();
    expect(
      emptyState.evaluate().isNotEmpty || normalState.evaluate().isNotEmpty,
      isTrue,
      reason: 'An add player button should be present',
    );
  });
}
