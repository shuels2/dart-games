import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('delete individual save removes it from modal list',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Pre-save 2 games
    final ids = await preSaveTwoGames();
    final savedId1 = ids[0];
    final savedId2 = ids[1];

    // Navigate to menu — modal should show 2 saves
    await UITestHelpers.navigateToGameMenu(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    expect(ElementFinders.getResumeGameModalSavedGameTile(savedId1),
        findsOneWidget);
    expect(ElementFinders.getResumeGameModalSavedGameTile(savedId2),
        findsOneWidget);

    // Delete the first save
    // Delete roundtrips through HTTP and triggers a reload — need asyncDataLoad.
    await UITestHelpers.deleteSavedGameTile(tester, savedId1);

    // First save should be gone, second still there
    expect(ElementFinders.getResumeGameModalSavedGameTile(savedId1),
        findsNothing);
    expect(ElementFinders.getResumeGameModalSavedGameTile(savedId2),
        findsOneWidget);

    // Verify via service
    final saves = await SaveGameService().loadSavedGames(gameType);
    expect(saves.length, 1);
    expect(saves[0].id, savedId2);
  });
}
