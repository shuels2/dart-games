import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/victory_music_file.dart';

void main() {
  group('VictoryMusicFile', () {
    test('creates instance with all fields', () {
      final now = DateTime.now();
      final file = VictoryMusicFile(
        id: 'test-id',
        name: 'Test Music.mp3',
        source: '/path/to/music.mp3',
        addedDate: now,
      );

      expect(file.id, 'test-id');
      expect(file.name, 'Test Music.mp3');
      expect(file.source, '/path/to/music.mp3');
      expect(file.addedDate, now);
    });

    test('serializes to JSON correctly', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final file = VictoryMusicFile(
        id: 'music-123',
        name: 'Victory Song.mp3',
        source: 'data:audio/mpeg;base64,ABC123',
        addedDate: now,
      );

      final json = file.toJson();

      expect(json['id'], 'music-123');
      expect(json['name'], 'Victory Song.mp3');
      expect(json['source'], 'data:audio/mpeg;base64,ABC123');
      expect(json['addedDate'], now.toIso8601String());
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'music-456',
        'name': 'Fanfare.wav',
        'source': '/storage/music/fanfare.wav',
        'addedDate': '2024-01-15T10:30:00.000Z',
      };

      final file = VictoryMusicFile.fromJson(json);

      expect(file.id, 'music-456');
      expect(file.name, 'Fanfare.wav');
      expect(file.source, '/storage/music/fanfare.wav');
      expect(file.addedDate, DateTime.parse('2024-01-15T10:30:00.000Z'));
    });

    test('round-trip serialization preserves data', () {
      final original = VictoryMusicFile(
        id: 'original-id',
        name: 'Original Music.ogg',
        source: 'data:audio/ogg;base64,XYZ789',
        addedDate: DateTime.now(),
      );

      final json = original.toJson();
      final deserialized = VictoryMusicFile.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.name, original.name);
      expect(deserialized.source, original.source);
      expect(
        deserialized.addedDate.difference(original.addedDate).inSeconds,
        lessThan(1),
      );
    });

    test('handles different file extensions in name', () {
      final extensions = ['.mp3', '.wav', '.ogg', '.aac', '.m4a'];

      for (final ext in extensions) {
        final file = VictoryMusicFile(
          id: 'test',
          name: 'music$ext',
          source: '/path/to/music$ext',
          addedDate: DateTime.now(),
        );

        expect(file.name, 'music$ext');
      }
    });

    test('handles data URL sources (web)', () {
      final dataUrl = 'data:audio/mpeg;base64,/+MYxAAAAAAAAAAA';
      final file = VictoryMusicFile(
        id: 'web-music',
        name: 'WebMusic.mp3',
        source: dataUrl,
        addedDate: DateTime.now(),
      );

      expect(file.source, dataUrl);
      expect(file.source.startsWith('data:'), isTrue);
    });

    test('handles file path sources (native)', () {
      final filePath = '/data/app/victory_music/music.mp3';
      final file = VictoryMusicFile(
        id: 'native-music',
        name: 'NativeMusic.mp3',
        source: filePath,
        addedDate: DateTime.now(),
      );

      expect(file.source, filePath);
      expect(file.source.startsWith('data:'), isFalse);
    });

    test('addedDate can be any valid DateTime', () {
      final dates = [
        DateTime(2020, 1, 1),
        DateTime(2024, 12, 31, 23, 59, 59),
        DateTime.now(),
        DateTime.now().add(const Duration(days: 30)),
      ];

      for (final date in dates) {
        final file = VictoryMusicFile(
          id: 'test',
          name: 'Test.mp3',
          source: '/test',
          addedDate: date,
        );

        expect(file.addedDate, date);
      }
    });

    test('serializes special characters in name correctly', () {
      final specialNames = [
        'Music & Sound.mp3',
        'Victory (2024).wav',
        "Winner's Song.ogg",
        'Música Española.mp3',
      ];

      for (final name in specialNames) {
        final file = VictoryMusicFile(
          id: 'test',
          name: name,
          source: '/test',
          addedDate: DateTime.now(),
        );

        final json = file.toJson();
        final deserialized = VictoryMusicFile.fromJson(json);

        expect(deserialized.name, name);
      }
    });

    test('handles long file names', () {
      final longName = 'A' * 200 + '.mp3';
      final file = VictoryMusicFile(
        id: 'long-name',
        name: longName,
        source: '/test',
        addedDate: DateTime.now(),
      );

      expect(file.name, longName);
      expect(file.name.length, 204);
    });

    test('handles long data URLs', () {
      final longBase64 = 'A' * 10000;
      final dataUrl = 'data:audio/mpeg;base64,$longBase64';
      final file = VictoryMusicFile(
        id: 'long-url',
        name: 'LargeFile.mp3',
        source: dataUrl,
        addedDate: DateTime.now(),
      );

      expect(file.source.length, greaterThan(10000));
    });
  });
}
