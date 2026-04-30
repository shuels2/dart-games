import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 11: Edit score at bullseye target changes outcome',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, includeBullseye: true);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);

    // Set player to target 21 (bullseye)
    provider.currentGame!.currentTarget[playerId] = 21;
    // Update turn start state for edit score
    provider.currentGame!.turnStartCurrentTarget[playerId] = 21;
    provider.currentGame!.turnStartLapsCompleted[playerId] = 0;
    provider.currentGame!.turnStartState = provider.currentGame!.state;
    provider.currentGame!.turnStartWinnerId = null;
    provider.currentGame!.turnStartCompletedTargets[playerId] = [];
    provider.notifyListeners();
    await PumpSequences.simpleUpdate(tester);

    // Throw 3 misses at bullseye target
    await throw3DartsAndWaitForTakeout(tester);
    expect(provider.hasWinner, isFalse);

    // Edit: change dart 1 to Bullseye hit
    await EditScoreHelpers.editScoreAndSave(
      tester, config,
      dart1: 'Bull',
    );

    // Should now be a winner
    expect(provider.hasWinner, isTrue);
    expect(provider.currentGame!.winnerId, playerId);
  });
}
