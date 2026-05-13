/// When the active filter combination matches zero games, the home screen
/// shows the "No games match" empty-state message instead of cards.
///
/// Filter combo chosen by inspecting `lib/constants/game_filter_registry.dart`
/// for a Style × Interaction intersection that's genuinely empty under the
/// current registry. Race × Heavy used to be empty but Gladiator Arena's
/// registration as {race, versus} × heavy made it non-empty (failure caught
/// when this test regressed silently — see commit history). Race × Light is
/// the next-most-natural empty combo: Race = {GA, CD, CC, LL}, Light = {PG, RR},
/// intersection = ∅. If a future game registration breaks this premise too,
/// pick another empty cell from the matrix (Versus × Parallel, Versus × Light,
/// Strategy × Heavy, Strategy × Parallel all work today).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/game_metadata.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Race + Light interaction → no games match, empty state shown',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'home_screen_filter_no_match',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToHomeScreen(tester);

        // Style: Race (CD, CC, LL, GA)
        await tester.tap(find.byKey(HomeKeys.filterGameplayStyleButton));
        await PumpSequences.simpleUpdate(tester);
        await tester.tap(find
            .byKey(HomeKeys.filterGameplayStyleOption(GameplayStyle.race)));
        await tester.pump();
        await tester.tapAt(const Offset(10, 10));
        await PumpSequences.simpleUpdate(tester);

        // Interaction: Light (PG, RR — no overlap with Race)
        await tester.tap(find.byKey(HomeKeys.filterPlayerInteractionButton));
        await PumpSequences.simpleUpdate(tester);
        await tester.tap(find.byKey(HomeKeys
            .filterPlayerInteractionOption(PlayerInteraction.light)));
        await tester.pump();
        await tester.tapAt(const Offset(10, 10));
        await PumpSequences.simpleUpdate(tester);

        // No game is both Race AND Light → all cards hidden + empty state.
        expect(find.byKey(HomeKeys.carnivalDerbyCard), findsNothing);
        expect(find.byKey(HomeKeys.clockworkQuestCard), findsNothing);
        expect(find.byKey(HomeKeys.lunarLanderCard), findsNothing);
        expect(find.byKey(HomeKeys.gladiatorArenaCard), findsNothing);
        expect(find.byKey(HomeKeys.targetTagCard), findsNothing);
        expect(find.byKey(HomeKeys.monsterMashCard), findsNothing);
        expect(find.byKey(HomeKeys.reefRoyaleCard), findsNothing);
        expect(find.byKey(HomeKeys.piratesGridCard), findsNothing);

        expect(find.textContaining('No games match'), findsOneWidget);
      },
    );
  });
}
