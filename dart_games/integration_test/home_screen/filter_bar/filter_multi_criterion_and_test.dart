/// Selecting values across two criteria (Style=Versus AND Interaction=Heavy)
/// narrows to only games that satisfy BOTH — AND semantics across criteria.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/game_metadata.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';

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

        // Style: Versus
        await tester.tap(find.byKey(HomeKeys.filterGameplayStyleButton));
        await PumpSequences.simpleUpdate(tester);
        await tester.tap(find.byKey(
            HomeKeys.filterGameplayStyleOption(GameplayStyle.versus)));
        // Two-pump settle so the checkbox onChanged bubbles up, parent
        // setState commits, and the home screen rebuilds with the filter
        // applied BEFORE we dismiss the popup. The previous single pump
        // sometimes left the filter state mid-commit, so the corner-tap
        // dismiss ran before the parent's setState had taken effect.
        await PumpSequences.simpleUpdate(tester);
        await tester.tapAt(const Offset(10, 10));
        await PumpSequences.simpleUpdate(tester);

        // Interaction: Heavy
        await tester.tap(find.byKey(HomeKeys.filterPlayerInteractionButton));
        await PumpSequences.simpleUpdate(tester);
        await tester.tap(find.byKey(HomeKeys
            .filterPlayerInteractionOption(PlayerInteraction.heavy)));
        await PumpSequences.simpleUpdate(tester);
        await tester.tapAt(const Offset(10, 10));
        await PumpSequences.simpleUpdate(tester);

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
