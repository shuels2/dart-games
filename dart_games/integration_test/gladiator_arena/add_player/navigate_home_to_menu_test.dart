import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player: navigate from home to menu', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify menu screen loaded
    expect(ElementFinders.getGladiatorArenaStartButton(), findsOneWidget);
    expect(
        ElementFinders.getGladiatorArenaAddPlayerButtonEmptyState(),
        findsOneWidget);
  });
}
