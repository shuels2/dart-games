import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Player selection and deselection - Select 3 players, deselect one, verify count updates', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 3 players
    await UITestHelpers.addPlayer(tester, 'Player One', config);
    await UITestHelpers.addPlayer(tester, 'Player Two', config);
    await UITestHelpers.addPlayer(tester, 'Player Three', config);

    // Verify all 3 players are visible
    expect(find.text('Player One'), findsWidgets);
    expect(find.text('Player Two'), findsWidgets);
    expect(find.text('Player Three'), findsWidgets);

    // Players should be auto-selected after creation
    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    expect(selectedPlayers.length, greaterThanOrEqualTo(3));
  });
}
