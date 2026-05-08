import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart' as driver;

/// Driver for the regular UI test suite.
///
/// Uses the EXTENDED `integrationDriver` so any test can call
/// `IntegrationTestWidgetsFlutterBinding.takeScreenshot(name)` and have the
/// PNG bytes persisted to disk by this driver's `onScreenshot` callback.
///
/// Conventions:
/// - Failure screenshots (taken by
///   `FailureScreenshotHelper.runWithFailureScreenshot`) go to
///   `temp_screenshots/failures/<test>_<timestamp>.png` so they don't collide
///   with screenshots taken by the dedicated screenshot test.
/// - The screenshot test driver (`screenshot_test.dart`) writes screenshots
///   directly to `temp_screenshots/<name>.png` — that path is reserved for
///   the screenshot suite.
Future<void> main() async {
  final dir = Directory('temp_screenshots/failures');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  await driver.integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      // The helper passes a path-like name (e.g. "failures/save_modal_xyz_1234").
      // Treat the name as a filename relative to temp_screenshots/ so callers
      // can route screenshots into subfolders without the driver caring.
      final file = File('temp_screenshots/$screenshotName.png');
      if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
      file.writeAsBytesSync(screenshotBytes);
      return true;
    },
  );
}
