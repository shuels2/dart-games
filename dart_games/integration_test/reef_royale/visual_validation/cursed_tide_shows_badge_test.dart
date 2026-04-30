import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 7: Cursed Tide shows badge and visual changes',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, cursedTide: true);

    // Cursed badge should be visible
    expect(find.byKey(ReefRoyaleGameKeys.cursedBadge), findsOneWidget);

    // Pearl counter should still be present
    expect(find.byKey(ReefRoyaleGameKeys.pearlCounter), findsOneWidget);
  });
}
