import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: draw shows "STALEMATE!" headline',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        bestOf: '1',
        playerNames: ['Player A', 'Player B']);

    // Set up draw state programmatically
    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    // Fill grid: no 3-in-a-row pattern → draw
    ProviderHelpers.setPiratesGridGameState(tester, claimedBy: [
      [p1Id, p2Id, p1Id],
      [p2Id, p1Id, p2Id],
      [p2Id, p1Id, p2Id],
    ]);
    provider.currentGame!.isDraw = true;
    provider.currentGame!.isMatchDraw = true;
    provider.currentGame!.state =
        provider.currentGame!.state; // keep playing state
    // Force to finished via match draw
    // ignore: invalid_use_of_protected_member
    provider.notifyListeners();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Navigate to results by triggering takeout
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    // Verify STALEMATE! headline
    expect(find.text('STALEMATE!'), findsOneWidget,
        reason: 'Draw should show STALEMATE! headline on results screen');
  });
}
