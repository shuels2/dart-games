/// Smoke test for FailureScreenshotHelper.
///
/// Deliberately fails so we can verify a PNG appears in
/// `temp_screenshots/failures/`. Once the mechanism is confirmed working,
/// this file can be deleted (it's not part of any game's test pack and is
/// not invoked by the parallel runner — it lives under `_smoke/` for that
/// reason).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../shared/failure_screenshot_helper.dart';
import '../shared/ui_test_helpers.dart';
import '../shared/game_ui_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: capture a failure screenshot from a deliberately-failing assertion',
      (tester) async {
    await FailureScreenshotHelper.runWithFailureScreenshot(
      tester,
      'smoke_failure_screenshot',
      () async {
        await UITestHelpers.resetServerState();

        // Land on the home screen so the screenshot has identifiable content.
        await UITestHelpers.navigateToGameMenu(tester, GameUIConfig.piratesGrid());

        // Deliberately fail so the helper triggers a screenshot.
        expect(true, isFalse,
            reason: 'Smoke test for FailureScreenshotHelper — '
                'this assertion is intentionally false to trigger capture.');
      },
    );
  });
}
