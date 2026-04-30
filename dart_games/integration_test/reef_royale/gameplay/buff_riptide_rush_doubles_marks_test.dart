import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/reef_royale_game.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 22: Buff Riptide Rush doubles marks',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, bonusBuffs: true);

    // Buffs badge should be visible in appbar
    expect(find.byKey(ReefRoyaleGameKeys.buffsBadge), findsOneWidget);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Programmatically set Riptide Rush buff
    ProviderHelpers.setReefRoyaleActiveBuff(tester, ReefBuff.riptideRush);

    // Throw single 20 -> should get 2 marks (doubled)
    await throwDartViaMock(tester, 20);

    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 2);
  });
}
