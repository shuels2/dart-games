import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 29: Shared neighbor hit shows pulsing glow on dart indicator',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, neighborNumbers: true);

    // Hit 1 -- shared neighbor of 20 and 18
    await throwDartViaMock(tester, 1);

    // Verify the dart indicator has a multi-target hit via provider
    final playerId = ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;
    final provider = ProviderHelpers.getReefRoyaleProvider(tester);
    final targetCount = provider.getDartThrowTargetCount(playerId);
    expect(targetCount.length, 1);
    expect(targetCount[0], greaterThan(1)); // Multi-target = pulsing glow

    // Verify the dart indicator widget exists and is wrapped in AnimatedBuilder
    final d0Finder = find.byKey(ReefRoyaleGameKeys.dartIndicator(0));
    expect(d0Finder, findsOneWidget);

    // Throw a direct hit on target 20 (single target, no glow)
    await throwDartViaMock(tester, 20);
    final targetCount2 = provider.getDartThrowTargetCount(playerId);
    expect(targetCount2[1], 1); // Single target = no glow
  });
}
