import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runResultsPauseAppearsTest(pauseModalSpec,
      description: 'Pause modal appears on Carnival Derby results screen');

  runResultsPauseBlocksPlayAgainTest(pauseModalSpec,
      description: 'Pause blocks Play Again button on Carnival Derby results');

  runResultsPauseBlocksChangeSettingsTest(pauseModalSpec,
      description: 'Pause blocks Change Settings button on Carnival Derby results');

  runResultsPauseBlocksBackToMenuTest(pauseModalSpec,
      description: 'Pause blocks Back to Menu button on Carnival Derby results');

  runResultsPauseDismissesTest(pauseModalSpec,
      description: 'Pause dismisses and buttons work on Carnival Derby results');
}
