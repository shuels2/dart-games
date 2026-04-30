import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 25: Random Reefs shows coral cards for non-standard targets',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, randomReefs: true);

    // With random reefs, the game should still have coral cards displayed
    // The exact targets will be random, but we verify via the provider
    final provider = ProviderHelpers.getReefRoyaleProvider(tester);
    final targets = provider.currentGame!.activeTargets;
    expect(targets.length, 7); // Still 7 targets (6 random + Bull)
    expect(targets.last, 25); // Bull always last

    // Verify coral cards exist for whatever targets were selected
    for (final target in targets) {
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(target)), findsOneWidget);
    }
  });
}
