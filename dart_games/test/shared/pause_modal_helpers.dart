import 'package:flutter_test/flutter_test.dart';

import 'provider_helpers.dart';
import 'pump_sequences.dart';

class PauseModalHelpers {
  static void verifyPauseModalVisible(WidgetTester tester) {
    expect(find.text('Game Paused'), findsOneWidget);
  }

  static void verifyPauseModalNotVisible(WidgetTester tester) {
    expect(find.text('Game Paused'), findsNothing);
  }

  static Future<void> simulateDisconnectAndVerify(
      WidgetTester tester) async {
    ProviderHelpers.simulateDartboardDisconnection(tester);
    await PumpSequences.simpleUpdate(tester);
    verifyPauseModalVisible(tester);
  }

  static Future<void> simulateReconnectAndVerify(
      WidgetTester tester) async {
    ProviderHelpers.simulateDartboardReconnection(tester);
    await PumpSequences.simpleUpdate(tester);
    verifyPauseModalNotVisible(tester);
  }
}
