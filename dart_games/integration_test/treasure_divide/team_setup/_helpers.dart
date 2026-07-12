// integration_test/treasure_divide/team_setup/_helpers.dart
//
// Shared helpers for Treasure Divide team setup tests.
// Covers Team mode UI (Manual/Random toggle, Team Count, crew assignment).
import 'package:flutter_test/flutter_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.treasureDivide();

// ===== NAVIGATION =====

Future<void> navigateToMenu(WidgetTester tester) =>
    UITestHelpers.navigateToGameMenu(tester, config);

// ===== SETTINGS HELPERS =====

Future<void> setGameModeTeam(WidgetTester tester) =>
    SettingsHelpers.setTreasureDivideGameModeTeam(tester);

Future<void> setGameModeSolo(WidgetTester tester) =>
    SettingsHelpers.setTreasureDivideGameModeSolo(tester);

Future<void> setAssignmentManual(WidgetTester tester) =>
    SettingsHelpers.setTreasureDivideAssignmentManual(tester);

Future<void> setAssignmentRandom(WidgetTester tester) =>
    SettingsHelpers.setTreasureDivideAssignmentRandom(tester);

// ===== PLAYER HELPERS =====

Future<void> addPlayer(WidgetTester tester, String name) =>
    UITestHelpers.addPlayer(tester, name, config);

Future<void> startGame(WidgetTester tester) =>
    UITestHelpers.startGame(tester, config);

// ===== TEAM SETUP HELPERS =====

/// Set up team mode with Manual assignment and [crews] crews.
/// Requires [players] to already be added.
Future<void> setupTeamModeManualWithCrews(
  WidgetTester tester,
  int crews,
) async {
  await setGameModeTeam(tester);
  await PumpSequences.fullRebuild(tester);
  await setAssignmentManual(tester);
  await PumpSequences.fullRebuild(tester);
  await SettingsHelpers.selectTreasureDivideCrews(tester, crews);
  await PumpSequences.fullRebuild(tester);
}

// ===== TEAM SETUP ASSERTIONS =====

/// Verify the Assignment Mode toggle IS present
void expectAssignmentTogglePresent(WidgetTester tester) {
  expect(
    ElementFinders.getTreasureDivideAssignmentModeToggle(),
    findsOneWidget,
    reason: 'Assignment mode toggle should be visible in Team mode',
  );
}

/// Add N players to the game, returns their names
Future<List<String>> addNPlayers(WidgetTester tester, int n) async {
  final names = List.generate(n, (i) => 'Player ${i + 1}');
  for (final name in names) {
    await addPlayer(tester, name);
  }
  return names;
}
