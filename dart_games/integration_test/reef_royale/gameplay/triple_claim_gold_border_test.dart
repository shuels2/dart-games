import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 17: Triple claim shows gold border on D1 and D2',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // D1: Triple 20 (3 marks = claimed) -> gold
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFFF4D03F);

    // D2: Triple 19 (3 marks = claimed) -> gold
    await throwDartViaMock(tester, 19, multiplier: 'triple');
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0xFFF4D03F);

    // D3: Miss -> pink
    await throwMissViaMock(tester);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(2), 0x80FF6B6B);
  });
}
