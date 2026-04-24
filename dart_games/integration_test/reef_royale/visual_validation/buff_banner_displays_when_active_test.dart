import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/reef_royale_game.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Buff banner displays when buff active',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, bonusBuffs: true);

    // Buffs badge should be visible in appbar
    expect(find.byKey(ReefRoyaleGameKeys.buffsBadge), findsOneWidget);

    // Programmatically set a buff
    ProviderHelpers.setReefRoyaleActiveBuff(tester, ReefBuff.riptideRush);
    await tester.pump();
    await tester.pump();

    // Buff banner should be visible
    expect(find.byKey(ReefRoyaleGameKeys.buffBanner), findsOneWidget);
  });
}
