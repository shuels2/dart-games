import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping game card shows resume modal when saves exist',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Pre-save a game
    final savedId = await preSaveGame();

    // Navigate from home to menu — pre-save games should be loaded
    await UITestHelpers.navigateToGameMenu(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // The game tile in the resume modal should be there
    expect(ElementFinders.getResumeGameModalSavedGameTile(savedId),
        findsOneWidget,
        reason: 'Saved game tile should be visible in the modal');
  });
}
