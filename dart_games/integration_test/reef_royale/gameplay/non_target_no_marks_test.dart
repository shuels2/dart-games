import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 11: Non-target number does not add marks',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Hit number 10 (not a standard target)
    await throwDartViaMock(tester, 10);

    // No marks should be added to any target
    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);
    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 19), 0);
  });
}
