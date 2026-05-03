import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: Play Again relaunches with same settings',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, altitude: 300, hardLanding: true);
    await completeGameToVictory(tester, hardLandingEnabled: true);
    await PumpSequences.fullRebuild(tester);

    // Click Play Again
    await UITestHelpers.clickPlayAgain(tester, config);

    // Should be on game screen now with same settings
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(ProviderHelpers.isLunarLanderGameActive(tester), isTrue);
    expect(ProviderHelpers.getLunarLanderStartingAltitude(tester), 300);
    expect(ProviderHelpers.isLunarLanderHardLandingEnabled(tester), isTrue);
  });
}
