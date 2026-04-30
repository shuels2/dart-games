import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Eliminated opponent visual state - Eliminated opponent marked via provider', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);

    await UITestHelpers.startGame(tester, config);

    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
    final playerBTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

    // Not eliminated initially
    expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, playerB.id), isFalse);

    // Attack player B to eliminate
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple'); // -3
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple'); // -3
    await throwDartViaMock(tester, playerBTarget, multiplier: 'triple'); // -3 -> 1 HP
    await clickDartsRemoved(tester);

    // Player B misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Player C misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Finish off Player B
    await throwDartViaMock(tester, playerBTarget, multiplier: 'single'); // -1 -> 0 HP

    // Verify elimination
    expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, playerB.id), isTrue);
    expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, playerB.id), 0);

    // Verify eliminated image path
    final imagePath = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, playerB.id)!;
    expect(imagePath, contains('Eliminated'));
  });
}
