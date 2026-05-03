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

  testWidgets('Play to Complete: Lunar Lander with low altitude (100) completes faster',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      altitude: 100,
    );

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getLunarLanderProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 200, // Fewer iterations needed at altitude 100
    );

    expect(provider.hasWinner, isTrue,
        reason: 'Low altitude (100) game should complete');
    expect(config.getPlayAgainButton(), findsOneWidget);
  });
}
