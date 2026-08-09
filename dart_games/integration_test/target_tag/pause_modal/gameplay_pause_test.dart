import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runGameplayPauseAppearsTest(pauseModalSpec,
      description: 'Pause modal appears during Target Tag gameplay',
      throwDartFirst: true);

  runGameplayPauseBlocksBackTest(pauseModalSpec,
      description: 'Pause blocks AppBar back button during Target Tag gameplay',
      throwDartFirst: true);

  runGameplayPauseBlocksEmulatorTest(pauseModalSpec,
      description: 'Pause blocks dartboard emulator during Target Tag gameplay');

  runGameplayPauseOverRemoveDartsTest(pauseModalSpec,
      description: 'Pause modal appears over RemoveDartsModal in Target Tag');

  runGameplayPauseOverSaveGameTest(pauseModalSpec,
      description: 'Pause modal appears over SaveGameModal in Target Tag');

  runGameplayEditScoreAutoClosesTest(pauseModalSpec,
      description: 'EditScoreDialog auto-closes on disconnect in Target Tag');

  runGameplayPauseDismissesTest(pauseModalSpec,
      description: 'Pause dismisses on reconnect and Target Tag game continues');

  runGameplayRemoveDartsSurvivesTest(pauseModalSpec,
      description: 'RemoveDartsModal still visible after reconnect in Target Tag');
}
