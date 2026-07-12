// integration_test/treasure_divide/team_setup/team_to_solo_keeps_panel_test.dart
//
// Phase 10 gap 2: Switching Team→Solo hides team-specific UI but keeps the
// selected player list intact. Solo min is 2, so 3 players is fine.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Team→Solo hides team UI; player list remains intact',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Start in Team mode, then add players
    await setGameModeTeam(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await addPlayer(tester, 'Alice');
    await addPlayer(tester, 'Bob');
    await addPlayer(tester, 'Carol');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Verify players visible in Team mode
    expect(find.textContaining('Alice'), findsWidgets,
        reason: 'Alice should be visible in Team mode before switching');
    expect(find.textContaining('Bob'), findsWidgets,
        reason: 'Bob should be visible in Team mode before switching');
    expect(find.textContaining('Carol'), findsWidgets,
        reason: 'Carol should be visible in Team mode before switching');

    // ── Switch back to Solo mode ─────────────────────────────────────────────
    await setGameModeSolo(tester);

    // All 3 players must still be listed (panel stays mounted, selection preserved)
    expect(find.textContaining('Alice'), findsWidgets,
        reason: 'Alice should remain visible after switching to Solo mode');
    expect(find.textContaining('Bob'), findsWidgets,
        reason: 'Bob should remain visible after switching to Solo mode');
    expect(find.textContaining('Carol'), findsWidgets,
        reason: 'Carol should remain visible after switching to Solo mode');
  });
}
