import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';

final config = GameUIConfig.lunarLander();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Play to Complete: Lunar Lander mid-game pickup',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(tester, config);

    // Throw 2 manual darts first (descend 20+20=40)
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 20);

    final provider = ProviderHelpers.getLunarLanderProvider(tester);
    expect(provider.hasWinner, isFalse);

    // Now let Play-to-Complete finish it from mid-game
    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
    );

    expect(provider.hasWinner, isTrue);
    expect(config.getPlayAgainButton(), findsOneWidget);
  });
}
