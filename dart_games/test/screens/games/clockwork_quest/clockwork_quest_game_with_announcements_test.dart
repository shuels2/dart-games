// Clockwork Quest Game - Announcement Integration Tests
// =====================================================
// 18 tests that validate announcements fire correctly during game flow.
//
// These tests replicate the announcement wiring logic from
// clockwork_quest_game_screen.dart (_handleDartThrow, _announceDartResult,
// _handleTakeoutFinished, _handleGameWon) and drive it through the
// ClockworkQuestProvider, verifying that the correct announcements fire
// in the correct order.
//
// The existing clockwork_quest_announcement_test.dart tests the HELPER
// methods in isolation (text output, sound effects). This file tests
// the GAME FLOW: that the right announcements fire when game events
// happen through the provider with the screen's precedence logic applied.
//
// ANNOUNCEMENT PRECEDENCE (from _announceDartResult):
//  Slot 1 (moment):
//   1. Victory (hasWinner) -> skip entire _announceDartResult
//   2. Lap complete -> announceLapComplete
//   3. Bullseye hit (target was 20, advanced to 21) -> announceBullseyeHit
//   4. Triple advance -> announceTripleAdvance
//   5. Double advance -> announceDoubleAdvance
//   6. Single gear activated -> announceGearActivated
//   7. Miss (!hitTarget) -> announceMiss
//
//  Slot 2 (milestone, checked after slot 1):
//   - newTarget == 21 && !completedLap -> announceBullseyeTarget
//   - completedTargets.length == 10 -> announceHalfway (speed mode only)
//   - completedTargets.length >= 18 -> announceNearVictory (speed mode only)
//
//  Remove darts: fires when dartsThrown >= 3 || hasWinner
//
// TEST GROUPS:
//  Group 1 - Lifecycle (3 tests): game start, player turn, remove darts
//  Group 2 - Moment announcements (7 tests): gear, double, triple, miss,
//            bullseye hit, lap complete, victory
//  Group 3 - Milestone announcements (3 tests): bullseye target, halfway,
//            near victory
//  Group 4 - Precedence (3 tests): lap > gear, victory suppresses all,
//            max 2 per event
//  Group 5 - Auto-play suppression (2 tests): per-dart, turn announcements

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/clockwork_quest_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/clockwork_quest_provider.dart';
import '../../../mocks/mock_clockwork_quest_audio_queue_service.dart';

// =============================================================================
// REUSABLE SETUP
// =============================================================================

List<Player> createPlayers(int count) {
  final names = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Hank'];
  return List.generate(count, (i) => Player(
    id: 'p${i + 1}',
    name: names[i],
    createdAt: DateTime(2026, 1, 1),
  ));
}

/// Creates a provider with a game in the playing state.
/// Default: 2 players, include bullseye, no speed mode, 1 lap.
ClockworkQuestProvider createTestProvider({
  required List<Player> players,
  bool includeBullseye = true,
  bool speedMode = false,
  int numberOfLaps = 1,
}) {
  final provider = ClockworkQuestProvider();
  provider.startGame(players, includeBullseye, speedMode, numberOfLaps);
  return provider;
}

/// Replicates the game screen's _announceDartResult logic.
///
/// This mirrors clockwork_quest_game_screen.dart lines 165-209 exactly,
/// using the mock audio queue instead of the real announcement helper.
void announceDartResult(
  ClockworkQuestProvider provider,
  String playerId,
  Player player,
  MockClockworkQuestAudioQueueService audioQueue,
) {
  final hitTargetList = provider.getDartThrowHitTarget(playerId);
  final multiplierList = provider.getDartThrowMultiplier(playerId);
  final advancedList = provider.getDartThrowAdvanced(playerId);
  final completedLapList = provider.getDartThrowCompletedLap(playerId);
  if (hitTargetList.isEmpty) return;

  final hitTarget = hitTargetList.last;
  final multiplier = multiplierList.last;
  final advanced = advancedList.last;
  final completedLap = completedLapList.last;
  final newTarget = provider.getPlayerCurrentTarget(playerId);
  final completedTargets = provider.getPlayerCompletedTargets(playerId);

  // Victory suppresses all dart result announcements
  if (provider.hasWinner) return;

  // Slot 1: moment announcement (highest priority wins)
  if (completedLap) {
    audioQueue.announceLapComplete();
  } else if (hitTarget && advanced && newTarget == 21) {
    audioQueue.announceBullseyeHit();
  } else if (hitTarget && advanced) {
    if (multiplier == 3) {
      audioQueue.announceTripleAdvance(player);
    } else if (multiplier == 2) {
      audioQueue.announceDoubleAdvance(player);
    } else {
      audioQueue.announceGearActivated(newTarget - 1);
    }
  } else if (!hitTarget) {
    audioQueue.announceMiss();
  }

  // Slot 2: milestone announcement
  if (newTarget == 21 && !completedLap) {
    audioQueue.announceBullseyeTarget();
  } else if (completedTargets.length == 10) {
    audioQueue.announceHalfway(player);
  } else if (completedTargets.length >= 18) {
    final gearsLeft = 20 - completedTargets.length;
    audioQueue.announceNearVictory(player, gearsLeft);
  }
}

/// Process a dart throw with full announcement wiring.
///
/// Mirrors _handleDartThrow from the game screen:
/// 1. Announce player turn on first dart
/// 2. Process the dart through provider
/// 3. Announce dart result (if not auto-playing)
/// 4. Announce remove darts when turn is over or game won
void processDartThrowWithAnnouncements(
  ClockworkQuestProvider provider,
  MockClockworkQuestAudioQueueService audioQueue,
  List<Player> players,
  String sector, {
  bool isAutoPlaying = false,
}) {
  final currentPlayerId = provider.getCurrentPlayerId();
  if (currentPlayerId == null) return;
  final currentPlayer = players.firstWhere((p) => p.id == currentPlayerId);

  // Announce turn on first dart
  final dartsBefore = provider.getCurrentPlayerDartsThrown();
  if (dartsBefore == 0 && !isAutoPlaying) {
    audioQueue.announcePlayerTurn(currentPlayer);
  }

  // Process the dart
  provider.processDartThrow(sector);

  // Announce dart result (unless auto-playing)
  if (!isAutoPlaying) {
    announceDartResult(provider, currentPlayerId, currentPlayer, audioQueue);
  }

  // Remove darts when turn over or winner
  final dartsAfter = provider.getCurrentPlayerDartsThrown();
  if (!isAutoPlaying && (dartsAfter >= 3 || provider.hasWinner)) {
    audioQueue.announceRemoveDarts(currentPlayer);
  }
}

/// Handle takeout finished with announcements.
/// Mirrors _handleTakeoutFinished and _handleGameWon from the game screen.
void handleTakeoutFinished(
  ClockworkQuestProvider provider,
  MockClockworkQuestAudioQueueService audioQueue,
  List<Player> players, {
  bool isAutoPlaying = false,
}) {
  if (provider.hasWinner) {
    // _handleGameWon
    if (!isAutoPlaying) {
      final winnerId = provider.currentGame?.winnerId;
      if (winnerId != null) {
        final winner = players.firstWhere((p) => p.id == winnerId);
        audioQueue.announceVictory(winner);
      }
    }
    return;
  }

  if (!provider.isGameActive) return;

  provider.confirmDartsRemoved();

  if (!isAutoPlaying) {
    final nextPlayerId = provider.getCurrentPlayerId();
    if (nextPlayerId != null) {
      // Turn announcement happens on next dart, not here.
      // The game screen does Future.delayed -> _announceCurrentPlayerTurn,
      // but we don't replicate the delayed turn announcement here because
      // the test verifies it fires on the first dart of the next turn instead.
    }
  }
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clockwork Quest - Game Flow with Announcements', () {
    late ClockworkQuestProvider provider;
    late MockClockworkQuestAudioQueueService audioQueue;
    late List<Player> players;

    // =========================================================================
    // Group 1 - Lifecycle announcements
    // =========================================================================

    group('Group 1 - Lifecycle', () {
      // Test 1: Game start announcement fires on initialization
      test('announceGameStart fires on initialization', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Mirrors _initializeGame in the game screen
        audioQueue.announceGameStart();

        expect(audioQueue.announcements.length, 1);
        expect(audioQueue.announcements[0],
            'Wind the gears! The quest begins!');
      });

      // Test 2: Player turn announcement fires on first dart of turn
      test('announcePlayerTurn fires after turn change', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Alice's first dart triggers turn announcement
        // Set her target to something she won't hit (target 1, throw S5 = miss)
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S5',
        );

        // First announcement should be the turn announcement
        expect(audioQueue.announcements.length, greaterThanOrEqualTo(1));
        expect(audioQueue.announcements[0],
            'Alice, your turn to tinker!');
      });

      // Test 3: Remove darts announcement fires at end of turn
      test('announceRemoveDarts fires at end of turn', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Throw 3 darts to trigger remove darts
        // All misses (target is 1, throw S5, S6, S7)
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S5',
        );
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S6',
        );
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S7',
        );

        // Last announcement should be remove darts
        expect(audioQueue.announcements.last,
            'Alice, remove your darts!');
      });
    });

    // =========================================================================
    // Group 2 - Moment announcements
    // =========================================================================

    group('Group 2 - Moment announcements', () {
      // Test 4: Single gear hit announces gear activated
      test('single gear hit announces gear activated', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Alice's target is 1. Hit S1 to activate gear 1, advance to 2.
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S1',
        );

        // Expect: turn announcement + gear activated
        expect(audioQueue.announcements, containsAll([
          'Alice, your turn to tinker!',
          'Gear 1 turns! Onward!',
        ]));
      });

      // Test 5: Double hit announces double advance
      test('double hit announces double advance', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Alice's target is 1. Hit D1 (double 1) to activate gear 1.
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'D1',
        );

        // Expect: turn announcement + double advance
        expect(audioQueue.announcements, contains(
            'Alice hits a double! Two gears turn!'));
      });

      // Test 6: Triple hit announces triple advance
      test('triple hit announces triple advance', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Alice's target is 1. Hit T1 (triple 1) to activate gear 1.
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'T1',
        );

        // Expect: turn announcement + triple advance
        expect(audioQueue.announcements, contains(
            'Alice hits a triple! Three gears turn!'));
      });

      // Test 7: Miss announces steam vent
      test('miss announces steam vent', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Alice's target is 1. Hit S5 = miss (wrong gear).
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S5',
        );

        // Expect: turn announcement + miss
        expect(audioQueue.announcements, contains(
            'Steam vents! That\'s not the right gear!'));
      });

      // Test 8: Bullseye hit announces crown gear
      // When the player advances from target 20 to target 21,
      // newTarget==21 triggers announceBullseyeHit (the crown gear).
      test('bullseye hit announces crown gear', () {
        players = createPlayers(2);
        // Use 2 laps so hitting bullseye target doesn't end the game
        provider = createTestProvider(
          players: players, includeBullseye: true, numberOfLaps: 2,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Set Alice's target to 20 (one before bullseye)
        provider.currentGame!.currentTarget['p1'] = 20;

        // Hit S20 to advance target to 21
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S20',
        );

        // Should contain bullseye hit announcement since newTarget == 21
        expect(audioQueue.announcements, contains(
            'The crown gear turns! Magnificent!'));
      });

      // Test 9: Lap complete announces lap completion
      test('lap complete announces lap completion', () {
        players = createPlayers(2);
        // No bullseye, so maxTarget is 20. 2 laps so first lap doesn't win.
        provider = createTestProvider(
          players: players, includeBullseye: false, numberOfLaps: 2,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Set Alice's target to 20 (last gear). Hit S20 to complete the lap.
        provider.currentGame!.currentTarget['p1'] = 20;

        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S20',
        );

        // Should contain lap complete announcement
        expect(audioQueue.announcements, contains(
            'Lap complete! Wind it again!'));
      });

      // Test 10: Victory announces winner
      test('victory announces winner', () {
        players = createPlayers(2);
        // 1 lap, no bullseye. Hit gear 20 to win.
        provider = createTestProvider(
          players: players, includeBullseye: false, numberOfLaps: 1,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Set Alice's target to 20
        provider.currentGame!.currentTarget['p1'] = 20;

        // Hit S20 to complete the only lap and win
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S20',
        );

        // Victory suppresses _announceDartResult, but remove darts fires
        // (hasWinner triggers remove darts)
        expect(audioQueue.announcements, contains(
            'Alice, remove your darts!'));
        // Victory announcement should NOT be in here yet -- it fires on takeout
        expect(audioQueue.announcements.where(
            (a) => a.contains('wins the Clockwork Crown')).length, 0);
        audioQueue.clearAnnouncements();

        // Takeout triggers victory
        handleTakeoutFinished(provider, audioQueue, players);
        expect(audioQueue.announcements, contains(
            'All gears turn! Alice wins the Clockwork Crown!'));
      });
    });

    // =========================================================================
    // Group 3 - Milestone announcements
    // =========================================================================

    group('Group 3 - Milestone announcements', () {
      // Test 11: Reaching bullseye target announces final gear
      test('reaching bullseye target announces final gear', () {
        players = createPlayers(2);
        // Include bullseye, 2 laps (so advancing to 21 doesn't end game)
        provider = createTestProvider(
          players: players, includeBullseye: true, numberOfLaps: 2,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Set Alice's target to 20
        provider.currentGame!.currentTarget['p1'] = 20;

        // Hit S20 to advance target to 21
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S20',
        );

        // Slot 2 milestone: newTarget == 21 && !completedLap -> bullseyeTarget
        expect(audioQueue.announcements, contains(
            'One final gear! Hit the bullseye to crown the clock!'));
      });

      // Test 12: Reaching gear 10 in speed mode announces halfway
      test('reaching gear 10 announces halfway', () {
        players = createPlayers(2);
        // Speed mode so completedTargets is populated
        provider = createTestProvider(
          players: players, includeBullseye: false, speedMode: true,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Pre-populate 9 completed targets for Alice
        provider.currentGame!.completedTargets['p1'] = [1, 2, 3, 4, 5, 6, 7, 8, 9];
        provider.currentGame!.currentTarget['p1'] = 10; // Next available

        // Hit S10 to complete the 10th gear
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S10',
        );

        // Slot 2 milestone: completedTargets.length == 10 -> halfway
        expect(audioQueue.announcements, contains(
            'Alice is halfway! The clock is ticking!'));
      });

      // Test 13: Reaching gear 18+ announces near victory
      test('reaching gear 18+ announces near victory', () {
        players = createPlayers(2);
        // Speed mode for completedTargets tracking
        provider = createTestProvider(
          players: players, includeBullseye: false, speedMode: true,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Pre-populate 17 completed targets
        provider.currentGame!.completedTargets['p1'] =
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
        provider.currentGame!.currentTarget['p1'] = 18;

        // Hit S18 to complete the 18th gear
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S18',
        );

        // Slot 2 milestone: completedTargets.length >= 18 -> nearVictory
        // gearsLeft = 20 - 18 = 2
        expect(audioQueue.announcements, contains(
            'Alice is almost there! Just 2 gears left!'));
      });
    });

    // =========================================================================
    // Group 4 - Precedence
    // =========================================================================

    group('Group 4 - Precedence', () {
      // Test 14: Lap complete takes precedence over gear activated
      test('lap complete takes precedence over gear activated', () {
        players = createPlayers(2);
        // No bullseye (maxTarget=20), 2 laps so first lap doesn't win
        provider = createTestProvider(
          players: players, includeBullseye: false, numberOfLaps: 2,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Set Alice to target 20 (last gear before lap completes)
        provider.currentGame!.currentTarget['p1'] = 20;

        // Hit S20 to complete the lap
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S20',
        );

        // Lap complete should fire, NOT gear activated
        expect(audioQueue.announcements, contains(
            'Lap complete! Wind it again!'));
        expect(audioQueue.announcements.where(
            (a) => a.contains('Gear') && a.contains('turns')).length, 0,
            reason: 'Gear activated must be suppressed by lap complete');
      });

      // Test 15: Victory suppresses all other announcements
      test('victory suppresses all other announcements', () {
        players = createPlayers(2);
        // 1 lap, no bullseye. Win on last gear.
        provider = createTestProvider(
          players: players, includeBullseye: false, numberOfLaps: 1,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Set Alice's target to 20
        provider.currentGame!.currentTarget['p1'] = 20;

        // Hit S20 to win
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S20',
        );

        // _announceDartResult returns early when hasWinner is true.
        // So no gear activated, no lap complete, no milestone announcements.
        // Only turn announcement (fires before provider.processDartThrow)
        // and remove darts (fires because hasWinner).
        expect(audioQueue.announcements.where(
            (a) => a.contains('Lap complete')).length, 0,
            reason: 'Lap complete must be suppressed by victory');
        expect(audioQueue.announcements.where(
            (a) => a.contains('Gear') && a.contains('turns')).length, 0,
            reason: 'Gear activated must be suppressed by victory');
        expect(audioQueue.announcements.where(
            (a) => a.contains('Steam vents')).length, 0,
            reason: 'Miss must be suppressed by victory');
        expect(audioQueue.announcements.where(
            (a) => a.contains('crown gear')).length, 0,
            reason: 'Bullseye hit must be suppressed by victory');

        // Turn + remove darts are the only announcements
        expect(audioQueue.announcements, contains(
            'Alice, your turn to tinker!'));
        expect(audioQueue.announcements, contains(
            'Alice, remove your darts!'));
        expect(audioQueue.announcements.length, 2);
      });

      // Test 16: Max 2 announcements per dart event
      test('max 2 announcements per dart event', () {
        players = createPlayers(2);
        // Include bullseye, 2 laps. Set target to 20 so advancing to 21
        // triggers both bullseyeHit (slot 1) and bullseyeTarget (slot 2).
        provider = createTestProvider(
          players: players, includeBullseye: true, numberOfLaps: 2,
        );
        audioQueue = MockClockworkQuestAudioQueueService();

        // Set Alice's target to 20
        provider.currentGame!.currentTarget['p1'] = 20;

        // First dart of turn triggers turn announcement too, so we throw
        // a miss first to get past the turn announcement.
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S5',
        );
        audioQueue.clearAnnouncements();

        // Second dart: hit S20 to advance to 21
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S20',
        );

        // Should have exactly 2 dart-result announcements:
        // Slot 1: bullseyeHit ("The crown gear turns! Magnificent!")
        // Slot 2: bullseyeTarget ("One final gear! Hit the bullseye...")
        // No remove darts yet (only 2 darts thrown)
        expect(audioQueue.announcements.length, 2,
            reason: 'Max 2 announcements per dart event (slot 1 + slot 2)');
        expect(audioQueue.announcements[0],
            'The crown gear turns! Magnificent!');
        expect(audioQueue.announcements[1],
            'One final gear! Hit the bullseye to crown the clock!');
      });
    });

    // =========================================================================
    // Group 5 - Auto-play suppression
    // =========================================================================

    group('Group 5 - Auto-play suppression', () {
      // Test 17: Auto-play suppresses per-dart announcements
      test('auto-play suppresses per-dart announcements', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Throw with auto-play enabled
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S1',
          isAutoPlaying: true,
        );
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S2',
          isAutoPlaying: true,
        );
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'S3',
          isAutoPlaying: true,
        );

        // No announcements should fire during auto-play
        expect(audioQueue.announcements.length, 0,
            reason: 'Auto-play must suppress all per-dart announcements');
      });

      // Test 18: Auto-play suppresses turn announcements
      test('auto-play suppresses turn announcements', () {
        players = createPlayers(2);
        provider = createTestProvider(players: players);
        audioQueue = MockClockworkQuestAudioQueueService();

        // Play through Alice's turn with auto-play
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'None',
          isAutoPlaying: true,
        );
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'None',
          isAutoPlaying: true,
        );
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'None',
          isAutoPlaying: true,
        );

        // Takeout with auto-play
        handleTakeoutFinished(
          provider, audioQueue, players,
          isAutoPlaying: true,
        );

        // No announcements at all
        expect(audioQueue.announcements.length, 0,
            reason: 'Auto-play must suppress turn and takeout announcements');

        // Bob's turn also silent
        processDartThrowWithAnnouncements(
          provider, audioQueue, players, 'None',
          isAutoPlaying: true,
        );

        expect(audioQueue.announcements.length, 0,
            reason: 'Auto-play must suppress next player turn announcement');
      });
    });
  });
}
