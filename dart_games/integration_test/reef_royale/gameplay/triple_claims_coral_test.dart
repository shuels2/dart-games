import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Triple dart throw claims coral (3 marks)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    await throwDartViaMock(tester, 20, multiplier: 'triple');

    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
        isTrue);
    expect(
        ProviderHelpers.getReefRoyalePlayerClaimedCount(tester, playerId),
        1);
  });
}
