import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 9: Dart indicators update after each throw',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Before any throws, all 3 indicators exist but are empty (transparent fill, border only)
    for (int i = 0; i < 3; i++) {
      final indicator = tester.widget<Container>(
        find.byKey(ClockworkQuestGameKeys.dartIndicator(i)),
      );
      final decoration = indicator.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent,
          reason: 'Dart indicator $i should be empty before throws');
    }

    // First dart -- hit target 1 (amber fill = hit)
    await throwDartViaMock(tester, 1);
    final d0After = tester.widget<Container>(
      find.byKey(ClockworkQuestGameKeys.dartIndicator(0)),
    );
    final d0Decoration = d0After.decoration as BoxDecoration;
    expect(d0Decoration.color, const Color(0xFFFFBF00),
        reason: 'D1 should be amber (hit)');

    // Second dart -- miss (silver fill)
    await throwMissViaMock(tester);
    final d1After = tester.widget<Container>(
      find.byKey(ClockworkQuestGameKeys.dartIndicator(1)),
    );
    final d1Decoration = d1After.decoration as BoxDecoration;
    expect(d1Decoration.color, const Color(0xFF8A8D93),
        reason: 'D2 should be silver (miss)');

    // Third dart -- hit target 2 (amber fill)
    await throwDartViaMock(tester, 2);
    final d2After = tester.widget<Container>(
      find.byKey(ClockworkQuestGameKeys.dartIndicator(2)),
    );
    final d2Decoration = d2After.decoration as BoxDecoration;
    expect(d2Decoration.color, const Color(0xFFFFBF00),
        reason: 'D3 should be amber (hit)');
  });
}
