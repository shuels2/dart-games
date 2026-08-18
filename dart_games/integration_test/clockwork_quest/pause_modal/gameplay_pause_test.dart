import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runGameplayPauseAppearsTest(pauseModalSpec,
      description: 'Pause modal appears during gameplay',
      throwDartFirst: true);

  runGameplayPauseBlocksBackTest(pauseModalSpec,
      description: 'Pause blocks AppBar back button',
      throwDartFirst: true);

  runGameplayPauseBlocksEmulatorTest(pauseModalSpec,
      description: 'Pause blocks dartboard emulator');

  runGameplayPauseOverRemoveDartsTest(pauseModalSpec,
      description: 'Pause over RemoveDartsModal');

  runGameplayPauseOverSaveGameTest(pauseModalSpec,
      description: 'Pause over SaveGameModal');

  runGameplayEditScoreAutoClosesTest(pauseModalSpec,
      description: 'EditScoreDialog auto-closes on disconnect');

  runGameplayPauseDismissesTest(pauseModalSpec,
      description: 'Pause dismisses on reconnect game continues');

  runGameplayRemoveDartsSurvivesTest(pauseModalSpec,
      description: 'RemoveDartsModal still visible after reconnect');
}
