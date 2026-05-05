import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Skip turn with darts thrown - Throw 1 dart, skip -> shouldPromptTakeout=true, after takeout advances to next player', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    // Throw 1 dart
    await throwMissViaMock(tester);
    expect(ProviderHelpers.getMonsterMashCurrentPlayerDartsThrown(tester), 1);

    // Hide dartboard emulator so skip button is not obscured
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Skip turn — with darts on the board, the game screen schedules
    // simulateTakeoutStarted after 3500ms, so wait long enough for that
    // delayed callback to fire before tapping DARTS REMOVED.
    await UITestHelpers.clickSkipTurn(tester, config);
    await tester.pump(const Duration(seconds: 4));
    await PumpSequences.fullRebuild(tester);

    // Verify shouldPromptTakeout
    final provider = ProviderHelpers.getMonsterMashProvider(tester);
    expect(provider.shouldPromptTakeout, isTrue);

    // Show dartboard emulator for DARTS REMOVED button. Pump enough cycles
    // for the AnimatedBuilder inside DartboardEmulatorSection to rebuild
    // and render the DARTS REMOVED button BEFORE clickDartsRemoved searches
    // for it (clickDartsRemoved silently no-ops if the button isn't found).
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // DIAGNOSTIC — assert DARTS REMOVED is in the tree before tapping. Without
    // this assertion, clickDartsRemoved silently no-ops if the button isn't
    // found, so the failure surfaces as "player ID didn't change" instead of
    // the actual cause. If this assertion fails the button isn't rendering
    // (rendering race / hit-test obstruction); if it passes the issue is
    // elsewhere in the takeout-finished chain.
    expect(find.text('DARTS REMOVED'), findsOneWidget,
        reason:
            'DARTS REMOVED button must be visible after FAB toggle shows the emulator');

    // Click darts removed
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Verify advanced to next player
    final player2Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    expect(player2Id, isNot(equals(player1Id)));
  });
}
