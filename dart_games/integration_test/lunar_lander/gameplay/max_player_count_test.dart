import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Verifies the game starts and runs correctly with the MAXIMUM player count (8).
  // Asserts all 8 descent tracks render, no overflow exceptions are thrown, all
  // characters are visible, gameplay works, and dynamic char sizing produces
  // a sensible value (clamped >= 120).
  testWidgets('Gameplay: maximum player count (8) — all 8 tracks render without overflow',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, playerNames: [
      'Player 1',
      'Player 2',
      'Player 3',
      'Player 4',
      'Player 5',
      'Player 6',
      'Player 7',
      'Player 8',
    ]);

    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    expect(selectedPlayers.length, 8, reason: 'Max player count is 8');

    final playerIds = selectedPlayers.map((p) => p.id).toList();

    // All 8 descent tracks should render
    for (final id in playerIds) {
      expect(find.byKey(LunarLanderGameKeys.descentTrack(id)), findsOneWidget,
          reason: 'Descent track for player $id should render');
    }

    // All inactive characters should render (7 inactive + 1 active = 8 total)
    final currentPlayerId = getCurrentPlayerId(tester)!;
    final inactiveIds = playerIds.where((id) => id != currentPlayerId);
    for (final id in inactiveIds) {
      expect(find.byKey(LunarLanderGameKeys.characterOnTrack(id)), findsOneWidget,
          reason: 'Inactive character for $id should render');
    }
    // Active player character
    expect(find.byKey(LunarLanderGameKeys.playerAvatar), findsOneWidget,
        reason: 'Active player character should render');

    // No overflow errors during layout
    expect(tester.takeException(), isNull,
        reason: '8-player layout should produce no exceptions/overflow');

    // Dynamic char sizing: charSize = (maxWidth / 8 * 0.85).clamp(120, 300).
    // The clamp floor is 120, so for any plausible test surface the resulting
    // character box height should be >= 120 (the minimum). Verify by inspecting
    // the active player's avatar Container size.
    final avatarFinder = find.byKey(LunarLanderGameKeys.playerAvatar);
    final avatarBox = tester.getSize(avatarFinder);
    expect(avatarBox.width, greaterThanOrEqualTo(120.0),
        reason: 'Character size should be clamped to a minimum of 120 px');

    // Confirm gameplay still works at max capacity — throw a single dart as P1
    final p1Id = currentPlayerId;
    final p1AltBefore = getAltitude(tester, p1Id);
    await throwDartViaMock(tester, 5);
    expect(getAltitude(tester, p1Id), p1AltBefore - 5,
        reason: 'Dart should subtract correctly even with 8 players');

    // No exceptions thrown during the gameplay step either
    expect(tester.takeException(), isNull);
  });
}
