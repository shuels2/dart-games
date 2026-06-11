// integration_test/treasure_divide/team_mode_gameplay/_helpers.dart
//
// Shared helpers for Treasure Divide team mode gameplay tests.
// All tests use Team mode with various player/crew configurations.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.treasureDivide();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> setupAndStartTeamGame(
  WidgetTester tester, {
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool manualAssignment = false,
  int? teamCount,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      teamMode: true,
      manualAssignment: manualAssignment,
      teamCount: teamCount,
      playerNames: playerNames,
    );

// ===== TREASURE DIVIDE TEAM-SPECIFIC HELPERS =====

/// Get the current round's target number from the provider.
int getCurrentRoundTarget(WidgetTester tester) {
  final roundIndex = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
  return ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
}

/// Get the currently active team ID.
String? getCurrentTeamId(WidgetTester tester) =>
    ProviderHelpers.getTreasureDivideCurrentTeamId(tester);

/// Get the currently active player ID.
String? getCurrentPlayerId(WidgetTester tester) =>
    ProviderHelpers.getTreasureDivideCurrentPlayerId(tester);
