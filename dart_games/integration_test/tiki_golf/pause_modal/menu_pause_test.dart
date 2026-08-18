import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runMenuPauseAppearsTest(pauseModalSpec,
      description: 'Test 1: Pause modal appears on menu screen');

  runMenuPauseBlocksBackTest(pauseModalSpec,
      description: 'Test 2: Pause blocks AppBar back button on menu');

  runMenuPauseBlocksStartTest(pauseModalSpec,
      description: 'Test 3: Pause blocks TEE OFF button');

  runMenuPauseBlocksSettingsTest(pauseModalSpec,
      description: 'Test 4: Pause blocks settings controls');

  runMenuPauseBlocksAddPlayerTest(pauseModalSpec,
      description: 'Test 5: Pause blocks Add Player button on menu');

  runMenuPauseDismissesTest(pauseModalSpec,
      description: 'Test 6: Pause dismisses on reconnect; AppBar back works again');

  runMenuReconnectRestoresBackTest(pauseModalSpec,
      description: 'Test 7: Post-reconnect back arrow returns to home with ≥3 cards visible');
}
