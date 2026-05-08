/// Smoke test for `UITestHelpers.runWithFailureScreenshot`.
///
/// Run via:
///   flutter drive
///     --driver=test_driver/screenshot_test.dart
///     --target=integration_test/_smoke/failure_screenshot_smoke_test.dart
///     -d chrome
///     --dart-define=SERVER_PORT=9000
///     --browser-dimension=1366x768
///
/// Expected outcome:
///   1. Test fails with the deliberate `expect(true, isFalse)`
///   2. A PNG appears in `temp_screenshots/failures/` showing the home
///      screen content at the moment of failure
///
/// Lives under `integration_test/_smoke/` — outside any game directory —
/// so neither `run_ui_tests.bat` (iterates the GAMES list) nor
/// `run_ui_tests_parallel.bat` (same) picks it up. Invoke directly via
/// `flutter drive` when verifying the helper after a Flutter SDK upgrade
/// or driver change.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/game_ui_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'smoke: capture a failure screenshot from a deliberately-failing assertion',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'smoke_failure_screenshot',
      () async {
        await UITestHelpers.resetServerState();

        await UITestHelpers.navigateToGameMenu(
            tester, GameUIConfig.piratesGrid());

        // Settle so the captured screenshot reflects a fully-rendered screen.
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        await tester.pump();
        await tester.pump();

        // Deliberately fail.
        expect(true, isFalse,
            reason: 'Smoke test for failure-screenshot mechanism — '
                'this assertion is intentionally false to trigger capture.');
      },
    );
  });
}
