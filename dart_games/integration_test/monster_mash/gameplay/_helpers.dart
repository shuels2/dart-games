import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/models/monster_mash_game.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.monsterMash();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> throwOuterBullViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwOuterBullViaMock(tester);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

// ===== GAME-SPECIFIC HELPERS =====

Future<void> setActiveBuff(WidgetTester tester, BonusBuff buff) async {
  final provider = ProviderHelpers.getMonsterMashProvider(tester);
  provider.currentGame!.activeBuff = buff;
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  provider.notifyListeners();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}
