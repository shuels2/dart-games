// integration_test/treasure_divide/gameplay/number_of_rounds_7_completes_in_7_rounds_test.dart
//
// Group B – Test 9: 7-round Solo game completes after exactly 7 rounds.
// Play all rounds to completion; assert hasWinner = true and results screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: 7-round game completes after 7 rounds and shows results',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        playerNames: ['R7_P1', 'R7_P2']);

    // Play to completion using alternating hit/miss
    await playGameToCompletion(tester);

    // ── Assert hasWinner ───────────────────────────────────────────────────
    expect(ProviderHelpers.treasureDivideHasWinner(tester), isTrue,
        reason: '[DIAG 7rounds] hasWinner should be true after 7 rounds');

    // ── Poll for results screen ────────────────────────────────────────────
    for (int i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      drainExceptions(tester);
      if (find.byKey(TreasureDivideResultsKeys.playAgainButton).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    drainExceptions(tester);

    expect(find.byKey(TreasureDivideResultsKeys.playAgainButton), findsOneWidget,
        reason: '[DIAG 7rounds] Results screen (SAIL AGAIN button) should be visible');
  });
}
