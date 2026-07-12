// integration_test/treasure_divide/team_setup/team_random_no_ui_test.dart
//
// Phase 10 gap 3: Team+Random mode renders NO per-player assign
// dropdowns; switching to Team+Manual makes them appear.
//
// The Team Count / "Crews" dropdown was removed from the menu — the
// manual assignment popup is now the sole source of truth for crew
// count, matching Tiki Golf and Target Tag. Assertions against
// `teamCountDropdown` were dropped here in tandem.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Team+Random has no per-player assign dropdowns; '
      'switching to Manual shows them',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Switch to Team mode (default assignment is Random)
    await setGameModeTeam(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

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

    // In manual mode each selected player gets an "Assign team" trailing
    // button (opens the crest picker). Presence of that label per selected
    // player is what confirms manual mode is wired up.
    expect(find.text('Assign team'),
        findsAtLeastNWidgets(playerProvider.selectedPlayers.length),
        reason:
            'Every selected player should show an "Assign team" trailing '
            'button after switching to Team+Manual');

  });
}
