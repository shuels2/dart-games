import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runResultsPauseAppearsTest(pauseModalSpec,
      description: 'Test 1: Pause modal appears on results screen');

  runResultsPauseBlocksPlayAgainTest(pauseModalSpec,
      description: 'Test 2: Pause blocks Play Again button');

  runResultsPauseBlocksChangeSettingsTest(pauseModalSpec,
      description: 'Test 3: Pause blocks Change Settings button');

  runResultsPauseBlocksBackToMenuTest(pauseModalSpec,
      description: 'Test 4: Pause blocks Back to Menu button');

  runResultsPauseDismissesTest(pauseModalSpec,
      description: 'Test 5: Pause dismisses and buttons work');
}
