import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runResultsPauseAppearsTest(pauseModalSpec,
      description: 'Test 1: Pause modal appears on results screen when board disconnects');

  runResultsPauseBlocksPlayAgainTest(pauseModalSpec,
      description: 'Test 2: Pause blocks PLAY AGAIN button tap');

  runResultsPauseBlocksChangeSettingsTest(pauseModalSpec,
      description: 'Test 3: Pause blocks CHANGE SETTINGS button tap');

  runResultsPauseBlocksBackToMenuTest(pauseModalSpec,
      description: 'Test 4: Pause blocks BACK TO MENU button tap');

  runResultsPauseDismissesTest(pauseModalSpec,
      description: 'Test 5: Pause dismisses on reconnect; action buttons work again');
}
