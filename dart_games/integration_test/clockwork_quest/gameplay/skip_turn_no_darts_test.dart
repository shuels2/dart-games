import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 37: Skip turn with no darts thrown - shouldPromptTakeout=true, after takeout advances to next player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final firstPlayerId = provider.getCurrentPlayerId()!;

    // Hide dartboard emulator so skip button is not obscured
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Skip turn without throwing any darts
    await UITestHelpers.clickSkipTurn(tester, config);
    await PumpSequences.fullRebuild(tester);

    // Verify shouldPromptTakeout
    expect(provider.shouldPromptTakeout, isTrue);

    // Show dartboard emulator for DARTS REMOVED button
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Click darts removed
    await clickDartsRemoved(tester);

    // Verify advanced to next player
    final secondPlayerId = provider.getCurrentPlayerId()!;
    expect(secondPlayerId, isNot(equals(firstPlayerId)));
  });
}
