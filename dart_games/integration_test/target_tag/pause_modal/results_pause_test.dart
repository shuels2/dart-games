import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runResultsPauseAppearsTest(pauseModalSpec,
      description: 'Pause modal appears on Target Tag results screen');

  runResultsPauseBlocksPlayAgainTest(pauseModalSpec,
      description: 'Pause blocks Play Again button on Target Tag results');

  runResultsPauseBlocksChangeSettingsTest(pauseModalSpec,
      description: 'Pause blocks Change Settings button on Target Tag results');

  runResultsPauseBlocksBackToMenuTest(pauseModalSpec,
      description: 'Pause blocks Back to Menu button on Target Tag results');

  runResultsPauseDismissesTest(pauseModalSpec,
      description: 'Pause dismisses and buttons work on Target Tag results');
}
