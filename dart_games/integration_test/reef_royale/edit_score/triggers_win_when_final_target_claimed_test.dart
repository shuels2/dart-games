import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Edit score triggers win when final target claimed',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // P1 Turn 1: claim 20, 19, 18
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 19, multiplier: 'triple');
    await throwDartViaMock(tester, 18, multiplier: 'triple');

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Click DARTS REMOVED
    final dartsRemovedButton = find.text('DARTS REMOVED');
    if (dartsRemovedButton.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // P2 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    final dartsRemovedButton2 = find.text('DARTS REMOVED');
    if (dartsRemovedButton2.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton2.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // P1 Turn 2: claim 17, 16, 15
    await throwDartViaMock(tester, 17, multiplier: 'triple');
    await throwDartViaMock(tester, 16, multiplier: 'triple');
    await throwDartViaMock(tester, 15, multiplier: 'triple');

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    final dartsRemovedButton3 = find.text('DARTS REMOVED');
    if (dartsRemovedButton3.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton3.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // P2 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    final dartsRemovedButton4 = find.text('DARTS REMOVED');
    if (dartsRemovedButton4.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton4.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // P1 now has 6/7 targets claimed — verify
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20), isTrue);
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 15), isTrue);

    // P1 Turn 3: throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Edit score to claim Bull (7th target) — Bullseye + Outer Bull + Miss = 3 marks
    await EditScoreHelpers.openEditScore(tester, config);
    await EditScoreHelpers.setDart1(tester, 'Bull');
    await EditScoreHelpers.setDart2(tester, '25');
    await EditScoreHelpers.setDart3(tester, 'Miss');
    await EditScoreHelpers.updateScore(tester);

    // Game should detect win
    expect(ProviderHelpers.reefRoyaleHasWinner(tester), isTrue);

    // Click DARTS REMOVED to trigger game won flow
    final dartsRemovedButton5 = find.text('DARTS REMOVED');
    if (dartsRemovedButton5.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton5.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // Wait for results screen navigation (3000ms delay in _handleGameWon)
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Results screen should be visible with winner name
    final winnerName = ElementFinders.getReefRoyaleWinnerName();
    expect(winnerName, findsOneWidget);
  });
}
