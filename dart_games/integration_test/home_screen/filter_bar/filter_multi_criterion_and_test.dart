/// Selecting values across two criteria (Style=Versus AND Interaction=Heavy)
/// narrows to only games that satisfy BOTH — AND semantics across criteria.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/game_metadata.dart';

import '../../shared/ui_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Style=Versus AND Interaction=Heavy → Target Tag + Monster Mash only',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'home_screen_filter_versus_and_heavy',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToHomeScreen(tester);

        // Style: Versus.
        //
        // Use tester.pump(Duration(ms: 200)) + bare pump everywhere a popup
        // interaction happens. Bare pumps advance the test clock but don't
        // wait real wall-clock time, so dropdown / checkbox / overlay-dismiss
        // animations don't progress. Under heavy parallel-runner load (9+
        // workers contending for CPU) animations stretch out enough that the
        // previous 2-bare-pump settle wasn't enough — the dismissal tap fired
        // mid-animation, the next filter-button tap landed on the still-
        // dismissing overlay, and the second filter never applied. Matches
        // the pattern adopted in filter_no_match_test.dart for the same
        // reason.
        await tester.tap(find.byKey(HomeKeys.filterGameplayStyleButton));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        await tester.tap(find.byKey(
            HomeKeys.filterGameplayStyleOption(GameplayStyle.versus)));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        await tester.tapAt(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        // Interaction: Heavy
        await tester.tap(find.byKey(HomeKeys.filterPlayerInteractionButton));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        await tester.tap(find.byKey(HomeKeys
            .filterPlayerInteractionOption(PlayerInteraction.heavy)));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        await tester.tapAt(const Offset(10, 10));
        // Bigger final settle so the home-screen filter-commit + card
        // rebuild definitely finishes before the assertions run.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

        // Only TT and MM should be visible
        expect(find.byKey(HomeKeys.targetTagCard), findsOneWidget);
        expect(find.byKey(HomeKeys.monsterMashCard), findsOneWidget);
        // All others hidden
        expect(find.byKey(HomeKeys.carnivalDerbyCard), findsNothing);
        expect(find.byKey(HomeKeys.clockworkQuestCard), findsNothing);
        expect(find.byKey(HomeKeys.lunarLanderCard), findsNothing);
        expect(find.byKey(HomeKeys.piratesGridCard), findsNothing);
        expect(find.byKey(HomeKeys.reefRoyaleCard), findsNothing);
      },
    );
  });
}
