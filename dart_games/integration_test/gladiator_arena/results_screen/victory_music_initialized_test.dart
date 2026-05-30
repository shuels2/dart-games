import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/results_helpers.dart';
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
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Alice', 'Bob'],
    );
    await completeGameToVictory(tester);

    // Wait for results screen initState to run
    await ResultsHelpers.pumpUntilResults(tester, config);
    // VictoryMusicService.initialize() runs async AFTER the Play Again button
    // mounts (HTTP GET /api/v1/music); pumpUntilResults only settles ~1s
    // post-button, which isn't enough under heavy parallel load.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    // VictoryMusicService should now be initialized (results screen called it)
    expect(VictoryMusicService().isInitialized, isTrue,
        reason: 'VictoryMusicService must be initialized — proves _playVictoryMusic() '
            'was called in results screen initState');
  });
}
