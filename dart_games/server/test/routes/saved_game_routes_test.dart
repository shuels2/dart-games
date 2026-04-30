import 'dart:convert';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/saved_game_routes.dart';

void main() {
  late Database database;
  late Function handler;

  Map<String, dynamic> makeGame({
    String id = 'game-1',
    String gameType = 'CarnivalDerby',
    String savedAt = '2026-01-01T00:00:00Z',
    List<String> playerNames = const ['Alice', 'Bob'],
    String progressInfo = 'Round 3 of 5',
    String gameModeName = 'Classic',
    String leadingPlayerName = 'Alice',
    String leadingPlayerScore = '15',
    Map<String, dynamic> gameState = const {'round': 3, 'scores': [15, 12]},
    bool waitingForTakeout = false,
  }) {
    return {
      'id': id,
      'gameType': gameType,
      'savedAt': savedAt,
      'playerNames': playerNames,
      'progressInfo': progressInfo,
      'gameModeName': gameModeName,
      'leadingPlayerName': leadingPlayerName,
      'leadingPlayerScore': leadingPlayerScore,
      'gameState': gameState,
      'waitingForTakeout': waitingForTakeout,
    };
  }

  Future<Response> sendGet(String path) async {
    return await handler(Request('GET', Uri.parse('http://localhost$path')));
  }

  Future<Response> sendPost(String path, Map<String, dynamic> body) async {
    return await handler(Request(
      'POST',
      Uri.parse('http://localhost$path'),
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    ));
  }

  Future<Response> sendDelete(String path) async {
    return await handler(Request('DELETE', Uri.parse('http://localhost$path')));
  }

  setUp(() {
    database = Database(':memory:');
    final routes = SavedGameRoutes(database.rawDb);
    handler = routes.router.call;
  });

  tearDown(() {
    database.close();
  });

  group('SavedGameRoutes', () {
    test('GET / returns empty list initially', () async {
      final response = await sendGet('/');
      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, isEmpty);
    });

    test('POST / saves game and returns 200 with game data', () async {
      final game = makeGame();
      final response = await sendPost('/', game);
      expect(response.statusCode, equals(200));

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['id'], equals('game-1'));
      expect(body['gameType'], equals('CarnivalDerby'));
      expect(body['savedAt'], equals('2026-01-01T00:00:00Z'));
      expect(body['playerNames'], equals(['Alice', 'Bob']));
      expect(body['progressInfo'], equals('Round 3 of 5'));
      expect(body['gameModeName'], equals('Classic'));
      expect(body['leadingPlayerName'], equals('Alice'));
      expect(body['leadingPlayerScore'], equals('15'));
      expect(body['waitingForTakeout'], isFalse);
    });

    test('GET / returns saved game in list', () async {
      await sendPost('/', makeGame());

      final response = await sendGet('/');
      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, hasLength(1));
      expect(body[0]['id'], equals('game-1'));
      expect(body[0]['gameType'], equals('CarnivalDerby'));
    });

    test('GET /<gameType> filters by type', () async {
      await sendPost('/', makeGame(id: 'game-1', gameType: 'CarnivalDerby'));
      await sendPost('/', makeGame(id: 'game-2', gameType: 'TargetTag'));

      final response = await sendGet('/CarnivalDerby');
      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, hasLength(1));
      expect(body[0]['id'], equals('game-1'));
      expect(body[0]['gameType'], equals('CarnivalDerby'));
    });

    test('GET /<gameType> returns empty list for unknown type', () async {
      await sendPost('/', makeGame(gameType: 'CarnivalDerby'));

      final response = await sendGet('/UnknownGame');
      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, isEmpty);
    });

    test('POST / upserts - saving same id twice results in one record',
        () async {
      await sendPost(
          '/',
          makeGame(
            id: 'game-1',
            progressInfo: 'Round 1 of 5',
          ));
      await sendPost(
          '/',
          makeGame(
            id: 'game-1',
            progressInfo: 'Round 4 of 5',
          ));

      final response = await sendGet('/');
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, hasLength(1));
      expect(body[0]['id'], equals('game-1'));
      expect(body[0]['progressInfo'], equals('Round 4 of 5'));
    });

    test('DELETE /<id> removes game and returns 204', () async {
      await sendPost('/', makeGame(id: 'game-1'));

      final deleteResponse = await sendDelete('/game-1');
      expect(deleteResponse.statusCode, equals(204));

      final listResponse = await sendGet('/');
      final body = jsonDecode(await listResponse.readAsString()) as List;
      expect(body, isEmpty);
    });

    test('DELETE /type/<gameType> removes all of that type', () async {
      await sendPost('/', makeGame(id: 'game-1', gameType: 'CarnivalDerby'));
      await sendPost('/', makeGame(id: 'game-2', gameType: 'CarnivalDerby'));
      await sendPost('/', makeGame(id: 'game-3', gameType: 'TargetTag'));

      final deleteResponse = await sendDelete('/type/CarnivalDerby');
      expect(deleteResponse.statusCode, equals(204));

      final allResponse = await sendGet('/');
      final allBody = jsonDecode(await allResponse.readAsString()) as List;
      expect(allBody, hasLength(1));
      expect(allBody[0]['id'], equals('game-3'));
      expect(allBody[0]['gameType'], equals('TargetTag'));
    });

    test('multiple game types can be stored and filtered independently',
        () async {
      await sendPost('/', makeGame(id: 'cd-1', gameType: 'CarnivalDerby'));
      await sendPost('/', makeGame(id: 'cd-2', gameType: 'CarnivalDerby'));
      await sendPost('/', makeGame(id: 'tt-1', gameType: 'TargetTag'));
      await sendPost('/', makeGame(id: 'mm-1', gameType: 'MonsterMash'));

      final allResponse = await sendGet('/');
      final allBody = jsonDecode(await allResponse.readAsString()) as List;
      expect(allBody, hasLength(4));

      final cdResponse = await sendGet('/CarnivalDerby');
      final cdBody = jsonDecode(await cdResponse.readAsString()) as List;
      expect(cdBody, hasLength(2));

      final ttResponse = await sendGet('/TargetTag');
      final ttBody = jsonDecode(await ttResponse.readAsString()) as List;
      expect(ttBody, hasLength(1));

      final mmResponse = await sendGet('/MonsterMash');
      final mmBody = jsonDecode(await mmResponse.readAsString()) as List;
      expect(mmBody, hasLength(1));
    });

    test('saved game preserves complex gameState with nested objects',
        () async {
      final complexState = {
        'round': 3,
        'scores': [15, 12],
        'players': {
          'alice': {'position': 5, 'items': ['sword', 'shield']},
          'bob': {'position': 3, 'items': ['potion']},
        },
        'board': [
          [1, 0, 0],
          [0, 2, 0],
          [0, 0, 1],
        ],
        'metadata': {'startTime': '2026-01-01T00:00:00Z', 'turnCount': 12},
      };

      await sendPost('/', makeGame(gameState: complexState));

      final response = await sendGet('/');
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, hasLength(1));

      final returnedState = body[0]['gameState'] as Map<String, dynamic>;
      expect(returnedState['round'], equals(3));
      expect(returnedState['scores'], equals([15, 12]));
      expect(returnedState['players']['alice']['position'], equals(5));
      expect(
          returnedState['players']['alice']['items'],
          equals(['sword', 'shield']));
      expect(returnedState['board'][0], equals([1, 0, 0]));
      expect(returnedState['metadata']['turnCount'], equals(12));
    });

    test('saved game preserves playerNames list correctly', () async {
      final names = ['Alice', 'Bob', 'Charlie', 'Diana'];
      await sendPost('/', makeGame(playerNames: names));

      final response = await sendGet('/');
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body[0]['playerNames'], equals(names));
    });

    test('waitingForTakeout true roundtrips correctly', () async {
      await sendPost(
          '/', makeGame(id: 'game-wait', waitingForTakeout: true));

      final response = await sendGet('/');
      final body = jsonDecode(await response.readAsString()) as List;
      final game =
          body.firstWhere((g) => g['id'] == 'game-wait');
      expect(game['waitingForTakeout'], isTrue);
    });

    test('waitingForTakeout false roundtrips correctly', () async {
      await sendPost(
          '/', makeGame(id: 'game-no-wait', waitingForTakeout: false));

      final response = await sendGet('/');
      final body = jsonDecode(await response.readAsString()) as List;
      final game =
          body.firstWhere((g) => g['id'] == 'game-no-wait');
      expect(game['waitingForTakeout'], isFalse);
    });
  });
}
