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

    // Read actual targets for cells [0,0] and [0,1]
    final target00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    final target01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);

    // Plant first flag
    await throwDartViaMock(tester, target00);
    expect(provider.currentGame!.getFlagsPlanted(p1Id), 1,
        reason: 'P1 should have 1 flag after hitting cell [0,0] target');

    // Plant second flag
    await throwDartViaMock(tester, target01);
    expect(provider.currentGame!.getFlagsPlanted(p1Id), 2,
        reason: 'P1 should have 2 flags after hitting cell [0,1] target');

    // Counter widget should still be present
    expect(ElementFinders.getPiratesGridFlagsCounter(p1Id), findsOneWidget,
        reason: 'Flags counter widget should be visible after 2 flags planted');
  });
}
