import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runResultsPauseAppearsTest(pauseModalSpec,
      description: 'Test 1: Pause modal appears on TD results screen when dartboard disconnects');

  runResultsPauseBlocksPlayAgainTest(pauseModalSpec,
      description: 'Test 2: Pause modal blocks Play Again button on TD results screen');

  runResultsPauseBlocksChangeSettingsTest(pauseModalSpec,
      description: 'Test 3: Pause modal blocks Change Settings button on TD results screen');

  runResultsPauseBlocksBackToMenuTest(pauseModalSpec,
      description: 'Test 4: Pause modal blocks Back to Menu button on TD results screen');

  runResultsPauseDismissesTest(pauseModalSpec,
      description: 'Test 5: Action buttons work after pause modal dismisses on TD results screen');
}
