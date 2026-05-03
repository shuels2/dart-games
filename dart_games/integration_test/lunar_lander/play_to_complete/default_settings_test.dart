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

  testWidgets('Play to Complete: Lunar Lander with default settings (altitude=200, Hard Landing=OFF)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(tester, config);

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getLunarLanderProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
    );

    expect(provider.hasWinner, isTrue);
    expect(config.getPlayAgainButton(), findsOneWidget);
  });
}
