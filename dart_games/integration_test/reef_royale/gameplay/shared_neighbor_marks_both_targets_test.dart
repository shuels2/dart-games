import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 26: Shared neighbor hit adds marks to both targets',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, neighborNumbers: true);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Standard targets: 20, 19, 18, 17, 16, 15, Bull
    // Number 1 is neighbor of both 20 AND 18 on the dartboard
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 18), 0);

    // Throw 1 -- shared neighbor of 20 and 18
    await throwDartViaMock(tester, 1);

    // Both targets should get 1 mark
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 1);
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 18), 1);

    // Other targets should be unaffected
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 19), 0);
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 17), 0);
  });
}
