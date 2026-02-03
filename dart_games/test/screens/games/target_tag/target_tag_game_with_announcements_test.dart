import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../mocks/mock_target_tag_audio_queue_service.dart';
import '../../../helpers/target_tag_test_helper.dart';

/// Target Tag Game - Automated Integration Tests WITH ANNOUNCEMENT VALIDATION
///
/// These tests validate BOTH game logic AND audio announcements
/// based on TARGET_TAG_TEST_PLAN.md
///
/// Note: This test suite covers Tests 1-8 (Solo Mode), 9-14 (Team Mode),
/// 15-17 (Hero Bonus), 18-19 (Turn Management), and 25-32 (Edge Cases).
/// Edit Score tests (20-24) are in a separate file as they require different test structure.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Target Tag - Solo Mode Tests (with announcements)', () {
    late TargetTagProvider provider;
    late MockTargetTagAudioQueueService audioQueue;
    late TargetTagTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TargetTagProvider();
      audioQueue = MockTargetTagAudioQueueService();
    });

    test('Test 1: Solo Mode - Basic Shield Building', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      expect(provider.getShields(alice.id), 0);
      expect(provider.getShields(bob.id), 0);

      helper.verifyAnnouncements(['Welcome to Target Tag! Fill those shields!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 1);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 14', '1 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D14');
      expect(provider.getShields(alice.id), 3);
      helper.verifyAnnouncements(['Double 14', '3 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('T14');
      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      helper.verifyAnnouncements(['Triple 14', 'JACKPOT! Alice is TAGGED IN!', 'Remove your darts']);
      helper.clearAnnouncements();

      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getShields(bob.id), 1);
      helper.verifyAnnouncements(['Bob, your turn', 'Single 20', '1 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D20');
      expect(provider.getShields(bob.id), 3);
      helper.verifyAnnouncements(['Double 20', '3 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('T20');
      expect(provider.getShields(bob.id), 5);
      expect(provider.isTaggedIn(bob.id), true);
      helper.verifyAnnouncements(['Triple 20', 'JACKPOT! Bob is TAGGED IN!', 'Remove your darts']);
      helper.clearAnnouncements();

      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 5);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 14']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.isTaggedIn(bob.id), true);
    });

    test('Test 2: Solo Mode - Reaching Tagged-In Status', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 1);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 14', '1 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('T14');
      expect(provider.getShields(alice.id), 4);
      helper.verifyAnnouncements(['Triple 14', '4 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      helper.verifyAnnouncements(['Single 14', 'JACKPOT! Alice is TAGGED IN!', 'Remove your darts']);
      helper.clearAnnouncements();

      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getShields(bob.id), 1);
      helper.verifyAnnouncements(['Bob, your turn', 'Single 20', '1 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D20');
      expect(provider.getShields(bob.id), 3);
      helper.verifyAnnouncements(['Double 20', '3 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getShields(bob.id), 4);
      expect(provider.isTaggedIn(bob.id), false);
      helper.verifyAnnouncements(['Single 20', '4 shields', 'Remove your darts']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.getShields(bob.id), 4);
      expect(provider.isTaggedIn(bob.id), false);
    });

    test('Test 3: Solo Mode - Successful Tag on Opponent', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 3;
      provider.currentGame!.taggedIn[alice.id] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getShields(bob.id), 2);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 20', 'Tag! Got \'em!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D20');
      expect(provider.getShields(bob.id), 0);
      expect(provider.isEliminated(bob.id), true);
      expect(provider.hasWinner, true);
      helper.verifyAnnouncements([
        'Double 20',
        'Tag! Got \'em!',
        'Bob is Tagged Out! Better luck next time!',
        'Remove your darts',
        'GAME OVER! Alice is the Target Tag Champion!',
      ]);

      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.getShields(bob.id), 0);
      expect(provider.isEliminated(bob.id), true);
    });

    test('Test 4: Solo Mode - Low Shields Warning', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 2;
      provider.currentGame!.taggedIn[alice.id] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getShields(bob.id), 1);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Single 20',
        'Tag! Got \'em!',
        'Warning! Bob\'s shields are almost gone!',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 1);
    });

    test('Test 5: Solo Mode - Losing Tagged-In Status', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      players = [alice, bob, carol];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 5;
      provider.currentGame!.shields[carol.id] = 3;
      provider.currentGame!.taggedIn[alice.id] = true;
      provider.currentGame!.taggedIn[bob.id] = true;

      provider.currentGame!.currentPlayerIndex = 1;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 4);
      expect(provider.isTaggedIn(alice.id), false);
      helper.verifyAnnouncements([
        'Bob, your turn',
        'Single 14',
        'Tag! Got \'em!',
        'Shield compromised! Alice is back on the hunt.',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D17');
      expect(provider.getShields(carol.id), 1);
      helper.verifyAnnouncements([
        'Double 17',
        'Tag! Got \'em!',
        'Warning! Carol\'s shields are almost gone!',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(alice.id), 4);
      expect(provider.isTaggedIn(alice.id), false);
      expect(provider.getShields(bob.id), 5);
      expect(provider.isTaggedIn(bob.id), true);
      expect(provider.getShields(carol.id), 1);
    });

    test('Test 6: Solo Mode - Multiple Low Shield Warnings', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      players = [alice, bob, carol];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 2;
      provider.currentGame!.shields[carol.id] = 2;
      provider.currentGame!.taggedIn[alice.id] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getShields(bob.id), 1);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Single 20',
        'Tag! Got \'em!',
        'Warning! Bob\'s shields are almost gone!',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S17');
      expect(provider.getShields(carol.id), 1);
      helper.verifyAnnouncements([
        'Single 17',
        'Tag! Got \'em!',
        'Warning! Carol\'s shields are almost gone!',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(bob.id), 1);
      expect(provider.getShields(carol.id), 1);
    });

    test('Test 7: Solo Mode - Miss Handling', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      expect(provider.getShields(alice.id), 0);
      helper.verifyAnnouncements(['Alice, your turn', 'Miss']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);
      helper.clearAnnouncements();

      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Bob, your turn', 'Miss']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(alice.id), 0);
      expect(provider.getShields(bob.id), 0);
    });

    test('Test 8: Solo Mode - Victory Condition', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 1;
      provider.currentGame!.taggedIn[alice.id] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getShields(bob.id), 0);
      expect(provider.isEliminated(bob.id), true);
      expect(provider.hasWinner, true);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Single 20',
        'Tag! Got \'em!',
        'Bob is Tagged Out! Better luck next time!',
        'Remove your darts',
        'GAME OVER! Alice is the Target Tag Champion!',
      ]);

      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 0);
      expect(provider.hasWinner, true);
    });
  });

  group('Target Tag - Team Mode Tests (with announcements)', () {
    late TargetTagProvider provider;
    late MockTargetTagAudioQueueService audioQueue;
    late TargetTagTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TargetTagProvider();
      audioQueue = MockTargetTagAudioQueueService();
    });

    test('Test 9: Team Mode Random - Basic Team Setup', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
      };

      provider.startTeamGame(teams, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 1);
      expect(provider.getShields(bob.id), 1);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 14', '1 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D14');
      expect(provider.getShields(alice.id), 3);
      expect(provider.getShields(bob.id), 3);
      helper.verifyAnnouncements(['Double 14', '3 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 4);
      expect(provider.getShields(bob.id), 4);
      helper.verifyAnnouncements(['Single 14', '4 shields', 'Remove your darts']);
      helper.clearAnnouncements();

      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S17');
      expect(provider.getShields(carol.id), 1);
      expect(provider.getShields(dave.id), 1);
      helper.verifyAnnouncements(['Carol, your turn', 'Single 17', '1 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S17');
      expect(provider.getShields(carol.id), 2);
      expect(provider.getShields(dave.id), 2);
      helper.verifyAnnouncements(['Single 17', '2 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S17');
      expect(provider.getShields(carol.id), 3);
      expect(provider.getShields(dave.id), 3);
      helper.verifyAnnouncements(['Single 17', '3 shields', 'Remove your darts']);
      helper.clearAnnouncements();

      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.isTaggedIn(bob.id), true);
      helper.verifyAnnouncements(['Bob, your turn', 'Single 14', 'JACKPOT! Alice and Bob are TAGGED IN!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 5);
      expect(provider.getShields(carol.id), 3);
      expect(provider.getShields(dave.id), 3);
    });

    test('Test 10: Team Mode Manual - Manual Team Assignment', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      final eve = Player.create(name: 'Eve');
      final frank = Player.create(name: 'Frank');
      players = [alice, bob, carol, dave, eve, frank];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
        'team3': [eve.id, frank.id],
      };

      provider.startTeamGame(teams, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;
      provider.currentGame!.targetNumbers[eve.id] = 18;
      provider.currentGame!.targetNumbers[frank.id] = 18;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn
      helper.processDartThrowWithAnnouncements('S14');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('S14');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Carol's turn
      helper.processDartThrowWithAnnouncements('S17');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('S17');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Eve's turn
      helper.processDartThrowWithAnnouncements('T18');
      expect(provider.getShields(eve.id), 3);
      expect(provider.getShields(frank.id), 3);
      helper.verifyAnnouncements(['Eve, your turn', 'Triple 18', '3 shields']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D18');
      expect(provider.getShields(eve.id), 5);
      expect(provider.getShields(frank.id), 5);
      expect(provider.isTaggedIn(eve.id), true);
      expect(provider.isTaggedIn(frank.id), true);
      helper.verifyAnnouncements(['Double 18', 'JACKPOT! Eve and Frank are TAGGED IN!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(alice.id), 2);
      expect(provider.getShields(carol.id), 2);
      expect(provider.getShields(eve.id), 5);
      expect(provider.isTaggedIn(eve.id), true);
    });

    test('Test 11: Team Mode - Team Reaching Tagged-In', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
      };

      provider.startTeamGame(teams, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Alice's turn
      helper.processDartThrowWithAnnouncements('T14');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Carol's turn
      helper.processDartThrowWithAnnouncements('S17');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Bob's turn
      helper.processDartThrowWithAnnouncements('D14');
      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.isTaggedIn(bob.id), true);
      helper.verifyAnnouncements(['Bob, your turn', 'Double 14', 'JACKPOT! Alice and Bob are TAGGED IN!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);
    });

    test('Test 12: Team Mode - Team Member Attacking Opponent', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
      };

      provider.startTeamGame(teams, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;

      provider.currentGame!.shields['team1'] = 5;
      provider.currentGame!.shields['team2'] = 3;
      provider.currentGame!.taggedIn['team1'] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('S17');
      expect(provider.getShields(carol.id), 2);
      expect(provider.getShields(dave.id), 2);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 17', 'Tag! Got \'em!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S17');
      expect(provider.getShields(carol.id), 1);
      expect(provider.getShields(dave.id), 1);
      helper.verifyAnnouncements(['Single 17', 'Tag! Got \'em!', 'Warning! Carol and Dave\'s shields are almost gone!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Carol's turn (not tagged-in, can't attack)
      helper.processDartThrowWithAnnouncements('S14');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      // Bob's turn (eliminates team)
      helper.processDartThrowWithAnnouncements('S17');
      expect(provider.getShields(carol.id), 0);
      expect(provider.getShields(dave.id), 0);
      expect(provider.isEliminated(carol.id), true);
      expect(provider.isEliminated(dave.id), true);
      expect(provider.hasWinner, true);
      helper.verifyAnnouncements([
        'Bob, your turn',
        'Single 17',
        'Tag! Got \'em!',
        'Carol and Dave are Tagged Out! Better luck next time!',
        'Remove your darts',
        'GAME OVER! Alice and Bob are the Target Tag Champions!',
      ]);
    });

    test('Test 13: Team Mode - Team Losing Tagged-In Status', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
      };

      provider.startTeamGame(teams, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;

      provider.currentGame!.shields['team1'] = 5;
      provider.currentGame!.shields['team2'] = 5;
      provider.currentGame!.taggedIn['team1'] = true;
      provider.currentGame!.taggedIn['team2'] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('D17');
      expect(provider.getShields(carol.id), 3);
      expect(provider.getShields(dave.id), 3);
      expect(provider.isTaggedIn(carol.id), false);
      expect(provider.isTaggedIn(dave.id), false);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Double 17',
        'Tag! Got \'em!',
        'Shield compromised! Carol and Dave are back on the hunt.',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(carol.id), 3);
      expect(provider.getShields(dave.id), 3);
      expect(provider.isTaggedIn(carol.id), false);
      expect(provider.isTaggedIn(dave.id), false);
    });

    test('Test 14: Team Mode - Team Elimination', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
      };

      provider.startTeamGame(teams, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;

      provider.currentGame!.shields['team1'] = 5;
      provider.currentGame!.shields['team2'] = 2;
      provider.currentGame!.taggedIn['team1'] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('D17');
      expect(provider.getShields(carol.id), 0);
      expect(provider.getShields(dave.id), 0);
      expect(provider.isEliminated(carol.id), true);
      expect(provider.isEliminated(dave.id), true);
      expect(provider.hasWinner, true);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Double 17',
        'Tag! Got \'em!',
        'Carol and Dave are Tagged Out! Better luck next time!',
        'Remove your darts',
        'GAME OVER! Alice and Bob are the Target Tag Champions!',
      ]);
    });
  });

  group('Target Tag - Hero Bonus Tests (with announcements)', () {
    late TargetTagProvider provider;
    late MockTargetTagAudioQueueService audioQueue;
    late TargetTagTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TargetTagProvider();
      audioQueue = MockTargetTagAudioQueueService();
    });

    test('Test 15: Solo Mode - Hero Bonus Enabled', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, true);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.soloHeroBuffNumbers![alice.id] = 7;
      provider.currentGame!.soloHeroBuffMultipliers![alice.id] = 'double';
      provider.currentGame!.soloHeroBuffNumbers![bob.id] = 13;
      provider.currentGame!.soloHeroBuffMultipliers![bob.id] = 'triple';

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 1);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D7');
      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.getShields(bob.id), 0);
      expect(provider.isEliminated(bob.id), true);
      expect(provider.hasWinner, true);
      helper.verifyAnnouncements([
        'Double 7',
        'JACKPOT! Alice is TAGGED IN!',
        'Bob is Tagged Out! Better luck next time!',
        'Remove your darts',
        'GAME OVER! Alice is the Target Tag Champion!',
      ]);
    });

    test('Test 16: Solo Mode - Hero Bonus Attack While Tagged-In', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      players = [alice, bob, carol];

      provider.startSoloGame(players, 5, true);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.soloHeroBuffNumbers![alice.id] = 7;
      provider.currentGame!.soloHeroBuffMultipliers![alice.id] = 'double';
      provider.currentGame!.soloHeroBuffNumbers![bob.id] = 13;
      provider.currentGame!.soloHeroBuffMultipliers![bob.id] = 'triple';
      provider.currentGame!.soloHeroBuffNumbers![carol.id] = 18;
      provider.currentGame!.soloHeroBuffMultipliers![carol.id] = 'double';

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 3;
      provider.currentGame!.shields[carol.id] = 4;
      provider.currentGame!.taggedIn[alice.id] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('D7');
      expect(provider.getShields(bob.id), 2);
      expect(provider.getShields(carol.id), 3);
      helper.verifyAnnouncements(['Alice, your turn', 'Double 7', 'Tag! Got \'em!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('D7');
      expect(provider.getShields(bob.id), 1);
      expect(provider.getShields(carol.id), 2);
      helper.verifyAnnouncements(['Double 7', 'Tag! Got \'em!', 'Warning! Bob\'s shields are almost gone!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 1);
      expect(provider.getShields(carol.id), 2);
    });

    test('Test 17: Team Mode - Hero Bonus Attack', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      final eve = Player.create(name: 'Eve');
      final frank = Player.create(name: 'Frank');
      players = [alice, bob, carol, dave, eve, frank];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
        'team3': [eve.id, frank.id],
      };

      provider.startTeamGame(teams, 5, true);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;
      provider.currentGame!.targetNumbers[eve.id] = 18;
      provider.currentGame!.targetNumbers[frank.id] = 18;

      provider.currentGame!.soloHeroBuffNumbers![alice.id] = 7;
      provider.currentGame!.soloHeroBuffMultipliers![alice.id] = 'triple';
      provider.currentGame!.soloHeroBuffNumbers![bob.id] = 7;
      provider.currentGame!.soloHeroBuffMultipliers![bob.id] = 'triple';
      provider.currentGame!.soloHeroBuffNumbers![carol.id] = 19;
      provider.currentGame!.soloHeroBuffMultipliers![carol.id] = 'double';
      provider.currentGame!.soloHeroBuffNumbers![dave.id] = 19;
      provider.currentGame!.soloHeroBuffMultipliers![dave.id] = 'double';
      provider.currentGame!.soloHeroBuffNumbers![eve.id] = 16;
      provider.currentGame!.soloHeroBuffMultipliers![eve.id] = 'double';
      provider.currentGame!.soloHeroBuffNumbers![frank.id] = 16;
      provider.currentGame!.soloHeroBuffMultipliers![frank.id] = 'double';

      provider.currentGame!.shields['team1'] = 5;
      provider.currentGame!.shields['team2'] = 3;
      provider.currentGame!.shields['team3'] = 4;
      provider.currentGame!.taggedIn['team1'] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('T7');
      expect(provider.getShields(carol.id), 2);
      expect(provider.getShields(dave.id), 2);
      expect(provider.getShields(eve.id), 3);
      expect(provider.getShields(frank.id), 3);
      helper.verifyAnnouncements(['Alice, your turn', 'Triple 7', 'Tag! Got \'em!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('T7');
      expect(provider.getShields(carol.id), 1);
      expect(provider.getShields(dave.id), 1);
      expect(provider.getShields(eve.id), 2);
      expect(provider.getShields(frank.id), 2);
      helper.verifyAnnouncements(['Triple 7', 'Tag! Got \'em!', 'Warning! Carol and Dave\'s shields are almost gone!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);
    });
  });

  group('Target Tag - Turn Management Tests (with announcements)', () {
    late TargetTagProvider provider;
    late MockTargetTagAudioQueueService audioQueue;
    late TargetTagTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TargetTagProvider();
      audioQueue = MockTargetTagAudioQueueService();
    });

    test('Test 18: Skip Player Turn', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      players = [alice, bob, carol];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      helper.skipTurn();
      expect(provider.getShields(alice.id), 0);
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S20');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S17');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 1);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 14', '1 shields']);

      expect(provider.getShields(alice.id), 1);
      expect(provider.getShields(bob.id), 1);
      expect(provider.getShields(carol.id), 1);
    });

    test('Test 19: Skip Multiple Turns in Sequence', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 19;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      helper.skipTurn();
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.skipTurn();
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('T17');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.skipTurn();
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('D14');
      expect(provider.getShields(alice.id), 2);
      helper.verifyAnnouncements(['Alice, your turn', 'Double 14', '2 shields']);

      expect(provider.getShields(alice.id), 2);
      expect(provider.getShields(bob.id), 0);
      expect(provider.getShields(carol.id), 3);
      expect(provider.getShields(dave.id), 0);
    });
  });

  group('Target Tag - Edit Score Tests (with announcements)', () {
    late TargetTagProvider provider;
    late MockTargetTagAudioQueueService audioQueue;
    late TargetTagTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TargetTagProvider();
      audioQueue = MockTargetTagAudioQueueService();
    });

    test('Test 20: Edit Score - Add Shields', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      provider.currentGame!.shields[alice.id] = 2;
      provider.currentGame!.shields[bob.id] = 0;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Step 2: Add Single 14
      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 3);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 14', '3 shields']);
      helper.clearAnnouncements();

      // Step 3: Add Double 14
      helper.processDartThrowWithAnnouncements('D14');
      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      helper.verifyAnnouncements(['Double 14', 'JACKPOT! Alice is TAGGED IN!']);
      helper.clearAnnouncements();

      // Step 4: Add Triple 14 (already at max, and turn ends after 3 darts)
      helper.processDartThrowWithAnnouncements('T14');
      expect(provider.getShields(alice.id), 5);
      helper.verifyAnnouncements(['Triple 14', 'Remove your darts']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
    });

    test('Test 21: Edit Score - Add Opponent Attacks', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      players = [alice, bob, carol];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 4;
      provider.currentGame!.shields[carol.id] = 3;
      provider.currentGame!.taggedIn[alice.id] = true;

      provider.currentGame!.turnStartShields = {alice.id: 5, bob.id: 4, carol.id: 3};
      provider.currentGame!.turnStartTaggedIn = {alice.id: true, bob.id: false, carol.id: false};

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Simulate Alice throwing 3 darts first (to have darts to edit)
      helper.processDartThrowWithAnnouncements('S20');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('S17');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();

      // Step 2: Edit dart 0 to Double 20
      provider.updateDartScore(alice.id, 0, 'D20');
      audioQueue.announceHit(20, 'double');
      audioQueue.announceSuccessfulTag();
      expect(provider.getShields(bob.id), 2);
      helper.verifyAnnouncements(['Double 20', 'Tag! Got \'em!']);
      helper.clearAnnouncements();

      // Step 3: Edit dart 1 to Double 17
      provider.updateDartScore(alice.id, 1, 'D17');
      audioQueue.announceHit(17, 'double');
      audioQueue.announceSuccessfulTag();
      audioQueue.announceLowShields([carol.name]);
      expect(provider.getShields(carol.id), 1);
      helper.verifyAnnouncements(['Double 17', 'Tag! Got \'em!', 'Warning! Carol\'s shields are almost gone!']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 2);
      expect(provider.getShields(carol.id), 1);
    });

    test('Test 22: Edit Score - Trigger Multiple Announcement Types', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      players = [alice, bob, carol];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;

      provider.currentGame!.shields[alice.id] = 4;
      provider.currentGame!.shields[bob.id] = 5;
      provider.currentGame!.shields[carol.id] = 2;
      provider.currentGame!.taggedIn[bob.id] = true;
      provider.currentGame!.currentPlayerIndex = 1; // Bob's turn

      provider.currentGame!.turnStartShields = {alice.id: 4, bob.id: 5, carol.id: 2};
      provider.currentGame!.turnStartTaggedIn = {alice.id: false, bob.id: true, carol.id: false};

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Simulate Bob throwing 3 darts first
      provider.processDartThrow('S17');
      provider.processDartThrow('S14');
      provider.processDartThrow('Miss');
      audioQueue.clearAnnouncements();

      // Step 2: Edit dart 0 to Single 17 (low shields warning)
      provider.updateDartScore(bob.id, 0, 'S17');
      audioQueue.announceHit(17, 'single');
      audioQueue.announceSuccessfulTag();
      audioQueue.announceLowShields([carol.name]);
      expect(provider.getShields(carol.id), 1);
      helper.verifyAnnouncements(['Single 17', 'Tag! Got \'em!', 'Warning! Carol\'s shields are almost gone!']);
      helper.clearAnnouncements();

      // Step 3: Edit dart 1 to Single 14
      provider.updateDartScore(bob.id, 1, 'S14');
      audioQueue.announceHit(14, 'single');
      audioQueue.announceSuccessfulTag();
      expect(provider.getShields(alice.id), 3);
      helper.verifyAnnouncements(['Single 14', 'Tag! Got \'em!']);
      helper.clearAnnouncements();

      // Step 4: Edit dart 2 to Single 17 (elimination)
      provider.updateDartScore(bob.id, 2, 'S17');
      audioQueue.announceHit(17, 'single');
      audioQueue.announceSuccessfulTag();
      audioQueue.announceEliminated([carol.name]);
      expect(provider.getShields(carol.id), 0);
      expect(provider.isEliminated(carol.id), true);
      helper.verifyAnnouncements(['Single 17', 'Tag! Got \'em!', 'Carol is Tagged Out! Better luck next time!']);

      expect(provider.getShields(alice.id), 3);
      expect(provider.getShields(bob.id), 5);
      expect(provider.isEliminated(carol.id), true);
    });

    test('Test 23: Edit Score - Remove Shields (Undo)', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 0;
      provider.currentGame!.taggedIn[alice.id] = true;

      provider.currentGame!.turnStartShields = {alice.id: 0, bob.id: 0};
      provider.currentGame!.turnStartTaggedIn = {alice.id: false, bob.id: false};

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Simulate Alice having thrown: S14, T14, S14
      provider.processDartThrow('S14');
      provider.processDartThrow('T14');
      provider.processDartThrow('S14');
      audioQueue.clearAnnouncements();

      // Step 2: Remove last dart (change to Miss)
      provider.updateDartScore(alice.id, 2, 'None');
      expect(provider.getShields(alice.id), 4);
      expect(provider.isTaggedIn(alice.id), false);
      // Announcements may replay or be silent - not strictly validating here
      helper.clearAnnouncements();

      // Step 3: Remove middle dart (change to Miss)
      provider.updateDartScore(alice.id, 1, 'None');
      expect(provider.getShields(alice.id), 1);
      expect(provider.isTaggedIn(alice.id), false);

      expect(provider.getShields(alice.id), 1);
      expect(provider.isTaggedIn(alice.id), false);
    });

    test('Test 24: Edit Score - Team Mode Shield Adjustment', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
      };

      provider.startTeamGame(teams, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;

      provider.currentGame!.shields['team1'] = 4;
      provider.currentGame!.shields['team2'] = 3;

      provider.currentGame!.turnStartShields = {'team1': 4, 'team2': 3};
      provider.currentGame!.turnStartTaggedIn = {'team1': false, 'team2': false};

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      // Simulate Alice throwing 3 darts first
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      provider.processDartThrow('Miss');
      audioQueue.clearAnnouncements();

      // Step 2: Edit dart 0 to Single 14
      provider.updateDartScore(alice.id, 0, 'S14');
      audioQueue.announceHit(14, 'single');
      audioQueue.announceTaggedIn([alice.name, bob.name]);
      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.isTaggedIn(bob.id), true);
      helper.verifyAnnouncements(['Single 14', 'JACKPOT! Alice and Bob are TAGGED IN!']);
      helper.clearAnnouncements();

      // Step 3: Edit dart 1 to Single 14 (already at max)
      provider.updateDartScore(alice.id, 1, 'S14');
      audioQueue.announceHit(14, 'single');
      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 5);
      helper.verifyAnnouncements(['Single 14']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 5);
      expect(provider.getShields(carol.id), 3);
      expect(provider.getShields(dave.id), 3);
    });
  });

  group('Target Tag - Edge Case Tests (with announcements)', () {
    late TargetTagProvider provider;
    late MockTargetTagAudioQueueService audioQueue;
    late TargetTagTestHelper helper;
    late List<Player> players;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TargetTagProvider();
      audioQueue = MockTargetTagAudioQueueService();
    });

    test('Test 25: Multiple Players Tagged-In Simultaneously', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 19;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 5;
      provider.currentGame!.shields[carol.id] = 3;
      provider.currentGame!.shields[dave.id] = 4;
      provider.currentGame!.taggedIn[alice.id] = true;
      provider.currentGame!.taggedIn[bob.id] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('S20');
      expect(provider.getShields(bob.id), 4);
      expect(provider.isTaggedIn(bob.id), false);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Single 20',
        'Tag! Got \'em!',
        'Shield compromised! Bob is back on the hunt.',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('S17');
      expect(provider.getShields(carol.id), 2);
      helper.verifyAnnouncements(['Single 17', 'Tag! Got \'em!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S14');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();

      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.getShields(bob.id), 4);
      expect(provider.isTaggedIn(bob.id), false);
    });

    test('Test 26: Simultaneous Eliminations (Team Mode with Hero Bonus)', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
      };

      provider.startTeamGame(teams, 5, true);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 14;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 17;

      provider.currentGame!.soloHeroBuffNumbers![alice.id] = 7;
      provider.currentGame!.soloHeroBuffMultipliers![alice.id] = 'triple';
      provider.currentGame!.soloHeroBuffNumbers![bob.id] = 7;
      provider.currentGame!.soloHeroBuffMultipliers![bob.id] = 'triple';
      provider.currentGame!.soloHeroBuffNumbers![carol.id] = 18;
      provider.currentGame!.soloHeroBuffMultipliers![carol.id] = 'double';
      provider.currentGame!.soloHeroBuffNumbers![dave.id] = 18;
      provider.currentGame!.soloHeroBuffMultipliers![dave.id] = 'double';

      provider.currentGame!.shields['team1'] = 5;
      provider.currentGame!.shields['team2'] = 1;
      provider.currentGame!.taggedIn['team1'] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('T7');
      expect(provider.getShields(carol.id), 0);
      expect(provider.getShields(dave.id), 0);
      expect(provider.isEliminated(carol.id), true);
      expect(provider.isEliminated(dave.id), true);
      expect(provider.hasWinner, true);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Triple 7',
        'Tag! Got \'em!',
        'Carol and Dave are Tagged Out! Better luck next time!',
        'Remove your darts',
        'GAME OVER! Alice and Bob are the Target Tag Champions!',
      ]);
    });

    test('Test 27: Regaining Tagged-In Status', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, false);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 5;
      provider.currentGame!.taggedIn[alice.id] = true;
      provider.currentGame!.taggedIn[bob.id] = true;

      provider.currentGame!.currentPlayerIndex = 1;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 4);
      expect(provider.isTaggedIn(alice.id), false);
      helper.verifyAnnouncements([
        'Bob, your turn',
        'Single 14',
        'Tag! Got \'em!',
        'Shield compromised! Alice is back on the hunt.',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.handleTakeoutFinished();

      helper.processDartThrowWithAnnouncements('S14');
      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      helper.verifyAnnouncements(['Alice, your turn', 'Single 14', 'JACKPOT! Alice is TAGGED IN!']);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('Miss');
      helper.clearAnnouncements();
      helper.processDartThrowWithAnnouncements('Miss');
      helper.verifyAnnouncements(['Miss', 'Remove your darts']);

      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.getShields(bob.id), 5);
      expect(provider.isTaggedIn(bob.id), true);
    });

    test('Test 28: All Bullseye Round (Hero Bonus ON)', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      players = [alice, bob];

      provider.startSoloGame(players, 5, true);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.soloHeroBuffNumbers![alice.id] = 13;
      provider.currentGame!.soloHeroBuffMultipliers![alice.id] = 'triple';
      provider.currentGame!.soloHeroBuffNumbers![bob.id] = 7;
      provider.currentGame!.soloHeroBuffMultipliers![bob.id] = 'double';

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      // Step 2: Alice throws Triple 13 (hero bonus) - fills to max AND attacks Bob, eliminating him
      helper.processDartThrowWithAnnouncements('T13');
      expect(provider.getShields(alice.id), 5);
      expect(provider.isTaggedIn(alice.id), true);
      expect(provider.getShields(bob.id), 0);
      expect(provider.isEliminated(bob.id), true);
      expect(provider.hasWinner, true);

      // The game behavior shows Bob is eliminated immediately, so we get all announcements
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Triple 13',
        'JACKPOT! Alice is TAGGED IN!',
        'Bob is Tagged Out! Better luck next time!',
        'Remove your darts',
        'GAME OVER! Alice is the Target Tag Champion!',
      ]);
    });

    test('Test 29: Ten Player Solo Game', () {
      final players = [
        Player.create(name: 'Alice'),
        Player.create(name: 'Bob'),
        Player.create(name: 'Carol'),
        Player.create(name: 'Dave'),
        Player.create(name: 'Eve'),
        Player.create(name: 'Frank'),
        Player.create(name: 'Grace'),
        Player.create(name: 'Hank'),
        Player.create(name: 'Ivy'),
        Player.create(name: 'Jack'),
      ];

      provider.startSoloGame(players, 5, false);
      final targets = [14, 20, 17, 19, 18, 16, 15, 13, 12, 11];
      for (int i = 0; i < players.length; i++) {
        provider.currentGame!.targetNumbers[players[i].id] = targets[i];
      }

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        final target = targets[i];

        helper.processDartThrowWithAnnouncements('S$target');
        expect(provider.getShields(player.id), 1);
        helper.clearAnnouncements();

        helper.processDartThrowWithAnnouncements('Miss');
        helper.clearAnnouncements();

        helper.processDartThrowWithAnnouncements('Miss');
        helper.clearAnnouncements();

        helper.handleTakeoutFinished();
      }

      for (final player in players) {
        expect(provider.getShields(player.id), 1);
      }
    });

    test('Test 30: Five Teams with Two Members Each', () {
      final players = [
        Player.create(name: 'Alice'),
        Player.create(name: 'Bob'),
        Player.create(name: 'Carol'),
        Player.create(name: 'Dave'),
        Player.create(name: 'Eve'),
        Player.create(name: 'Frank'),
        Player.create(name: 'Grace'),
        Player.create(name: 'Hank'),
        Player.create(name: 'Ivy'),
        Player.create(name: 'Jack'),
      ];

      final teams = {
        'team1': [players[0].id, players[1].id],
        'team2': [players[2].id, players[3].id],
        'team3': [players[4].id, players[5].id],
        'team4': [players[6].id, players[7].id],
        'team5': [players[8].id, players[9].id],
      };

      provider.startTeamGame(teams, 5, false);

      final targets = [14, 14, 17, 17, 18, 18, 15, 15, 12, 12];
      for (int i = 0; i < players.length; i++) {
        provider.currentGame!.targetNumbers[players[i].id] = targets[i];
      }

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.announceGameStart();
      helper.clearAnnouncements();

      final teamPlayers = [0, 2, 4, 6, 8];
      for (int i = 0; i < teamPlayers.length; i++) {
        final playerIndex = teamPlayers[i];
        final target = targets[playerIndex];

        helper.processDartThrowWithAnnouncements('S$target');
        helper.clearAnnouncements();
        helper.processDartThrowWithAnnouncements('Miss');
        helper.clearAnnouncements();
        helper.processDartThrowWithAnnouncements('Miss');
        helper.clearAnnouncements();
        helper.handleTakeoutFinished();
      }

      for (int i = 0; i < 5; i++) {
        expect(provider.getShields(players[i * 2].id), 1);
        expect(provider.getShields(players[i * 2 + 1].id), 1);
      }
    });

    test('Test 31: Solo Mode - Multiple Hero Bonus Attacks in Succession', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      players = [alice, bob, carol, dave];

      provider.startSoloGame(players, 5, true);
      provider.currentGame!.targetNumbers[alice.id] = 14;
      provider.currentGame!.targetNumbers[bob.id] = 20;
      provider.currentGame!.targetNumbers[carol.id] = 17;
      provider.currentGame!.targetNumbers[dave.id] = 19;
      provider.currentGame!.soloHeroBuffNumbers![alice.id] = 13;
      provider.currentGame!.soloHeroBuffMultipliers![alice.id] = 'triple';
      provider.currentGame!.soloHeroBuffNumbers![bob.id] = 7;
      provider.currentGame!.soloHeroBuffMultipliers![bob.id] = 'double';
      provider.currentGame!.soloHeroBuffNumbers![carol.id] = 19;
      provider.currentGame!.soloHeroBuffMultipliers![carol.id] = 'double';
      provider.currentGame!.soloHeroBuffNumbers![dave.id] = 16;
      provider.currentGame!.soloHeroBuffMultipliers![dave.id] = 'triple';

      provider.currentGame!.shields[alice.id] = 5;
      provider.currentGame!.shields[bob.id] = 4;
      provider.currentGame!.shields[carol.id] = 3;
      provider.currentGame!.shields[dave.id] = 2;
      provider.currentGame!.taggedIn[alice.id] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('T13');
      expect(provider.getShields(bob.id), 3);
      expect(provider.getShields(carol.id), 2);
      expect(provider.getShields(dave.id), 1);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Triple 13',
        'Tag! Got \'em!',
        'Warning! Dave\'s shields are almost gone!',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('T13');
      expect(provider.getShields(bob.id), 2);
      expect(provider.getShields(carol.id), 1);
      expect(provider.getShields(dave.id), 0);
      expect(provider.isEliminated(dave.id), true);
      helper.verifyAnnouncements([
        'Triple 13',
        'Tag! Got \'em!',
        'Dave is Tagged Out! Better luck next time!',
        'Warning! Carol\'s shields are almost gone!',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('T13');
      expect(provider.getShields(bob.id), 1);
      expect(provider.getShields(carol.id), 0);
      expect(provider.isEliminated(carol.id), true);
      helper.verifyAnnouncements([
        'Triple 13',
        'Tag! Got \'em!',
        'Carol is Tagged Out! Better luck next time!',
        'Warning! Bob\'s shields are almost gone!',
        'Remove your darts',
      ]);

      expect(provider.getShields(alice.id), 5);
      expect(provider.getShields(bob.id), 1);
      expect(provider.isEliminated(carol.id), true);
      expect(provider.isEliminated(dave.id), true);
    });

    test('Test 32: Team Mode - Multiple Hero Bonus Attacks in Succession', () {
      final alice = Player.create(name: 'Alice');
      final bob = Player.create(name: 'Bob');
      final carol = Player.create(name: 'Carol');
      final dave = Player.create(name: 'Dave');
      final eve = Player.create(name: 'Eve');
      final frank = Player.create(name: 'Frank');
      final grace = Player.create(name: 'Grace');
      final hank = Player.create(name: 'Hank');
      players = [alice, bob, carol, dave, eve, frank, grace, hank];

      final teams = {
        'team1': [alice.id, bob.id],
        'team2': [carol.id, dave.id],
        'team3': [eve.id, frank.id],
        'team4': [grace.id, hank.id],
      };

      provider.startTeamGame(teams, 5, true);

      final targets = [14, 14, 17, 17, 18, 18, 15, 15];
      for (int i = 0; i < players.length; i++) {
        provider.currentGame!.targetNumbers[players[i].id] = targets[i];
      }

      provider.currentGame!.soloHeroBuffNumbers![alice.id] = 13;
      provider.currentGame!.soloHeroBuffMultipliers![alice.id] = 'triple';
      provider.currentGame!.soloHeroBuffNumbers![bob.id] = 13;
      provider.currentGame!.soloHeroBuffMultipliers![bob.id] = 'triple';
      for (int i = 2; i < players.length; i++) {
        provider.currentGame!.soloHeroBuffNumbers![players[i].id] = 7;
        provider.currentGame!.soloHeroBuffMultipliers![players[i].id] = 'double';
      }

      provider.currentGame!.shields['team1'] = 5;
      provider.currentGame!.shields['team2'] = 4;
      provider.currentGame!.shields['team3'] = 3;
      provider.currentGame!.shields['team4'] = 2;
      provider.currentGame!.taggedIn['team1'] = true;

      helper = TargetTagTestHelper(
        provider: provider,
        audioQueue: audioQueue,
        players: players,
      );

      helper.processDartThrowWithAnnouncements('T13');
      expect(provider.getShields(carol.id), 3);
      expect(provider.getShields(dave.id), 3);
      expect(provider.getShields(eve.id), 2);
      expect(provider.getShields(frank.id), 2);
      expect(provider.getShields(grace.id), 1);
      expect(provider.getShields(hank.id), 1);
      helper.verifyAnnouncements([
        'Alice, your turn',
        'Triple 13',
        'Tag! Got \'em!',
        'Warning! Grace and Hank\'s shields are almost gone!',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('T13');
      expect(provider.getShields(grace.id), 0);
      expect(provider.getShields(hank.id), 0);
      expect(provider.isEliminated(grace.id), true);
      expect(provider.isEliminated(hank.id), true);
      helper.verifyAnnouncements([
        'Triple 13',
        'Tag! Got \'em!',
        'Grace and Hank are Tagged Out! Better luck next time!',
        'Warning! Eve and Frank\'s shields are almost gone!',
      ]);
      helper.clearAnnouncements();

      helper.processDartThrowWithAnnouncements('T13');
      expect(provider.getShields(eve.id), 0);
      expect(provider.getShields(frank.id), 0);
      expect(provider.isEliminated(eve.id), true);
      expect(provider.isEliminated(frank.id), true);
      helper.verifyAnnouncements([
        'Triple 13',
        'Tag! Got \'em!',
        'Eve and Frank are Tagged Out! Better luck next time!',
        'Warning! Carol and Dave\'s shields are almost gone!',
        'Remove your darts',
      ]);

      expect(provider.getShields(carol.id), 1);
      expect(provider.getShields(dave.id), 1);
      expect(provider.isEliminated(eve.id), true);
      expect(provider.isEliminated(frank.id), true);
      expect(provider.isEliminated(grace.id), true);
      expect(provider.isEliminated(hank.id), true);
    });
  });
}
