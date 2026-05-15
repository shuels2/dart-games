// integration_test/tiki_golf/team_setup/_helpers.dart
//
// Shared helpers for Tiki Golf team setup tests.
// Covers Team mode UI (Manual/Random toggle, Team Count, assignment dialog).
import 'package:flutter_test/flutter_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.tikiGolf();

// ===== NAVIGATION =====

Future<void> navigateToMenu(WidgetTester tester) =>
    UITestHelpers.navigateToGameMenu(tester, config);

// ===== SETTINGS HELPERS =====

Future<void> setGameModeTeam(WidgetTester tester) =>
    SettingsHelpers.setTikiGolfGameModeTeam(tester);

Future<void> setGameModeSolo(WidgetTester tester) =>
    SettingsHelpers.setTikiGolfGameModeSolo(tester);

Future<void> setAssignmentManual(WidgetTester tester) =>
    SettingsHelpers.setTikiGolfAssignmentManual(tester);

Future<void> setAssignmentRandom(WidgetTester tester) =>
    SettingsHelpers.setTikiGolfAssignmentRandom(tester);

// ===== PLAYER HELPERS =====

Future<void> addPlayer(WidgetTester tester, String name) =>
    UITestHelpers.addPlayer(tester, name, config);

Future<void> startGame(WidgetTester tester) =>
    UITestHelpers.startGame(tester, config);

// ===== TEAM SETUP ASSERTIONS =====

/// Verify the Team Count dropdown IS present (Team+Manual mode expected)
void expectTeamCountDropdownPresent(WidgetTester tester) {
  expect(
    ElementFinders.getTikiGolfTeamCountDropdown(),
    findsOneWidget,
    reason: 'Team Count dropdown should be visible in Team+Manual mode',
  );
}

/// Verify the Team Count dropdown is NOT present (Team+Random or Solo)
void expectTeamCountDropdownAbsent(WidgetTester tester) {
  expect(
    ElementFinders.getTikiGolfTeamCountDropdown(),
    findsNothing,
    reason: 'Team Count dropdown should NOT be visible in Random/Solo mode',
  );
}

/// Verify the Assignment Mode toggle IS present
void expectAssignmentTogglePresent(WidgetTester tester) {
  expect(
    ElementFinders.getTikiGolfAssignmentModeToggle(),
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
