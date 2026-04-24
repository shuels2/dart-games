import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 16: D1 target hit shows green, D2 miss shows pink, D3 target hit shows green',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // D1: Single 20 (valid target, 1 mark, not claimed) -> green
    await throwDartViaMock(tester, 20);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFF48D1CC);

    // D2: Miss (non-target hit) -> pink
    await throwMissViaMock(tester);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0x80FF6B6B);

    // D3: Single 19 (valid target, 1 mark, not claimed) -> green
    await throwDartViaMock(tester, 19);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(2), 0xFF48D1CC);
  });
}
