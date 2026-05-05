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
      'Test 38: Skip turn with darts thrown - Throw 1 dart, skip -> shouldPromptTakeout=true, after takeout advances to next player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final firstPlayerId = provider.getCurrentPlayerId()!;

    // Throw 1 dart
    await throwMissViaMock(tester);
    expect(provider.getCurrentPlayerDartsThrown(), 1);

    // Hide dartboard emulator so skip button is not obscured
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Skip remaining darts — with darts on the board, the game screen
    // schedules simulateTakeoutStarted after 3500ms, so wait long enough
    // for that delayed callback to fire before tapping DARTS REMOVED.
    await UITestHelpers.clickSkipTurn(tester, config);
    await tester.pump(const Duration(seconds: 4));
    await PumpSequences.fullRebuild(tester);

    // Verify shouldPromptTakeout
    expect(provider.shouldPromptTakeout, isTrue);

    // Show dartboard emulator for DARTS REMOVED button. Pump enough cycles
    // for the AnimatedBuilder inside DartboardEmulatorSection to rebuild
    // and render the DARTS REMOVED button BEFORE clickDartsRemoved searches
    // for it (clickDartsRemoved silently no-ops if the button isn't found).
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Click darts removed
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Verify advanced to next player
    final secondPlayerId = provider.getCurrentPlayerId()!;
    expect(secondPlayerId, isNot(equals(firstPlayerId)));
  });
}
