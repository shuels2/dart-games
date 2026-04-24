import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 12: Bullseye adds 2 marks to Bull target',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    await throwBullseyeViaMock(tester);

    // Bull target is 25, bullseye gives 2 marks
    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 25), 2);
  });
}
