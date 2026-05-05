import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: double hit subtracts 2x face value',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final playerId = getCurrentPlayerId(tester)!;
    final startAlt = getAltitude(tester, playerId);

    // Throw double 10 = 20 subtracted
    await throwDartViaMock(tester, 10, multiplier: 'double');

    expect(getAltitude(tester, playerId), startAlt - 20);
  });
}
