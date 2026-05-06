import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: VictoryMusicService initialized after game completion.
  testWidgets('Results: VictoryMusicService is initialized after game completes',
      (WidgetTester tester) async {
    // resetServerState resets VictoryMusicService._initialized to false
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);
    await completeGameToVictory(tester);

    // MANDATORY: VictoryMusicService should be initialized
    expect(VictoryMusicService().isInitialized, isTrue,
        reason:
            'VictoryMusicService should be initialized after results screen '
            'triggers victory music playback');
  });
}
