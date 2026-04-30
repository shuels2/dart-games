import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Cancel edit score preserves original darts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    await throwDartViaMock(tester, 20);
    final marksBefore =
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20);

    await throwDartViaMock(tester, 19);
    await throwDartViaMock(tester, 18);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Open and cancel edit score
    final editButton = config.getEditScoreButton();
    await tester.tap(editButton);
    await PumpSequences.dialogOpen(tester);

    await tester.tap(ElementFinders.getEditScoreCancelButton());
    await PumpSequences.dialogClose(tester);

    // Marks should be unchanged
    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20),
        marksBefore);
  });
}
