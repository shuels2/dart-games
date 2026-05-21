import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

/// Opponent display: 3-player Solo game — non-current players' scorecard rows
/// are visible AND update after their turns complete.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: 3-player game shows all player scorecard rows; opponent rows update after turns',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        maxStrokes: 3,
        playerNames: ['Alice', 'Bob', 'Carol']);

    final players = ProviderHelpers.getSelectedPlayers(tester);
    expect(players.length, 3);

    // All 3 player names visible in scorecard at start
    for (final player in players) {
      expect(find.textContaining(player.name), findsWidgets,
          reason:
              '${player.name} should be visible in scorecard at game start');
    }

    // Complete hole 1 for all 3 players
    for (int i = 0; i < 3; i++) {
      await throwTargetDart(tester);
      await clickDartsRemoved(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    // All 3 players should have a hole 1 score (row updated)
    for (final player in players) {
      final score = ProviderHelpers.getTikiGolfPlayerHoleScore(
          tester, player.id, 1);
      expect(score, isNotNull,
          reason:
              '${player.name} should have a score for hole 1 after their turn');

      // Name is still visible in scorecard after update
      expect(find.textContaining(player.name), findsWidgets,
          reason:
              '${player.name} should still be visible in scorecard after turn');
    }
  });
}
