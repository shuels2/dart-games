import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart' as driver;

Future<void> main() async {
  final dir = Directory('temp_screenshots');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  await driver.integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      final File image = File('temp_screenshots/$screenshotName.png');
      image.writeAsBytesSync(screenshotBytes);
      return true;
    },
  );
}
