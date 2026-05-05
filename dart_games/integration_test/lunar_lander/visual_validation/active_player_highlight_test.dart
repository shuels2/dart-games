import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Color constants from lunar_lander_game_screen.dart
  const rocketFlame = Color(0xFFF26430); // active player background
  const skyBlue = Color(0xFF4A9EC4); // inactive player background

  final config = GameUIConfig.lunarLander();

  // Verifies that the active player's name pill is orange (rocketFlame) and
  // inactive players' name pills are sky blue (Color(0xFF4A9EC4)). Confirms
  // the highlight follows the active player when the turn advances.
  testWidgets('Visual: active player name pill is orange, inactive is sky blue',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartLunarLander(tester, config,
        playerNames: ['Astro Alice', 'Bob Beta']);

    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    expect(selectedPlayers.length, 2);
    final p1 = selectedPlayers[0];
    final p2 = selectedPlayers[1];

    // P1 is active at start. Find P1's name pill via Text "Astro Alice" and
    // walk up to the nearest Container ancestor that has a BoxDecoration.
    final p1NameTextFinder = find.descendant(
      of: find.byKey(LunarLanderGameKeys.descentTrack(p1.id)),
      matching: find.text(p1.name),
    );
    expect(p1NameTextFinder, findsOneWidget,
        reason: "P1's name should appear in P1's descent track");

    final p1PillFinder = find
        .ancestor(
          of: p1NameTextFinder,
          matching: find.byType(Container),
        )
        .first;
    final p1Pill = tester.widget<Container>(p1PillFinder);
    final p1Decoration = p1Pill.decoration as BoxDecoration;
    expect(p1Decoration.color, rocketFlame.withOpacity(0.9),
        reason: 'Active player (P1) name pill should be orange (rocketFlame)');

    // P2 inactive: name pill should be sky blue
    final p2NameTextFinder = find.descendant(
      of: find.byKey(LunarLanderGameKeys.descentTrack(p2.id)),
      matching: find.text(p2.name),
    );
    expect(p2NameTextFinder, findsOneWidget,
        reason: "P2's name should appear in P2's descent track");
    final p2PillFinder = find
        .ancestor(
          of: p2NameTextFinder,
          matching: find.byType(Container),
        )
        .first;
    final p2Pill = tester.widget<Container>(p2PillFinder);
    final p2Decoration = p2Pill.decoration as BoxDecoration;
    expect(p2Decoration.color, skyBlue.withOpacity(0.9),
        reason: 'Inactive player (P2) name pill should be sky blue');

    // Now advance turn: P1 throws 3 darts, takeout
    await DartThrowHelpers.throwDartViaMock(tester, 5);
    await DartThrowHelpers.throwDartViaMock(tester, 5);
    await DartThrowHelpers.throwDartViaMock(tester, 5);
    await DartThrowHelpers.clickDartsRemoved(tester);

    // P2 should now be active
    expect(ProviderHelpers.getLunarLanderCurrentPlayerId(tester), p2.id);

    // Re-find pills (widget tree rebuilt)
    final p2NameTextFinder2 = find.descendant(
      of: find.byKey(LunarLanderGameKeys.descentTrack(p2.id)),
      matching: find.text(p2.name),
    );
    final p2PillFinder2 = find
        .ancestor(
          of: p2NameTextFinder2,
          matching: find.byType(Container),
        )
        .first;
    final p2Pill2 = tester.widget<Container>(p2PillFinder2);
    final p2Decoration2 = p2Pill2.decoration as BoxDecoration;
    expect(p2Decoration2.color, rocketFlame.withOpacity(0.9),
        reason: 'P2 (now active) name pill should be orange');

    final p1NameTextFinder2 = find.descendant(
      of: find.byKey(LunarLanderGameKeys.descentTrack(p1.id)),
      matching: find.text(p1.name),
    );
    final p1PillFinder2 = find
        .ancestor(
          of: p1NameTextFinder2,
          matching: find.byType(Container),
        )
        .first;
    final p1Pill2 = tester.widget<Container>(p1PillFinder2);
    final p1Decoration2 = p1Pill2.decoration as BoxDecoration;
    expect(p1Decoration2.color, skyBlue.withOpacity(0.9),
        reason: 'P1 (now inactive) name pill should be sky blue');
  });
}
