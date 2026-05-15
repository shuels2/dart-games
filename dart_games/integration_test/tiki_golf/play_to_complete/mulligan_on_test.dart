// integration_test/tiki_golf/play_to_complete/mulligan_on_test.dart
//
// Play-to-Complete: Solo 2 players, Mulligan ON.
// The Splash+Mulligan modal may appear for the loser player (who misses every
// dart). The strategy does NOT take the mulligan — it taps NEXT PLAYER instead.
// The PTC loop must complete successfully through mulligan modal states.
//
// Strategy note: TikiGolfStrategy returns miss throws for non-winner players.
// The PlayToCompleteRunner handles the mulligan modal by tapping NEXT PLAYER
// (not USE MULLIGAN) since the strategy has no mechanism to indicate mulligan
// preference — the modal's "NEXT PLAYER" path is used.
//
// Section 12B — play_to_complete test 4 (mulligan_on)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.tikiGolf();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Tiki Golf with Mulligan ON handles Splash+Mulligan modal correctly',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      mulliganEnabled: true,
    );

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 600, // extra headroom for mulligan modal pump cycles
    );

    expect(provider.hasWinner, isTrue,
        reason:
            'Game should complete with Mulligan ON — PTC must handle the mulligan modal');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible');
    // Verify mulligan was enabled for this game
    expect(ProviderHelpers.isTikiGolfMulliganEnabled(tester), isTrue,
        reason: 'Mulligan should be enabled as configured');
  });
}
