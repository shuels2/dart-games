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

  testWidgets('Resume Game loads game screen', (tester) async {
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
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    expect(config.getSkipTurnButton(), findsOneWidget);

    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
    expect(alice, isNotNull);
    expect(bob, isNotNull);

    expect(ProviderHelpers.getCarnivalDerbyPlayerScore(tester, alice!.id), 20);
    expect(ProviderHelpers.getCarnivalDerbyPlayerScore(tester, bob!.id), 0);

    expect(ProviderHelpers.getCarnivalDerbyCurrentPlayerId(tester), alice.id);

    expect(ProviderHelpers.isCarnivalDerbyGameActive(tester), true);
  });
}
