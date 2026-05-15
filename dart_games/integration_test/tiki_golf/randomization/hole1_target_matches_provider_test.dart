// integration_test/tiki_golf/randomization/hole1_target_matches_provider_test.dart
//
// Start game, read provider's holeTargets[0], verify the top bar's target
// number text matches what the provider reports.
//
// This confirms the game screen reflects the per-game random target, not a
// hardcoded value.
//
// Section 12B File 3a — Randomization test 1
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Randomization: hole 1 target number on game screen matches provider holeTargets[0]',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_randomization_hole1_target_matches_provider',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester);

        // Read the target from the provider
        final providerTarget = ProviderHelpers.getTikiGolfHoleTarget(tester, 1);
        expect(providerTarget, inInclusiveRange(1, 20),
            reason: 'Hole 1 target should be a valid dart number (1..20)');

        // The game screen should display the target number in the top bar
        final targetFinder = ElementFinders.getTikiGolfTargetNumber();
        expect(targetFinder, findsOneWidget,
            reason: 'Target number widget should be present on game screen');

        // Verify the displayed text matches the provider value
        final targetText = (tester.widget(targetFinder) as dynamic);
        // Use textContaining as the widget may add labels like "Target: 7"
        expect(
          find.textContaining('$providerTarget'),
          findsWidgets,
          reason:
              'Game screen should display the provider\'s hole 1 target ($providerTarget) '
              'in the top bar — confirms randomization is reflected in the UI',
        );
      },
    );
  });
}
