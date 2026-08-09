import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/game_announcement_queue_service.dart';
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

  // ─── WS02 2.9 ─────────────────────────────────────────────────────────

  group('VictoryMusicService.sourceFor', () {
    // Regression cover for a real bug: every one of the ten hand-written
    // `_playVictoryMusic` copies branched
    //   startsWith('data:') ? UrlSource : DeviceFileSource
    // but getRandomMusicSource() returns a SERVER URL
    // (http://host/api/v1/music/<id>/file). Those all took the else branch,
    // so uploaded victory music was handed to the device-file loader and
    // could never play.
    test('server http URL is a UrlSource, not a DeviceFileSource', () {
      final source = VictoryMusicService.sourceFor(
          'http://192.168.1.50:8080/api/v1/music/abc123/file');
      expect(source, isA<UrlSource>());
      expect(source, isNot(isA<DeviceFileSource>()));
    });

    test('https URL is a UrlSource', () {
      expect(VictoryMusicService.sourceFor('https://example.com/a.mp3'),
          isA<UrlSource>());
    });

    test('data URL is a UrlSource', () {
      expect(VictoryMusicService.sourceFor('data:audio/mpeg;base64,AAAA'),
          isA<UrlSource>());
    });

    test('a real filesystem path is still a DeviceFileSource', () {
      expect(VictoryMusicService.sourceFor(r'C:\musicictory.mp3'),
          isA<DeviceFileSource>());
      expect(VictoryMusicService.sourceFor('/home/steve/victory.mp3'),
          isA<DeviceFileSource>());
    });

    test('no hardcoded remote fallback remains', () {
      // The mixkit URL used to be the fallback in all ten results screens and
      // fails on an offline kiosk. The fallback is now a bundled asset path.
      expect(VictoryMusicService.fallbackAssetPath, isNot(contains('http')));
      expect(VictoryMusicService.fallbackAssetPath,
          'common/sounds/victory_fallback.mp3');
    });
  });

  group('GameAnnouncementQueueService.speaking (ducking signal)', () {
    tearDown(() => GameAnnouncementQueueService.speaking.value = false);

    test('is a static, app-wide notifier', () {
      // Nine of the ten results screens own no queue — the winner line is
      // spoken by the game screen's queue before it navigates. A per-instance
      // notifier would be invisible to exactly the screens that need to duck,
      // so this must stay reachable without an instance.
      GameAnnouncementQueueService.speaking.value = true;
      expect(GameAnnouncementQueueService.speaking.value, isTrue);
      GameAnnouncementQueueService.speaking.value = false;
      expect(GameAnnouncementQueueService.speaking.value, isFalse);
    });

    test('notifies listeners on both edges', () {
      final seen = <bool>[];
      void listener() =>
          seen.add(GameAnnouncementQueueService.speaking.value);
      GameAnnouncementQueueService.speaking.addListener(listener);

      GameAnnouncementQueueService.speaking.value = true;
      GameAnnouncementQueueService.speaking.value = false;

      GameAnnouncementQueueService.speaking.removeListener(listener);
      expect(seen, [true, false]);
    });
  });

  group('VictoryMusicService volume constants', () {
    test('ducked volume is meaningfully below full volume', () {
      expect(VictoryMusicService.duckedVolume,
          lessThan(VictoryMusicService.fullVolume));
      expect(VictoryMusicService.fullVolume, 0.7);
      expect(VictoryMusicService.duckedVolume, 0.25);
    });
  });
}
