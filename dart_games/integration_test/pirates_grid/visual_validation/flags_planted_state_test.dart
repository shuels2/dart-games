import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY programmatic visual test: flags planted counter.
  testWidgets(
      'Visual: flags counter updates as flags are planted',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Verify initial flags counter: 0
    expect(provider.currentGame!.getFlagsPlanted(p1Id), 0,
        reason: 'P1 should have 0 flags at start');

    // Flags counter widget should be present
    expect(ElementFinders.getPiratesGridFlagsCounter(p1Id), findsOneWidget,
        reason: 'Flags counter widget should be visible');

    // Plant first flag: S20 → cell [0,0]
    await throwDartViaMock(tester, 20);
    expect(provider.currentGame!.getFlagsPlanted(p1Id), 1,
        reason: 'P1 should have 1 flag after S20');

    // Plant second flag: S18 → cell [0,1]
    await throwDartViaMock(tester, 18);
    expect(provider.currentGame!.getFlagsPlanted(p1Id), 2,
        reason: 'P1 should have 2 flags after S18');

    // Counter widget should still be present
    expect(ElementFinders.getPiratesGridFlagsCounter(p1Id), findsOneWidget,
        reason: 'Flags counter widget should be visible after 2 flags planted');
  });
}
