import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 5: Dart Box Colors - Game Logic Validation - Validates D1/D2/D3 game mechanics when player not tagged in. Hitting own target while not tagged in adds shields (game logic verified). Missing target does not add shields (game logic verified). Note: Does NOT validate visual dart indicator border colors (green 0xFF00FFA3 or pink 0xFFFF007A) - only game logic tested, not visual display',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'DartColor1', config);
    await UITestHelpers.addPlayer(tester, 'DartColor2', config);
    await UITestHelpers.startGame(tester, config);

    // Verify game started
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // Get current player and their target
    final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayerId, isNotNull);
    final playerTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, currentPlayerId!);
    expect(playerTarget, isNotNull);

    // Hit own target (should be green - building shields)
    await throwDartViaMock(tester, playerTarget!);

    // Verify dart indicator present (actual color checking would require visual testing)
    // For now, verify game continues normally
    final shieldsAfterHit = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
    expect(shieldsAfterHit, greaterThan(0));

    // Throw miss (should be pink)
    await throwMissViaMock(tester);

    // Shields should not increase
    final shieldsAfterMiss = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
    expect(shieldsAfterMiss, equals(shieldsAfterHit));
  });
}
