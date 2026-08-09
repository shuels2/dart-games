import 'package:integration_test/integration_test.dart';

import '../../shared/pause_modal_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runGameplayPauseAppearsTest(pauseModalSpec,
      description: 'Test 1: Pause modal appears during TD gameplay when dartboard disconnects');

  runGameplayPauseBlocksBackTest(pauseModalSpec,
      description: 'Test 2: Pause modal blocks AppBar back button during TD gameplay');

  runGameplayPauseBlocksEmulatorTest(pauseModalSpec,
      description: 'Test 3: Pause modal blocks dartboard emulator during TD gameplay');

  runGameplayPauseOverRemoveDartsTest(pauseModalSpec,
      description: 'Test 4: Pause modal paints over RemoveDartsModal during TD gameplay');

  runGameplayPauseOverSaveGameTest(pauseModalSpec,
      description: 'Test 5: Pause modal blocks SaveGameModal save button during TD gameplay');

  runGameplayEditScoreAutoClosesTest(pauseModalSpec,
      description: 'Test 6: EditScoreDialog auto-closes when dartboard disconnects during TD gameplay');

  runGameplayPauseDismissesTest(pauseModalSpec,
      description: 'Test 7: Pause modal dismisses on reconnect during TD gameplay');

  runGameplayRemoveDartsSurvivesTest(pauseModalSpec,
      description: 'Test 8: RemoveDartsModal still visible after reconnect during TD gameplay');
}
