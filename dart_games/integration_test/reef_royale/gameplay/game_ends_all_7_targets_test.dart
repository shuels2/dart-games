import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 15: Game ends when player claims all 7 targets',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // P1 claims all 7 targets using triples
    // Turn 1: claim 20, 19, 18
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 19, multiplier: 'triple');
    await throwDartViaMock(tester, 18, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // P2 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Turn 2: claim 17, 16, 15
    await throwDartViaMock(tester, 17, multiplier: 'triple');
    await throwDartViaMock(tester, 16, multiplier: 'triple');
    await throwDartViaMock(tester, 15, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // P2 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Turn 3: claim Bull
    await throwBullseyeViaMock(tester); // 2 marks
    await throwOuterBullViaMock(tester); // 1 mark = 3 total = claimed!

    // Game should end
    expect(ProviderHelpers.reefRoyaleHasWinner(tester), isTrue);

    // Wait for results screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  });
}
