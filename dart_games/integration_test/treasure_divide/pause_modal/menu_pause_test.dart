import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runMenuPauseAppearsTest(pauseModalSpec,
      description: 'Test 1: Pause modal appears on TD menu when dartboard disconnects');

  runMenuPauseBlocksBackTest(pauseModalSpec,
      description: 'Test 2: Pause modal blocks AppBar back button on TD menu');

  runMenuPauseBlocksStartTest(pauseModalSpec,
      description: 'Test 3: Pause modal blocks SET SAIL button on TD menu');

  runMenuPauseBlocksSettingsTest(pauseModalSpec,
      description: 'Test 4: Pause modal blocks Game Mode toggle on TD menu');

  runMenuPauseBlocksAddPlayerTest(pauseModalSpec,
      description: 'Test 5: Pause modal blocks NEW PLAYER button on TD menu');

  runMenuPauseDismissesTest(pauseModalSpec,
      description: 'Test 6: Pause modal dismisses on reconnect on TD menu');

  runMenuReconnectRestoresBackTest(pauseModalSpec,
      description: 'Test 7: Back button works after pause modal dismisses on TD menu');
}
