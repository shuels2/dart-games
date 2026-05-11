import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Gap-coverage test (cross-game audit): existing UI gameplay coverage hits
/// min (2) and max (8) player counts but nothing in between. The pillar/character
/// sizing logic in `_charSizeForCount` has distinct breakpoints per count, so
/// at least one mid-count test guards against layout regressions and per-count
/// option interactions at 5 players. (Single mid-count spot test instead of
/// 3/5/7 separate files to keep UI runtime in check — 5 is the median.)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: 5 players renders all podiums + scores update',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 200,
      playerNames: [
        'Player A',
        'Player B',
        'Player C',
        'Player D',
        'Player E',
      ],
    );

    // Game screen active and all 5 podiums visible
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);
    final players = ProviderHelpers.getAllPlayers(tester);
    expect(players.length, 5);
    for (final player in players) {
      expect(ElementFinders.getGladiatorArenaPodium(player.id),
          findsOneWidget,
          reason: 'Podium for ${player.name} should be visible');
    }

    // Smoke check: the current player can score and the provider records it.
    final firstPlayerId =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    expect(
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, firstPlayerId), 60,
        reason: '5-player game commits scores per turn just like 2/8-player');
  });
}
