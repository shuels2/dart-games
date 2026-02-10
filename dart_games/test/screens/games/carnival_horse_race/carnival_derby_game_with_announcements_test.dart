import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../mocks/mock_carnival_derby_audio_queue_service.dart';
import '../../../helpers/carnival_derby_test_helper.dart';

/// Carnival Derby Game - Automated Integration Tests WITH ANNOUNCEMENT VALIDATION
///
/// These tests validate BOTH game logic AND audio announcements
/// based on CARNIVAL_DERBY_ANNOUNCEMENTS.md
///
/// Covers:
/// - Normal mode (non-exact score)
/// - Perfect Finish mode (exact score with busts)
/// - All dart types (single, double, triple, bullseye, outer bull, miss)
/// - Game flow from start to finish
/// - Skip turn functionality

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Carnival Derby - Normal Mode Tests (with announcements)', () {
    late HorseRaceProvider provider;
    late MockCarnivalDerbyAudioQueueService audioQueue;
    late CarnivalDerbyTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = HorseRaceProvider();
      audioQueue = MockCarnivalDerbyAudioQueueService();
    });

    test('Test 1: Normal Mode - Basic Scoring with Different Dart Types', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      // Start game with target score 60 (normal mode)
      provider.startGame(players, 60, exactScoreMode: false);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: Single 20, Double 10, Miss
      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getPlayerScore(alice.id), 20);

      helper.processDartThrowWithAnnouncements('D10');
      expect(provider.getPlayerScore(alice.id), 40);

      helper.processDartThrowWithAnnouncements('Miss');
      expect(provider.getPlayerScore(alice.id), 40);

      // Verify announcements
      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        '20',
        'double 10 for 20',
        'Miss',
        'Alice, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Bob's turn: Triple 20 (wins)
      helper.processDartThrowWithAnnouncements('T20');
      expect(provider.getPlayerScore(bob.id), 60);
      expect(provider.hasWinner, true);
      expect(provider.getWinner(players), bob);

      helper.verifyAnnouncements([
        'Bob, it\'s your turn',
        'triple 20 for 60',
        'Bob, remove your darts',
      ]);
    });

    test('Test 2: Normal Mode - Bullseye and Outer Bull', () {
      final alice = Player.create(name: 'Alice');
      players = [alice];

      // Start game with target score 125 (normal mode)
      provider.startGame(players, 125, exactScoreMode: false);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: Bullseye (50), Outer Bull (25), Bullseye (50) = 125 (wins)
      helper.processDartThrowWithAnnouncements('Bull');
      expect(provider.getPlayerScore(alice.id), 50);

      helper.processDartThrowWithAnnouncements('25');
      expect(provider.getPlayerScore(alice.id), 75);

      helper.processDartThrowWithAnnouncements('Bull');
      expect(provider.getPlayerScore(alice.id), 125);
      expect(provider.hasWinner, true);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        'Bullseye! 50 points!',
        '25. Outer bull.',
        'Bullseye! 50 points!',
        'Alice, remove your darts',
      ]);
    });

    test('Test 3: Normal Mode - Multiple Players, Full Game', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final charlie = Player.create(name: 'Charlie');
      players = [alice, bob, charlie];

      // Start game with target score 100 (normal mode)
      provider.startGame(players, 100, exactScoreMode: false);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: T20, S10, S10 = 80
      helper.processDartThrowWithAnnouncements('T20');
      helper.processDartThrowWithAnnouncements('S10');
      helper.processDartThrowWithAnnouncements('S10');
      expect(provider.getPlayerScore(alice.id), 80);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        'triple 20 for 60',
        '10',
        '10',
        'Alice, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Bob's turn: D20, D20, Miss = 80
      helper.processDartThrowWithAnnouncements('D20');
      helper.processDartThrowWithAnnouncements('D20');
      helper.processDartThrowWithAnnouncements('Miss');
      expect(provider.getPlayerScore(bob.id), 80);

      helper.verifyAnnouncements([
        'Bob, it\'s your turn',
        'double 20 for 40',
        'double 20 for 40',
        'Miss',
        'Bob, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Charlie's turn: Bull, Bull = 100 (wins)
      helper.processDartThrowWithAnnouncements('Bull');
      helper.processDartThrowWithAnnouncements('Bull');
      expect(provider.getPlayerScore(charlie.id), 100);
      expect(provider.hasWinner, true);
      expect(provider.getWinner(players), charlie);

      helper.verifyAnnouncements([
        'Charlie, it\'s your turn',
        'Bullseye! 50 points!',
        'Bullseye! 50 points!',
        'Charlie, remove your darts',
      ]);
    });

    test('Test 4: Normal Mode - Skip Turn', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startGame(players, 60, exactScoreMode: false);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice throws one dart then skips
      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getPlayerScore(alice.id), 20);

      helper.clearAnnouncements();
      helper.skipTurn();

      // Verify skip announcements
      helper.verifyAnnouncements([
        'Alice, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Bob's turn
      helper.processDartThrowWithAnnouncements('T20');
      expect(provider.getPlayerScore(bob.id), 60);

      helper.verifyAnnouncements([
        'Bob, it\'s your turn',
        'triple 20 for 60',
        'Bob, remove your darts',
      ]);
    });
  });

  group('Carnival Derby - Perfect Finish Mode Tests (with announcements)', () {
    late HorseRaceProvider provider;
    late MockCarnivalDerbyAudioQueueService audioQueue;
    late CarnivalDerbyTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = HorseRaceProvider();
      audioQueue = MockCarnivalDerbyAudioQueueService();
    });

    test('Test 5: Perfect Finish - Player Busts (Goes Over)', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      // Start game with target score 50 (exact score mode)
      provider.startGame(players, 50, exactScoreMode: true);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: S20 (20), T20 (80 total - BUST!)
      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getPlayerScore(alice.id), 20);

      helper.processDartThrowWithAnnouncements('T20');
      // After bust, score stays at 20 (before the busting dart)
      expect(provider.getPlayerScore(alice.id), 20);
      expect(provider.currentPlayerBusted, true);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        '20',
        'triple 20 for 60',
        'Alice, you busted and your turn is over',
        'Alice, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Bob's turn: Bull = 50 (exact - wins)
      helper.processDartThrowWithAnnouncements('Bull');
      expect(provider.getPlayerScore(bob.id), 50);
      expect(provider.hasWinner, true);
      expect(provider.getWinner(players), bob);

      helper.verifyAnnouncements([
        'Bob, it\'s your turn',
        'Bullseye! 50 points!',
        'Bob, remove your darts',
      ]);
    });

    test('Test 6: Perfect Finish - Exact Score Win After Bust', () {
      final alice = Player.create(name: 'Alice');
      players = [alice];

      // Start game with target score 80 (exact score mode)
      provider.startGame(players, 80, exactScoreMode: true);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: T20, T20, T20 = 180 (BUST!)
      helper.processDartThrowWithAnnouncements('T20');
      expect(provider.getPlayerScore(alice.id), 60);

      helper.processDartThrowWithAnnouncements('T20');
      // 60 + 60 = 120 > 80 (BUST - score stays at 60)
      expect(provider.getPlayerScore(alice.id), 60);
      expect(provider.currentPlayerBusted, true);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        'triple 20 for 60',
        'triple 20 for 60',
        'Alice, you busted and your turn is over',
        'Alice, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Alice's second turn: S20 = 80 (exact - wins)
      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getPlayerScore(alice.id), 80);
      expect(provider.hasWinner, true);
      expect(provider.getWinner(players), alice);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        '20',
        'Alice, remove your darts',
      ]);
    });

    test('Test 7: Perfect Finish - Multiple Busts', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      // Start game with target score 40 (exact score mode)
      provider.startGame(players, 40, exactScoreMode: true);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: Bull = 50 (BUST!)
      helper.processDartThrowWithAnnouncements('Bull');
      expect(provider.getPlayerScore(alice.id), 0);
      expect(provider.currentPlayerBusted, true);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        'Bullseye! 50 points!',
        'Alice, you busted and your turn is over',
        'Alice, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Bob's turn: T20 = 60 (BUST!)
      helper.processDartThrowWithAnnouncements('T20');
      expect(provider.getPlayerScore(bob.id), 0);
      expect(provider.currentPlayerBusted, true);

      helper.verifyAnnouncements([
        'Bob, it\'s your turn',
        'triple 20 for 60',
        'Bob, you busted and your turn is over',
        'Bob, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Alice's second turn: D20 = 40 (exact - wins)
      helper.processDartThrowWithAnnouncements('D20');
      expect(provider.getPlayerScore(alice.id), 40);
      expect(provider.hasWinner, true);
      expect(provider.getWinner(players), alice);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        'double 20 for 40',
        'Alice, remove your darts',
      ]);
    });

    test('Test 8: Perfect Finish - Close Calls (Just Under Target)', () {
      final alice = Player.create(name: 'Alice');
      players = [alice];

      // Start game with target score 100 (exact score mode)
      provider.startGame(players, 100, exactScoreMode: true);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: T20, S20, S15 = 95 (just under - safe)
      helper.processDartThrowWithAnnouncements('T20');
      helper.processDartThrowWithAnnouncements('S20');
      helper.processDartThrowWithAnnouncements('S15');
      expect(provider.getPlayerScore(alice.id), 95);
      expect(provider.currentPlayerBusted, false);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        'triple 20 for 60',
        '20',
        '15',
        'Alice, remove your darts',
      ]);

      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Alice's second turn: S5 = 100 (exact - wins)
      helper.processDartThrowWithAnnouncements('S5');
      expect(provider.getPlayerScore(alice.id), 100);
      expect(provider.hasWinner, true);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        '5',
        'Alice, remove your darts',
      ]);
    });

    test('Test 9: Perfect Finish - Bust on First Dart', () {
      final alice = Player.create(name: 'Alice');
      players = [alice];

      // Start game with target score 30 (exact score mode)
      provider.startGame(players, 30, exactScoreMode: true);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: D20 = 40 (BUST on first dart!)
      helper.processDartThrowWithAnnouncements('D20');
      expect(provider.getPlayerScore(alice.id), 0);
      expect(provider.currentPlayerBusted, true);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        'double 20 for 40',
        'Alice, you busted and your turn is over',
        'Alice, remove your darts',
      ]);
    });

    test('Test 10: Perfect Finish - Progressive Scoring to Win', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      // Start game with target score 80 (exact score mode)
      provider.startGame(players, 80, exactScoreMode: true);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn: T20, S10, S10 = 80 (exact - wins)
      helper.processDartThrowWithAnnouncements('T20');
      expect(provider.getPlayerScore(alice.id), 60);

      helper.processDartThrowWithAnnouncements('S10');
      expect(provider.getPlayerScore(alice.id), 70);

      helper.processDartThrowWithAnnouncements('S10');
      expect(provider.getPlayerScore(alice.id), 80);
      expect(provider.hasWinner, true);
      expect(provider.getWinner(players), alice);

      helper.verifyAnnouncements([
        'Alice, it\'s your turn',
        'triple 20 for 60',
        '10',
        '10',
        'Alice, remove your darts',
      ]);
    });
  });

  group('Carnival Derby - Results Screen Announcements', () {
    late HorseRaceProvider provider;
    late MockCarnivalDerbyAudioQueueService audioQueue;
    late CarnivalDerbyTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = HorseRaceProvider();
      audioQueue = MockCarnivalDerbyAudioQueueService();
    });

    test('Test 11: Game Complete and Winner Announcements', () {
      final alice = Player.create(name: 'Alice');
      players = [alice];

      provider.startGame(players, 60, exactScoreMode: false);

      helper = CarnivalDerbyTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice wins
      helper.processDartThrowWithAnnouncements('T20');
      helper.clearAnnouncements();

      // Simulate results screen announcements
      helper.announceGameComplete();
      helper.announceWinner();

      helper.verifyAnnouncements([
        'The game is complete',
        'Alice is the winner',
      ]);
    });
  });
}
