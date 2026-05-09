import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '_helpers.dart';

// Hard difficulty cell requirement reference (from grid_target_generator.dart):
//   Corners (0,0), (0,2), (2,0), (2,2) → tripleOnly
//   Edges   (0,1), (1,0), (1,2), (2,1) → doubleOnly
//   Center  (1,1)                       → bull (number=0; any 25 or 50 hit)

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Gameplay: Hard difficulty — per-cell requirements', () {
    // ── testWidgets 1: corner [0,0] requires tripleOnly ───────────────────────
    testWidgets(
        'Hard corner [0,0] — single and double do NOT claim; triple DOES claim',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          difficulty: 'Hard', playerNames: ['Player A', 'Player B']);

      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      final p1Id = provider.currentGame!.playerIds[0];

      // Look up the actual shuffled target number at runtime
      final targetNum =
          ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), isNull,
          reason: 'Cell [0,0] should be empty before any dart');

      // --- Throw 1: single — should NOT claim (tripleOnly rejects singles) ---
      await throwDartViaMock(tester, targetNum, multiplier: 'single');

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), isNull,
          reason: 'Single should NOT claim a tripleOnly corner');
      expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 0,
          reason: 'P1 flag count should still be 0 after single miss');

      // --- Throw 2: double — should NOT claim (tripleOnly rejects doubles) ---
      await throwDartViaMock(tester, targetNum, multiplier: 'double');

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), isNull,
          reason: 'Double should NOT claim a tripleOnly corner');
      expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 0,
          reason: 'P1 flag count should still be 0 after double miss');

      // Complete P1 turn (1 dart left) with a miss so P2 can throw, then P1
      // gets a fresh turn to throw the triple.
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await tester.pump();

      // P2 turn — throw 3 misses to pass back to P1
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await tester.pump();

      // P1 turn again — verify cell is still empty
      expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
          reason: 'P1 should be active again');
      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), isNull,
          reason: 'Cell [0,0] should still be unclaimed before triple');

      // --- Throw 3: triple — SHOULD claim the corner cell ---
      await throwDartViaMock(tester, targetNum, multiplier: 'triple');

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), p1Id,
          reason: 'Triple SHOULD claim the tripleOnly corner cell [0,0]');
      expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 1,
          reason: 'P1 should now have 1 flag planted');
    });

    // ── testWidgets 2: edge [0,1] requires doubleOnly ─────────────────────────
    testWidgets(
        'Hard edge [0,1] — single does NOT claim; double DOES claim; triple does NOT claim',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          difficulty: 'Hard', playerNames: ['Player A', 'Player B']);

      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      final p1Id = provider.currentGame!.playerIds[0];

      final targetNum =
          ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), isNull,
          reason: 'Cell [0,1] should be empty before any dart');

      // --- Throw 1: single — should NOT claim (doubleOnly rejects singles) ---
      await throwDartViaMock(tester, targetNum, multiplier: 'single');

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), isNull,
          reason: 'Single should NOT claim a doubleOnly edge cell');
      expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 0,
          reason: 'P1 flag count should still be 0 after single');

      // --- Throw 2: triple — should NOT claim (doubleOnly rejects triples) ---
      // The code in CellTarget.matches for doubleOnly:
      //   return dartNumber == number && dartMultiplier == 2;
      // so triple (multiplier=3) does NOT satisfy doubleOnly.
      await throwDartViaMock(tester, targetNum, multiplier: 'triple');

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), isNull,
          reason: 'Triple should NOT claim a doubleOnly edge cell');
      expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 0,
          reason: 'P1 flag count should still be 0 after triple');

      // One dart left — miss to exhaust P1's turn
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await tester.pump();

      // P2 turn — 3 misses to return to P1
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await tester.pump();

      // P1 fresh turn — verify cell is still empty
      expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
          reason: 'P1 should be active again');
      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), isNull,
          reason: 'Cell [0,1] should still be unclaimed');

      // --- Throw 3: double — SHOULD claim the edge cell ---
      await throwDartViaMock(tester, targetNum, multiplier: 'double');

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), p1Id,
          reason: 'Double SHOULD claim the doubleOnly edge cell [0,1]');
      expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 1,
          reason: 'P1 should now have 1 flag planted');
    });

    // ── testWidgets 3: center [1,1] requires bull ─────────────────────────────
    testWidgets(
        'Hard center [1,1] — single number miss does NOT claim; bullseye DOES claim',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          difficulty: 'Hard', playerNames: ['Player A', 'Player B']);

      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      final p1Id = provider.currentGame!.playerIds[0];

      // Center cell has number=0 and requirement=bull.
      // CellTarget.matches for bull: dartNumber == 25 || dartNumber == 50.
      // A single on any non-bull number should NOT claim it.

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 1, 1), isNull,
          reason: 'Center cell [1,1] should be empty before any dart');

      // --- Throw 1: single on number 1 — should NOT claim center (not a bull) ---
      await throwDartViaMock(tester, 1, multiplier: 'single');

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 1, 1), isNull,
          reason:
              'A non-bull dart should NOT claim the bull-requirement center cell');
      expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 0,
          reason: 'P1 flag count should still be 0 after non-bull dart');

      // Complete P1 turn with 2 more misses, then P2 turn with 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await tester.pump();

      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await tester.pump();

      // P1 fresh turn — throw inner bull (bullseye = score 50)
      expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
          reason: 'P1 should be active again');

      // --- Throw 2: bullseye (inner bull, score=50) — SHOULD claim center ---
      // throwBullseyeViaMock sends score=50, multiplier='bullseye' → sector='Bull'
      // _parseSector('Bull') → {score: 50, multiplier: 1}
      // CellTarget.matches for bull: dartNumber==25 || dartNumber==50 → true for 50
      await DartThrowHelpers.throwBullseyeViaMock(tester);

      expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 1, 1), p1Id,
          reason:
              'Bullseye (inner bull) SHOULD claim the bull-requirement center cell [1,1]');
      expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 1,
          reason: 'P1 should now have 1 flag planted on the center');
    });
  });
}
