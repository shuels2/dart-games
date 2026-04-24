import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 22: Edit Score - Reach Tagged In Status - Validates Player 2 starts with partial shields (2 shields, not tagged in yet), edit score used to add shields to Player 2 (setting darts to own target), when shields reach max value (3) Player 2 gets "TAGGED IN" badge, tagged in status confirmed via provider. Note: Does NOT validate active panel switches to show opponent targets list or that Player 2 can attack opponents - only validates game state (shields, tagged in status) and badge display',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'EditTagIn1', config);
    await UITestHelpers.addPlayer(tester, 'EditTagIn2', config);
    await UITestHelpers.startGame(tester, config);

    // Player 1 builds partial shields
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

    await throwDartViaMock(tester, player1Target!);
    await throwDartViaMock(tester, player1Target);
    await throwMissViaMock(tester);

    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), 2);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isFalse);

    // Use edit score to reach tagged in
    await EditScoreHelpers.openEditScore(tester, config);
    await EditScoreHelpers.setAllDarts(tester, 'S$player1Target', 'S$player1Target', 'S$player1Target');
    await EditScoreHelpers.updateScore(tester);

    // Verify tagged in
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), 3);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);
    expect(find.text('TAGGED IN'), findsAtLeastNWidgets(1));
  });
}
