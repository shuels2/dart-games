import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runGameplayPauseAppearsTest(pauseModalSpec,
      description: 'Pause modal appears during Carnival Derby gameplay',
      throwDartFirst: true);

  runGameplayPauseBlocksBackTest(pauseModalSpec,
      description: 'Pause blocks AppBar back button during Carnival Derby gameplay',
      throwDartFirst: true);

  runGameplayPauseBlocksEmulatorTest(pauseModalSpec,
      description: 'Pause blocks dartboard emulator during Carnival Derby gameplay');

  runGameplayPauseOverRemoveDartsTest(pauseModalSpec,
      description: 'Pause modal appears over RemoveDartsModal in Carnival Derby');

  runGameplayPauseOverSaveGameTest(pauseModalSpec,
      description: 'Pause modal appears over SaveGameModal in Carnival Derby');

  runGameplayEditScoreAutoClosesTest(pauseModalSpec,
      description: 'EditScoreDialog auto-closes on disconnect in Carnival Derby');

  runGameplayPauseDismissesTest(pauseModalSpec,
      description: 'Pause dismisses on reconnect and Carnival Derby game continues');

  runGameplayRemoveDartsSurvivesTest(pauseModalSpec,
      description: 'RemoveDartsModal still visible after reconnect in Carnival Derby');
}
