/// Verify the home-screen filter bar renders all 5 dropdown buttons
/// below the AppBar and above the game grid.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('filter bar with all 5 dropdowns renders on home screen',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'home_screen_filter_bar_visible',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToHomeScreen(tester);

        expect(find.byKey(HomeKeys.filterBar), findsOneWidget,
            reason: 'Filter bar Material should be present on home screen');
        expect(find.byKey(HomeKeys.filterMaxPlayersButton), findsOneWidget);
        expect(find.byKey(HomeKeys.filterGameplayStyleButton), findsOneWidget);
        expect(
            find.byKey(HomeKeys.filterPlayerInteractionButton), findsOneWidget);
        expect(find.byKey(HomeKeys.filterGameLengthButton), findsOneWidget);
        expect(find.byKey(HomeKeys.filterSoloTeamButton), findsOneWidget);

        // Sanity: all 7 cards are visible in the unfiltered state.
        expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);
        expect(find.byKey(HomeKeys.targetTagCard), findsOneWidget);
        expect(find.byKey(HomeKeys.monsterMashCard), findsOneWidget);
        expect(find.byKey(HomeKeys.reefRoyaleCard), findsOneWidget);
        expect(find.byKey(HomeKeys.clockworkQuestCard), findsOneWidget);
        expect(find.byKey(HomeKeys.lunarLanderCard), findsOneWidget);
        expect(find.byKey(HomeKeys.piratesGridCard), findsOneWidget);
      },
    );
  });
}
