import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 9: Skip turn without darts (auto-advance) - Skip immediately -> auto-advance to next player', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

    // Hide dartboard emulator so skip button is not obscured
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Skip turn without throwing darts
    await UITestHelpers.clickSkipTurn(tester, config);

    // Wait for auto-advance (500ms delay in game screen for 0-dart skip)
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.pump();

    // Verify advanced to next player
    final player2Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    expect(player2Id, isNot(equals(player1Id)));
  });
}
