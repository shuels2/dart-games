// integration_test/treasure_divide/save_resume/resume_preserves_mid_turn_gold_test.dart
//
// Regression: gold earned before a mid-turn save must survive the resume.
//
// The turn's haul lives on the provider and is only committed to the round
// score when the darts are removed. restoreGame used to reset it to 0, so
// resuming mid-turn and then finishing the takeout recorded an all-miss turn —
// which does not merely lose the points, it HALVES the player's treasure and
// counts a halving event against them.
//
// The unit test (test/providers/treasure_divide_save_restore_test.dart) covers
// the provider round-trip. This covers the path a player actually takes:
// throw, back out, Save Game, return home, resume from the tile, remove darts.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gold earned before a mid-turn save survives the resume',
      (tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester,
        numberOfRounds: 7, playerNames: ['Alice', 'Bob']);

    final playerId = ProviderHelpers.getTreasureDivideCurrentPlayerId(tester)!;
    final target = ProviderHelpers.getTreasureDivideRoundTarget(tester, 0);
    expect(target, greaterThan(0),
        reason: 'Round 1 must be a plain number round for this scenario');

    // Two scoring darts, third unthrown — the turn is still open.
    await throwDartViaMock(tester, target);
    await throwDartViaMock(tester, target);
    final expectedGold = target * 2;

    // Save mid-turn through the real flow: back button → Save Game.
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    await tester.tap(find.byKey(TreasureDivideMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Resume from the saved-game tile.
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);
    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue);

    // Finish the turn: third dart, then remove the darts to commit the round.
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, playerId),
        expectedGold,
        reason: 'The two darts thrown before the save must still count — '
            'resuming with a haul of 0 records an all-miss turn');
    expect(
        ProviderHelpers.getTreasureDivideTimesHalvedPerPlayer(tester, playerId),
        0,
        reason: 'A scoring turn must never be recorded as a halving event');
  });
}
