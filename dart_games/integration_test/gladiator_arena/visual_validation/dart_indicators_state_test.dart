import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Visual: dart indicators render for each thrown dart',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Initially all 3 dart indicator slots should be present
    expect(ElementFinders.getGladiatorArenaDartIndicator(0), findsOneWidget,
        reason: 'Dart indicator D1 should be present');
    expect(ElementFinders.getGladiatorArenaDartIndicator(1), findsOneWidget,
        reason: 'Dart indicator D2 should be present');
    expect(ElementFinders.getGladiatorArenaDartIndicator(2), findsOneWidget,
        reason: 'Dart indicator D3 should be present');

    // Throw 1 dart
    await throwDartViaMock(tester, 20);
    final dartsThrown =
        ProviderHelpers.getGladiatorArenaCurrentPlayerDartsThrown(tester);
    expect(dartsThrown, 1, reason: 'Should have 1 dart thrown');

    // Indicators should still be visible
    expect(ElementFinders.getGladiatorArenaDartIndicator(0), findsOneWidget);
    expect(ElementFinders.getGladiatorArenaDartIndicator(1), findsOneWidget);
    expect(ElementFinders.getGladiatorArenaDartIndicator(2), findsOneWidget);
  });
}
