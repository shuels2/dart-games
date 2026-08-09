import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runGameplayPauseAppearsTest(pauseModalSpec,
      description: 'Test 1: Pause modal appears during gameplay');

  runGameplayPauseBlocksBackTest(pauseModalSpec,
      description: 'Test 2: Pause blocks AppBar back button during gameplay');

  runGameplayPauseBlocksEmulatorTest(pauseModalSpec,
      description: 'Test 3: Pause blocks dartboard emulator');

  runGameplayPauseOverRemoveDartsTest(pauseModalSpec,
      description: 'Test 4: Pause over RemoveDartsModal');

  runGameplayPauseOverSaveGameTest(pauseModalSpec,
      description: 'Test 5: Pause over SaveGameModal');

  runGameplayEditScoreAutoClosesTest(pauseModalSpec,
      description: 'Test 6: EditScoreDialog auto-closes on disconnect');

  runGameplayPauseDismissesTest(pauseModalSpec,
      description: 'Test 7: Pause dismisses on reconnect game continues');

  runGameplayRemoveDartsSurvivesTest(pauseModalSpec,
      description: 'Test 8: RemoveDartsModal still visible after reconnect');
}
