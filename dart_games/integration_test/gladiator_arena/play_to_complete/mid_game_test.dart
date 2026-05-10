import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';

final config = GameUIConfig.gladiatorArena();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Gladiator Arena from mid-game state',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartGladiatorArena(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
    );

    // Play partway through
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.clickDartsRemoved(tester);
    await DartThrowHelpers.completeTurnWithMisses(tester);

    // Now play to complete from mid-game
    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getGladiatorArenaProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
    );

    expect(provider.hasWinner, isTrue);
    expect(config.getPlayAgainButton(), findsOneWidget);
  });
}
