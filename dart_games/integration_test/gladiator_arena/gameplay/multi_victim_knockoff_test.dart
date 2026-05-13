import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Gap-coverage test (cross-game audit). Multi-victim knockoff was only
/// covered at the provider/model level. This UI test verifies the game
/// screen correctly reflects the state when ONE dart commits a score that
/// matches TWO opponents simultaneously — both opponents must visibly drop
/// to 0, the attacker's knockoffsDealt must increment by 2, and the screen
/// must stay responsive.
///
/// Setup uses direct provider-state manipulation (matching the pattern used
/// for shield-round and knockoff scenarios elsewhere) because reaching this
/// configuration through natural play would require ~5 rounds of misses and
/// a shield-round setup, which is out of proportion to the UI-level signal
/// this test is meant to capture.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: a single dart matching two opponents knocks BOTH off and '
      'the screen reflects the new scores',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 500,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B', 'Player C'],
    );

    final provider = ProviderHelpers.getGladiatorArenaProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];
    final p3Id = provider.currentGame!.playerIds[2];

    // Set p2 and p3 to the same non-zero score. Force p1 to be the active
    // player and seed p1 at 100 so T20+Miss+Miss commits to exactly 160 —
    // matching both p2 and p3, triggering a multi-victim knockoff.
    provider.currentGame!.scores[p1Id] = 100;
    provider.currentGame!.scores[p2Id] = 160;
    provider.currentGame!.scores[p3Id] = 160;
    provider.currentGame!.currentPlayerIndex =
        provider.currentGame!.playerIds.indexOf(p1Id);

    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60 pts
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // After the commit, both p2 and p3 must be at 0 (multi-victim KO) and
    // p1 must hold 160 + the knockoff stats must reflect 2 dealt knockoffs.
    expect(ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id), 160);
    expect(ProviderHelpers.getGladiatorArenaPlayerScore(tester, p2Id), 0,
        reason: 'p2 must be knocked off by the multi-victim dart');
    expect(ProviderHelpers.getGladiatorArenaPlayerScore(tester, p3Id), 0,
        reason: 'p3 must be knocked off by the multi-victim dart');
    expect(provider.currentGame!.knockoffsDealt[p1Id], 2,
        reason: 'attacker is credited with two knockoffs on a single turn');
    expect(provider.currentGame!.knockoffsReceived[p2Id], 1);
    expect(provider.currentGame!.knockoffsReceived[p3Id], 1);
  });
}
