import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: Bo3 match win shows "CAPTAIN OF THE SEAS!" headline',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        bestOf: '3',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);

    // Read row 0 target numbers dynamically (grid is randomized)
    final t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    final t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
    final t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);

    // Win round 1 for P1
    await throwDartViaMock(tester, t00);
    await throwDartViaMock(tester, t01);
    await throwDartViaMock(tester, t02);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Win round 2 for P1 (P2 alternates starting, but we fill P1's row 0 again)
    await completeTurnWithMisses(tester); // P2 misses
    // P1 turn: throw row 0 (re-read after round reset — grid may have new layout)
    final r2t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    final r2t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
    final r2t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
    await throwDartViaMock(tester, r2t00);
    await throwDartViaMock(tester, r2t01);
    await throwDartViaMock(tester, r2t02);
    await clickDartsRemoved(tester);
    await ResultsHelpers.pumpUntilResults(tester, config);

    // P1 should have won the match (2/2 rounds for Bo3)
    // Verify CAPTAIN OF THE SEAS! headline
    expect(find.text('CAPTAIN OF THE SEAS!'), findsOneWidget,
        reason: 'Bo3 match win should show CAPTAIN OF THE SEAS! headline');
  });
}
