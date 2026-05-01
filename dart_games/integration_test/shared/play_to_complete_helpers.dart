import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'pump_sequences.dart';

class PlayToCompleteHelpers {
  static Finder getPlayToCompleteButton() {
    return find.byKey(DartboardEmulatorKeys.playToCompleteButton);
  }

  static Future<void> tapPlayToComplete(WidgetTester tester) async {
    final button = getPlayToCompleteButton();
    expect(button, findsOneWidget);
    await tester.tap(button);
    await PumpSequences.simpleUpdate(tester);
  }

  static Future<void> waitForGameCompletion(
    WidgetTester tester, {
    required bool Function() isComplete,
    int maxIterations = 500,
  }) async {
    for (int i = 0; i < maxIterations; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      if (isComplete()) break;
    }
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}
