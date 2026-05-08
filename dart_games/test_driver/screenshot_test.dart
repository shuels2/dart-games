import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart' as driver;

Future<void> main() async {
  final dir = Directory('temp_screenshots');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  await driver.integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      // Allow callers to use subdirectory paths in `screenshotName`
      // (e.g. `failures/<test>_<ts>`) so failure screenshots can be
      // routed to a separate folder without polluting the main capture
      // dir. Create the parent dir on demand so writeAsBytesSync doesn't
      // fail on a missing intermediate directory.
      final File image = File('temp_screenshots/$screenshotName.png');
      if (!image.parent.existsSync()) {
        image.parent.createSync(recursive: true);
      }
      image.writeAsBytesSync(screenshotBytes);
      return true;
    },
  );
}
