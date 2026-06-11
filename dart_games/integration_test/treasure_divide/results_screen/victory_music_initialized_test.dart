// integration_test/treasure_divide/results_screen/victory_music_initialized_test.dart
//
// Results-4 — VictoryMusicService is initialized after results screen loads.
// MANDATORY: proves _playVictoryMusic() was called in results screen initState.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: VictoryMusicService is initialized after Treasure Divide results screen loads',
      (WidgetTester tester) async {
    // resetServerState() calls VictoryMusicService().resetForTesting()
    // which sets _initialized = false
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7, playerNames: ['MusicP1', 'MusicP2']);

    await playGameToResultsScreen(tester);

    // VictoryMusicService.initialize() runs async AFTER the Play Again
    // button mounts (HTTP GET /api/v1/music); pumpUntilResults only
    // settles ~1s post-button, which isn't enough under heavy parallel load.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    // VictoryMusicService should now be initialized
    expect(VictoryMusicService().isInitialized, isTrue,
        reason:
            '[DIAG td_results_music] VictoryMusicService must be initialized — '
            'proves _playVictoryMusic() was called in results screen initState');
  });
}
