import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY programmatic visual test: dart indicator states.
  testWidgets(
      'Visual: dart indicators reflect thrown dart states correctly',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Verify dart indicators exist (indices 0, 1, 2)
    expect(ElementFinders.getPiratesGridDartIndicator(0), findsOneWidget,
        reason: 'Dart indicator 0 should be visible at start');
    expect(ElementFinders.getPiratesGridDartIndicator(1), findsOneWidget,
        reason: 'Dart indicator 1 should be visible at start');
    expect(ElementFinders.getPiratesGridDartIndicator(2), findsOneWidget,
        reason: 'Dart indicator 2 should be visible at start');

    // 0 darts thrown initially
    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    expect(provider.getCurrentPlayerDartsThrown(), 0,
        reason: 'No darts thrown at start');

    // Throw dart 1: S20
    await throwDartViaMock(tester, 20);
    expect(provider.getCurrentPlayerDartsThrown(), 1,
        reason: 'Dart indicator 1 should be filled after first throw');

    // Throw dart 2: Miss
    await throwMissViaMock(tester);
    expect(provider.getCurrentPlayerDartsThrown(), 2,
        reason: 'Dart indicator 2 should be filled after second throw');

    // Throw dart 3: S18
    await throwDartViaMock(tester, 18);
    expect(provider.getCurrentPlayerDartsThrown(), 3,
        reason: 'All 3 dart indicators should be filled after third throw');

    // All 3 dart indicators remain visible
    expect(ElementFinders.getPiratesGridDartIndicator(0), findsOneWidget);
    expect(ElementFinders.getPiratesGridDartIndicator(1), findsOneWidget);
    expect(ElementFinders.getPiratesGridDartIndicator(2), findsOneWidget);
  });
}
