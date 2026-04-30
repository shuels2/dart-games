import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Dart indicators show thrown darts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // All 3 dart indicator slots should exist
    expect(find.byKey(ReefRoyaleGameKeys.dartIndicator(0)), findsOneWidget);
    expect(find.byKey(ReefRoyaleGameKeys.dartIndicator(1)), findsOneWidget);
    expect(find.byKey(ReefRoyaleGameKeys.dartIndicator(2)), findsOneWidget);

    // Throw a dart and verify indicator updates
    await throwDartViaMock(tester, 20);

    expect(
        ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 1);
  });
}
