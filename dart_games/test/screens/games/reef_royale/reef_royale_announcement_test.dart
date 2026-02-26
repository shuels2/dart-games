import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/reef_royale_game.dart';
import '../../../mocks/mock_reef_royale_audio_queue_service.dart';

void main() {
  late MockReefRoyaleAudioQueueService mockQueue;

  setUp(() {
    mockQueue = MockReefRoyaleAudioQueueService();
  });

  tearDown(() {
    mockQueue.dispose();
  });

  // Helper to create a standard game
  ReefRoyaleGame createStandardGame({
    ReefRoyaleGameMode gameMode = ReefRoyaleGameMode.standard,
    bool easyClaim = false,
    bool neighborNumbers = false,
    bool bonusBuffs = false,
    bool speedPlay = false,
    int roundLimit = 10,
  }) {
    return ReefRoyaleGame.create(
      playerIds: ['p1', 'p2'],
      gameMode: gameMode,
      easyClaim: easyClaim,
      neighborNumbers: neighborNumbers,
      randomReefs: false,
      bonusBuffsEnabled: bonusBuffs,
      showHints: false,
      speedPlayEnabled: speedPlay,
      roundLimit: roundLimit,
    );
  }

  group('Game Events', () {
    test('game start announcement', () {
      mockQueue.announceGameStart();
      expect(mockQueue.announcements, contains('Dive in! The reef awaits!'));
    });

    test('random reefs announcement', () {
      mockQueue.announceRandomReefs();
      expect(mockQueue.announcements, contains('The reef has shifted!'));
    });

    test('turn announcement', () {
      mockQueue.announceTurn('Alice');
      expect(mockQueue.announcements, contains('Alice, your turn to swim!'));
    });

    test('remove darts announcement', () {
      mockQueue.announceRemoveDarts();
      expect(mockQueue.announcements, contains('Remove your darts'));
    });
  });

  group('Dart Events', () {
    test('miss announcement', () {
      mockQueue.announceMiss();
      expect(mockQueue.announcements, contains('That one drifted with the current!'));
    });

    test('non-target announcement', () {
      mockQueue.announceNonTarget();
      expect(mockQueue.announcements, contains("That reef isn't on the map!"));
    });

    test('single mark announcement', () {
      mockQueue.announceSingleMark('Fire Coral');
      expect(mockQueue.announcements, contains('A fish arrives at Fire Coral!'));
    });

    test('double mark announcement', () {
      mockQueue.announceDoubleMark('Brain Coral');
      expect(mockQueue.announcements, contains('A school gathers at Brain Coral!'));
    });

    test('triple mark announcement', () {
      mockQueue.announceTripleMark('Fan Coral');
      expect(mockQueue.announcements, contains('A triple! Fan Coral blooms!'));
    });

    test('neighbor mark announcement', () {
      mockQueue.announceNeighborMark('Staghorn Coral');
      expect(mockQueue.announcements, contains('A neighbor fish drifts to Staghorn Coral!'));
    });
  });

  group('Claim and Lock Events', () {
    test('coral claimed announcement', () {
      mockQueue.announceCoralClaimed('Alice', 'Fire Coral');
      expect(mockQueue.announcements, contains('Alice claims Fire Coral! It blooms!'));
    });

    test('reef locked announcement', () {
      mockQueue.announceReefLocked('Brain Coral');
      expect(mockQueue.announcements, contains('Brain Coral is locked! The reef is sealed!'));
    });
  });

  group('Scoring Events', () {
    test('standard scoring announcement', () {
      mockQueue.announceScoring('Alice', 20);
      expect(mockQueue.announcements, contains('Alice harvests 20 pearls!'));
    });

    test('big score announcement (40+)', () {
      mockQueue.announceScoring('Bob', 60);
      expect(mockQueue.announcements, contains('A massive pearl haul! 60 pearls!'));
    });

    test('cursed tide scoring announcement', () {
      mockQueue.announceCursedScoring(20, 'Bob');
      expect(mockQueue.announcements, contains('Cursed tide! 20 pearls weigh down Bob!'));
    });
  });

  group('Buff Events', () {
    test('riptide rush announcement', () {
      mockQueue.announceBuff(ReefBuff.riptideRush);
      expect(mockQueue.announcements, contains('Riptide rush! Double marks this round!'));
    });

    test('pearl fever announcement', () {
      mockQueue.announceBuff(ReefBuff.pearlFever);
      expect(mockQueue.announcements, contains('Pearl fever! Double pearls this round!'));
    });

    test('ink cloud announcement', () {
      mockQueue.announceBuff(ReefBuff.inkCloud);
      expect(mockQueue.announcements, contains('Ink cloud! The reef goes dark!'));
    });
  });

  group('Game Completion Events', () {
    test('near victory announcement', () {
      mockQueue.announceNearVictory('Alice');
      expect(mockQueue.announcements, contains('Alice has six corals! One more!'));
    });

    test('speed play end announcement', () {
      mockQueue.announceSpeedPlayEnd();
      expect(mockQueue.announcements, contains("Time's up! The tides decide the winner!"));
    });

    test('victory announcement', () {
      mockQueue.announceVictory('Alice');
      expect(mockQueue.announcements, contains('All hail Alice, Crown of the Reef!'));
    });
  });

  group('Announcement Precedence (max 2 per dart)', () {
    test('claim supersedes mark announcement', () {
      // When a dart causes a claim, we announce the claim (not just the mark)
      mockQueue.clearAnnouncements();
      // Simulate: dart hits, causes mark + claim
      mockQueue.announceCoralClaimed('Alice', 'Fire Coral');
      // Should NOT also announce single/double/triple mark
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'Alice claims Fire Coral! It blooms!');
    });

    test('score and claim can both fire (max 2)', () {
      mockQueue.clearAnnouncements();
      // Simulate: excess marks cause both claim and scoring
      mockQueue.announceCoralClaimed('Alice', 'Fire Coral');
      mockQueue.announceScoring('Alice', 20);
      expect(mockQueue.announcements.length, 2);
    });

    test('reef locked fires after claim', () {
      mockQueue.clearAnnouncements();
      mockQueue.announceCoralClaimed('Alice', 'Fire Coral');
      mockQueue.announceReefLocked('Fire Coral');
      expect(mockQueue.announcements.length, 2);
      expect(mockQueue.announcements[1], 'Fire Coral is locked! The reef is sealed!');
    });

    test('miss is standalone (1 announcement)', () {
      mockQueue.clearAnnouncements();
      mockQueue.announceMiss();
      expect(mockQueue.announcements.length, 1);
    });

    test('remove darts always fires independently', () {
      mockQueue.clearAnnouncements();
      mockQueue.announceCoralClaimed('Alice', 'Fire Coral');
      mockQueue.announceScoring('Alice', 20);
      mockQueue.announceRemoveDarts();
      // Remove darts is separate from dart events
      expect(mockQueue.announcements.length, 3);
      expect(mockQueue.announcements[2], 'Remove your darts');
    });
  });

  group('Game State Integration', () {
    test('game model tracks per-dart data for announcements', () {
      final game = createStandardGame();
      final playerId = game.playerIds[0];

      // Process a dart that hits target 20
      game.processDart(playerId, 20, 'single', isNeighborHit: false, resolvedTarget: 20);

      expect(game.dartThrowMarksAdded[playerId]!.length, 1);
      expect(game.dartThrowMarksAdded[playerId]![0], 1);
      expect(game.dartThrowClaimedCoral[playerId]![0], false);
      expect(game.dartThrowPearlsScored[playerId]![0], 0);
    });

    test('game model tracks claim events', () {
      final game = createStandardGame();
      final playerId = game.playerIds[0];

      // Hit target 20 three times to claim
      game.processDart(playerId, 20, 'single', isNeighborHit: false, resolvedTarget: 20);
      game.processDart(playerId, 20, 'single', isNeighborHit: false, resolvedTarget: 20);
      game.processDart(playerId, 20, 'single', isNeighborHit: false, resolvedTarget: 20);

      expect(game.dartThrowClaimedCoral[playerId]![2], true);
      expect(game.hasPlayerClaimed(playerId, 20), true);
    });

    test('game model tracks neighbor hits', () {
      final game = createStandardGame(neighborNumbers: true);
      final playerId = game.playerIds[0];

      // Hit number 1 (neighbor of 20)
      game.processDart(playerId, 1, 'single', isNeighborHit: true, resolvedTarget: 20);

      expect(game.dartThrowIsNeighbor[playerId]![0], true);
      expect(game.dartThrowMarksAdded[playerId]![0], 1); // Neighbors always 1 mark
    });

    test('game model tracks pearl scoring', () {
      final game = createStandardGame();
      final p1 = game.playerIds[0];

      // P1 claims target 20
      game.processDart(p1, 20, 'single', isNeighborHit: false, resolvedTarget: 20);
      game.processDart(p1, 20, 'single', isNeighborHit: false, resolvedTarget: 20);
      game.processDart(p1, 20, 'single', isNeighborHit: false, resolvedTarget: 20);

      // Clear darts for next turn simulation
      game.dartsThrown[p1] = 0;

      // P1 scores pearls on target 20 (opponent hasn't claimed)
      game.processDart(p1, 20, 'single', isNeighborHit: false, resolvedTarget: 20);

      final pearlsScored = game.dartThrowPearlsScored[p1]!;
      expect(pearlsScored.last, 20); // 20 pearls for single 20
    });

    test('cursed tide pearls go to opponents', () {
      final game = createStandardGame(gameMode: ReefRoyaleGameMode.cursedTide);
      final p1 = game.playerIds[0];
      final p2 = game.playerIds[1];

      // P1 claims target 20
      game.processDart(p1, 20, 'single', isNeighborHit: false, resolvedTarget: 20);
      game.processDart(p1, 20, 'single', isNeighborHit: false, resolvedTarget: 20);
      game.processDart(p1, 20, 'single', isNeighborHit: false, resolvedTarget: 20);
      game.dartsThrown[p1] = 0;

      // P1 hits 20 again, pearls go to P2
      game.processDart(p1, 20, 'single', isNeighborHit: false, resolvedTarget: 20);

      expect(game.getPlayerPearls(p2), 20); // P2 got the pearls
      expect(game.getPlayerPearls(p1), 0); // P1 didn't get them
    });
  });
}
