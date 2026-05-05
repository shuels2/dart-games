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
      'Test 37: Skip turn with no darts thrown — bypass auto-advances to next player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final firstPlayerId = provider.getCurrentPlayerId()!;

    // Hide dartboard emulator so skip button is not obscured.
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Skip turn without throwing any darts — the game screen's 0-darts
    // bypass schedules simulateTakeoutFinished after 500ms so RemoveDartsModal
    // never shows and the player advances directly.
    await UITestHelpers.clickSkipTurn(tester, config);
    await tester.pump(const Duration(milliseconds: 800));
    await PumpSequences.fullRebuild(tester);

    // Verify advanced to next player.
    final secondPlayerId = provider.getCurrentPlayerId()!;
    expect(secondPlayerId, isNot(equals(firstPlayerId)));
    expect(provider.shouldPromptTakeout, isFalse);
  });
}
