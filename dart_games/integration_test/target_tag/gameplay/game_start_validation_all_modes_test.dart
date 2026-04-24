import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 13: Game Start Validation - All Modes - Validates game successfully starts in standard solo mode with 2 players, game screen displays correctly with "Target Tag Game On!" title, player names appear in UI, turn order established, game state initialized properly for solo mode gameplay', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Verify we're on menu screen
    expect(find.textContaining('Shield Max:'), findsOneWidget);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // ===== Verify game screen displays correctly =====
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // Verify player names appear in UI
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);

    // Verify turn order established (active panel shows current player info)
    expect(find.textContaining('Target number:'), findsWidgets);

    // Verify game state initialized (shield max = 6 by default)
    final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayerId, isNotNull);

    final currentPlayerShields = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId!);
    expect(currentPlayerShields, equals(0), reason: 'Player should start with 0 shields');

    // Verify not tagged in initially
    final isTaggedIn = ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentPlayerId);
    expect(isTaggedIn, isFalse, reason: 'Player should not be tagged in at game start');
  });
}
