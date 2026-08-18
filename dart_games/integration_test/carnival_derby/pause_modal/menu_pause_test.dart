import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runMenuPauseAppearsTest(pauseModalSpec,
      description: 'Pause modal appears on Carnival Derby menu screen');

  runMenuPauseBlocksBackTest(pauseModalSpec,
      description: 'Pause blocks AppBar back button on Carnival Derby menu');

  runMenuPauseBlocksStartTest(pauseModalSpec,
      description: 'Pause blocks start game button on Carnival Derby menu');

  runMenuPauseBlocksSettingsTest(pauseModalSpec,
      description: 'Pause blocks settings controls on Carnival Derby menu');

  runMenuPauseCleanDisconnectTest(pauseModalSpec,
      description: 'Pause modal on clean Carnival Derby menu disconnect works');

  runMenuPauseDismissesTest(pauseModalSpec,
      description: 'Pause dismisses and Carnival Derby menu still works',
      playerName: 'PostPause',
      verifyAfter: (tester) =>
          expect(find.text('PostPause'), findsWidgets,
              reason: 'Menu stopped accepting input after the pause'));

  runMenuReconnectRestoresBackTest(pauseModalSpec,
      description: 'Pause blocks back button then reconnect allows it on Carnival Derby menu');
}
