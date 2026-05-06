import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: cancel preserves original dart values',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Throw 3 darts → RemoveDartsModal
    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwDartViaMock(tester, 18);

    // Record original segments
    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final originalSegments = List<String>.from(
        provider.getCurrentTurnDartSegments(p1Id));

    // Open Edit Score, change dart 1, then cancel
    await openEditScore(tester);
    await EditScoreHelpers.setDart1(tester, 'S19');
    await cancelEditScore(tester);

    // Segments should be unchanged
    final afterCancelSegments = provider.getCurrentTurnDartSegments(p1Id);
    expect(afterCancelSegments, equals(originalSegments),
        reason: 'Cancelling edit should preserve original dart values');
  });
}
