import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Monster image changes with health - Provider getMonsterImagePath returns correct state: FullHealth, 70Health, 30Health, Eliminated', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Full health: FullHealth image
    final fullImage = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, opponentId)!;
    expect(fullImage, contains('FullHealth'));

    // Reduce to 70% health (7/10) -> 70Health image
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 7/10
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    final image70 = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, opponentId)!;
    expect(image70, contains('70Health'));

    // Opponent misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Reduce to 30% health (3/10) -> 30Health image
    await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 5/10
    await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 3/10
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    final image30 = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, opponentId)!;
    expect(image30, contains('30Health'));

    // Opponent misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Eliminate (reduce to 0)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 0
    expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, opponentId), isTrue);

    final eliminatedImage = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, opponentId)!;
    expect(eliminatedImage, contains('Eliminated'));
  });
}
