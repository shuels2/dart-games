import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Single dart throw registers 1 mark',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    await throwDartViaMock(tester, 20);

    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 1);
    expect(
        ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 1);
  });
}
