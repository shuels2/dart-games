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

  testWidgets('Play to Complete: Lunar Lander with high altitude (500) still completes',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      altitude: 500,
    );

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getLunarLanderProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 1000, // More iterations needed at altitude 500
    );

    expect(provider.hasWinner, isTrue,
        reason: 'High altitude (500) game should still complete');
    expect(config.getPlayAgainButton(), findsOneWidget);
  });
}
