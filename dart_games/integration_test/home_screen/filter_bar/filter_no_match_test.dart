/// When the active filter combination matches zero games, the home screen
/// shows the "No games match" empty-state message instead of cards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/game_metadata.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Race + Heavy interaction → no games match, empty state shown',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'home_screen_filter_no_match',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToHomeScreen(tester);

        // Style: Race (CD, CC, LL only — all parallel)
        await tester.tap(find.byKey(HomeKeys.filterGameplayStyleButton));
        await PumpSequences.simpleUpdate(tester);
        await tester.tap(find
            .byKey(HomeKeys.filterGameplayStyleOption(GameplayStyle.race)));
        await tester.pump();
        await tester.tapAt(const Offset(10, 10));
        await PumpSequences.simpleUpdate(tester);

        // Interaction: Heavy (TT, MM only — neither is race)
        await tester.tap(find.byKey(HomeKeys.filterPlayerInteractionButton));
        await PumpSequences.simpleUpdate(tester);
        await tester.tap(find.byKey(HomeKeys
            .filterPlayerInteractionOption(PlayerInteraction.heavy)));
        await tester.pump();
        await tester.tapAt(const Offset(10, 10));
        await PumpSequences.simpleUpdate(tester);

        // No game is both Race AND Heavy → all cards hidden + empty state
        expect(find.byKey(HomeKeys.carnivalDerbyCard), findsNothing);
        expect(find.byKey(HomeKeys.clockworkQuestCard), findsNothing);
        expect(find.byKey(HomeKeys.lunarLanderCard), findsNothing);
        expect(find.byKey(HomeKeys.targetTagCard), findsNothing);
        expect(find.byKey(HomeKeys.monsterMashCard), findsNothing);
        expect(find.byKey(HomeKeys.reefRoyaleCard), findsNothing);
        expect(find.byKey(HomeKeys.piratesGridCard), findsNothing);

        expect(find.textContaining('No games match'), findsOneWidget);
      },
    );
  });
}
