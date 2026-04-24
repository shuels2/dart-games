import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Skip turn advances to next player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final firstPlayerId = provider.getCurrentPlayerId()!;

    // Hide dartboard emulator so skip button is not obscured
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    await UITestHelpers.clickSkipTurn(tester, config);

    // Show dartboard emulator for DARTS REMOVED button
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    await clickDartsRemoved(tester);

    final secondPlayerId = provider.getCurrentPlayerId()!;
    expect(secondPlayerId, isNot(equals(firstPlayerId)));
  });
}
