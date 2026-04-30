import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 18: Bullseye shows green, outer bull claiming Bull shows gold',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // D1: Bullseye (2 marks on Bull, not yet claimed) -> green
    await throwBullseyeViaMock(tester);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFF48D1CC);

    // D2: Outer bull (1 mark on Bull, total 3 = claimed!) -> gold
    await throwOuterBullViaMock(tester);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0xFFF4D03F);
  });
}
