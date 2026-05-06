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

    // Throw 3 darts (row 0 col 0, Miss, row 0 col 1) → RemoveDartsModal appears
    final t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    await throwDartViaMock(tester, t00);
    await throwMissViaMock(tester);
    final t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
    await throwDartViaMock(tester, t01);

    // Verify RemoveDartsModal is visible (edit button appears)
    final editButton = config.getEditScoreButton();
    expect(editButton, findsOneWidget);

    // Open Edit Score dialog
    await openEditScore(tester);

    // Change dart 1 to S19 (a different segment)
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
