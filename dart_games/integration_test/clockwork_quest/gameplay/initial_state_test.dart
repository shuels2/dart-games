import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Game starts with correct initial state',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);
    expect(
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester), isNotNull);
    expect(
        ProviderHelpers.getClockworkQuestCurrentPlayerDartsThrown(tester), 0);

    // Verify game screen widgets
    expect(find.byKey(ClockworkQuestGameKeys.activePlayerPanel),
        findsOneWidget);
    expect(find.byKey(ClockworkQuestGameKeys.gearTracker), findsOneWidget);
    expect(find.byKey(ClockworkQuestGameKeys.activePlayerName),
        findsOneWidget);
  });
}
