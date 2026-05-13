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
///
/// **Timing note:** earlier versions of this test used `PumpSequences.simpleUpdate`
/// (2 pumps) between filter taps. That was too tight under parallel-runner
/// load — the second filter's `onChanged` -> `setState` -> rebuild cycle wasn't
/// reliably flushed before the dismissal tap, so the Light filter occasionally
/// failed to apply and Carnival Derby (a Race + Parallel game) stayed visible.
/// This version uses `tester.pump(Duration(milliseconds: 200))` between every
/// filter interaction PLUS an intermediate assertion after applying Race —
/// the intermediate assertion both verifies Race actually applied and forces
/// a full rebuild flush before the Light filter is applied.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/game_metadata.dart';

import '../../shared/ui_test_helpers.dart';

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

        // Apply Style: Race (CD, CC, LL, GA).
        await tester.tap(find.byKey(HomeKeys.filterGameplayStyleButton));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find
            .byKey(HomeKeys.filterGameplayStyleOption(GameplayStyle.race)));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tapAt(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 200));

        // Intermediate check: Race actually applied. If this fails, the
        // Race tap didn't register and we'd otherwise see a confusing
        // failure at the final assertion. Race games are visible
        // (CD/CC/LL/GA); non-Race games are hidden (PG/RR/MM/TT).
        expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget,
            reason: 'Race filter should keep Carnival Derby visible');
        expect(find.byKey(HomeKeys.piratesGridCard), findsNothing,
            reason: 'Race filter should hide Pirate\'s Grid (Strategy)');
        expect(find.byKey(HomeKeys.reefRoyaleCard), findsNothing,
            reason: 'Race filter should hide Reef Royale (Strategy)');
        expect(find.byKey(HomeKeys.monsterMashCard), findsNothing,
            reason: 'Race filter should hide Monster Mash (Versus)');
        expect(find.byKey(HomeKeys.targetTagCard), findsNothing,
            reason: 'Race filter should hide Target Tag (Versus only)');

        // Apply Interaction: Light (PG, RR — no overlap with Race).
        await tester.tap(find.byKey(HomeKeys.filterPlayerInteractionButton));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byKey(HomeKeys
            .filterPlayerInteractionOption(PlayerInteraction.light)));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tapAt(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 200));

        // No game is both Race AND Light → all cards hidden + empty state.
        expect(find.byKey(HomeKeys.carnivalDerbyCard), findsNothing,
            reason: 'Race + Light filter should hide CD (Race+Parallel)');
        expect(find.byKey(HomeKeys.clockworkQuestCard), findsNothing,
            reason: 'Race + Light filter should hide CC (Race+Parallel)');
        expect(find.byKey(HomeKeys.lunarLanderCard), findsNothing,
            reason: 'Race + Light filter should hide LL (Race+Parallel)');
        expect(find.byKey(HomeKeys.gladiatorArenaCard), findsNothing,
            reason: 'Race + Light filter should hide GA (Race+Heavy)');
        expect(find.byKey(HomeKeys.targetTagCard), findsNothing);
        expect(find.byKey(HomeKeys.monsterMashCard), findsNothing);
        expect(find.byKey(HomeKeys.reefRoyaleCard), findsNothing);
        expect(find.byKey(HomeKeys.piratesGridCard), findsNothing);

        expect(find.textContaining('No games match'), findsOneWidget);
      },
    );
  });
}
