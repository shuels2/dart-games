// integration_test/tiki_golf/team_setup/random_blocked_n2_test.dart
//
// Team+Random with 2 players: TEE OFF disabled (below N=3 minimum).
//
// The spec requires a minimum of 3 players in Team mode (N=3 is the smallest
// valid configuration: [2,1]). With only 2 players, the TEE OFF button
// should be disabled.
//
// Section 12B File 8 — Team setup test 9 (random_blocked_n2)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Team+Random with 2 players — TEE OFF button disabled (below N=3 minimum)',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_setup_random_blocked_n2',
      () async {
        await UITestHelpers.resetServerState();
        await navigateToMenu(tester);

        // Switch to Team mode (default Random assignment)
        await setGameModeTeam(tester);
        // Stay in Random mode (default)

        // Add only 2 players
        await addPlayer(tester, 'Alice');
        await addPlayer(tester, 'Bob');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // TEE OFF button should be disabled (2 players < minimum 3 for team mode)
        final teeOffButton = ElementFinders.getTikiGolfStartButton();
        expect(teeOffButton, findsOneWidget,
            reason: 'TEE OFF button should be rendered');

        // Verify it's disabled: the button's onPressed should be null
        // We verify this by attempting a tap and confirming no navigation occurs
        await tester.tap(teeOffButton, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Should still be on the menu screen (game didn't start)
        expect(teeOffButton, findsOneWidget,
            reason:
                'Should still be on menu screen — TEE OFF was disabled with 2 players in Team+Random mode '
                '(N=2 < minimum 3 for team mode). Tapping a disabled button should not navigate.');
      },
    );
  });
}
