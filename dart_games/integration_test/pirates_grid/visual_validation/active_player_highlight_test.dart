import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY programmatic visual test: active player highlight.
  testWidgets(
      'Visual: active player highlight swaps after turn advances',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    // Verify P1 is active at start
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
        reason: 'P1 should be active at start');

    // Active avatar should be present
    expect(ElementFinders.getPiratesGridPlayerAvatarActive(), findsOneWidget,
        reason: 'Active player avatar should be visible at start');

    // Inactive avatar should also be present
    expect(ElementFinders.getPiratesGridPlayerAvatarInactive(), findsOneWidget,
        reason: 'Inactive player avatar should be visible at start');

    // Both player names should be visible
    expect(find.text('Player A'), findsWidgets,
        reason: 'P1 name should be visible');
    expect(find.text('Player B'), findsWidgets,
        reason: 'P2 name should be visible');

    // P1 completes turn → P2 becomes active
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Verify P2 is now active
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p2Id,
        reason: 'P2 should be active after P1 completes turn');

    // Active avatar widget should still be present (now showing P2)
    expect(ElementFinders.getPiratesGridPlayerAvatarActive(), findsOneWidget,
        reason: 'Active player avatar should be visible (now P2)');

    // Inactive avatar should still be present (now showing P1)
    expect(ElementFinders.getPiratesGridPlayerAvatarInactive(), findsOneWidget,
        reason: 'Inactive player avatar should be visible (now P1)');
  });
}
