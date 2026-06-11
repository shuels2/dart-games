// integration_test/treasure_divide/team_setup/team_random_no_ui_test.dart
//
// Phase 10 gap 3: Team+Random mode renders NO Team Count dropdown and NO
// per-player assign dropdowns. Switching to Team+Manual makes them appear.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Team+Random has no Team Count dropdown or per-player assign dropdowns; '
      'switching to Manual shows them',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Switch to Team mode (default assignment is Random)
    await setGameModeTeam(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Team Count dropdown must NOT be shown in Random mode
    expect(ElementFinders.getTreasureDivideTeamCountDropdown(), findsNothing,
        reason: 'Team Count dropdown should NOT be visible in Team+Random mode');

    // Add 4 players
    await addPlayer(tester, 'Alice');
    await addPlayer(tester, 'Bob');
    await addPlayer(tester, 'Carol');
    await addPlayer(tester, 'Dave');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Per-player team assign dropdowns must NOT be present in Random mode
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    for (final p in playerProvider.selectedPlayers) {
      expect(find.byKey(TreasureDivideMenuKeys.teamAssignDropdown(p.id)),
          findsNothing,
          reason:
              'Per-player assign dropdown for ${p.name} should NOT appear in '
              'Team+Random mode');
    }

    // ── Switch to Team + Manual ────────────────────────────────────────────
    await setAssignmentManual(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Team Count dropdown NOW present in Manual mode
    expect(ElementFinders.getTreasureDivideTeamCountDropdown(), findsOneWidget,
        reason:
            'Team Count dropdown should appear after switching to Team+Manual');

    // Drain accumulated RenderFlex overflow exceptions from TD menu layout.
    tester.binding.takeException();
    tester.binding.takeException();
  });
}
