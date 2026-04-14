import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/victory_music_service.dart';
import 'package:dart_games/models/victory_music_file.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;

  group('VictoryMusicService', () {
    late VictoryMusicService service;

    setUp(() {
      mockServer = MockApiServer();
      service = VictoryMusicService();
      service.initializeApi(mockServer.apiClient);
      service.resetForTesting();
    });

    test('is a singleton', () {
      final service1 = VictoryMusicService();
      final service2 = VictoryMusicService();

      expect(identical(service1, service2), isTrue);
    });

    test('initializes with empty music list', () async {
      final files = await service.getMusicFiles();

      expect(files, isEmpty);
    });

    test('hasCustomMusic returns false when empty', () async {
      final hasMusic = await service.hasCustomMusic();

      expect(hasMusic, isFalse);
    });

    test('getRandomMusicSource returns null when empty', () async {
      final source = await service.getRandomMusicSource();

      expect(source, isNull);
    });

    test('getMusicFiles returns unmodifiable list', () async {
      final files = await service.getMusicFiles();

      expect(() => files.add(VictoryMusicFile(
        id: 'test',
        name: 'test',
        source: 'test',
        addedDate: DateTime.now(),
      )), throwsUnsupportedError);
    });

    test('addMusicFile with fileBytes succeeds', () async {
      final bytes = Uint8List.fromList([0, 1, 2, 3, 4]);
      await service.addMusicFile(
        fileName: 'victory.mp3',
        fileBytes: bytes,
      );

      final files = await service.getMusicFiles();
      expect(files, hasLength(1));
      expect(files[0].name, 'victory.mp3');
    });

    test('addMusicFile with dataUrl succeeds', () async {
      final bytes = Uint8List.fromList([0, 1, 2, 3, 4]);
      final b64 = base64Encode(bytes);
      final dataUrl = 'data:audio/mpeg;base64,$b64';

      await service.addMusicFile(
        fileName: 'victory.mp3',
        dataUrl: dataUrl,
      );

      final files = await service.getMusicFiles();
      expect(files, hasLength(1));
      expect(files[0].name, 'victory.mp3');
    });

    test('throws exception when adding file without data', () async {
      expect(
        () async => await service.addMusicFile(
          fileName: 'test.mp3',
          // No fileBytes or dataUrl
        ),
        throwsException,
      );
    });

    test('clearAllMusic clears all files', () async {
      final bytes = Uint8List.fromList([0, 1, 2]);
      await service.addMusicFile(fileName: 'song1.mp3', fileBytes: bytes);
      await service.addMusicFile(fileName: 'song2.mp3', fileBytes: bytes);

      await service.clearAllMusic();
      final files = await service.getMusicFiles();

      expect(files, isEmpty);
    });

    test('hasCustomMusic returns true after adding files', () async {
      final initialState = await service.hasCustomMusic();
      expect(initialState, isFalse);

      final bytes = Uint8List.fromList([0, 1, 2]);
      await service.addMusicFile(fileName: 'song.mp3', fileBytes: bytes);

      final afterAdd = await service.hasCustomMusic();
      expect(afterAdd, isTrue);
    });

    test('deprecated getMusicSource calls getRandomMusicSource', () async {
      // Both should return null when no music is available
      final source1 = await service.getMusicSource();
      final source2 = await service.getRandomMusicSource();

      expect(source1, source2);
    });

    test('deprecated getMusicName returns null when empty', () async {
      final name = await service.getMusicName();

      expect(name, isNull);
    });

    test('deprecated clearMusic calls clearAllMusic', () async {
      await service.clearMusic();
      final files = await service.getMusicFiles();

      expect(files, isEmpty);
    });

    test('multiple initializations are idempotent', () async {
      await service.initialize();
      await service.initialize();
      await service.initialize();

      final files = await service.getMusicFiles();
      expect(files, isEmpty);
    });
  });

  group('VictoryMusicService - File Management', () {
    late VictoryMusicService service;

    setUp(() {
      mockServer = MockApiServer();
      service = VictoryMusicService();
      service.initializeApi(mockServer.apiClient);
      service.resetForTesting();
    });

    test('removeMusicFile removes by ID', () async {
      final bytes = Uint8List.fromList([0, 1, 2]);
      await service.addMusicFile(fileName: 'song1.mp3', fileBytes: bytes);
      await service.addMusicFile(fileName: 'song2.mp3', fileBytes: bytes);

      final files = await service.getMusicFiles();
      expect(files, hasLength(2));

      await service.removeMusicFile(files[0].id);

      final remaining = await service.getMusicFiles();
      expect(remaining, hasLength(1));
      expect(remaining[0].name, 'song2.mp3');
    });

    test('service persists across multiple get calls', () async {
      final files1 = await service.getMusicFiles();
      final files2 = await service.getMusicFiles();

      expect(files1.length, files2.length);
    });
  });

  group('VictoryMusicService - Backward Compatibility', () {
    late VictoryMusicService service;

    setUp(() {
      mockServer = MockApiServer();
      service = VictoryMusicService();
      service.initializeApi(mockServer.apiClient);
      service.resetForTesting();
    });

    test('deprecated saveMusic throws without proper data', () async {
      expect(
        () async => await service.saveMusic(
          fileName: 'test.mp3',
          // Missing fileBytes and filePath
        ),
        throwsException,
      );
    });

    test('all deprecated methods exist and are callable', () async {
      // Verify backward compatibility methods exist
      expect(service.getMusicSource, isNotNull);
      expect(service.getMusicName, isNotNull);
      expect(service.saveMusic, isNotNull);
      expect(service.clearMusic, isNotNull);
    });
  });

  group('VictoryMusicService - Random Selection', () {
    late VictoryMusicService service;

    setUp(() {
      mockServer = MockApiServer();
      service = VictoryMusicService();
      service.initializeApi(mockServer.apiClient);
      service.resetForTesting();
    });

    test('getRandomMusicSource with single file returns that file', () async {
      final bytes = Uint8List.fromList([0, 1, 2]);
      await service.addMusicFile(fileName: 'only.mp3', fileBytes: bytes);

      final source = await service.getRandomMusicSource();
      expect(source, isNotNull);
      expect(source, contains('/api/v1/music/'));
    });

    test('getRandomMusicSource returns one of multiple files', () async {
      final bytes = Uint8List.fromList([0, 1, 2]);
      await service.addMusicFile(fileName: 'song1.mp3', fileBytes: bytes);
      await service.addMusicFile(fileName: 'song2.mp3', fileBytes: bytes);
      await service.addMusicFile(fileName: 'song3.mp3', fileBytes: bytes);

      final source = await service.getRandomMusicSource();
      expect(source, isNotNull);
      expect(source, contains('/api/v1/music/'));
    });
  });

  group('VictoryMusicService - Error Handling', () {
    late VictoryMusicService service;

    setUp(() {
      mockServer = MockApiServer();
      service = VictoryMusicService();
      service.initializeApi(mockServer.apiClient);
      service.resetForTesting();
    });

    test('handles empty storage gracefully', () async {
      await service.initialize();

      // Should not throw
      expect(await service.hasCustomMusic(), isFalse);
    });

    test('getMusicFiles handles empty storage', () async {
      final files = await service.getMusicFiles();

      expect(files, isNotNull);
      expect(files, isEmpty);
    });
  });

  group('VictoryMusicService - Data Persistence', () {
    late VictoryMusicService service;

    setUp(() {
      mockServer = MockApiServer();
      service = VictoryMusicService();
      service.initializeApi(mockServer.apiClient);
      service.resetForTesting();
    });

    test('service maintains state across calls', () async {
      final files1 = await service.getMusicFiles();
      final files2 = await service.getMusicFiles();

      expect(files1.length, equals(files2.length));
    });

    test('clearAllMusic resets state', () async {
      final bytes = Uint8List.fromList([0, 1, 2]);
      await service.addMusicFile(fileName: 'song.mp3', fileBytes: bytes);

      await service.clearAllMusic();
      final files = await service.getMusicFiles();

      expect(files, isEmpty);
    });
  });
}
