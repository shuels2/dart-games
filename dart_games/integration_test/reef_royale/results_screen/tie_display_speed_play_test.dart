import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Tie display (speed play) — round-limit ranking with both players at 0 corals/0 pearls yields multi-winner result',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Speed Play ON with the minimum round limit (5) so the game ends via
    // the round-limit branch of _determineWinnerByRanking. All-miss play
    // through every round leaves both players at the same 0 corals / 0
    // pearls ranking — the top-of-leaderboard tie path that populates
    // `winnerIds` with multiple ids.
    await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);
    await SettingsHelpers.setReefRoyaleRoundLimit(tester, 5);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Five rounds × two players × three misses each. After this both
    // players have 0 corals and 0 pearls — guaranteed tie at the top
    // when the round-limit fires.
    for (int round = 0; round < 5; round++) {
      // Player A: 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player B: 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
    }

    // Wait for results-screen navigation
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Provider should have multiple winners (the tie path).
    final provider = ProviderHelpers.getReefRoyaleProvider(tester);
    final winnerIds = provider.currentGame?.winnerIds ?? const <String>[];
    expect(winnerIds.length, greaterThanOrEqualTo(2),
        reason:
            'A speed-play round-limit ending with both players at 0 corals/0 pearls should fill winnerIds with both player ids.');

    // Results screen should surface the tie state to the user. Reef
    // Royale's UI uses ranked display; a tie at the top is signaled by
    // either a "TIED" badge or by both player names appearing in the
    // winner highlight position. We assert at least one of those
    // user-visible signals is present, mirroring how the Monster Mash
    // and Tiki Golf tie tests confirm tie display.
    final tiedText = find.textContaining('TIED');
    final tiedTextCase = find.textContaining('Tied');
    expect(tiedText.evaluate().isNotEmpty || tiedTextCase.evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected the results screen to surface a "TIED"/"Tied" label '
            'when winnerIds contains more than one player.');
  });
}
