import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runResultsPauseAppearsTest(pauseModalSpec,
      description: 'Pause modal appears on results screen');

  runResultsPauseBlocksPlayAgainTest(pauseModalSpec,
      description: 'Pause blocks Play Again button');

  runResultsPauseBlocksChangeSettingsTest(pauseModalSpec,
      description: 'Pause blocks Change Settings button');

  runResultsPauseBlocksBackToMenuTest(pauseModalSpec,
      description: 'Pause blocks Back to Menu button');

  runResultsPauseDismissesTest(pauseModalSpec,
      description: 'Pause dismisses and buttons work');
}
