// integration_test/treasure_divide/gameplay/max_player_count_test.dart
//
// Group A – Test 2: Solo, 8 players (maximum). All 8 tiles render without
// RenderFlex overflow errors. Active player can still throw darts.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: 8-player Solo game — all tiles render, dart throwing works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        playerNames: [
          'MaxP1', 'MaxP2', 'MaxP3', 'MaxP4',
          'MaxP5', 'MaxP6', 'MaxP7', 'MaxP8',
        ]);

    // ── All 8 players selected ─────────────────────────────────────────────
    final players = ProviderHelpers.getSelectedPlayers(tester);
    expect(players.length, 8,
        reason: '[DIAG max_player] Should have 8 players selected');

    // ── All player names visible in UI ─────────────────────────────────────
    for (final p in players) {
      expect(find.textContaining(p.name), findsWidgets,
          reason: '[DIAG max_player] ${p.name} should appear in UI with 8 players');
    }

    // ── Game is active ─────────────────────────────────────────────────────
    expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue,
        reason: '[DIAG max_player] Game should be active after start');


    // ── P1 throws 1 dart successfully at 8-player count ───────────────────
    final target = getCurrentRoundTarget(tester);
    await throwDartViaMock(tester, target);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();


    // ── Still active ──────────────────────────────────────────────────────
    expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue,
        reason: '[DIAG max_player] Game should remain active after single dart');

  });
}
