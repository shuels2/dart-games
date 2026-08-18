import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runMenuPauseAppearsTest(pauseModalSpec,
      description: 'Pause modal appears on menu screen');

  runMenuPauseBlocksBackTest(pauseModalSpec,
      description: 'Pause blocks AppBar back button');

  runMenuPauseBlocksStartTest(pauseModalSpec,
      description: 'Pause blocks start game button');

  runMenuPauseBlocksSettingsTest(pauseModalSpec,
      description: 'Pause blocks settings controls');

  runMenuPauseCleanDisconnectTest(pauseModalSpec,
      description: 'Pause on menu with basic disconnect');

  runMenuPauseDismissesTest(pauseModalSpec,
      description: 'Pause dismisses and menu still works',
      playerName: 'Player A',
      verifyAfter: (tester) =>
          expect(find.text('Player A'), findsWidgets,
              reason: 'Menu stopped accepting input after the pause'));

  runMenuReconnectRestoresBackTest(pauseModalSpec,
      description: 'Pause blocks then reconnect enables back');
}
