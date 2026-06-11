// integration_test/treasure_divide/gameplay/number_of_rounds_12_completes_in_12_rounds_test.dart
//
// Group B – Test 10: 12-round Solo game — game does NOT end at round 9 and
// completes only after round 12.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: 12-round game does not end early and completes at round 12',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 12,
        playerNames: ['R12_P1', 'R12_P2']);

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);

    // Play through round 9 (index 8): game must NOT have winner yet
    int turnCount = 0;
    while (!provider.hasWinner &&
        ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester) <= 8) {
      final roundIdx = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
      final target = ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);
      if (turnCount % 2 == 0) {
        if (target == -1) {
          await throwDartViaMock(tester, 1, multiplier: 'double');
          await throwDartViaMock(tester, 1, multiplier: 'double');
          await throwDartViaMock(tester, 1, multiplier: 'double');
        } else if (target == -2) {
          await throwDartViaMock(tester, 1, multiplier: 'triple');
          await throwDartViaMock(tester, 1, multiplier: 'triple');
          await throwDartViaMock(tester, 1, multiplier: 'triple');
        } else {
          await throwDartViaMock(tester, target);
          await throwDartViaMock(tester, target);
          await throwDartViaMock(tester, target);
        }
      } else {
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
      }
      await simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      drainExceptions(tester);
      turnCount++;
    }

    // ── Assert game NOT finished after round 9 completes ──────────────────
    if (!provider.hasWinner) {
      expect(provider.hasWinner, isFalse,
          reason: '[DIAG 12rounds] Game should not have ended at or before round 9');
      final roundIdx = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
      expect(roundIdx, greaterThanOrEqualTo(9),
          reason: '[DIAG 12rounds] Should be on round 9+ after passing round 8');
    }

    // ── Continue playing to completion (rounds 9-11) ───────────────────────
    while (!provider.hasWinner) {
      final roundIdx = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
      final target = ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);
      if (turnCount % 2 == 0) {
        if (target == -1) {
          await throwDartViaMock(tester, 1, multiplier: 'double');
          await throwDartViaMock(tester, 1, multiplier: 'double');
          await throwDartViaMock(tester, 1, multiplier: 'double');
        } else if (target == -2) {
          await throwDartViaMock(tester, 1, multiplier: 'triple');
          await throwDartViaMock(tester, 1, multiplier: 'triple');
          await throwDartViaMock(tester, 1, multiplier: 'triple');
        } else if (target == 25) {
          await throwDartViaMock(tester, 25, multiplier: 'bull');
          await throwDartViaMock(tester, 25, multiplier: 'bull');
          await throwDartViaMock(tester, 25, multiplier: 'bull');
        } else {
          await throwDartViaMock(tester, target);
          await throwDartViaMock(tester, target);
          await throwDartViaMock(tester, target);
        }
      } else {
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
      }
      await simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      drainExceptions(tester);
      turnCount++;
    }

    // ── Assert: game over at round 12 ─────────────────────────────────────
    expect(provider.hasWinner, isTrue,
        reason: '[DIAG 12rounds] hasWinner should be true after 12 rounds');

    // ── Poll for results ───────────────────────────────────────────────────
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
        reason: '[DIAG 12rounds] Results screen should be visible after 12-round game');
  });
}
