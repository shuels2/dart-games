import 'package:test/test.dart';
import 'package:dart_games_server/models/player_model.dart';
import 'package:dart_games_server/models/game_history_model.dart';
import 'package:dart_games_server/models/dartboard_model.dart';
import 'package:dart_games_server/models/saved_game_model.dart';
import 'package:dart_games_server/models/victory_music_model.dart';

void main() {
  group('ServerPlayer', () {
    test('fromDbRow parses snake_case keys correctly', () {
      final row = {
        'id': 'p1',
        'name': 'Alice',
        'photo_path': '/photos/alice.png',
        'created_at': '2026-01-01T00:00:00Z',
        'games_played': 10,
        'games_won': 3,
      };

      final player = ServerPlayer.fromDbRow(row);

      expect(player.id, 'p1');
      expect(player.name, 'Alice');
      expect(player.photoPath, '/photos/alice.png');
      expect(player.createdAt, '2026-01-01T00:00:00Z');
      expect(player.gamesPlayed, 10);
      expect(player.gamesWon, 3);
    });

    test('fromDbRow creates empty gameHistory by default', () {
      final row = {
        'id': 'p1',
        'name': 'Bob',
        'photo_path': null,
        'created_at': '2026-01-01',
        'games_played': 0,
        'games_won': 0,
      };

      final player = ServerPlayer.fromDbRow(row);

      expect(player.gameHistory, isEmpty);
    });

    test('fromDbRow handles null photo_path', () {
      final row = {
        'id': 'p1',
        'name': 'Bob',
        'photo_path': null,
        'created_at': '2026-01-01',
        'games_played': 0,
        'games_won': 0,
      };

      final player = ServerPlayer.fromDbRow(row);

      expect(player.photoPath, isNull);
    });

    test('fromJson parses camelCase keys with game history', () {
      final json = {
        'id': 'p1',
        'name': 'Alice',
        'photoPath': '/photos/alice.png',
        'createdAt': '2026-01-01T00:00:00Z',
        'gamesPlayed': 10,
        'gamesWon': 3,
        'gameHistory': [
          {
            'id': 'gh1',
            'playerId': 'p1',
            'gameName': 'Target Tag',
            'timestamp': '2026-01-01',
            'durationMs': 5000,
            'metadata': null,
            'dartThrows': null,
            'turns': null,
            'playerCount': null,
          },
        ],
      };

      final player = ServerPlayer.fromJson(json);

      expect(player.id, 'p1');
      expect(player.name, 'Alice');
      expect(player.gameHistory.length, 1);
      expect(player.gameHistory[0].gameName, 'Target Tag');
    });

    test('fromJson handles missing gameHistory', () {
      final json = {
        'id': 'p1',
        'name': 'Alice',
        'photoPath': null,
        'createdAt': '2026-01-01',
        'gamesPlayed': 0,
        'gamesWon': 0,
      };

      final player = ServerPlayer.fromJson(json);

      expect(player.gameHistory, isEmpty);
    });

    test('toJson produces camelCase keys', () {
      final player = ServerPlayer(
        id: 'p1',
        name: 'Alice',
        photoPath: '/photos/alice.png',
        createdAt: '2026-01-01T00:00:00Z',
        gamesPlayed: 10,
        gamesWon: 3,
      );

      final json = player.toJson();

      expect(json['id'], 'p1');
      expect(json['name'], 'Alice');
      expect(json['photoPath'], '/photos/alice.png');
      expect(json['createdAt'], '2026-01-01T00:00:00Z');
      expect(json['gamesPlayed'], 10);
      expect(json['gamesWon'], 3);
      expect(json['gameHistory'], isA<List>());
      expect(json['gameHistory'], isEmpty);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = {
        'id': 'p1',
        'name': 'Alice',
        'photoPath': '/photos/alice.png',
        'createdAt': '2026-01-01T00:00:00Z',
        'gamesPlayed': 10,
        'gamesWon': 3,
        'gameHistory': [
          {
            'id': 'gh1',
            'playerId': 'p1',
            'gameName': 'Target Tag',
            'timestamp': '2026-01-01',
            'durationMs': 5000,
            'metadata': {'result': 'win'},
            'dartThrows': 25,
            'turns': 5,
            'playerCount': 4,
          },
        ],
      };

      final player = ServerPlayer.fromJson(original);
      final roundtripped = player.toJson();

      expect(roundtripped['id'], original['id']);
      expect(roundtripped['name'], original['name']);
      expect(roundtripped['photoPath'], original['photoPath']);
      expect(roundtripped['gamesPlayed'], original['gamesPlayed']);
      expect(roundtripped['gamesWon'], original['gamesWon']);
      expect((roundtripped['gameHistory'] as List).length, 1);
      final historyEntry =
          (roundtripped['gameHistory'] as List)[0] as Map<String, dynamic>;
      expect(historyEntry['gameName'], 'Target Tag');
      expect(historyEntry['dartThrows'], 25);
    });
  });

  group('ServerGameHistoryEntry', () {
    test('fromDbRow parses metadata JSON string to Map', () {
      final row = {
        'id': 'gh1',
        'player_id': 'p1',
        'game_name': 'Target Tag',
        'timestamp': '2026-01-01T00:00:00Z',
        'duration_ms': 5000,
        'metadata': '{"result":"win","score":100}',
        'dart_throws': 25,
        'turns': 5,
        'player_count': 4,
      };

      final entry = ServerGameHistoryEntry.fromDbRow(row);

      expect(entry.id, 'gh1');
      expect(entry.playerId, 'p1');
      expect(entry.gameName, 'Target Tag');
      expect(entry.timestamp, '2026-01-01T00:00:00Z');
      expect(entry.durationMs, 5000);
      expect(entry.metadata, isA<Map<String, dynamic>>());
      expect(entry.metadata!['result'], 'win');
      expect(entry.metadata!['score'], 100);
      expect(entry.dartThrows, 25);
      expect(entry.turns, 5);
      expect(entry.playerCount, 4);
    });

    test('fromDbRow handles null metadata', () {
      final row = {
        'id': 'gh1',
        'player_id': 'p1',
        'game_name': 'Carnival Derby',
        'timestamp': '2026-01-01',
        'duration_ms': 3000,
        'metadata': null,
        'dart_throws': null,
        'turns': null,
        'player_count': null,
      };

      final entry = ServerGameHistoryEntry.fromDbRow(row);

      expect(entry.metadata, isNull);
      expect(entry.dartThrows, isNull);
      expect(entry.turns, isNull);
      expect(entry.playerCount, isNull);
    });

    test('fromDbRow handles empty metadata string', () {
      final row = {
        'id': 'gh1',
        'player_id': 'p1',
        'game_name': 'Carnival Derby',
        'timestamp': '2026-01-01',
        'duration_ms': 3000,
        'metadata': '',
        'dart_throws': null,
        'turns': null,
        'player_count': null,
      };

      final entry = ServerGameHistoryEntry.fromDbRow(row);

      expect(entry.metadata, isNull);
    });

    test('fromJson parses camelCase keys', () {
      final json = {
        'id': 'gh1',
        'playerId': 'p1',
        'gameName': 'Target Tag',
        'timestamp': '2026-01-01T00:00:00Z',
        'durationMs': 5000,
        'metadata': {'result': 'win'},
        'dartThrows': 25,
        'turns': 5,
        'playerCount': 4,
      };

      final entry = ServerGameHistoryEntry.fromJson(json);

      expect(entry.id, 'gh1');
      expect(entry.playerId, 'p1');
      expect(entry.gameName, 'Target Tag');
      expect(entry.durationMs, 5000);
      expect(entry.metadata, {'result': 'win'});
      expect(entry.dartThrows, 25);
      expect(entry.turns, 5);
      expect(entry.playerCount, 4);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = {
        'id': 'gh1',
        'playerId': 'p1',
        'gameName': 'Monster Mash',
        'timestamp': '2026-02-15T12:30:00Z',
        'durationMs': 12000,
        'metadata': {'placement': 1, 'character': 'Dragon'},
        'dartThrows': 42,
        'turns': 10,
        'playerCount': 6,
      };

      final entry = ServerGameHistoryEntry.fromJson(original);
      final roundtripped = entry.toJson();

      expect(roundtripped['id'], original['id']);
      expect(roundtripped['playerId'], original['playerId']);
      expect(roundtripped['gameName'], original['gameName']);
      expect(roundtripped['timestamp'], original['timestamp']);
      expect(roundtripped['durationMs'], original['durationMs']);
      expect(roundtripped['metadata'], original['metadata']);
      expect(roundtripped['dartThrows'], original['dartThrows']);
      expect(roundtripped['turns'], original['turns']);
      expect(roundtripped['playerCount'], original['playerCount']);
    });

    test('toJson includes null optional fields', () {
      final entry = ServerGameHistoryEntry(
        id: 'gh1',
        playerId: 'p1',
        gameName: 'Target Tag',
        timestamp: '2026-01-01',
        durationMs: 5000,
      );

      final json = entry.toJson();

      expect(json.containsKey('metadata'), isTrue);
      expect(json['metadata'], isNull);
      expect(json.containsKey('dartThrows'), isTrue);
      expect(json['dartThrows'], isNull);
      expect(json.containsKey('turns'), isTrue);
      expect(json['turns'], isNull);
      expect(json.containsKey('playerCount'), isTrue);
      expect(json['playerCount'], isNull);
    });
  });

  group('ServerDartboard', () {
    test('fromDbRow converts int to bool for useEmulator', () {
      final row = {
        'name': 'Living Room Board',
        'serial_number': 'SN-12345',
        'api_key': 'key-abc',
        'use_emulator': 1,
      };

      final board = ServerDartboard.fromDbRow(row);

      expect(board.name, 'Living Room Board');
      expect(board.serialNumber, 'SN-12345');
      expect(board.apiKey, 'key-abc');
      expect(board.useEmulator, isTrue);
    });

    test('fromDbRow converts 0 to false for useEmulator', () {
      final row = {
        'name': null,
        'serial_number': null,
        'api_key': null,
        'use_emulator': 0,
      };

      final board = ServerDartboard.fromDbRow(row);

      expect(board.useEmulator, isFalse);
      expect(board.name, isNull);
      expect(board.serialNumber, isNull);
      expect(board.apiKey, isNull);
    });

    test('fromJson parses camelCase keys', () {
      final json = {
        'name': 'My Board',
        'serialNumber': 'SN-999',
        'apiKey': 'key-xyz',
        'useEmulator': true,
      };

      final board = ServerDartboard.fromJson(json);

      expect(board.name, 'My Board');
      expect(board.serialNumber, 'SN-999');
      expect(board.apiKey, 'key-xyz');
      expect(board.useEmulator, isTrue);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = {
        'name': 'Game Room',
        'serialNumber': 'SN-555',
        'apiKey': 'key-roundtrip',
        'useEmulator': false,
      };

      final board = ServerDartboard.fromJson(original);
      final roundtripped = board.toJson();

      expect(roundtripped['name'], original['name']);
      expect(roundtripped['serialNumber'], original['serialNumber']);
      expect(roundtripped['apiKey'], original['apiKey']);
      expect(roundtripped['useEmulator'], original['useEmulator']);
    });

    test('toJson produces camelCase keys', () {
      final board = ServerDartboard(
        name: 'Test',
        serialNumber: 'SN-1',
        apiKey: 'key-1',
        useEmulator: false,
      );

      final json = board.toJson();

      expect(json.containsKey('serialNumber'), isTrue);
      expect(json.containsKey('apiKey'), isTrue);
      expect(json.containsKey('useEmulator'), isTrue);
      // Ensure snake_case keys are NOT present
      expect(json.containsKey('serial_number'), isFalse);
      expect(json.containsKey('api_key'), isFalse);
      expect(json.containsKey('use_emulator'), isFalse);
    });
  });

  group('ServerDartboardProfile', () {
    test('fromDbRow parses snake_case keys', () {
      final row = {
        'serial_number': 'SN-001',
        'name': 'Board Alpha',
        'api_key': 'key-alpha',
        'last_used': '2026-03-15T10:00:00Z',
      };

      final profile = ServerDartboardProfile.fromDbRow(row);

      expect(profile.serialNumber, 'SN-001');
      expect(profile.name, 'Board Alpha');
      expect(profile.apiKey, 'key-alpha');
      expect(profile.lastUsed, '2026-03-15T10:00:00Z');
    });

    test('fromJson parses camelCase keys', () {
      final json = {
        'serialNumber': 'SN-002',
        'name': 'Board Beta',
        'apiKey': 'key-beta',
        'lastUsed': '2026-04-01T12:00:00Z',
      };

      final profile = ServerDartboardProfile.fromJson(json);

      expect(profile.serialNumber, 'SN-002');
      expect(profile.name, 'Board Beta');
      expect(profile.apiKey, 'key-beta');
      expect(profile.lastUsed, '2026-04-01T12:00:00Z');
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = {
        'serialNumber': 'SN-003',
        'name': 'Board Gamma',
        'apiKey': 'key-gamma',
        'lastUsed': '2026-05-20T08:30:00Z',
      };

      final profile = ServerDartboardProfile.fromJson(original);
      final roundtripped = profile.toJson();

      expect(roundtripped['serialNumber'], original['serialNumber']);
      expect(roundtripped['name'], original['name']);
      expect(roundtripped['apiKey'], original['apiKey']);
      expect(roundtripped['lastUsed'], original['lastUsed']);
    });

    test('toJson produces camelCase keys not snake_case', () {
      final profile = ServerDartboardProfile(
        serialNumber: 'SN-1',
        name: 'Test',
        apiKey: 'key-1',
        lastUsed: '2026-01-01',
      );

      final json = profile.toJson();

      expect(json.containsKey('serialNumber'), isTrue);
      expect(json.containsKey('apiKey'), isTrue);
      expect(json.containsKey('lastUsed'), isTrue);
      expect(json.containsKey('serial_number'), isFalse);
      expect(json.containsKey('api_key'), isFalse);
      expect(json.containsKey('last_used'), isFalse);
    });
  });

  group('ServerSavedGame', () {
    test('fromDbRow deserializes JSON strings for playerNames and gameState',
        () {
      final row = {
        'id': 'sg1',
        'game_type': 'target_tag',
        'saved_at': '2026-01-01T00:00:00Z',
        'player_names': '["Alice","Bob","Charlie"]',
        'progress_info': 'Round 3/5',
        'game_mode_name': 'Classic',
        'leading_player_name': 'Alice',
        'leading_player_score': '250',
        'game_state': '{"round":3,"scores":{"Alice":250,"Bob":200}}',
        'waiting_for_takeout': 0,
      };

      final saved = ServerSavedGame.fromDbRow(row);

      expect(saved.id, 'sg1');
      expect(saved.gameType, 'target_tag');
      expect(saved.savedAt, '2026-01-01T00:00:00Z');
      expect(saved.playerNames, ['Alice', 'Bob', 'Charlie']);
      expect(saved.progressInfo, 'Round 3/5');
      expect(saved.gameModeName, 'Classic');
      expect(saved.leadingPlayerName, 'Alice');
      expect(saved.leadingPlayerScore, '250');
      expect(saved.gameState, isA<Map<String, dynamic>>());
      expect(saved.gameState['round'], 3);
      expect(saved.waitingForTakeout, isFalse);
    });

    test('fromDbRow converts int 1 to true for waitingForTakeout', () {
      final row = {
        'id': 'sg2',
        'game_type': 'carnival_derby',
        'saved_at': '2026-02-01',
        'player_names': '["Dave"]',
        'progress_info': 'Race 1/3',
        'game_mode_name': 'Sprint',
        'leading_player_name': 'Dave',
        'leading_player_score': '50',
        'game_state': '{"race":1}',
        'waiting_for_takeout': 1,
      };

      final saved = ServerSavedGame.fromDbRow(row);

      expect(saved.waitingForTakeout, isTrue);
    });

    test('fromJson parses camelCase keys', () {
      final json = {
        'id': 'sg1',
        'gameType': 'target_tag',
        'savedAt': '2026-01-01T00:00:00Z',
        'playerNames': ['Alice', 'Bob'],
        'progressInfo': 'Round 2/5',
        'gameModeName': 'Classic',
        'leadingPlayerName': 'Alice',
        'leadingPlayerScore': '150',
        'gameState': {'round': 2, 'active': true},
        'waitingForTakeout': false,
      };

      final saved = ServerSavedGame.fromJson(json);

      expect(saved.id, 'sg1');
      expect(saved.gameType, 'target_tag');
      expect(saved.playerNames, ['Alice', 'Bob']);
      expect(saved.gameState['round'], 2);
      expect(saved.gameState['active'], true);
      expect(saved.waitingForTakeout, isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = {
        'id': 'sg1',
        'gameType': 'monster_mash',
        'savedAt': '2026-03-01T15:00:00Z',
        'playerNames': ['Eve', 'Frank', 'Grace'],
        'progressInfo': 'Battle 5/7',
        'gameModeName': 'Team Battle',
        'leadingPlayerName': 'Grace',
        'leadingPlayerScore': '450',
        'gameState': {
          'battle': 5,
          'teams': {'a': ['Eve'], 'b': ['Frank', 'Grace']},
        },
        'waitingForTakeout': true,
      };

      final saved = ServerSavedGame.fromJson(original);
      final roundtripped = saved.toJson();

      expect(roundtripped['id'], original['id']);
      expect(roundtripped['gameType'], original['gameType']);
      expect(roundtripped['savedAt'], original['savedAt']);
      expect(roundtripped['playerNames'], original['playerNames']);
      expect(roundtripped['progressInfo'], original['progressInfo']);
      expect(roundtripped['gameModeName'], original['gameModeName']);
      expect(roundtripped['leadingPlayerName'], original['leadingPlayerName']);
      expect(roundtripped['leadingPlayerScore'],
          original['leadingPlayerScore']);
      expect(roundtripped['gameState'], original['gameState']);
      expect(roundtripped['waitingForTakeout'], original['waitingForTakeout']);
    });

    test('toJson produces camelCase keys', () {
      final saved = ServerSavedGame(
        id: 'sg1',
        gameType: 'test',
        savedAt: '2026-01-01',
        playerNames: ['A'],
        progressInfo: 'info',
        gameModeName: 'mode',
        leadingPlayerName: 'A',
        leadingPlayerScore: '0',
        gameState: {},
        waitingForTakeout: false,
      );

      final json = saved.toJson();

      expect(json.containsKey('gameType'), isTrue);
      expect(json.containsKey('savedAt'), isTrue);
      expect(json.containsKey('playerNames'), isTrue);
      expect(json.containsKey('progressInfo'), isTrue);
      expect(json.containsKey('gameModeName'), isTrue);
      expect(json.containsKey('leadingPlayerName'), isTrue);
      expect(json.containsKey('leadingPlayerScore'), isTrue);
      expect(json.containsKey('gameState'), isTrue);
      expect(json.containsKey('waitingForTakeout'), isTrue);
      // No snake_case keys
      expect(json.containsKey('game_type'), isFalse);
      expect(json.containsKey('saved_at'), isFalse);
      expect(json.containsKey('waiting_for_takeout'), isFalse);
    });
  });

  group('ServerVictoryMusic', () {
    test('fromDbRow converts int to bool for isCurrent', () {
      final row = {
        'id': 'vm1',
        'file_name': 'victory.mp3',
        'file_path': '/music/victory.mp3',
        'is_current': 1,
        'created_at': '2026-01-01T00:00:00Z',
      };

      final music = ServerVictoryMusic.fromDbRow(row);

      expect(music.id, 'vm1');
      expect(music.fileName, 'victory.mp3');
      expect(music.filePath, '/music/victory.mp3');
      expect(music.isCurrent, isTrue);
      expect(music.createdAt, '2026-01-01T00:00:00Z');
    });

    test('fromDbRow converts 0 to false for isCurrent', () {
      final row = {
        'id': 'vm2',
        'file_name': 'old_song.mp3',
        'file_path': '/music/old_song.mp3',
        'is_current': 0,
        'created_at': '2025-12-01',
      };

      final music = ServerVictoryMusic.fromDbRow(row);

      expect(music.isCurrent, isFalse);
    });

    test('fromJson parses camelCase keys', () {
      final json = {
        'id': 'vm1',
        'fileName': 'celebration.mp3',
        'filePath': '/music/celebration.mp3',
        'isCurrent': true,
        'createdAt': '2026-02-14T00:00:00Z',
      };

      final music = ServerVictoryMusic.fromJson(json);

      expect(music.id, 'vm1');
      expect(music.fileName, 'celebration.mp3');
      expect(music.filePath, '/music/celebration.mp3');
      expect(music.isCurrent, isTrue);
      expect(music.createdAt, '2026-02-14T00:00:00Z');
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = {
        'id': 'vm1',
        'fileName': 'fanfare.mp3',
        'filePath': '/uploads/fanfare.mp3',
        'isCurrent': false,
        'createdAt': '2026-04-10T09:00:00Z',
      };

      final music = ServerVictoryMusic.fromJson(original);
      final roundtripped = music.toJson();

      expect(roundtripped['id'], original['id']);
      expect(roundtripped['fileName'], original['fileName']);
      expect(roundtripped['filePath'], original['filePath']);
      expect(roundtripped['isCurrent'], original['isCurrent']);
      expect(roundtripped['createdAt'], original['createdAt']);
    });

    test('toJson produces camelCase keys not snake_case', () {
      final music = ServerVictoryMusic(
        id: 'vm1',
        fileName: 'test.mp3',
        filePath: '/test.mp3',
        isCurrent: true,
        createdAt: '2026-01-01',
      );

      final json = music.toJson();

      expect(json.containsKey('fileName'), isTrue);
      expect(json.containsKey('filePath'), isTrue);
      expect(json.containsKey('isCurrent'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('file_name'), isFalse);
      expect(json.containsKey('file_path'), isFalse);
      expect(json.containsKey('is_current'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
    });
  });
}
