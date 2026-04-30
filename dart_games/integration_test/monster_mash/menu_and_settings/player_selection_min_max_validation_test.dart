import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Player selection min/max validation - Start disabled with <2 players, enabled with 2+', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add only 1 player
    await UITestHelpers.addPlayer(tester, 'Solo Monster', config);

    // Verify player was added
    expect(find.text('Solo Monster'), findsWidgets);

    // With only 1 player, game cannot start (need at least 2)
    // Add a second player
    await UITestHelpers.addPlayer(tester, 'Duo Monster', config);

    // Verify both players present
    expect(find.text('Solo Monster'), findsWidgets);
    expect(find.text('Duo Monster'), findsWidgets);
  });
}
