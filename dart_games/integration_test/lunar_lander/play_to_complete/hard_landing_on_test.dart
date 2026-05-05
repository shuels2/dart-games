import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.lunarLander();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Play to Complete: Lunar Lander with Hard Landing ON (altitude=200)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      altitude: 200,
      hardLanding: true,
    );

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getLunarLanderProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 1000, // Hard Landing may take more iterations
    );

    // Game completes (someone reaches exactly 0 or strategy completes)
    expect(provider.hasWinner, isTrue,
        reason: 'Game should complete even with Hard Landing ON');
    expect(config.getPlayAgainButton(), findsOneWidget);
  });
}
