import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumed game auto-deletes saved game on completion',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    await tester.tap(find.byKey(CarnivalDerbyMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    final savedGameId = saved[0].id;
    await UITestHelpers.selectSavedGameTile(tester, savedGameId);
    await UITestHelpers.tapResumeGameButton(tester);

    // Play to completion: Alice has 20 pts, 1/3 darts, target=150
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60 → total 80
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60 → total 140
    await clickDartsRemoved(tester);

    // Bob's turn: miss all 3
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Alice's turn: S20 → total 160 >= 150 = wins!
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    expect(config.getPlayAgainButton(), findsOneWidget);

    final remaining = await SaveGameService().loadSavedGames(gameType);
    expect(remaining, isEmpty);
  });
}
