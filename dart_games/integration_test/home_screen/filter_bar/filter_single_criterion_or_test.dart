/// Selecting two values within a single criterion (Max Players: 2 + 10) shows
/// games matching either — OR semantics within a criterion.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/game_metadata.dart';

import '../../shared/ui_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Max Players: 2 + 10 shows only Pirate\'s Grid and Target Tag',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'home_screen_filter_max_players_or',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToHomeScreen(tester);

        // Open Max Players dropdown.
        //
        // Use tester.pump(Duration(ms: 200)) + bare pump everywhere a popup
        // interaction happens. Bare pumps advance the test clock but don't
        // wait real wall-clock time, so dropdown / checkbox / overlay-dismiss
        // animations don't progress. Under heavy parallel-runner load the
        // previous 2-bare-pump settle wasn't enough — matches the pattern
        // adopted in filter_no_match_test.dart and
        // filter_multi_criterion_and_test.dart for the same reason.
        await tester.tap(find.byKey(HomeKeys.filterMaxPlayersButton));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        // Toggle "2 (1v1)" and "Up to 10".
        await tester.tap(find
            .byKey(HomeKeys.filterMaxPlayersOption(MaxPlayersBucket.twoOnly)));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        await tester.tap(find
            .byKey(HomeKeys.filterMaxPlayersOption(MaxPlayersBucket.upToTen)));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        // Dismiss menu by tapping outside
        await tester.tapAt(const Offset(10, 10));
        // Bigger final settle so the home-screen filter-commit + card rebuild
        // definitely finishes before the assertions run.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

        // PG (twoOnly) and TT (upToTen) visible — others hidden
        expect(find.byKey(HomeKeys.piratesGridCard), findsOneWidget);
        expect(find.byKey(HomeKeys.targetTagCard), findsOneWidget);
        // upToEight games hidden
        expect(find.byKey(HomeKeys.carnivalDerbyCard), findsNothing);
        expect(find.byKey(HomeKeys.clockworkQuestCard), findsNothing);
        expect(find.byKey(HomeKeys.monsterMashCard), findsNothing);
        expect(find.byKey(HomeKeys.reefRoyaleCard), findsNothing);
        expect(find.byKey(HomeKeys.lunarLanderCard), findsNothing);
      },
    );
  });
}
