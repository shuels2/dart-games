import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: single dart subtracts face value from altitude',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final playerId = getCurrentPlayerId(tester)!;
    final startAlt = getAltitude(tester, playerId);

    // Throw single 15 — should subtract 15
    await throwDartViaMock(tester, 15);

    expect(getAltitude(tester, playerId), startAlt - 15);
  });
}
