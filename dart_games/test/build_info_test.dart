import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/build_info.dart';

void main() {
  group('BuildInfo', () {
    test('defaults to "dev" when --dart-define=BUILD_NUMBER is not set', () {
      // `flutter test` doesn't pass --dart-define, so the constant
      // takes its fallback value. The build.bat / build.sh wrappers
      // are responsible for setting it on production builds.
      expect(BuildInfo.number, 'dev');
    });
  });
}
