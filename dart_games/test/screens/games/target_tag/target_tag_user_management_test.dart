import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../mocks/mock_target_tag_audio_queue_service.dart';
import '../../../helpers/target_tag_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Target Tag - User Management Integration', () {
    late PlayerProvider playerProvider;
    late TargetTagProvider provider;
    late MockTargetTagAudioQueueService audioQueue;
    late TargetTagTestHelper helper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      playerProvider = PlayerProvider();
      provider = TargetTagProvider();
      audioQueue = MockTargetTagAudioQueueService();
      await playerProvider.loadPlayers();
    });

    // NOTE: Tests 1-3 (Add Player Dialog) require widget testing with UI interaction
    // They are documented in the test plan but not automated here as they test UI behavior

    group('Win Tracking - Solo Mode', () {
      test('Test 4: Solo Mode - Single Winner Records Stats', () async {
        // Create 2 players
        final alice = Player.create(name: 'Alice');
        final bob = Player.create(name: 'Bob');
        await playerProvider.savePlayer(alice);
        await playerProvider.savePlayer(bob);

        // Start solo game
        provider.startSoloGame([alice, bob], 3, false);
        final game = provider.currentGame!;
        expect(game.startedAt, isNotNull);

        // Set target numbers
        game.targetNumbers[alice.id] = 14;
        game.targetNumbers[bob.id] = 20;

        // Set Alice to already be tagged in with 3 shields, Bob with 3 shields
        game.shields[alice.id] = 3;
        game.shields[bob.id] = 3;
        game.taggedIn[alice.id] = true;

        // Create helper
        helper = TargetTagTestHelper(
          provider: provider,
          audioQueue: audioQueue,
          players: [alice, bob],
        );

        // Alice eliminates Bob (hits Bob's target until game ends)
        helper.processDartThrowWithAnnouncements('S20');
        expect(provider.getShields(bob.id), 2);

        helper.processDartThrowWithAnnouncements('D20');
        expect(provider.getShields(bob.id), 0);

        // Check if game is over (don't throw more darts if game ended)
        if (!provider.hasWinner) {
          helper.processDartThrowWithAnnouncements('S20');
        }

        // Verify game is complete
        expect(provider.isEliminated(bob.id), true);
        expect(provider.hasWinner, true);

        // Calculate duration
        final gameDuration = DateTime.now().difference(game.startedAt);

        // Get winners (using playerProvider.allPlayers like real game)
        final winners = provider.getWinners(playerProvider.allPlayers);
        expect(winners.length, 1);
        expect(winners[0].id, alice.id);

        final winnerIds = winners.map((p) => p.id).toSet();

        // Update stats for all players (matching real game logic)
        for (final playerId in game.playerIds) {
          final isWinner = winnerIds.contains(playerId);
          await playerProvider.updatePlayerStats(
            playerId,
            won: isWinner,
            gameName: 'Target Tag',
            gameDuration: gameDuration,
          );
        }

        // Reload players from storage (like real game would after update)
        await playerProvider.loadPlayers();

        // Verify Alice (Winner)
        final aliceUpdated = playerProvider.getPlayerById(alice.id);
        expect(aliceUpdated!.gamesPlayed, 1);
        expect(aliceUpdated.gamesWon, 1);
        expect(aliceUpdated.gameHistory.length, 1);
        expect(aliceUpdated.gameHistory[0].gameName, 'Target Tag');
        expect(aliceUpdated.gameHistory[0].duration, isNotNull);
        expect(aliceUpdated.gameHistory[0].timestamp, isNotNull);

        // Verify Bob (Loser) - should also have history with duration
        final bobUpdated = playerProvider.getPlayerById(bob.id);
        expect(bobUpdated!.gamesPlayed, 1);
        expect(bobUpdated.gamesWon, 0);
        expect(bobUpdated.gameHistory.length, 1);
        expect(bobUpdated.gameHistory[0].gameName, 'Target Tag');
        expect(bobUpdated.gameHistory[0].duration, isNotNull);
        expect(bobUpdated.gameHistory[0].timestamp, isNotNull);

        // Verify both have same duration
        expect(aliceUpdated.gameHistory[0].duration, bobUpdated.gameHistory[0].duration);
      });

      test('Test 5: Solo Mode - Multiple Games Accumulate History', () async {
        // Create 2 players
        final charlie = Player.create(name: 'Charlie');
        final david = Player.create(name: 'David');
        await playerProvider.savePlayer(charlie);
        await playerProvider.savePlayer(david);

        // Helper function to complete a game (following "play again" pattern)
        Future<void> playGame(Player winner, Player loser, bool isFirstGame) async {
          if (isFirstGame) {
            provider.startSoloGame([charlie, david], 3, false);
          } else {
            // "Play again" pattern - get players from current game and restart
            final currentGame = provider.currentGame!;
            final players = currentGame.playerIds
                .map((id) => playerProvider.getPlayerById(id))
                .whereType<Player>()
                .toList();
            provider.startSoloGame(players, 3, false);
          }

          final game = provider.currentGame!;
          game.targetNumbers[charlie.id] = 14;
          game.targetNumbers[david.id] = 20;

          // Set winner to tagged in, both with some shields
          game.shields[winner.id] = 3;
          game.shields[loser.id] = 3;
          game.taggedIn[winner.id] = true;

          // Set current player to the winner (who is tagged in)
          final winnerIndex = game.playerIds.indexOf(winner.id);
          game.currentPlayerIndex = winnerIndex;

          helper = TargetTagTestHelper(
            provider: provider,
            audioQueue: audioQueue,
            players: [charlie, david],
          );

          // Winner eliminates loser (stop if game ends)
          final loserTarget = game.targetNumbers[loser.id]!;
          helper.processDartThrowWithAnnouncements('S$loserTarget');
          if (!provider.hasWinner) {
            helper.processDartThrowWithAnnouncements('D$loserTarget');
          }
          if (!provider.hasWinner) {
            helper.processDartThrowWithAnnouncements('S$loserTarget');
          }

          expect(provider.hasWinner, true);

          final duration = DateTime.now().difference(game.startedAt);
          final winners = provider.getWinners(playerProvider.allPlayers);
          final winnerIds = winners.map((p) => p.id).toSet();

          for (final playerId in game.playerIds) {
            await playerProvider.updatePlayerStats(
              playerId,
              won: winnerIds.contains(playerId),
              gameName: 'Target Tag',
              gameDuration: duration,
            );
          }

          await playerProvider.loadPlayers();
        }

        // Game 1: Charlie wins
        await playGame(charlie, david, true);

        // Game 2: David wins
        await playGame(david, charlie, false);

        // Game 3: Charlie wins
        await playGame(charlie, david, false);

        // Verify Charlie's stats (2 wins, 1 loss)
        final charlieUpdated = playerProvider.getPlayerById(charlie.id);
        expect(charlieUpdated!.gamesPlayed, 3);
        expect(charlieUpdated.gamesWon, 2);
        expect(charlieUpdated.gameHistory.length, 3);
        expect(
          charlieUpdated.gameHistory.every((e) => e.gameName == 'Target Tag'),
          isTrue,
        );
        expect(
          charlieUpdated.gameHistory.every((e) => e.duration.inMilliseconds >= 0),
          isTrue,
        );

        // Verify David's stats (1 win, 2 losses)
        final davidUpdated = playerProvider.getPlayerById(david.id);
        expect(davidUpdated!.gamesPlayed, 3);
        expect(davidUpdated.gamesWon, 1);
        expect(davidUpdated.gameHistory.length, 3);
        expect(
          davidUpdated.gameHistory.every((e) => e.gameName == 'Target Tag'),
          isTrue,
        );
        expect(
          davidUpdated.gameHistory.every((e) => e.duration.inMilliseconds >= 0),
          isTrue,
        );

        // Verify unique IDs
        final allHistoryIds = [
          ...charlieUpdated.gameHistory.map((e) => e.id),
          ...davidUpdated.gameHistory.map((e) => e.id),
        ];
        expect(allHistoryIds.toSet().length, 6); // 3 games × 2 players = 6 unique entries
      });

      test('Test 6: Solo Mode - Game Duration Accuracy', () async {
        final emily = Player.create(name: 'Emily');
        final frank = Player.create(name: 'Frank');
        await playerProvider.savePlayer(emily);
        await playerProvider.savePlayer(frank);

        provider.startSoloGame([emily, frank], 3, false);
        final game = provider.currentGame!;
        final startTime = game.startedAt;

        game.targetNumbers[emily.id] = 14;
        game.targetNumbers[frank.id] = 20;

        // Set Emily tagged in with shields
        game.shields[emily.id] = 3;
        game.shields[frank.id] = 3;
        game.taggedIn[emily.id] = true;

        helper = TargetTagTestHelper(
          provider: provider,
          audioQueue: audioQueue,
          players: [emily, frank],
        );

        // Emily eliminates Frank
        helper.processDartThrowWithAnnouncements('S20');
        if (!provider.hasWinner) {
          helper.processDartThrowWithAnnouncements('D20');
        }
        if (!provider.hasWinner) {
          helper.processDartThrowWithAnnouncements('S20');
        }

        expect(provider.hasWinner, true);

        final endTime = DateTime.now();
        final expectedDuration = endTime.difference(startTime);

        // Update stats
        final winners = provider.getWinners(playerProvider.allPlayers);
        final winnerIds = winners.map((p) => p.id).toSet();

        for (final playerId in game.playerIds) {
          await playerProvider.updatePlayerStats(
            playerId,
            won: winnerIds.contains(playerId),
            gameName: 'Target Tag',
            gameDuration: expectedDuration,
          );
        }

        await playerProvider.loadPlayers();

        // Verify Emily (Winner)
        final emilyUpdated = playerProvider.getPlayerById(emily.id);
        expect(emilyUpdated!.gameHistory.length, 1);
        final emilyDuration = emilyUpdated.gameHistory[0].duration;
        expect(
          (emilyDuration.inSeconds - expectedDuration.inSeconds).abs(),
          lessThan(2),
        );

        // Verify Frank (Loser)
        final frankUpdated = playerProvider.getPlayerById(frank.id);
        expect(frankUpdated!.gameHistory.length, 1);
        final frankDuration = frankUpdated.gameHistory[0].duration;
        expect(
          (frankDuration.inSeconds - expectedDuration.inSeconds).abs(),
          lessThan(2),
        );

        // Verify both have identical duration
        expect(emilyDuration, frankDuration);
      });

      test('Test 7: Solo Mode - Stats Persist Across App Restart', () async {
        final grace = Player.create(name: 'Grace');
        final henry = Player.create(name: 'Henry');
        await playerProvider.savePlayer(grace);
        await playerProvider.savePlayer(henry);

        // Play 1 game (Grace wins)
        provider.startSoloGame([grace, henry], 3, false);
        final game = provider.currentGame!;
        game.targetNumbers[grace.id] = 14;
        game.targetNumbers[henry.id] = 20;

        // Set Grace tagged in with shields
        game.shields[grace.id] = 3;
        game.shields[henry.id] = 3;
        game.taggedIn[grace.id] = true;

        helper = TargetTagTestHelper(
          provider: provider,
          audioQueue: audioQueue,
          players: [grace, henry],
        );

        // Grace eliminates Henry
        helper.processDartThrowWithAnnouncements('S20');
        if (!provider.hasWinner) {
          helper.processDartThrowWithAnnouncements('D20');
        }
        if (!provider.hasWinner) {
          helper.processDartThrowWithAnnouncements('S20');
        }

        expect(provider.hasWinner, true);

        final duration = DateTime.now().difference(game.startedAt);
        final winners = provider.getWinners(playerProvider.allPlayers);
        final winnerIds = winners.map((p) => p.id).toSet();

        for (final playerId in game.playerIds) {
          await playerProvider.updatePlayerStats(
            playerId,
            won: winnerIds.contains(playerId),
            gameName: 'Target Tag',
            gameDuration: duration,
          );
        }

        await playerProvider.loadPlayers();

        // Create new provider (simulate app restart)
        final newProvider = PlayerProvider();
        await newProvider.loadPlayers();

        // Verify Grace (Winner)
        final graceLoaded = newProvider.getPlayerById(grace.id);
        expect(graceLoaded, isNotNull);
        expect(graceLoaded!.gamesPlayed, 1);
        expect(graceLoaded.gamesWon, 1);
        expect(graceLoaded.gameHistory.length, 1);
        expect(graceLoaded.gameHistory[0].gameName, 'Target Tag');
        expect(graceLoaded.gameHistory[0].duration, isNotNull);

        // Verify Henry (Loser)
        final henryLoaded = newProvider.getPlayerById(henry.id);
        expect(henryLoaded, isNotNull);
        expect(henryLoaded!.gamesPlayed, 1);
        expect(henryLoaded.gamesWon, 0);
        expect(henryLoaded.gameHistory.length, 1);
        expect(henryLoaded.gameHistory[0].gameName, 'Target Tag');
        expect(henryLoaded.gameHistory[0].duration, isNotNull);
      });
    });

    group('Win Tracking - Team Mode', () {
      test('Test 8: Team Mode - All Players Get Stats with Duration', () async {
        // Create 4 players
        final alice = Player.create(name: 'Alice');
        final bob = Player.create(name: 'Bob');
        final charlie = Player.create(name: 'Charlie');
        final dave = Player.create(name: 'Dave');

        await playerProvider.savePlayer(alice);
        await playerProvider.savePlayer(bob);
        await playerProvider.savePlayer(charlie);
        await playerProvider.savePlayer(dave);

        // Create teams
        final teams = {
          'team1': [alice.id, bob.id],
          'team2': [charlie.id, dave.id],
        };

        provider.startTeamGame(teams, 3, false);
        final game = provider.currentGame!;

        // Set target numbers
        game.targetNumbers[alice.id] = 14;
        game.targetNumbers[bob.id] = 15;
        game.targetNumbers[charlie.id] = 20;
        game.targetNumbers[dave.id] = 19;

        // Team 1 tagged in with shields, Team 2 has shields
        game.shields['team1'] = 3;
        game.shields['team2'] = 3;
        game.taggedIn['team1'] = true;

        helper = TargetTagTestHelper(
          provider: provider,
          audioQueue: audioQueue,
          players: [alice, bob, charlie, dave],
        );

        // Team 1 eliminates Team 2 (hit Charlie's target)
        helper.processDartThrowWithAnnouncements('S20');
        if (!provider.hasWinner) {
          helper.processDartThrowWithAnnouncements('D20');
        }
        if (!provider.hasWinner) {
          helper.processDartThrowWithAnnouncements('S20');
        }

        expect(provider.hasWinner, true);

        final duration = DateTime.now().difference(game.startedAt);
        final winners = provider.getWinners(playerProvider.allPlayers);
        final winnerIds = winners.map((p) => p.id).toSet();

        for (final playerId in game.playerIds) {
          await playerProvider.updatePlayerStats(
            playerId,
            won: winnerIds.contains(playerId),
            gameName: 'Target Tag',
            gameDuration: duration,
          );
        }

        await playerProvider.loadPlayers();

        // Verify Alice (Team 1 Winner)
        final aliceUpdated = playerProvider.getPlayerById(alice.id);
        expect(aliceUpdated!.gamesPlayed, 1);
        expect(aliceUpdated.gamesWon, 1);
        expect(aliceUpdated.gameHistory.length, 1);
        expect(aliceUpdated.gameHistory[0].gameName, 'Target Tag');
        expect(aliceUpdated.gameHistory[0].duration, isNotNull);

        // Verify Bob (Team 1 Winner)
        final bobUpdated = playerProvider.getPlayerById(bob.id);
        expect(bobUpdated!.gamesPlayed, 1);
        expect(bobUpdated.gamesWon, 1);
        expect(bobUpdated.gameHistory.length, 1);
        expect(bobUpdated.gameHistory[0].gameName, 'Target Tag');
        expect(bobUpdated.gameHistory[0].duration, isNotNull);

        // Verify Charlie (Team 2 Loser)
        final charlieUpdated = playerProvider.getPlayerById(charlie.id);
        expect(charlieUpdated!.gamesPlayed, 1);
        expect(charlieUpdated.gamesWon, 0);
        expect(charlieUpdated.gameHistory.length, 1);
        expect(charlieUpdated.gameHistory[0].gameName, 'Target Tag');
        expect(charlieUpdated.gameHistory[0].duration, isNotNull);

        // Verify Dave (Team 2 Loser)
        final daveUpdated = playerProvider.getPlayerById(dave.id);
        expect(daveUpdated!.gamesPlayed, 1);
        expect(daveUpdated.gamesWon, 0);
        expect(daveUpdated.gameHistory.length, 1);
        expect(daveUpdated.gameHistory[0].gameName, 'Target Tag');
        expect(daveUpdated.gameHistory[0].duration, isNotNull);

        // Verify all have same duration
        expect(aliceUpdated.gameHistory[0].duration, bobUpdated.gameHistory[0].duration);
        expect(aliceUpdated.gameHistory[0].duration, charlieUpdated.gameHistory[0].duration);
        expect(aliceUpdated.gameHistory[0].duration, daveUpdated.gameHistory[0].duration);
      });

      test('Test 9: Team Mode - Mixed Player History Across Multiple Games', () async {
        final alice = Player.create(name: 'Alice');
        final bob = Player.create(name: 'Bob');
        final charlie = Player.create(name: 'Charlie');
        final dave = Player.create(name: 'Dave');
        await playerProvider.savePlayer(alice);
        await playerProvider.savePlayer(bob);
        await playerProvider.savePlayer(charlie);
        await playerProvider.savePlayer(dave);

        var teams1 = {'team1': [alice.id, bob.id], 'team2': [charlie.id, dave.id]};
        provider.startTeamGame(teams1, 3, false);
        var game1 = provider.currentGame!;
        game1.targetNumbers[alice.id] = 14;
        game1.targetNumbers[bob.id] = 15;
        game1.targetNumbers[charlie.id] = 20;
        game1.targetNumbers[dave.id] = 19;
        game1.shields['team1'] = 3;
        game1.shields['team2'] = 3;
        game1.taggedIn['team1'] = true;

        // Set current player to someone on the tagged-in team (Alice is on team1)
        game1.currentPlayerIndex = game1.playerIds.indexOf(alice.id);

        helper = TargetTagTestHelper(provider: provider, audioQueue: audioQueue, players: [alice, bob, charlie, dave]);
        helper.processDartThrowWithAnnouncements('S20');
        if (!provider.hasWinner) helper.processDartThrowWithAnnouncements('D20');
        if (!provider.hasWinner) helper.processDartThrowWithAnnouncements('S20');
        expect(provider.hasWinner, true);

        var duration1 = DateTime.now().difference(game1.startedAt);
        var winners1 = provider.getWinners(playerProvider.allPlayers);
        var winnerIds1 = winners1.map((p) => p.id).toSet();
        for (final playerId in game1.playerIds) {
          await playerProvider.updatePlayerStats(playerId, won: winnerIds1.contains(playerId), gameName: 'Target Tag', gameDuration: duration1);
        }
        await playerProvider.loadPlayers();

        var teams2 = {'team1': [alice.id, charlie.id], 'team2': [bob.id, dave.id]};
        provider.startTeamGame(teams2, 3, false);
        var game2 = provider.currentGame!;
        game2.targetNumbers[alice.id] = 14;
        game2.targetNumbers[charlie.id] = 20;
        game2.targetNumbers[bob.id] = 15;
        game2.targetNumbers[dave.id] = 19;
        game2.shields['team1'] = 3;
        game2.shields['team2'] = 3;
        game2.taggedIn['team2'] = true;

        // Set current player to someone on the tagged-in team (Bob is on team2 in game 2)
        game2.currentPlayerIndex = game2.playerIds.indexOf(bob.id);

        helper = TargetTagTestHelper(provider: provider, audioQueue: audioQueue, players: [alice, bob, charlie, dave]);
        helper.processDartThrowWithAnnouncements('S14');
        if (!provider.hasWinner) helper.processDartThrowWithAnnouncements('D14');
        if (!provider.hasWinner) helper.processDartThrowWithAnnouncements('S14');
        expect(provider.hasWinner, true);

        var duration2 = DateTime.now().difference(game2.startedAt);
        var winners2 = provider.getWinners(playerProvider.allPlayers);
        var winnerIds2 = winners2.map((p) => p.id).toSet();
        for (final playerId in game2.playerIds) {
          await playerProvider.updatePlayerStats(playerId, won: winnerIds2.contains(playerId), gameName: 'Target Tag', gameDuration: duration2);
        }
        await playerProvider.loadPlayers();

        final aliceUpdated = playerProvider.getPlayerById(alice.id);
        expect(aliceUpdated!.gamesPlayed, 2);
        expect(aliceUpdated.gamesWon, 1);
        expect(aliceUpdated.gameHistory.length, 2);
        final bobUpdated = playerProvider.getPlayerById(bob.id);
        expect(bobUpdated!.gamesPlayed, 2);
        expect(bobUpdated.gamesWon, 2);
        expect(bobUpdated.gameHistory.length, 2);
        final charlieUpdated = playerProvider.getPlayerById(charlie.id);
        expect(charlieUpdated!.gamesPlayed, 2);
        expect(charlieUpdated.gamesWon, 0);
        expect(charlieUpdated.gameHistory.length, 2);
        final daveUpdated = playerProvider.getPlayerById(dave.id);
        expect(daveUpdated!.gamesPlayed, 2);
        expect(daveUpdated.gamesWon, 1);
        expect(daveUpdated.gameHistory.length, 2);
      });

      test('Test 10: Team Mode - 3-Team Game Stats', () async {
        final alice = Player.create(name: 'Alice');
        final bob = Player.create(name: 'Bob');
        final charlie = Player.create(name: 'Charlie');
        final dave = Player.create(name: 'Dave');
        final eve = Player.create(name: 'Eve');
        final frank = Player.create(name: 'Frank');
        await playerProvider.savePlayer(alice);
        await playerProvider.savePlayer(bob);
        await playerProvider.savePlayer(charlie);
        await playerProvider.savePlayer(dave);
        await playerProvider.savePlayer(eve);
        await playerProvider.savePlayer(frank);

        final teams = {'team1': [alice.id, bob.id], 'team2': [charlie.id, dave.id], 'team3': [eve.id, frank.id]};
        provider.startTeamGame(teams, 3, false);
        final game = provider.currentGame!;
        game.targetNumbers[alice.id] = 14;
        game.targetNumbers[bob.id] = 15;
        game.targetNumbers[charlie.id] = 20;
        game.targetNumbers[dave.id] = 19;
        game.targetNumbers[eve.id] = 18;
        game.targetNumbers[frank.id] = 17;
        // Team 2 has 3 shields and is tagged in
        // Team 1 has 1 shield (needs 2 hits to eliminate: 1→0, then 0→eliminated)
        // Team 3 starts at 0 shields (needs 1 hit to eliminate)
        game.shields['team1'] = 1;
        game.shields['team2'] = 3;
        game.shields['team3'] = 0;
        game.taggedIn['team2'] = true;

        // Set current player to someone on the tagged-in team (Charlie is on team2)
        game.currentPlayerIndex = game.playerIds.indexOf(charlie.id);

        helper = TargetTagTestHelper(provider: provider, audioQueue: audioQueue, players: [alice, bob, charlie, dave, eve, frank]);

        // Charlie's turn (3 darts): eliminate both teams
        helper.processDartThrowWithAnnouncements('S18'); // Team 3: 0→eliminated (hit while at 0)
        helper.processDartThrowWithAnnouncements('S14'); // Team 1: 1→0 shields (not eliminated)
        helper.processDartThrowWithAnnouncements('S14'); // Team 1: 0→eliminated

        expect(provider.hasWinner, true);

        final duration = DateTime.now().difference(game.startedAt);
        final winners = provider.getWinners(playerProvider.allPlayers);
        final winnerIds = winners.map((p) => p.id).toSet();
        for (final playerId in game.playerIds) {
          await playerProvider.updatePlayerStats(playerId, won: winnerIds.contains(playerId), gameName: 'Target Tag', gameDuration: duration);
        }
        await playerProvider.loadPlayers();

        final aliceUpdated = playerProvider.getPlayerById(alice.id);
        final bobUpdated = playerProvider.getPlayerById(bob.id);
        expect(aliceUpdated!.gamesPlayed, 1);
        expect(aliceUpdated.gamesWon, 0);
        expect(aliceUpdated.gameHistory.length, 1);
        expect(bobUpdated!.gamesPlayed, 1);
        expect(bobUpdated.gamesWon, 0);
        expect(bobUpdated.gameHistory.length, 1);

        final charlieUpdated = playerProvider.getPlayerById(charlie.id);
        final daveUpdated = playerProvider.getPlayerById(dave.id);
        expect(charlieUpdated!.gamesPlayed, 1);
        expect(charlieUpdated.gamesWon, 1);
        expect(charlieUpdated.gameHistory.length, 1);
        expect(daveUpdated!.gamesPlayed, 1);
        expect(daveUpdated.gamesWon, 1);
        expect(daveUpdated.gameHistory.length, 1);

        final eveUpdated = playerProvider.getPlayerById(eve.id);
        final frankUpdated = playerProvider.getPlayerById(frank.id);
        expect(eveUpdated!.gamesPlayed, 1);
        expect(eveUpdated.gamesWon, 0);
        expect(eveUpdated.gameHistory.length, 1);
        expect(frankUpdated!.gamesPlayed, 1);
        expect(frankUpdated.gamesWon, 0);
        expect(frankUpdated.gameHistory.length, 1);

        expect(aliceUpdated.gameHistory[0].duration, charlieUpdated.gameHistory[0].duration);
        expect(aliceUpdated.gameHistory[0].duration, eveUpdated.gameHistory[0].duration);
      });
    });

    group('Stats Calculations', () {
      test('Test 11: Total Play Time Calculation', () async {
        final isabel = Player.create(name: 'Isabel');
        final opponent = Player.create(name: 'Opponent');
        await playerProvider.savePlayer(isabel);
        await playerProvider.savePlayer(opponent);

        await playerProvider.updatePlayerStats(isabel.id, won: true, gameName: 'Target Tag', gameDuration: const Duration(minutes: 3));
        await playerProvider.updatePlayerStats(opponent.id, won: false, gameName: 'Target Tag', gameDuration: const Duration(minutes: 3));
        await playerProvider.updatePlayerStats(isabel.id, won: false, gameName: 'Target Tag', gameDuration: const Duration(minutes: 5));
        await playerProvider.updatePlayerStats(opponent.id, won: true, gameName: 'Target Tag', gameDuration: const Duration(minutes: 5));
        await playerProvider.updatePlayerStats(isabel.id, won: true, gameName: 'Target Tag', gameDuration: const Duration(minutes: 4));
        await playerProvider.updatePlayerStats(opponent.id, won: false, gameName: 'Target Tag', gameDuration: const Duration(minutes: 4));

        final totalTime = playerProvider.getPlayerTotalPlayTime(isabel.id);
        expect(totalTime.inMinutes, 12);
      });

      test('Test 12: Average Game Duration by Game Name', () async {
        final jack = Player.create(name: 'Jack');
        final opponent = Player.create(name: 'Opponent');
        await playerProvider.savePlayer(jack);
        await playerProvider.savePlayer(opponent);

        await playerProvider.updatePlayerStats(jack.id, won: true, gameName: 'Target Tag', gameDuration: const Duration(minutes: 6));
        await playerProvider.updatePlayerStats(jack.id, won: false, gameName: 'Target Tag', gameDuration: const Duration(minutes: 4));
        await playerProvider.updatePlayerStats(jack.id, won: true, gameName: 'Target Tag', gameDuration: const Duration(minutes: 8));
        await playerProvider.updatePlayerStats(jack.id, won: true, gameName: 'Carnival Derby', gameDuration: const Duration(minutes: 10));

        final avgDuration = playerProvider.getPlayerAverageGameDuration(jack.id, 'Target Tag');
        expect(avgDuration, isNotNull);
        expect(avgDuration!.inMinutes, 6);

        final allHistory = playerProvider.getPlayerHistory(jack.id);
        expect(allHistory.length, 4);
        expect(allHistory.where((e) => e.gameName == 'Target Tag').length, 3);
        expect(allHistory.where((e) => e.gameName == 'Carnival Derby').length, 1);
      });
    });

    group('Player Selection', () {
      test('Test 13: Max 10 players can be selected for Target Tag', () async {
        // Create 12 players
        final players = <Player>[];
        for (int i = 1; i <= 12; i++) {
          final player = Player.create(name: 'Player $i');
          await playerProvider.savePlayer(player);
          players.add(player);
        }

        // Select first 9 players (under max of 10)
        for (int i = 0; i < 9; i++) {
          playerProvider.selectPlayer(players[i], maxPlayers: 10);
        }

        expect(playerProvider.selectedPlayers.length, 9);

        // Select 10th player - should succeed
        playerProvider.selectPlayer(players[9], maxPlayers: 10);
        expect(playerProvider.selectedPlayers.length, 10);

        // Attempt to select 11th player - should fail (max reached)
        playerProvider.selectPlayer(players[10], maxPlayers: 10);
        expect(playerProvider.selectedPlayers.length, 10);
        expect(
          playerProvider.selectedPlayers.any((p) => p.id == players[10].id),
          isFalse,
        );

        // Deselect one player
        playerProvider.deselectPlayer(players[9].id);
        expect(playerProvider.selectedPlayers.length, 9);

        // Now selecting 11th player should succeed (under max again)
        playerProvider.selectPlayer(players[10], maxPlayers: 10);
        expect(playerProvider.selectedPlayers.length, 10);
        expect(
          playerProvider.selectedPlayers.any((p) => p.id == players[10].id),
          isTrue,
        );
      });
    });

    group('Dart and Turn Tracking', () {
      test('Test 14: Skip Turn Does Not Count as Throws or Turns', () async {
        final alice = Player.create(name: 'Alice');
        final bob = Player.create(name: 'Bob');
        await playerProvider.savePlayer(alice);
        await playerProvider.savePlayer(bob);

        provider.startSoloGame([alice, bob], 3, false);
        final game = provider.currentGame!;

        helper = TargetTagTestHelper(provider: provider, audioQueue: audioQueue, players: [alice, bob]);

        // Alice throws 1 dart
        helper.processDartThrowWithAnnouncements('S14');
        expect(game.getTotalDartsThrown(alice.id), 1);
        expect(game.getTotalTurns(alice.id), 1); // Turn started with first dart

        // Skip remaining darts
        provider.skipTurn();

        // Verify: Skip does NOT increment dart count
        expect(game.getTotalDartsThrown(alice.id), 1); // Still 1, not 3

        // Advance to next player
        provider.handleTakeoutFinished();

        // Verify: Turn incremented (because Alice threw 1 dart)
        expect(game.getTotalTurns(alice.id), 1);
      });

      test('Test 15: Win on First Dart Counts as 1 Turn', () async {
        final alice = Player.create(name: 'Alice');
        final bob = Player.create(name: 'Bob');
        await playerProvider.savePlayer(alice);
        await playerProvider.savePlayer(bob);

        provider.startSoloGame([alice, bob], 3, false);
        final game = provider.currentGame!;

        // Set up game state: Alice tagged in, Bob with 0 shields (vulnerable)
        game.shields[alice.id] = 3;
        game.shields[bob.id] = 0;
        game.taggedIn[alice.id] = true;
        game.targetNumbers[alice.id] = 14;
        game.targetNumbers[bob.id] = 20;

        helper = TargetTagTestHelper(provider: provider, audioQueue: audioQueue, players: [alice, bob]);

        // Alice eliminates Bob with 1 dart (single 20 = 1 hit, Bob at 0 shields)
        helper.processDartThrowWithAnnouncements('S20');

        // Verify: Game over after 1 dart
        expect(provider.hasWinner, true);
        expect(game.getTotalDartsThrown(alice.id), 1);  // Total darts thrown (cumulative)

        // Manually increment turn count (since game ended, advanceToNextPlayer may not have been called)
        game.advanceToNextPlayer();

        // Verify: Turn counted even though only 1 dart thrown
        expect(game.getTotalTurns(alice.id), 1);
      });

      test('Test 16: Win on Second Dart Counts as 1 Turn', () async {
        final alice = Player.create(name: 'Alice');
        final bob = Player.create(name: 'Bob');
        await playerProvider.savePlayer(alice);
        await playerProvider.savePlayer(bob);

        provider.startSoloGame([alice, bob], 3, false);
        final game = provider.currentGame!;

        // Set up: Alice tagged in, Bob with 1 shield
        game.shields[alice.id] = 3;
        game.shields[bob.id] = 1;
        game.taggedIn[alice.id] = true;
        game.targetNumbers[alice.id] = 14;
        game.targetNumbers[bob.id] = 20;

        helper = TargetTagTestHelper(provider: provider, audioQueue: audioQueue, players: [alice, bob]);

        // Alice throws 1 dart (single 20 = 1 hit, reduces Bob to 0 shields)
        helper.processDartThrowWithAnnouncements('S20');
        expect(game.getTotalDartsThrown(alice.id), 1);
        expect(game.shields[bob.id], 0); // Bob now vulnerable

        // Alice throws 2nd dart (single 20 = 1 hit, eliminates Bob at 0 shields)
        helper.processDartThrowWithAnnouncements('S20');

        // Verify: Game over after 2 darts
        expect(provider.hasWinner, true);
        expect(game.getTotalDartsThrown(alice.id), 2);  // Total darts thrown (cumulative)

        // Manually increment turn count (since game ended, advanceToNextPlayer may not have been called)
        game.advanceToNextPlayer();

        // Verify: Turn counted with 2 darts
        expect(game.getTotalTurns(alice.id), 1);
      });

      test('Test 17: Skip Entire Turn (0 Darts) Does Not Count as Turn', () async {
        final alice = Player.create(name: 'Alice');
        final bob = Player.create(name: 'Bob');
        await playerProvider.savePlayer(alice);
        await playerProvider.savePlayer(bob);

        provider.startSoloGame([alice, bob], 3, false);
        final game = provider.currentGame!;

        // Skip entire turn without throwing any darts
        provider.skipTurn();

        // Verify: No darts thrown
        expect(game.getTotalDartsThrown(alice.id), 0);

        provider.handleTakeoutFinished();

        // Verify: Turn NOT counted (player threw 0 darts)
        expect(game.getTotalTurns(alice.id), 0);
      });
    });
  });
}
