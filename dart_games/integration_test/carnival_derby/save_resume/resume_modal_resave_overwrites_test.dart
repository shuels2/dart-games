import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumed game re-save overwrites instead of duplicating',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    var saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    final originalId = saved[0].id;

    await tester.tap(find.byKey(CarnivalDerbyMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    saved = await SaveGameService().loadSavedGames(gameType);
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    await throwOneDart(tester);

    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    expect(saved[0].id, originalId);
  });
}
