import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Add player with name only - Open dialog, enter name, tap Add, verify player appears in list', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add a player with just a name (no photo)
    await UITestHelpers.addPlayer(tester, 'Dracula Fan', config);

    // Verify player appears in the list
    expect(find.text('Dracula Fan'), findsWidgets);

    // Verify player was created via provider
    final player = ProviderHelpers.findPlayerByName(tester, 'Dracula Fan');
    expect(player, isNotNull);
  });
}
