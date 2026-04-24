import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Add multiple players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Inventor1', config);
    await UITestHelpers.addPlayer(tester, 'Inventor2', config);
    await UITestHelpers.addPlayer(tester, 'Inventor3', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    expect(players.any((p) => p.name == 'Inventor1'), isTrue);
    expect(players.any((p) => p.name == 'Inventor2'), isTrue);
    expect(players.any((p) => p.name == 'Inventor3'), isTrue);
  });
}
