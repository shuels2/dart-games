// Monster Mash Game - Announcement Validation Tests
// ===================================================
// 18 tests that validate all announcement types fire with correct text
// and precedence rules are applied correctly.
//
// ANNOUNCEMENT PRECEDENCE RULES:
//  1. Hit suppressed when any secondary effect exists
//  2. Elimination supersedes attack text
//  3. Elimination supersedes health warning
//  4. Elimination supersedes heal (same throw)
//  5. Clutch heal supersedes healing amount
//  6. Health warning only on tier crossing (>70% → ≤70% → ≤30% → ≤10%)
//  7. Hat trick supersedes attack (3rd dart)
//  8. Hat trick + elimination merged into single announcement
//  9. Multiple eliminations combined into single announcement
// 10. Remove darts always fires on 3rd dart or skip-with-darts
//
// ANNOUNCEMENT TYPES COVERED:
//  1. Game Start         → Test 1
//  2. Turn Transition    → Test 1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
//  3. Dart Hit (Single)  → Test 1, 17
//  4. Dart Hit (Miss)    → Test 1, 11
//  5. Dart Hit (Bullseye)→ Test 18
//  6. Healing            → Test 3, 14, 15
//  7. Attack (single)    → Test 2, 4, 11
//  8. Attack (double)    → Test 2, 4
//  9. Attack (triple)    → Test 13, 16
// 10. Attack (0 damage)  → Test 12
// 11. Health Warning     → Test 4, 11 (all 3 tiers)
// 12. Elimination        → Test 4, 9
// 13. Combined Elim      → Test 10
// 14. Hat Trick          → Test 5
// 15. Hat Trick + Elim   → Test 4 (merged)
// 16. Clutch Heal        → Test 6
// 17. Buff Activation    → Test 7
// 18. Remove Darts       → Test 1, 2, 3, 4, 9, 10, 11
// 19. Winner             → Test 4, 9, 10
// 20. Winners (tie)      → Test 8
// 21. Skip Turn          → Test 1
// 22. Max Health!        → Test 15
// 23. Elim opponent hit  → Test 17
// 24. Bullseye full HP   → Test 18

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/monster_mash_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/monster_mash_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../mocks/mock_monster_mash_audio_queue_service.dart';
import '../../../helpers/monster_mash_test_helper.dart';

// =============================================================================
// REUSABLE SETUP
// =============================================================================

/// Creates a provider with a deterministic game (known target numbers).
/// Uses the raw MonsterMashGame constructor to avoid random assignments.
///
/// Default 2-player setup:
///   - Alice (p1) → target 5, Dracula
///   - Bob   (p2) → target 10, Frankenstein
///
/// 3-player setup adds:
///   - Charlie (p3) → target 15, Mummy
MonsterMashProvider createTestProvider({
  required List<Player> players,
  int healthMax = 20,
  bool bonusBuffsEnabled = false,
  bool speedPlayEnabled = false,
  int roundLimit = 10,
}) {
  final provider = MonsterMashProvider();
  final playerIds = players.map((p) => p.id).toList();

  final targets = <String, int>{};
  final monsters = <String, MonsterType>{};
  final targetNumbers = [5, 10, 15, 20, 1, 2, 3, 4];
  final monsterTypes = MonsterType.values;

  for (int i = 0; i < playerIds.length; i++) {
    targets[playerIds[i]] = targetNumbers[i];
    monsters[playerIds[i]] = monsterTypes[i];
  }

  // Use startGame then replace the game with our deterministic one
  provider.startGame(players, healthMax, bonusBuffsEnabled, speedPlayEnabled, roundLimit);

  // Replace internal game with deterministic assignments
  final game = provider.currentGame!;
  game.targetNumbers.clear();
  game.targetNumbers.addAll(targets);
  game.monsterAssignments.clear();
  game.monsterAssignments.addAll(monsters);

  // Re-save initial turn state with our modifications
  game.saveInitialTurnStartState();

  return provider;
}

List<Player> createPlayers(int count) {
  final names = ['Alice', 'Bob', 'Charlie', 'Diana'];
  return List.generate(count, (i) => Player(
    id: 'p${i + 1}',
    name: names[i],
    createdAt: DateTime(2026, 1, 1),
  ));
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Monster Mash - Announcement Validation', () {
    late MonsterMashProvider provider;
    late MockMonsterMashAudioQueueService audioQueue;
    late MonsterMashTestHelper helper;
    late List<Player> players;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // =========================================================================
    // Test 1: Game Start → Turn → Single Hit → Miss → Skip → Remove Darts
    // Covers: announceGameStart, announceTurn, announceHit (unassigned number),
    //         announceHit (miss), skipTurn, remove darts
    // Precedence: Hit fires because no secondary effect (unassigned number)
    // =========================================================================
    test('Test 1: Game start, unassigned hit, miss, skip turn', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // --- Game Start ---
      helper.announceGameStart();
      helper.verifyAnnouncements([
        'Welcome to Monster Mash! Let the battle begin!',
      ]);
      helper.clearAnnouncements();

      // --- Alice's turn: Single 7 (unassigned - no effect), Miss, then skip ---
      // Hit fires because no secondary effect exists
      helper.processDartThrowWithAnnouncements('S7');
      helper.verifyAnnouncements([
        'Alice, your turn',  // Turn announcement (first dart)
        'Single 7',          // Hit (no secondary, so hit fires)
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('None');
      helper.verifyAnnouncements([
        'Miss',              // Miss (no secondary)
      ]);
      helper.clearAnnouncements();

      // Skip remaining 1 dart (darts thrown > 0 so remove darts fires)
      helper.skipTurn();
      helper.verifyAnnouncements([
        'Remove your darts',
      ]);
      helper.clearAnnouncements();

      // --- Takeout → Bob's turn starts ---
      helper.handleTakeoutFinished();

      // --- Bob skips entire turn (0 darts) → NO remove darts ---
      helper.skipTurn();
      helper.verifyAnnouncements([
        'Bob, your turn',    // Turn announced even on skip
        // No 'Remove your darts' — 0 darts thrown
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 2: Attack announcements with different multipliers
    // Covers: attack (single, double, triple), hat trick
    // Precedence: Hit suppressed (attack is secondary), hat trick supersedes
    //             attack on 3rd dart, health warning only on tier crossing
    // =========================================================================
    test('Test 2: Attack with single, double, triple damage', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Alice hits Bob's number (10) with single — hit suppressed
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Single 10' suppressed — attack is secondary
        'A glancing blow! Bob feels the sting.',  // single attack
        // No health warning — Bob at 19/20 = 95% > 70%, tier 0
      ]);
      helper.clearAnnouncements();

      // Double — hit suppressed
      helper.processDartThrowWithAnnouncements('D10');
      helper.verifyAnnouncements([
        // 'Double 10' suppressed
        'Powerful hit! Bob feels the pain!',  // double attack
        // Bob at 17/20 = 85% > 70%, tier 0, no crossing
      ]);
      helper.clearAnnouncements();

      // Triple on 3rd dart — hat trick supersedes attack and health warning
      helper.processDartThrowWithAnnouncements('T10');
      helper.verifyAnnouncements([
        // 'Triple 10' suppressed
        // Attack suppressed by hat trick
        // Health warning suppressed by hat trick (Bob 14/20=70% → tier 1 crossing)
        'MONSTROUS! Triple strike on Bob!',  // Hat trick
        'Remove your darts',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 3: Healing — own number, outer bull, bullseye
    // Covers: healing (single, +5, max health)
    // Precedence: Hit suppressed (healing is secondary)
    // =========================================================================
    test('Test 3: Healing from own number, outer bull, bullseye', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Set Alice low for healing tests
      provider.currentGame!.health['p1'] = 10;
      provider.currentGame!.saveInitialTurnStartState();

      // Alice hits own number (5) with single → heals +1, hit suppressed
      helper.processDartThrowWithAnnouncements('S5');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Single 5' suppressed — healing is secondary
        'Plus 1!',  // Heal +1
      ]);
      helper.clearAnnouncements();

      // Alice hits outer bull (25) → heals +5, hit suppressed
      helper.processDartThrowWithAnnouncements('25');
      helper.verifyAnnouncements([
        // 'Outer bull' suppressed
        'Plus 5!',  // Heal +5
      ]);
      helper.clearAnnouncements();

      // Alice hits bullseye (50) → heals to max, hit suppressed
      helper.processDartThrowWithAnnouncements('Bull');
      helper.verifyAnnouncements([
        // 'Bullseye!' suppressed
        'Plus 4!',  // Healed 4 (16→20)
        'Remove your darts',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 4: Health warnings (tier crossing only) → elimination → winner
    // Covers: health warning (tier crossing), elimination, hat trick + elim
    //         merged, winner
    // Precedence: Health warning only fires on tier crossing, elimination
    //             supersedes attack/warning, hat trick + elimination merged
    // =========================================================================
    test('Test 4: Health warnings, elimination, and winner', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Set Bob to 7 HP (7/20=35%, tier 1 on init)
      provider.currentGame!.health['p2'] = 7;
      provider.currentGame!.saveInitialTurnStartState();

      // Alice hits Bob (number 10) with single → 7→6, 6/20=30% → tier 2
      // Tier crossing: 1→2, so health warning fires
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Single 10' suppressed
        'A glancing blow! Bob feels the sting.',
        'Bob is in critical condition!',  // Tier crossing 1→2
      ]);
      helper.clearAnnouncements();

      // Alice hits Bob again → 6→4, 4/20=20% → still tier 2
      // NO tier crossing (already tier 2), so NO health warning
      helper.processDartThrowWithAnnouncements('D10');
      helper.verifyAnnouncements([
        // 'Double 10' suppressed
        'Powerful hit! Bob feels the pain!',
        // No health warning — same tier (2→2)
      ]);
      helper.clearAnnouncements();

      // Set Bob to 1 HP for elimination
      provider.currentGame!.health['p2'] = 1;

      // Alice hits Bob → 1→0, elimination + hat trick (all 3 darts on Bob)
      // Hat trick + elimination merged into single announcement
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        // 'Single 10' suppressed
        // Attack suppressed by hat trick + elimination
        // Health warning suppressed by elimination
        'MONSTROUS! Triple strike eliminates Bob!',  // Merged hat trick + elimination
        'Remove your darts',
      ]);
      helper.clearAnnouncements();

      // Takeout triggers winner announcement
      helper.handleTakeoutFinished();
      helper.verifyAnnouncements([
        'GAME OVER! The night belongs to Alice!',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 5: Hat trick (all 3 darts hit same opponent, no kill)
    // Covers: hat trick supersedes attack
    // =========================================================================
    test('Test 5: Hat trick - three darts on same opponent', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 50);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Alice hits Bob's number (10) three times
      helper.processDartThrowWithAnnouncements('S10');
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S10');
      helper.clearAnnouncements();

      // 3rd dart triggers hat trick — supersedes attack
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        // 'Single 10' suppressed
        // Attack suppressed by hat trick
        'MONSTROUS! Triple strike on Bob!',  // Hat trick
        'Remove your darts',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 6: Clutch heal (heal while below 10 HP)
    // Covers: clutch heal supersedes healing amount, hit suppressed
    // =========================================================================
    test('Test 6: Clutch heal when below 10 HP', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Set Alice to 5 HP (below 10)
      provider.currentGame!.health['p1'] = 5;
      provider.currentGame!.saveInitialTurnStartState();

      // Alice hits own number (5) → heals +1, clutch heal supersedes healing
      helper.processDartThrowWithAnnouncements('S5');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Single 5' suppressed — clutch heal is secondary
        // 'Plus 1!' suppressed — clutch heal supersedes
        'Alice rises from near death!',  // Clutch heal
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 7: Buff activation announcement
    // Covers: announceBuff (all 4 buff types)
    // =========================================================================
    test('Test 7: Buff activation announcements', () {
      players = createPlayers(2);
      provider = createTestProvider(
        players: players,
        healthMax: 20,
        bonusBuffsEnabled: true,
      );
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Directly test all 4 buff announcement texts through the mock
      audioQueue.announceBuff(BonusBuff.bloodMoon);
      audioQueue.announceBuff(BonusBuff.ancientBandages);
      audioQueue.announceBuff(BonusBuff.shadowWalk);
      audioQueue.announceBuff(BonusBuff.laboratorySpark);

      helper.verifyAnnouncements([
        'Blood Moon rises! Attack damage doubled!',
        'Ancient Bandages discovered! Healing boosted to 5!',
        'Shadow Walk activated! Attacks deal no damage!',
        'Laboratory Spark! Bullseye zaps all opponents!',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 8: Tie game winner announcement (multiple winners)
    // Covers: announceWinners (plural)
    // =========================================================================
    test('Test 8: Tie game announces multiple winners', () {
      players = createPlayers(2);
      provider = createTestProvider(
        players: players,
        healthMax: 20,
        speedPlayEnabled: true,
        roundLimit: 1,
      );
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Both at same health and same damage → tie
      provider.currentGame!.totalDamageDealt['p1'] = 5;
      provider.currentGame!.totalDamageDealt['p2'] = 5;

      // Play through round 1 (all misses to keep health equal)
      // Alice's turn
      helper.processDartThrowWithAnnouncements('None');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('None');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('None');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();
      helper.clearAnnouncements();

      // Bob's turn (completes round 1 → game ends at round limit)
      helper.processDartThrowWithAnnouncements('None');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('None');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('None');
      helper.clearAnnouncements();

      // Takeout triggers game end → tie announcement
      helper.handleTakeoutFinished();
      helper.verifyAnnouncements([
        'GAME OVER! The night is shared by Alice and Bob!',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 9: Single elimination on 1st dart (no hat trick)
    // Covers: elimination fires without hat trick, hit suppressed
    // Precedence: Elimination supersedes attack
    // =========================================================================
    test('Test 9: Single elimination without hat trick', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Set Bob to 1 HP for elimination on first dart
      provider.currentGame!.health['p2'] = 1;
      provider.currentGame!.saveInitialTurnStartState();

      // Alice hits Bob's number (10) → 1→0, eliminated
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Single 10' suppressed — elimination is secondary
        // Attack suppressed by elimination
        'Bob! Back to the shadows!',  // Elimination (no hat trick)
        'Remove your darts',  // hasWinner → remove darts fires
      ]);
      helper.clearAnnouncements();

      // Takeout triggers winner
      helper.handleTakeoutFinished();
      helper.verifyAnnouncements([
        'GAME OVER! The night belongs to Alice!',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 10: Lab Spark combined elimination + elimination supersedes heal
    // Covers: Lab Spark bullseye damages all opponents, combined elimination,
    //         elimination supersedes healing
    // Precedence: Elimination supersedes heal (same throw), multiple
    //             eliminations combined
    // =========================================================================
    test('Test 10: Lab Spark combined elimination supersedes heal', () {
      players = createPlayers(3);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Set Alice low for healing, opponents low for elimination
      provider.currentGame!.health['p1'] = 10;
      provider.currentGame!.health['p2'] = 5;   // Bob dies from 10 damage
      provider.currentGame!.health['p3'] = 8;   // Charlie dies from 10 damage
      provider.currentGame!.activeBuff = BonusBuff.laboratorySpark;
      provider.currentGame!.saveInitialTurnStartState();

      // Alice bullseye → heals to max (10→20), Lab Spark kills Bob and Charlie
      helper.processDartThrowWithAnnouncements('Bull');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // Healing suppressed — elimination supersedes
        // 'Bullseye!' suppressed — elimination is secondary
        'Bob and Charlie! Back to the shadows!',  // Combined elimination
        'Remove your darts',  // hasWinner
      ]);
      helper.clearAnnouncements();

      // Takeout triggers winner
      helper.handleTakeoutFinished();
      helper.verifyAnnouncements([
        'GAME OVER! The night belongs to Alice!',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 11: Health warning tier crossings — "starting to weaken" and
    //          "barely clinging" (without elimination)
    // Covers: announceHealthWarning at tier 0→1 and tier 1→3
    // Precedence: Health warning fires alongside attack (no elimination/hat
    //             trick to supersede)
    // =========================================================================
    test('Test 11: Health warning tier crossings - weaken and barely clinging', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Set Bob to 15 HP (75%, tier 0)
      provider.currentGame!.health['p2'] = 15;
      provider.currentGame!.saveInitialTurnStartState();

      // Dart 1: S10 → Bob 15→14 (70%, tier 1) → tier 0→1 crossing
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        'Alice, your turn',
        'A glancing blow! Bob feels the sting.',
        'Bob is starting to weaken!',  // Tier crossing 0→1
      ]);
      helper.clearAnnouncements();

      // Set Bob to 3 HP (tracker still at tier 1 from dart 1)
      provider.currentGame!.health['p2'] = 3;

      // Dart 2: S10 → Bob 3→2 (10%, tier 3) → tier 1→3 crossing
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        'A glancing blow! Bob feels the sting.',
        'Bob is barely clinging to life!',  // Tier crossing 1→3
      ]);
      helper.clearAnnouncements();

      // Dart 3: Miss (no hat trick since not all 3 on same target type)
      helper.processDartThrowWithAnnouncements('None');
      helper.verifyAnnouncements([
        'Miss',
        'Remove your darts',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 12: Shadow Walk — 0-damage attack
    // Covers: announceAttack with damage=0 ("The shadows protect...")
    // =========================================================================
    test('Test 12: Shadow Walk 0-damage attack', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Activate Shadow Walk
      provider.currentGame!.activeBuff = BonusBuff.shadowWalk;

      // Alice hits Bob's number (10) → 0 damage
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Single 10' suppressed — attack is secondary
        'The shadows protect Bob!',  // Shadow Walk 0-damage
        // No health warning — no health change
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 13: Blood Moon — doubled damage with triple attack text
    // Covers: announceAttack with triple multiplier and Blood Moon damage
    // =========================================================================
    test('Test 13: Blood Moon doubled damage', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 50);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Activate Blood Moon
      provider.currentGame!.activeBuff = BonusBuff.bloodMoon;

      // Alice T10 → triple=3, ×2=6 damage, Bob 50→44 (88%, tier 0, no crossing)
      helper.processDartThrowWithAnnouncements('T10');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Triple 10' suppressed — attack is secondary
        'Devastating strike! Bob takes 6 damage!',  // Blood Moon 2x
        // No health warning — 88% still tier 0
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 14: Ancient Bandages — +5 healing on own number
    // Covers: Ancient Bandages buff boosts single heal from +1 to +5
    // =========================================================================
    test('Test 14: Ancient Bandages +5 healing', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Set Alice to 12 HP (above 10, avoids clutch heal)
      provider.currentGame!.health['p1'] = 12;
      provider.currentGame!.activeBuff = BonusBuff.ancientBandages;
      provider.currentGame!.saveInitialTurnStartState();

      // Alice hits own number (5) with single → heals +5 (normally +1)
      helper.processDartThrowWithAnnouncements('S5');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Single 5' suppressed — healing is secondary
        'Plus 5!',  // Ancient Bandages boosts to +5
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 15: Max Health! text — direct method test
    // Covers: announceHealing "Max Health!" variant (amount >= 50)
    // Note: This path requires healthMax > 50 which is outside valid game
    //       parameters (max=50), so tested via direct method call like Test 7.
    // =========================================================================
    test('Test 15: Max Health! text variant', () {
      audioQueue = MockMonsterMashAudioQueueService();

      // Directly test the Max Health! text path (amount >= 50)
      audioQueue.announceHealing('single', 50);
      audioQueue.announceHealing('single', 75);

      helper = MonsterMashTestHelper(
        provider: createTestProvider(players: createPlayers(2), healthMax: 20),
        audioQueue: audioQueue,
        players: createPlayers(2),
      );
      helper.verifyAnnouncements([
        'Max Health!',
        'Max Health!',
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 16: Triple attack standalone (not hat trick, 1st dart)
    // Covers: announceAttack with triple multiplier showing damage text
    // =========================================================================
    test('Test 16: Triple attack standalone - not hat trick', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 50);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Alice T10 on 1st dart → not hat trick (only 1 dart)
      helper.processDartThrowWithAnnouncements('T10');
      helper.verifyAnnouncements([
        'Alice, your turn',
        // 'Triple 10' suppressed — attack is secondary
        'Devastating strike! Bob takes 3 damage!',  // Triple standalone
        // No health warning — 47/50=94%, tier 0
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 17: Hit on eliminated opponent's number — no effect, hit fires
    // Covers: Hit fires when targeting eliminated opponent (no secondary)
    // =========================================================================
    test('Test 17: Hit on eliminated opponent number - hit fires', () {
      players = createPlayers(3);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Eliminate Bob (his number is 10)
      provider.currentGame!.health['p2'] = 0;
      provider.currentGame!.eliminated['p2'] = true;
      provider.currentGame!.saveInitialTurnStartState();

      // Alice hits Bob's old number (10) → no effect (eliminated)
      helper.processDartThrowWithAnnouncements('S10');
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Single 10',  // Hit fires — no secondary (opponent eliminated)
      ]);
      helper.clearAnnouncements();
    });

    // =========================================================================
    // Test 18: Bullseye at full health — no heal, hit fires
    // Covers: Bullseye when already at max health (heal amount = 0)
    // =========================================================================
    test('Test 18: Bullseye at full health - hit fires', () {
      players = createPlayers(2);
      provider = createTestProvider(players: players, healthMax: 20);
      audioQueue = MockMonsterMashAudioQueueService();
      helper = MonsterMashTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Alice at full health (20/20)
      // Bullseye heals to max → 20→20, amount=0, no healing
      helper.processDartThrowWithAnnouncements('Bull');
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Bullseye!',  // Hit fires — no secondary (heal amount = 0)
      ]);
      helper.clearAnnouncements();
    });
  });
}
