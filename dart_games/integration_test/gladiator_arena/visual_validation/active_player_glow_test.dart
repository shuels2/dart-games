import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Visual: active player name label shows under active podium',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Active player name label should be visible
    expect(
        ElementFinders.getGladiatorArenaActivePlayerNameLabel(),
        findsOneWidget,
        reason: 'Active player name label should be visible');

    // P1's podium should be visible
    expect(ElementFinders.getGladiatorArenaPodium(p1Id), findsOneWidget,
        reason: 'P1 podium should be visible');

    // After P1's turn, P2 becomes active
    await completeTurnWithMisses(tester);

    final p2Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;
    expect(p2Id, isNot(equals(p1Id)));

    // Active player name label should still be visible (now showing P2)
    expect(
        ElementFinders.getGladiatorArenaActivePlayerNameLabel(),
        findsOneWidget,
        reason: 'Active player name label should update to P2');
  });
}
