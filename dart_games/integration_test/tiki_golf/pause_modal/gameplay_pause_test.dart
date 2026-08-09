import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runGameplayPauseAppearsTest(pauseModalSpec,
      description: 'Test 1: Pause modal appears on game screen when board disconnects');

  runGameplayPauseBlocksBackTest(pauseModalSpec,
      description: 'Test 2: Pause blocks AppBar back arrow on game screen');

  runGameplayPauseBlocksEmulatorTest(pauseModalSpec,
      description: 'Test 3: Pause blocks dartboard emulator (DARTS REMOVED not tappable)');

  runGameplayPauseOverRemoveDartsTest(pauseModalSpec,
      description: 'Test 4: Pause modal renders OVER RemoveDartsModal (3 misses → turn ends → pause on top)');

  runGameplayPauseOverSaveGameTest(pauseModalSpec,
      description: 'Test 5: Pause modal renders OVER SaveGameModal (back triggers save modal → pause blocks Save)');

  runGameplayEditScoreAutoClosesTest(pauseModalSpec,
      description: 'Test 6: EditScoreDialog auto-closes on dartboard disconnect');

  runGameplayPauseDismissesTest(pauseModalSpec,
      description: 'Test 7: Pause dismisses on reconnect (back to normal gameplay)');

  runGameplayRemoveDartsSurvivesTest(pauseModalSpec,
      description: 'Test 8: RemoveDartsModal still visible after pause dismisses');
}
