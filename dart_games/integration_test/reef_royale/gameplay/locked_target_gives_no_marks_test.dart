import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 14: Locked target gives no marks',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // P1 claims target 20
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // P2 claims target 20
    await throwDartViaMock(tester, 20, multiplier: 'triple');

    // Target 20 should be locked (both players claimed)
    expect(
        ProviderHelpers.isReefRoyaleTargetLocked(tester, 20), isTrue);
  });
}
