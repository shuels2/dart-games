import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Coral card updates after claim',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Coral card for 20 should exist before claiming
    expect(find.byKey(ReefRoyaleGameKeys.coralCard(20)), findsOneWidget);

    // Claim target 20 with triple
    await throwDartViaMock(tester, 20, multiplier: 'triple');

    // Verify the claim happened in provider
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
        isTrue);

    // Coral card should still be present (now in claimed state)
    expect(find.byKey(ReefRoyaleGameKeys.coralCard(20)), findsOneWidget);
  });
}
