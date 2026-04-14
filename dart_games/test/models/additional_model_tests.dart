import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/dartboard.dart';
import 'package:dart_games/models/dartboard_connection_profile.dart';
import 'package:dart_games/models/api_log_entry.dart';
import 'package:dart_games/models/saved_game_metadata.dart';

void main() {
  group('Dartboard', () {
    test('constructor creates valid instance with all fields', () {
      final dartboard = Dartboard(
        serialNumber: 'SN-12345',
        name: 'My Board',
        isHomeSbc: true,
      );

      expect(dartboard.serialNumber, 'SN-12345');
      expect(dartboard.name, 'My Board');
      expect(dartboard.isHomeSbc, true);
    });

    test('isHomeSbc defaults to false', () {
      final dartboard = Dartboard(
        serialNumber: 'SN-99999',
        name: 'Default Board',
      );

      expect(dartboard.isHomeSbc, false);
    });

    test('toJson includes all fields', () {
      final dartboard = Dartboard(
        serialNumber: 'SN-ABC',
        name: 'Board Alpha',
        isHomeSbc: true,
      );
      final json = dartboard.toJson();

      expect(json['serialNumber'], 'SN-ABC');
      expect(json['name'], 'Board Alpha');
      expect(json['isHomeSbc'], true);
      expect(json.keys.length, 3);
    });

    test('toJson includes isHomeSbc as false when defaulted', () {
      final dartboard = Dartboard(
        serialNumber: 'SN-001',
        name: 'Test',
      );
      final json = dartboard.toJson();

      expect(json['isHomeSbc'], false);
    });

    test('fromJson restores all fields correctly', () {
      final json = {
        'serialNumber': 'SN-FROMJSON',
        'name': 'Restored Board',
        'isHomeSbc': true,
      };

      final dartboard = Dartboard.fromJson(json);

      expect(dartboard.serialNumber, 'SN-FROMJSON');
      expect(dartboard.name, 'Restored Board');
      expect(dartboard.isHomeSbc, true);
    });

    test('fromJson defaults isHomeSbc to false when missing', () {
      final json = {
        'serialNumber': 'SN-OLD',
        'name': 'Old Board',
      };

      final dartboard = Dartboard.fromJson(json);

      expect(dartboard.isHomeSbc, false);
    });

    test('fromJson defaults isHomeSbc to false when null', () {
      final json = {
        'serialNumber': 'SN-NULL',
        'name': 'Null Board',
        'isHomeSbc': null,
      };

      final dartboard = Dartboard.fromJson(json);

      expect(dartboard.isHomeSbc, false);
    });

    test('round-trip serialization preserves all data', () {
      final original = Dartboard(
        serialNumber: 'SN-ROUND',
        name: 'Round Trip Board',
        isHomeSbc: true,
      );

      final json = original.toJson();
      final restored = Dartboard.fromJson(json);

      expect(restored.serialNumber, original.serialNumber);
      expect(restored.name, original.name);
      expect(restored.isHomeSbc, original.isHomeSbc);
    });

    test('round-trip preserves default isHomeSbc', () {
      final original = Dartboard(
        serialNumber: 'SN-DEF',
        name: 'Default Board',
      );

      final json = original.toJson();
      final restored = Dartboard.fromJson(json);

      expect(restored.isHomeSbc, false);
    });

    test('handles empty string fields', () {
      final dartboard = Dartboard(
        serialNumber: '',
        name: '',
      );

      expect(dartboard.serialNumber, '');
      expect(dartboard.name, '');

      final json = dartboard.toJson();
      final restored = Dartboard.fromJson(json);

      expect(restored.serialNumber, '');
      expect(restored.name, '');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Dartboard(
        serialNumber: 'SN-ORIG',
        name: 'Original',
        isHomeSbc: false,
      );

      final updated = original.copyWith(
        name: 'Updated',
        isHomeSbc: true,
      );

      expect(updated.serialNumber, 'SN-ORIG');
      expect(updated.name, 'Updated');
      expect(updated.isHomeSbc, true);
      expect(original.name, 'Original');
      expect(original.isHomeSbc, false);
    });

    test('copyWith preserves fields when not specified', () {
      final original = Dartboard(
        serialNumber: 'SN-KEEP',
        name: 'Keep Me',
        isHomeSbc: true,
      );

      final updated = original.copyWith();

      expect(updated.serialNumber, original.serialNumber);
      expect(updated.name, original.name);
      expect(updated.isHomeSbc, original.isHomeSbc);
    });

    test('copyWith can update serialNumber', () {
      final original = Dartboard(
        serialNumber: 'OLD-SN',
        name: 'Board',
      );

      final updated = original.copyWith(serialNumber: 'NEW-SN');

      expect(updated.serialNumber, 'NEW-SN');
      expect(updated.name, 'Board');
    });
  });

  group('DartboardConnectionProfile', () {
    final testDate = DateTime(2026, 4, 14, 10, 30, 0);

    test('constructor creates valid instance with all fields', () {
      final profile = DartboardConnectionProfile(
        name: 'Home Board',
        serialNumber: 'SN-HOME',
        apiKey: 'key-abc-123',
        lastUsed: testDate,
      );

      expect(profile.name, 'Home Board');
      expect(profile.serialNumber, 'SN-HOME');
      expect(profile.apiKey, 'key-abc-123');
      expect(profile.lastUsed, testDate);
    });

    test('toJson includes all fields', () {
      final profile = DartboardConnectionProfile(
        name: 'Profile A',
        serialNumber: 'SN-A',
        apiKey: 'api-key-a',
        lastUsed: testDate,
      );
      final json = profile.toJson();

      expect(json['name'], 'Profile A');
      expect(json['serialNumber'], 'SN-A');
      expect(json['apiKey'], 'api-key-a');
      expect(json['lastUsed'], testDate.toIso8601String());
      expect(json.keys.length, 4);
    });

    test('toJson serializes lastUsed as ISO 8601 string', () {
      final profile = DartboardConnectionProfile(
        name: 'Date Test',
        serialNumber: 'SN-DT',
        apiKey: 'key',
        lastUsed: DateTime(2025, 12, 25, 8, 0, 0),
      );
      final json = profile.toJson();

      expect(json['lastUsed'], isA<String>());
      expect(json['lastUsed'], contains('2025-12-25'));
    });

    test('fromJson restores all fields correctly', () {
      final json = {
        'name': 'Restored Profile',
        'serialNumber': 'SN-RESTORED',
        'apiKey': 'restored-key',
        'lastUsed': '2026-04-14T10:30:00.000',
      };

      final profile = DartboardConnectionProfile.fromJson(json);

      expect(profile.name, 'Restored Profile');
      expect(profile.serialNumber, 'SN-RESTORED');
      expect(profile.apiKey, 'restored-key');
      expect(profile.lastUsed.year, 2026);
      expect(profile.lastUsed.month, 4);
      expect(profile.lastUsed.day, 14);
      expect(profile.lastUsed.hour, 10);
      expect(profile.lastUsed.minute, 30);
    });

    test('round-trip serialization preserves all data', () {
      final original = DartboardConnectionProfile(
        name: 'Round Trip Profile',
        serialNumber: 'SN-RT',
        apiKey: 'rt-api-key-xyz',
        lastUsed: DateTime(2026, 1, 15, 14, 45, 30),
      );

      final json = original.toJson();
      final restored = DartboardConnectionProfile.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.serialNumber, original.serialNumber);
      expect(restored.apiKey, original.apiKey);
      expect(restored.lastUsed, original.lastUsed);
    });

    test('handles empty string fields', () {
      final profile = DartboardConnectionProfile(
        name: '',
        serialNumber: '',
        apiKey: '',
        lastUsed: testDate,
      );

      final json = profile.toJson();
      final restored = DartboardConnectionProfile.fromJson(json);

      expect(restored.name, '');
      expect(restored.serialNumber, '');
      expect(restored.apiKey, '');
    });

    test('handles long apiKey values', () {
      final longKey = 'a' * 1000;
      final profile = DartboardConnectionProfile(
        name: 'Long Key',
        serialNumber: 'SN-LK',
        apiKey: longKey,
        lastUsed: testDate,
      );

      final json = profile.toJson();
      final restored = DartboardConnectionProfile.fromJson(json);

      expect(restored.apiKey, longKey);
      expect(restored.apiKey.length, 1000);
    });

    test('handles UTC DateTime', () {
      final utcDate = DateTime.utc(2026, 6, 15, 12, 0, 0);
      final profile = DartboardConnectionProfile(
        name: 'UTC Test',
        serialNumber: 'SN-UTC',
        apiKey: 'utc-key',
        lastUsed: utcDate,
      );

      final json = profile.toJson();
      final restored = DartboardConnectionProfile.fromJson(json);

      expect(restored.lastUsed.year, 2026);
      expect(restored.lastUsed.month, 6);
      expect(restored.lastUsed.day, 15);
    });
  });

  group('ApiLogEntry', () {
    final testTimestamp = DateTime(2026, 4, 14, 12, 0, 0);

    test('constructor creates valid instance with all fields', () {
      final entry = ApiLogEntry(
        id: 'log-001',
        timestamp: testTimestamp,
        method: 'GET',
        endpoint: '/api/players',
        request: {'page': 1},
        response: {'players': []},
        userNote: 'Test note',
      );

      expect(entry.id, 'log-001');
      expect(entry.timestamp, testTimestamp);
      expect(entry.method, 'GET');
      expect(entry.endpoint, '/api/players');
      expect(entry.request, {'page': 1});
      expect(entry.response, {'players': []});
      expect(entry.userNote, 'Test note');
    });

    test('request defaults to null', () {
      final entry = ApiLogEntry(
        id: 'log-002',
        timestamp: testTimestamp,
        method: 'GET',
        endpoint: '/api/status',
      );

      expect(entry.request, isNull);
    });

    test('response defaults to null', () {
      final entry = ApiLogEntry(
        id: 'log-003',
        timestamp: testTimestamp,
        method: 'GET',
        endpoint: '/api/status',
      );

      expect(entry.response, isNull);
    });

    test('userNote defaults to empty string', () {
      final entry = ApiLogEntry(
        id: 'log-004',
        timestamp: testTimestamp,
        method: 'POST',
        endpoint: '/api/data',
      );

      expect(entry.userNote, '');
    });

    test('toJson includes all fields', () {
      final entry = ApiLogEntry(
        id: 'log-full',
        timestamp: testTimestamp,
        method: 'POST',
        endpoint: '/api/players',
        request: {'name': 'Alice'},
        response: {'id': 'p-1', 'name': 'Alice'},
        userNote: 'Created player',
      );
      final json = entry.toJson();

      expect(json['id'], 'log-full');
      expect(json['timestamp'], testTimestamp.toIso8601String());
      expect(json['method'], 'POST');
      expect(json['endpoint'], '/api/players');
      expect(json['request'], {'name': 'Alice'});
      expect(json['response'], {'id': 'p-1', 'name': 'Alice'});
      expect(json['userNote'], 'Created player');
      expect(json.keys.length, 7);
    });

    test('toJson includes null request and response', () {
      final entry = ApiLogEntry(
        id: 'log-null',
        timestamp: testTimestamp,
        method: 'GET',
        endpoint: '/api/health',
      );
      final json = entry.toJson();

      expect(json.containsKey('request'), true);
      expect(json['request'], isNull);
      expect(json.containsKey('response'), true);
      expect(json['response'], isNull);
    });

    test('toJson includes empty userNote', () {
      final entry = ApiLogEntry(
        id: 'log-empty-note',
        timestamp: testTimestamp,
        method: 'GET',
        endpoint: '/api/test',
      );
      final json = entry.toJson();

      expect(json['userNote'], '');
    });

    test('fromJson restores all fields correctly', () {
      final json = {
        'id': 'log-from',
        'timestamp': '2026-04-14T12:00:00.000',
        'method': 'PUT',
        'endpoint': '/api/settings',
        'request': {'volume': 80},
        'response': {'status': 'ok'},
        'userNote': 'Updated settings',
      };

      final entry = ApiLogEntry.fromJson(json);

      expect(entry.id, 'log-from');
      expect(entry.timestamp.year, 2026);
      expect(entry.timestamp.month, 4);
      expect(entry.timestamp.day, 14);
      expect(entry.method, 'PUT');
      expect(entry.endpoint, '/api/settings');
      expect(entry.request, {'volume': 80});
      expect(entry.response, {'status': 'ok'});
      expect(entry.userNote, 'Updated settings');
    });

    test('fromJson handles null request and response', () {
      final json = {
        'id': 'log-nulls',
        'timestamp': '2026-04-14T12:00:00.000',
        'method': 'GET',
        'endpoint': '/api/health',
        'request': null,
        'response': null,
        'userNote': '',
      };

      final entry = ApiLogEntry.fromJson(json);

      expect(entry.request, isNull);
      expect(entry.response, isNull);
    });

    test('fromJson handles missing request and response', () {
      final json = {
        'id': 'log-missing',
        'timestamp': '2026-04-14T12:00:00.000',
        'method': 'DELETE',
        'endpoint': '/api/players/1',
      };

      final entry = ApiLogEntry.fromJson(json);

      expect(entry.request, isNull);
      expect(entry.response, isNull);
    });

    test('fromJson defaults userNote to empty string when missing', () {
      final json = {
        'id': 'log-no-note',
        'timestamp': '2026-04-14T12:00:00.000',
        'method': 'GET',
        'endpoint': '/api/test',
      };

      final entry = ApiLogEntry.fromJson(json);

      expect(entry.userNote, '');
    });

    test('fromJson defaults userNote to empty string when null', () {
      final json = {
        'id': 'log-null-note',
        'timestamp': '2026-04-14T12:00:00.000',
        'method': 'GET',
        'endpoint': '/api/test',
        'userNote': null,
      };

      final entry = ApiLogEntry.fromJson(json);

      expect(entry.userNote, '');
    });

    test('round-trip serialization preserves all data', () {
      final original = ApiLogEntry(
        id: 'log-rt',
        timestamp: DateTime(2026, 3, 10, 8, 15, 30),
        method: 'POST',
        endpoint: '/api/games',
        request: {'gameType': 'target_tag', 'players': ['Alice', 'Bob']},
        response: {'gameId': 'g-1', 'status': 'started'},
        userNote: 'Started a game',
      );

      final json = original.toJson();
      final restored = ApiLogEntry.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.timestamp, original.timestamp);
      expect(restored.method, original.method);
      expect(restored.endpoint, original.endpoint);
      expect(restored.request, original.request);
      expect(restored.response, original.response);
      expect(restored.userNote, original.userNote);
    });

    test('round-trip preserves null optional fields', () {
      final original = ApiLogEntry(
        id: 'log-rt-null',
        timestamp: testTimestamp,
        method: 'GET',
        endpoint: '/api/status',
      );

      final json = original.toJson();
      final restored = ApiLogEntry.fromJson(json);

      expect(restored.request, isNull);
      expect(restored.response, isNull);
      expect(restored.userNote, '');
    });

    test('handles empty string fields', () {
      final entry = ApiLogEntry(
        id: '',
        timestamp: testTimestamp,
        method: '',
        endpoint: '',
      );

      final json = entry.toJson();
      final restored = ApiLogEntry.fromJson(json);

      expect(restored.id, '');
      expect(restored.method, '');
      expect(restored.endpoint, '');
    });

    test('userNote is mutable', () {
      final entry = ApiLogEntry(
        id: 'log-mutable',
        timestamp: testTimestamp,
        method: 'GET',
        endpoint: '/api/test',
      );

      expect(entry.userNote, '');
      entry.userNote = 'Updated note';
      expect(entry.userNote, 'Updated note');
    });

    test('handles complex nested request and response data', () {
      final complexRequest = {
        'players': [
          {'name': 'Alice', 'score': 100},
          {'name': 'Bob', 'score': 200},
        ],
        'settings': {
          'mode': 'advanced',
          'options': {'timer': true, 'rounds': 5},
        },
      };
      final complexResponse = {
        'success': true,
        'data': {'gameId': 'g-complex'},
      };

      final entry = ApiLogEntry(
        id: 'log-complex',
        timestamp: testTimestamp,
        method: 'POST',
        endpoint: '/api/games',
        request: complexRequest,
        response: complexResponse,
      );

      final json = entry.toJson();
      final restored = ApiLogEntry.fromJson(json);

      expect(restored.request, complexRequest);
      expect(restored.response, complexResponse);
    });
  });

  group('SavedGameMetadata', () {
    final testSavedAt = DateTime(2026, 4, 14, 15, 30, 0);

    test('constructor creates valid instance with all fields', () {
      final metadata = SavedGameMetadata(
        id: 'game-001',
        gameType: 'target_tag',
        savedAt: testSavedAt,
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Round 3 of 5',
        gameModeName: 'Classic',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '150',
        gameState: {'round': 3, 'scores': {'Alice': 150, 'Bob': 100}},
        waitingForTakeout: true,
      );

      expect(metadata.id, 'game-001');
      expect(metadata.gameType, 'target_tag');
      expect(metadata.savedAt, testSavedAt);
      expect(metadata.playerNames, ['Alice', 'Bob']);
      expect(metadata.progressInfo, 'Round 3 of 5');
      expect(metadata.gameModeName, 'Classic');
      expect(metadata.leadingPlayerName, 'Alice');
      expect(metadata.leadingPlayerScore, '150');
      expect(metadata.gameState, {'round': 3, 'scores': {'Alice': 150, 'Bob': 100}});
      expect(metadata.waitingForTakeout, true);
    });

    test('waitingForTakeout defaults to false', () {
      final metadata = SavedGameMetadata(
        id: 'game-002',
        gameType: 'carnival_derby',
        savedAt: testSavedAt,
        playerNames: ['Charlie'],
        progressInfo: 'Race 1',
        gameModeName: 'Standard',
        leadingPlayerName: 'Charlie',
        leadingPlayerScore: '50',
        gameState: {},
      );

      expect(metadata.waitingForTakeout, false);
    });

    test('factory create generates a UUID id', () {
      final metadata = SavedGameMetadata.create(
        gameType: 'monster_mash',
        playerNames: ['Alice'],
        progressInfo: 'Battle 1',
        gameModeName: 'Arena',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '10',
        gameState: {'hp': 100},
      );

      expect(metadata.id, isNotEmpty);
      // UUID v4 format: 8-4-4-4-12 hex characters
      expect(metadata.id.length, 36);
      expect(metadata.id.contains('-'), true);
    });

    test('factory create uses existingId when provided', () {
      final metadata = SavedGameMetadata.create(
        gameType: 'target_tag',
        playerNames: ['Alice'],
        progressInfo: 'Round 1',
        gameModeName: 'Classic',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '0',
        gameState: {},
        existingId: 'my-custom-id',
      );

      expect(metadata.id, 'my-custom-id');
    });

    test('factory create sets savedAt to approximately now', () {
      final before = DateTime.now();
      final metadata = SavedGameMetadata.create(
        gameType: 'reef_royale',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Turn 5',
        gameModeName: 'Quick',
        leadingPlayerName: 'Bob',
        leadingPlayerScore: '30',
        gameState: {},
      );
      final after = DateTime.now();

      expect(metadata.savedAt.isAfter(before) || metadata.savedAt.isAtSameMomentAs(before), true);
      expect(metadata.savedAt.isBefore(after) || metadata.savedAt.isAtSameMomentAs(after), true);
    });

    test('factory create accepts waitingForTakeout parameter', () {
      final metadata = SavedGameMetadata.create(
        gameType: 'target_tag',
        playerNames: ['Alice'],
        progressInfo: 'Round 1',
        gameModeName: 'Classic',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '0',
        gameState: {},
        waitingForTakeout: true,
      );

      expect(metadata.waitingForTakeout, true);
    });

    test('factory create defaults waitingForTakeout to false', () {
      final metadata = SavedGameMetadata.create(
        gameType: 'target_tag',
        playerNames: ['Alice'],
        progressInfo: 'Round 1',
        gameModeName: 'Classic',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '0',
        gameState: {},
      );

      expect(metadata.waitingForTakeout, false);
    });

    test('toJson includes all fields', () {
      final metadata = SavedGameMetadata(
        id: 'game-json',
        gameType: 'target_tag',
        savedAt: testSavedAt,
        playerNames: ['Alice', 'Bob', 'Charlie'],
        progressInfo: 'Round 2 of 5',
        gameModeName: 'Classic',
        leadingPlayerName: 'Bob',
        leadingPlayerScore: '200',
        gameState: {'active': true, 'round': 2},
        waitingForTakeout: true,
      );
      final json = metadata.toJson();

      expect(json['id'], 'game-json');
      expect(json['gameType'], 'target_tag');
      expect(json['savedAt'], testSavedAt.toIso8601String());
      expect(json['playerNames'], ['Alice', 'Bob', 'Charlie']);
      expect(json['progressInfo'], 'Round 2 of 5');
      expect(json['gameModeName'], 'Classic');
      expect(json['leadingPlayerName'], 'Bob');
      expect(json['leadingPlayerScore'], '200');
      expect(json['gameState'], {'active': true, 'round': 2});
      expect(json['waitingForTakeout'], true);
      expect(json.keys.length, 10);
    });

    test('toJson serializes savedAt as ISO 8601 string', () {
      final metadata = SavedGameMetadata(
        id: 'game-date',
        gameType: 'test',
        savedAt: DateTime(2025, 12, 25, 8, 0, 0),
        playerNames: [],
        progressInfo: '',
        gameModeName: '',
        leadingPlayerName: '',
        leadingPlayerScore: '',
        gameState: {},
      );
      final json = metadata.toJson();

      expect(json['savedAt'], isA<String>());
      expect(json['savedAt'], contains('2025-12-25'));
    });

    test('fromJson restores all fields correctly', () {
      final json = {
        'id': 'game-from',
        'gameType': 'carnival_derby',
        'savedAt': '2026-04-14T15:30:00.000',
        'playerNames': ['Dave', 'Eve'],
        'progressInfo': 'Race 2 of 3',
        'gameModeName': 'Sprint',
        'leadingPlayerName': 'Eve',
        'leadingPlayerScore': '75',
        'gameState': {'race': 2, 'positions': {'Dave': 3, 'Eve': 5}},
        'waitingForTakeout': true,
      };

      final metadata = SavedGameMetadata.fromJson(json);

      expect(metadata.id, 'game-from');
      expect(metadata.gameType, 'carnival_derby');
      expect(metadata.savedAt.year, 2026);
      expect(metadata.savedAt.month, 4);
      expect(metadata.savedAt.day, 14);
      expect(metadata.playerNames, ['Dave', 'Eve']);
      expect(metadata.progressInfo, 'Race 2 of 3');
      expect(metadata.gameModeName, 'Sprint');
      expect(metadata.leadingPlayerName, 'Eve');
      expect(metadata.leadingPlayerScore, '75');
      expect(metadata.gameState['race'], 2);
      expect(metadata.waitingForTakeout, true);
    });

    test('fromJson defaults waitingForTakeout to false when missing', () {
      final json = {
        'id': 'game-old',
        'gameType': 'target_tag',
        'savedAt': '2026-04-14T15:30:00.000',
        'playerNames': ['Alice'],
        'progressInfo': 'Round 1',
        'gameModeName': 'Classic',
        'leadingPlayerName': 'Alice',
        'leadingPlayerScore': '0',
        'gameState': {},
      };

      final metadata = SavedGameMetadata.fromJson(json);

      expect(metadata.waitingForTakeout, false);
    });

    test('fromJson defaults waitingForTakeout to false when null', () {
      final json = {
        'id': 'game-null-wft',
        'gameType': 'target_tag',
        'savedAt': '2026-04-14T15:30:00.000',
        'playerNames': ['Alice'],
        'progressInfo': 'Round 1',
        'gameModeName': 'Classic',
        'leadingPlayerName': 'Alice',
        'leadingPlayerScore': '0',
        'gameState': {},
        'waitingForTakeout': null,
      };

      final metadata = SavedGameMetadata.fromJson(json);

      expect(metadata.waitingForTakeout, false);
    });

    test('round-trip serialization preserves all data', () {
      final original = SavedGameMetadata(
        id: 'game-rt',
        gameType: 'monster_mash',
        savedAt: DateTime(2026, 2, 28, 20, 45, 15),
        playerNames: ['Alice', 'Bob', 'Charlie', 'Dave'],
        progressInfo: 'Battle 4 of 6',
        gameModeName: 'Team Battle',
        leadingPlayerName: 'Charlie',
        leadingPlayerScore: '350',
        gameState: {
          'battle': 4,
          'teams': {
            'red': ['Alice', 'Bob'],
            'blue': ['Charlie', 'Dave'],
          },
          'scores': {'Alice': 200, 'Bob': 150, 'Charlie': 350, 'Dave': 300},
        },
        waitingForTakeout: true,
      );

      final json = original.toJson();
      final restored = SavedGameMetadata.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.gameType, original.gameType);
      expect(restored.savedAt, original.savedAt);
      expect(restored.playerNames, original.playerNames);
      expect(restored.progressInfo, original.progressInfo);
      expect(restored.gameModeName, original.gameModeName);
      expect(restored.leadingPlayerName, original.leadingPlayerName);
      expect(restored.leadingPlayerScore, original.leadingPlayerScore);
      expect(restored.gameState['battle'], 4);
      expect(restored.waitingForTakeout, original.waitingForTakeout);
    });

    test('round-trip preserves default waitingForTakeout', () {
      final original = SavedGameMetadata(
        id: 'game-rt-def',
        gameType: 'test',
        savedAt: testSavedAt,
        playerNames: ['Alice'],
        progressInfo: '',
        gameModeName: '',
        leadingPlayerName: '',
        leadingPlayerScore: '',
        gameState: {},
      );

      final json = original.toJson();
      final restored = SavedGameMetadata.fromJson(json);

      expect(restored.waitingForTakeout, false);
    });

    test('handles empty playerNames list', () {
      final metadata = SavedGameMetadata(
        id: 'game-empty-players',
        gameType: 'test',
        savedAt: testSavedAt,
        playerNames: [],
        progressInfo: '',
        gameModeName: '',
        leadingPlayerName: '',
        leadingPlayerScore: '',
        gameState: {},
      );

      final json = metadata.toJson();
      final restored = SavedGameMetadata.fromJson(json);

      expect(restored.playerNames, isEmpty);
    });

    test('handles empty gameState map', () {
      final metadata = SavedGameMetadata(
        id: 'game-empty-state',
        gameType: 'test',
        savedAt: testSavedAt,
        playerNames: ['Alice'],
        progressInfo: '',
        gameModeName: '',
        leadingPlayerName: '',
        leadingPlayerScore: '',
        gameState: {},
      );

      final json = metadata.toJson();
      final restored = SavedGameMetadata.fromJson(json);

      expect(restored.gameState, isEmpty);
    });

    test('handles empty string fields', () {
      final metadata = SavedGameMetadata(
        id: '',
        gameType: '',
        savedAt: testSavedAt,
        playerNames: [],
        progressInfo: '',
        gameModeName: '',
        leadingPlayerName: '',
        leadingPlayerScore: '',
        gameState: {},
      );

      final json = metadata.toJson();
      final restored = SavedGameMetadata.fromJson(json);

      expect(restored.id, '');
      expect(restored.gameType, '');
      expect(restored.progressInfo, '');
      expect(restored.gameModeName, '');
      expect(restored.leadingPlayerName, '');
      expect(restored.leadingPlayerScore, '');
    });

    test('handles complex nested gameState', () {
      final complexState = {
        'players': [
          {'name': 'Alice', 'hp': 100, 'buffs': ['shield', 'speed']},
          {'name': 'Bob', 'hp': 80, 'buffs': []},
        ],
        'board': {
          'width': 10,
          'height': 10,
          'cells': [
            [0, 1, 2],
            [3, 4, 5],
          ],
        },
        'config': {
          'difficulty': 'hard',
          'timer': true,
        },
      };

      final metadata = SavedGameMetadata(
        id: 'game-complex',
        gameType: 'test',
        savedAt: testSavedAt,
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Complex state',
        gameModeName: 'Advanced',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '100',
        gameState: complexState,
      );

      final json = metadata.toJson();
      final restored = SavedGameMetadata.fromJson(json);

      expect(restored.gameState['config'], {'difficulty': 'hard', 'timer': true});
    });

    test('factory create generates unique IDs', () {
      final metadata1 = SavedGameMetadata.create(
        gameType: 'test',
        playerNames: ['Alice'],
        progressInfo: '',
        gameModeName: '',
        leadingPlayerName: '',
        leadingPlayerScore: '',
        gameState: {},
      );
      final metadata2 = SavedGameMetadata.create(
        gameType: 'test',
        playerNames: ['Alice'],
        progressInfo: '',
        gameModeName: '',
        leadingPlayerName: '',
        leadingPlayerScore: '',
        gameState: {},
      );

      expect(metadata1.id, isNot(metadata2.id));
    });

    test('handles many player names', () {
      final manyPlayers = List.generate(8, (i) => 'Player ${i + 1}');

      final metadata = SavedGameMetadata(
        id: 'game-many',
        gameType: 'reef_royale',
        savedAt: testSavedAt,
        playerNames: manyPlayers,
        progressInfo: 'Turn 1',
        gameModeName: 'Standard',
        leadingPlayerName: 'Player 1',
        leadingPlayerScore: '0',
        gameState: {},
      );

      final json = metadata.toJson();
      final restored = SavedGameMetadata.fromJson(json);

      expect(restored.playerNames.length, 8);
      expect(restored.playerNames[0], 'Player 1');
      expect(restored.playerNames[7], 'Player 8');
    });
  });
}
