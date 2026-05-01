import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../gameplay/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Play to Complete: Monster Mash mid-game pickup',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Throw 2 manual darts (attacks on opponent)
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final players = ProviderHelpers.getSelectedPlayers(tester);
    final opponent = players.firstWhere((p) => p.id != currentPlayerId);
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponent.id)!;

    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

    final provider = ProviderHelpers.getMonsterMashProvider(tester);
    expect(provider.hasWinner, isFalse);

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
    );

    expect(provider.hasWinner, isTrue);

    final playAgainButton = config.getPlayAgainButton();
    expect(playAgainButton, findsOneWidget);
  });
}
