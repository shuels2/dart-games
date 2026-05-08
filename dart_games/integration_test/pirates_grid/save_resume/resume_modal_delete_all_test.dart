import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('delete all saved games shows empty state', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    await preSaveTwoGames();
    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    await UITestHelpers.deleteAllSavedGames(tester);

    expect(ElementFinders.getResumeGameModalEmptyState(), findsOneWidget);
  });
}
