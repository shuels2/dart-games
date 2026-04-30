import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 20: Hitting claimed target for pearls shows light gold border',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // P1 Turn 1: claim 20 with triple, then 2 misses
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // P2 Turn 1: 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // P1 Turn 2: hit 20 again (already claimed by P1, P2 hasn't -> scores pearls)
    await throwDartViaMock(tester, 20);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xB3F4D03F);
  });
}
