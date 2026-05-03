import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: descent track reflects current altitude',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final playerId = getCurrentPlayerId(tester)!;
    final startAlt = getAltitude(tester, playerId);
    expect(startAlt, 200); // default altitude

    // Throw three darts: 20 + 20 + 20 = 60 total descent
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    final altAfterTurn = getAltitude(tester, playerId);
    expect(altAfterTurn, startAlt - 60);
  });
}
