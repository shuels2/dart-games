import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 24: Speed Play shows round counter',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config,
        speedPlay: true, roundLimit: 8);

    // Verify round counter is visible
    expect(find.byKey(ReefRoyaleGameKeys.roundCounter), findsOneWidget);

    // Verify round limit was set
    expect(ProviderHelpers.getReefRoyaleRoundLimit(tester), 8);
  });
}
