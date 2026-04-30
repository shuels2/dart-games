import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 17: Bullseye OFF - hitting 20 wins game',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, includeBullseye: false);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    expect(provider.currentGame!.maxTarget, 20);

    provider.currentGame!.currentTarget[playerId] = 20;
    await throwDartViaMock(tester, 20);

    expect(provider.hasWinner, isTrue);
  });
}
