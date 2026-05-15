import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

/// Hole advancement: after all players complete hole 1, the game advances
/// to hole 2, and the hole counter + image update accordingly.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: game advances from hole 1 to hole 2 after all players play',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_gameplay_hole_advancement',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester, maxStrokes: 3,
            playerNames: ['Alice', 'Bob']);

        // Capture hole 1 target image path
        final hole1ImagePath =
            ProviderHelpers.getTikiGolfHoleImagePath(tester, 1);

        // Verify on hole 1
        expect(ProviderHelpers.getTikiGolfCurrentHole(tester), 1,
            reason: 'Game should start on hole 1');

        // Hole counter widget visible
        expect(ElementFinders.getTikiGolfHoleCounter(), findsOneWidget,
            reason: 'Hole counter should be visible');

        // Player 1 (Alice): birdie (hit on dart 1) → takeout
        await throwTargetDart(tester);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // Player 2 (Bob): birdie → takeout
        await throwTargetDart(tester);
        await clickDartsRemoved(tester);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // Both players done → should advance to hole 2
        final currentHole = ProviderHelpers.getTikiGolfCurrentHole(tester);
        expect(currentHole, 2,
            reason: 'Game should advance to hole 2 after all players complete hole 1');

        // Hole image should have changed
        final hole2ImagePath =
            ProviderHelpers.getTikiGolfHoleImagePath(tester, 2);
        expect(hole2ImagePath, isNotNull);
        expect(hole2ImagePath, isNot(hole1ImagePath),
            reason: 'Hole image should update when advancing to hole 2');
      },
    );
  });
}
