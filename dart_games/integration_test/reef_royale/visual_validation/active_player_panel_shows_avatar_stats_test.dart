import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Active player panel shows avatar and stats',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    expect(find.byKey(ReefRoyaleGameKeys.playerAvatar), findsOneWidget);
    expect(find.byKey(ReefRoyaleGameKeys.pearlCounter), findsOneWidget);
    expect(find.byKey(ReefRoyaleGameKeys.coralCounter), findsOneWidget);

    // No option badges should be visible with default settings
    expect(find.byKey(ReefRoyaleGameKeys.cursedBadge), findsNothing);
    expect(find.byKey(ReefRoyaleGameKeys.neighborsBadge), findsNothing);
    expect(find.byKey(ReefRoyaleGameKeys.buffsBadge), findsNothing);
  });
}
