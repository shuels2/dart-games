import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: default target score 200 is set correctly',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      playerNames: ['Player A', 'Player B'],
    );

    // Default target score should be 200
    expect(ProviderHelpers.getGladiatorArenaTargetScore(tester), 200,
        reason: 'Default target score should be 200');

    // Game should be active
    expect(ProviderHelpers.isGladiatorArenaGameActive(tester), isTrue);
  });
}
