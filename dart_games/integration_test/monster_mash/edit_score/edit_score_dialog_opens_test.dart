import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Edit score dialog opens - 3 darts -> takeout modal -> tap Edit Player Score -> dialog opens with dart dropdowns', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Verify we're in takeout state
    final provider = ProviderHelpers.getMonsterMashProvider(tester);
    expect(provider.shouldPromptTakeout, isTrue);

    // Open edit score dialog
    await EditScoreHelpers.openEditScore(tester, config);

    // Verify dialog is open with dart dropdowns
    EditScoreHelpers.verifyDialogElements();
  });
}
