import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 24: Multi-Team Setup with Unbalanced Teams and Hero Buffs - Comprehensive 6-Phase Validation - Phase 1: Team mode with manual assignment enabled, hero bonus enabled, shield max 3, 5 players added for 3 teams (Team 1: 2 players, Team 2: 2 players, Team 3: 1 player - unbalanced), players manually assigned to teams. Phase 2: Turn rotation validated with unbalanced teams (Team 3 with 1 player appears twice per cycle due to alternating team members). Phase 3: All 3 teams reach tagged-in status through dart throws. Phase 4: Team 1 hits hero buff number and damages all opponent teams (shields reduced). Phase 5: Team 2 hits hero buff for shield regeneration (0 to 3 shields). Phase 6: Team 3 eliminated through hero buff attacks, tagged out status confirmed. Validates team rotation, tagged-in mechanics, hero buff damage to multiple opponents, shield regeneration, and team elimination',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable team mode
    await SettingsHelpers.toggleTargetTagTeamMode(tester);
    await PumpSequences.fullRebuild(tester);

    // Enable hero bonus
    await SettingsHelpers.toggleTargetTagHeroBonus(tester);
    await PumpSequences.simpleUpdate(tester);

    // Set shield max to 3 for faster test
    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    // Toggle manual team assignment (turn OFF random assignment)
    await tester.tap(ElementFinders.getTargetTagAssignTeamsButton());
    await PumpSequences.simpleUpdate(tester);

    // Add 5 players for 3 teams
    await UITestHelpers.addPlayer(tester, 'Team1P1', config);
    await UITestHelpers.addPlayer(tester, 'Team1P2', config);
    await UITestHelpers.addPlayer(tester, 'Team2P1', config);
    await UITestHelpers.addPlayer(tester, 'Team2P2', config);
    await UITestHelpers.addPlayer(tester, 'Team3P1', config);

    // Scroll to top of player list to ensure all players are visible
    final listFinder = find.byType(ListView).first;
    await tester.fling(listFinder, const Offset(0, 500), 5000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Assign Team1P1 to Team 1 (index 0)
    await tester.ensureVisible(find.text('Team1P1'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog1 = find.byType(AlertDialog);
    final gestureDetectors1 = find.descendant(of: dialog1, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors1.at(0)); // Team 1
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Team1P2 to Team 1 (index 0)
    await tester.ensureVisible(find.text('Team1P2'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog2 = find.byType(AlertDialog);
    final gestureDetectors2 = find.descendant(of: dialog2, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors2.at(0)); // Team 1
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Team2P1 to Team 2 (index 1)
    await tester.ensureVisible(find.text('Team2P1'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog3 = find.byType(AlertDialog);
    final gestureDetectors3 = find.descendant(of: dialog3, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors3.at(1)); // Team 2
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Team2P2 to Team 2 (index 1)
    await tester.ensureVisible(find.text('Team2P2'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog4 = find.byType(AlertDialog);
    final gestureDetectors4 = find.descendant(of: dialog4, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors4.at(1)); // Team 2
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Team3P1 to Team 3 (index 2) - this is the unbalanced team with only 1 player
    await tester.ensureVisible(find.text('Team3P1'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog5 = find.byType(AlertDialog);
    final gestureDetectors5 = find.descendant(of: dialog5, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors5.at(2)); // Team 3
    await tester.pump(const Duration(milliseconds: 500));

    final team1p1 = ProviderHelpers.findPlayerByName(tester, 'Team1P1');
    final team1p2 = ProviderHelpers.findPlayerByName(tester, 'Team1P2');
    final team2p1 = ProviderHelpers.findPlayerByName(tester, 'Team2P1');
    final team2p2 = ProviderHelpers.findPlayerByName(tester, 'Team2P2');
    final team3p1 = ProviderHelpers.findPlayerByName(tester, 'Team3P1');

    // Start game
    await UITestHelpers.startGame(tester, config);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // === UI VALIDATION ===
    // Verify game screen displays
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // === PHASE 0: Verify the rotation of teams with the unbalance team player becoming active twice ===

    // Verify TEAM1P1 is the active player
    final currentPlayer1 = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayer1, team1p1!.id);
    expect(find.text('Team1P1'), findsWidgets);

    // Throw 3 darts to end the turn TEAM1P1
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to TEAM2P1
    await clickDartsRemoved(tester);

    // Verify TEAM2P1 is the active player
    final currentPlayer2 = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayer2, team2p1!.id);
    expect(find.text('Team2P1'), findsWidgets);

    // Throw 3 darts to end the turn TEAM2P1
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to TEAM3P1 - the unbalanced team
    await clickDartsRemoved(tester);

    // Verify TEAM3P1 is the active player (first time)
    final currentPlayer3 = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayer3, team3p1!.id);
    expect(find.text('Team3P1'), findsWidgets);

    // Throw 3 darts to end the turn TEAM3P1 - the unbalanced team
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to TEAM1P2
    await clickDartsRemoved(tester);

    // Verify TEAM1P2 is the active player
    final currentPlayer4 = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayer4, team1p2!.id);
    expect(find.text('Team1P2'), findsWidgets);

    // Throw 3 darts to end the turn TEAM1P2
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to TEAM2P2
    await clickDartsRemoved(tester);

    // Verify TEAM2P2 is the active player
    final currentPlayer5 = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayer5, team2p2!.id);
    expect(find.text('Team2P2'), findsWidgets);

    // Throw 3 darts to end the turn TEAM2P2
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to TEAM3P1 - the unbalanced team
    await clickDartsRemoved(tester);

    // Verify TEAM3P1 is the active player (second time - unbalanced team)
    final currentPlayer6 = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayer6, team3p1!.id);
    expect(find.text('Team3P1'), findsWidgets);

    // Throw 3 darts to end the turn TEAM3P1 - the unbalanced team
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to TEAM1P1
    await clickDartsRemoved(tester);

    // === PHASE 1: Team 1 Gets Tagged In ===
    final team1p1Id = team1p1!.id;
    final team1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, team1p1Id);

    // Build shields for Team 1
    for (int i = 0; i < 3; i++) {
      await throwDartViaMock(tester, team1Target!);
    }
    await clickDartsRemoved(tester);

    // Verify Team 1 is tagged in
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, team1p1Id), isTrue);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team1p1Id), 3);

    // === PHASE 2: Team 2 Gets Tagged In ===
    final team2p1Id = team2p1!.id;
    final team2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, team2p1Id);

    for (int i = 0; i < 3; i++) {
      await throwDartViaMock(tester, team2Target!);
    }
    await clickDartsRemoved(tester);

    // Verify Team 2 is now tagged in
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team2p1Id), 3);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, team2p1Id), isTrue);

    // === PHASE 3: Team 3 Gets Tagged In ===
    final team3p1Id = team3p1!.id;
    final team3Target = ProviderHelpers.getTargetTagPlayerTarget(tester, team3p1Id);

    for (int i = 0; i < 3; i++) {
      await throwDartViaMock(tester, team3Target!);
    }
    await clickDartsRemoved(tester);

    // Verify Team 3 is tagged in
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, team3p1Id), isTrue);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team3p1Id), 3);

    // === PHASE 4: All 3 Teams Tagged In - Verify State ===
    // Verify all 3 teams are tagged in
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, team1p1Id), isTrue);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, team2p1Id), isTrue);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, team3p1Id), isTrue);

    // Verify all 3 teams have 3 shields
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team1p1Id), 3);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team2p1Id), 3);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team3p1Id), 3);

    // === PHASE 5: Team 1 Hits Hero Buff - No Change in Shields but -1 to Opponents ===
    // Get Team 1 Hero Buff number
    final targetTagProvider = ProviderHelpers.getTargetTagProvider(tester);
    final team1HeroBuff = targetTagProvider.getSoloHeroBuffNumber(team1p1Id);
    final team1HeroMultiplier = targetTagProvider.getSoloHeroBuffMultiplier(team1p1Id);

    // Throw dart 1 and hit hero buff
    await throwDartViaMock(tester, team1HeroBuff!, multiplier: team1HeroMultiplier!);

    // Validate Team 1 shields still at 3 and opponents are at 2
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team1p1Id), 3);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team2p1Id), 2);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team3p1Id), 2);

    // Throw dart 2 and hit hero buff
    await throwDartViaMock(tester, team1HeroBuff, multiplier: team1HeroMultiplier);

    // Validate Team 1 shields still at 3 and opponents are at 1
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team1p1Id), 3);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team2p1Id), 1);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team3p1Id), 1);

    // Throw dart 3 and hit hero buff
    await throwDartViaMock(tester, team1HeroBuff, multiplier: team1HeroMultiplier);

    // Validate Team 1 shields still at 3 and opponents are at 0
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team1p1Id), 3);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team2p1Id), 0);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team3p1Id), 0);

    await clickDartsRemoved(tester);

    // === PHASE 6: Team 2 Hits Hero Buff - Shields go to 3, Team 3 tagged out, Team 1 loses 1 shield ===
    // Get Team 2 Hero Buff number
    final team2HeroBuff = targetTagProvider.getSoloHeroBuffNumber(team2p1Id);
    final team2HeroMultiplier = targetTagProvider.getSoloHeroBuffMultiplier(team2p1Id);

    // Throw dart 1 and hit hero buff
    await throwDartViaMock(tester, team2HeroBuff!, multiplier: team2HeroMultiplier!);

    // Validate Team 2 shields move to 3 and tagged in
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team2p1Id), 3);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, team2p1Id), isTrue);

    // Validate Team 1 shields down to 2 shields
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, team1p1Id), 2);

    // Validate Team 3 is eliminated and shows tagged out
    expect(ProviderHelpers.isTargetTagPlayerEliminated(tester, team3p1Id), isTrue);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, team3p1Id), isFalse);

    // Throw 2 more darts to advance turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Verify game continues (no victory yet)
    expect(find.text('VICTORY'), findsNothing);
  });
}
