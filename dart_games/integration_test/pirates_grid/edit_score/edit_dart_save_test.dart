import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: open from RemoveDartsModal, change dart, save updates state',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Throw 3 darts (S20, Miss, S18) → RemoveDartsModal appears
    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwDartViaMock(tester, 18);

    // Verify RemoveDartsModal is visible (edit button appears)
    final editButton = config.getEditScoreButton();
    expect(editButton, findsOneWidget);

    // Open Edit Score dialog
    await openEditScore(tester);

    // Change dart 1 from S20 to S19 (hits a different cell)
    await EditScoreHelpers.setDart1(tester, 'S19');

    // Save the edit
    await updateScore(tester);

    // Verify edit dialog is closed
    EditScoreHelpers.verifyDialogClosed();

    // Provider state should be updated: dart segments now include S19
    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final segments = provider.getCurrentTurnDartSegments(p1Id);
    // S19 should appear in the updated segments
    expect(segments.any((s) => s == 'S19' || s.startsWith('S19')), isTrue,
        reason: 'Dart 1 should be updated to S19');

    await PumpSequences.simpleUpdate(tester);
  });
}
