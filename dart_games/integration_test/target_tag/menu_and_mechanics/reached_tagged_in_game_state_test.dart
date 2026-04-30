import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 7: Reached Tagged In - Game State Validation - Validates player starts with 0 shields not tagged in, hitting own target with triple dart reaches max shields (3 shields for max 3), player immediately transitions to tagged in status, "TAGGED IN" badge appears on player tile. Note: Does NOT validate visual dart border colors (green 0xFF00FFA3 mentioned in original description) - only game state and badge display tested',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3
    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'TaggedIn1', config);
    await UITestHelpers.addPlayer(tester, 'TaggedIn2', config);
    await UITestHelpers.startGame(tester, config);

    final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayerId, isNotNull);

    // Verify starting state
    final initialShields = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId!);
    final initialTaggedIn = ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentPlayerId);
    expect(initialShields, 0);
    expect(initialTaggedIn, isFalse);

    // Get player target
    final playerTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, currentPlayerId);
    expect(playerTarget, isNotNull);

    // Hit with triple to reach max shields instantly
    await throwDartViaMock(tester, playerTarget!, multiplier: 'triple');

    // Verify reached tagged in
    final finalShields = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
    final finalTaggedIn = ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentPlayerId);
    expect(finalShields, 3);
    expect(finalTaggedIn, isTrue);

    // Verify tagged in badge appears
    expect(find.text('TAGGED IN'), findsAtLeastNWidgets(1));
  });
}
