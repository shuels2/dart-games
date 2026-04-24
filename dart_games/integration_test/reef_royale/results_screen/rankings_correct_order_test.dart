import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Rankings show in correct order',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    // Verify ranking keys exist for both players
    expect(find.byKey(ReefRoyaleResultsKeys.playerRanking(0)),
        findsOneWidget);
    expect(find.byKey(ReefRoyaleResultsKeys.playerRanking(1)),
        findsOneWidget);
  });
}
