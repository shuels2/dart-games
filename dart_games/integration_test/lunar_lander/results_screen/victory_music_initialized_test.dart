import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: Victory music initialized test.
  // Proves _playVictoryMusic() was called in the results screen's initState.
  testWidgets('Results: VictoryMusicService is initialized after results screen loads',
      (WidgetTester tester) async {
    // resetServerState() calls VictoryMusicService().resetForTesting()
    // which sets _initialized = false
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    // Extra pump time for results screen initState to run
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // VictoryMusicService should now be initialized (results screen called it)
    expect(VictoryMusicService().isInitialized, isTrue,
        reason: 'VictoryMusicService must be initialized — proves _playVictoryMusic() '
            'was called in results screen initState');
  });
}
