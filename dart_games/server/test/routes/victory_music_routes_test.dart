import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/victory_music_routes.dart';

void main() {
  late Database database;
  late Function handler;
  late String dataDir;

  // "Hello World" in base64 - just needs to be valid base64, not valid audio
  const testFileData = 'SGVsbG8gV29ybGQ=';
  // Different content for a second file
  const testFileData2 = 'R29vZGJ5ZSBXb3JsZA=='; // "Goodbye World"

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

  Future<Response> sendPut(String path) async {
    return await handler(Request('PUT', Uri.parse('http://localhost$path')));
  }

  Future<Response> sendDelete(String path) async {
    return await handler(Request('DELETE', Uri.parse('http://localhost$path')));
  }

  Future<Map<String, dynamic>> uploadMusic({
    String fileName = 'song.mp3',
    String fileData = testFileData,
  }) async {
    final response = await sendPost('/', {
      'fileName': fileName,
      'fileData': fileData,
    });
    return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  }

  setUp(() {
    database = Database(':memory:');
    dataDir = Directory.systemTemp.createTempSync('music_test_').path;
    final routes = VictoryMusicRoutes(database.rawDb, dataDir);
    handler = routes.router.call;
  });

  tearDown(() {
    database.close();
    final dir = Directory(dataDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  group('VictoryMusicRoutes', () {
    test('GET / returns empty list initially', () async {
      final response = await sendGet('/');
      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, isEmpty);
    });

    test('POST / uploads music file and returns 201 with music info',
        () async {
      final response = await sendPost('/', {
        'fileName': 'victory.mp3',
        'fileData': testFileData,
      });
      expect(response.statusCode, equals(201));

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['id'], isNotEmpty);
      expect(body['fileName'], equals('victory.mp3'));
      expect(body['filePath'], isNotEmpty);
      expect(body['isCurrent'], isFalse);
      expect(body['createdAt'], isNotEmpty);
    });

    test('GET / returns uploaded music in list', () async {
      await uploadMusic(fileName: 'track.mp3');

      final response = await sendGet('/');
      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as List;
      expect(body, hasLength(1));
      expect(body[0]['fileName'], equals('track.mp3'));
    });

    test('GET /current returns 404 when no current set', () async {
      final response = await sendGet('/current');
      expect(response.statusCode, equals(404));

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['error'], contains('No current music'));
    });

    test('PUT /<id>/current sets music as current', () async {
      final music = await uploadMusic(fileName: 'song.mp3');
      final id = music['id'] as String;

      final response = await sendPut('/$id/current');
      expect(response.statusCode, equals(200));

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['id'], equals(id));
      expect(body['isCurrent'], isTrue);
    });

    test('GET /current returns the current music', () async {
      final music = await uploadMusic(fileName: 'current_song.mp3');
      final id = music['id'] as String;
      await sendPut('/$id/current');

      final response = await sendGet('/current');
      expect(response.statusCode, equals(200));

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['id'], equals(id));
      expect(body['fileName'], equals('current_song.mp3'));
      expect(body['isCurrent'], isTrue);
    });

    test('PUT /<id>/current returns 404 for unknown id', () async {
      final response = await sendPut('/nonexistent-id/current');
      expect(response.statusCode, equals(404));

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['error'], contains('not found'));
    });

    test('GET /<id>/file downloads the file', () async {
      final music = await uploadMusic(
        fileName: 'download_test.mp3',
        fileData: testFileData,
      );
      final id = music['id'] as String;

      final response = await sendGet('/$id/file');
      expect(response.statusCode, equals(200));

      final bytes = await response.read().fold<List<int>>(
          [], (prev, chunk) => prev..addAll(chunk));
      expect(bytes, isNotEmpty);
    });

    test('GET /<id>/file returns 404 for unknown id', () async {
      final response = await sendGet('/nonexistent-id/file');
      expect(response.statusCode, equals(404));

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['error'], contains('not found'));
    });

    test('DELETE /<id> removes music and file from disk and returns 204',
        () async {
      final music = await uploadMusic(fileName: 'delete_me.mp3');
      final id = music['id'] as String;
      final filePath = music['filePath'] as String;

      // Verify file exists on disk before delete
      expect(File(filePath).existsSync(), isTrue);

      final deleteResponse = await sendDelete('/$id');
      expect(deleteResponse.statusCode, equals(204));

      // Verify removed from database
      final listResponse = await sendGet('/');
      final body = jsonDecode(await listResponse.readAsString()) as List;
      expect(body, isEmpty);

      // Verify file removed from disk
      expect(File(filePath).existsSync(), isFalse);
    });

    test('DELETE / removes all music and files and returns 204', () async {
      final music1 = await uploadMusic(fileName: 'song1.mp3');
      final music2 =
          await uploadMusic(fileName: 'song2.mp3', fileData: testFileData2);
      final filePath1 = music1['filePath'] as String;
      final filePath2 = music2['filePath'] as String;

      // Verify files exist
      expect(File(filePath1).existsSync(), isTrue);
      expect(File(filePath2).existsSync(), isTrue);

      final deleteResponse = await sendDelete('/');
      expect(deleteResponse.statusCode, equals(204));

      // Verify database is empty
      final listResponse = await sendGet('/');
      final body = jsonDecode(await listResponse.readAsString()) as List;
      expect(body, isEmpty);

      // Verify files removed from disk
      expect(File(filePath1).existsSync(), isFalse);
      expect(File(filePath2).existsSync(), isFalse);
    });

    test('upload multiple files and set different ones as current', () async {
      final music1 = await uploadMusic(fileName: 'track1.mp3');
      final music2 =
          await uploadMusic(fileName: 'track2.mp3', fileData: testFileData2);
      final id1 = music1['id'] as String;
      final id2 = music2['id'] as String;

      // Set first as current
      await sendPut('/$id1/current');
      var currentResponse = await sendGet('/current');
      var currentBody = jsonDecode(await currentResponse.readAsString())
          as Map<String, dynamic>;
      expect(currentBody['id'], equals(id1));
      expect(currentBody['fileName'], equals('track1.mp3'));

      // Set second as current
      await sendPut('/$id2/current');
      currentResponse = await sendGet('/current');
      currentBody = jsonDecode(await currentResponse.readAsString())
          as Map<String, dynamic>;
      expect(currentBody['id'], equals(id2));
      expect(currentBody['fileName'], equals('track2.mp3'));
    });

    test('setting new current clears old current', () async {
      final music1 = await uploadMusic(fileName: 'old.mp3');
      final music2 =
          await uploadMusic(fileName: 'new.mp3', fileData: testFileData2);
      final id1 = music1['id'] as String;
      final id2 = music2['id'] as String;

      // Set first as current
      await sendPut('/$id1/current');

      // Set second as current
      await sendPut('/$id2/current');

      // List all and verify only one is current
      final listResponse = await sendGet('/');
      final body = jsonDecode(await listResponse.readAsString()) as List;
      expect(body, hasLength(2));

      final currentItems = body.where((m) => m['isCurrent'] == true).toList();
      expect(currentItems, hasLength(1));
      expect(currentItems[0]['id'], equals(id2));

      final nonCurrentItems =
          body.where((m) => m['isCurrent'] == false).toList();
      expect(nonCurrentItems, hasLength(1));
      expect(nonCurrentItems[0]['id'], equals(id1));
    });

    test('file data is correctly stored and retrieved (base64 roundtrip)',
        () async {
      final music = await uploadMusic(
        fileName: 'roundtrip.mp3',
        fileData: testFileData,
      );
      final id = music['id'] as String;

      // Download the file
      final response = await sendGet('/$id/file');
      expect(response.statusCode, equals(200));

      final downloadedBytes = await response.read().fold<List<int>>(
          [], (prev, chunk) => prev..addAll(chunk));

      // Decode the original base64 and compare
      final originalBytes = base64Decode(testFileData);
      expect(downloadedBytes, equals(originalBytes));
    });
  });
}
