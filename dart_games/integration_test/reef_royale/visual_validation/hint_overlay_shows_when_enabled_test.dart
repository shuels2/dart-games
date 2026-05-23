import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Hint overlay shows when enabled',
      (WidgetTester tester) async {
    // Hints are always on for new games now (the Show Hints menu
    // toggle was removed), so the overlay should appear without any
    // explicit option flip.
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    expect(find.byKey(ReefRoyaleGameKeys.hintOverlay), findsOneWidget);
  });
}
