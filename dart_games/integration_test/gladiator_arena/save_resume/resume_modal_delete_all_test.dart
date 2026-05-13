import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Delete All button removes all saved games', (tester) async {
    await UITestHelpers.resetServerState();

    // Pre-save 2 games
    await preSaveTwoGames();

    // Navigate to menu — modal should show 2 saves
    await UITestHelpers.navigateToGameMenu(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Tap Delete All
    // Delete roundtrips through HTTP and triggers a reload — need asyncDataLoad.
    await UITestHelpers.deleteAllSavedGames(tester);

    // Modal should show empty state
    expect(ElementFinders.getResumeGameModalEmptyState(), findsOneWidget);

    // Verify via service
    final hasSaved = await SaveGameService().hasSavedGames(gameType);
    expect(hasSaved, false);
  });
}
