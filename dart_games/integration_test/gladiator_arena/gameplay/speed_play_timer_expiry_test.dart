import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: Speed Play timer expiry processes only thrown darts',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 500,
      speedPlayEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Throw 1 dart (S20 = 20)
    await throwDartViaMock(tester, 20);

    // Let timer expire (25 seconds)
    await tester.pump(const Duration(seconds: 26));
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // Turn should have ended and darts should have been processed
    // Score should be 20 (only the 1 dart thrown)
    final score =
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id);
    expect(score, 20,
        reason:
            'Score should only count the dart thrown before timer expired');
  });
}
