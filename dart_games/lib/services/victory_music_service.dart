import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/victory_music_file.dart';

// Conditional import for web
import 'victory_music_web.dart' if (dart.library.io) 'victory_music_native.dart'
    as platform;

/// Service to manage victory music storage.
/// On web, stores audio data in IndexedDB (persistent, supports large files).
/// On native platforms, stores file paths in SharedPreferences.
/// Supports multiple music files with random selection.
class VictoryMusicService {
  static final VictoryMusicService _instance =
      VictoryMusicService._internal();
  factory VictoryMusicService() => _instance;
  VictoryMusicService._internal();

  // In-memory cache
  List<VictoryMusicFile> _musicFiles = [];
  bool _initialized = false;
  final Random _random = Random();

  /// Initialize the service and load any stored music.
  Future<void> initialize() async {
    if (_initialized) return;

    // Try to load new format first
    if (kIsWeb) {
      final stored = await platform.loadStoredMusicFiles();
      if (stored != null && stored.isNotEmpty) {
        _musicFiles =
            stored.map((json) => VictoryMusicFile.fromJson(json)).toList();
        _initialized = true;
        return;
      }

      // Migration: Check for old single-file format
      final oldFormat = await platform.loadStoredMusic();
      if (oldFormat != null) {
        final migratedFile = VictoryMusicFile(
          id: const Uuid().v4(),
          name: oldFormat['name'] as String,
          source: oldFormat['dataUrl'] as String,
          addedDate: DateTime.now(),
        );
        _musicFiles = [migratedFile];
        await _saveMusicFiles(); // Save in new format
        await platform.clearStoredMusic(); // Clean up old format
      }
    } else {
      final prefs = await SharedPreferences.getInstance();

      // Try new format
      final jsonString = prefs.getString('victory_music_files');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _musicFiles =
            jsonList.map((json) => VictoryMusicFile.fromJson(json)).toList();
        _initialized = true;
        return;
      }

      // Migration: Check for old single-file format
      final oldPath = prefs.getString('victory_music_path');
      final oldName = prefs.getString('victory_music_name');
      if (oldPath != null && oldPath.isNotEmpty) {
        // Check if old file still exists and copy to app storage
        try {
          if (await platform.fileExists(oldPath)) {
            final id = const Uuid().v4();
            final newPath = await platform.copyMusicToAppStorage(
                oldPath, oldName ?? 'custom_music.mp3', id);

            final migratedFile = VictoryMusicFile(
              id: id,
              name: oldName ?? 'Custom music',
              source: newPath,
              addedDate: DateTime.now(),
            );
            _musicFiles = [migratedFile];
            await _saveMusicFiles(); // Save in new format
          }
          // If file doesn't exist, don't migrate it
        } catch (e) {
          print('Error migrating old music file: $e');
          // Continue without migrating if there's an error
        }

        // Clean up old keys regardless of migration success
        await prefs.remove('victory_music_path');
        await prefs.remove('victory_music_name');
      }
    }

    _initialized = true;
  }

  /// Get all stored music files.
  Future<List<VictoryMusicFile>> getMusicFiles() async {
    await initialize();
    return List.unmodifiable(_musicFiles);
  }

  /// Get a random music source for playback.
  Future<String?> getRandomMusicSource() async {
    await initialize();

    if (_musicFiles.isEmpty) {
      return null;
    }

    if (_musicFiles.length == 1) {
      return _musicFiles[0].source;
    }

    final randomIndex = _random.nextInt(_musicFiles.length);
    return _musicFiles[randomIndex].source;
  }

  /// Add a new music file.
  Future<void> addMusicFile({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    await initialize();

    final id = const Uuid().v4();
    final String source;

    if (kIsWeb && fileBytes != null) {
      // Convert to data URL (existing logic)
      final mimeType = _getMimeType(fileName);
      final base64Data = base64Encode(fileBytes);
      source = 'data:$mimeType;base64,$base64Data';
    } else if (filePath != null) {
      // Native platform - copy file to app storage for persistent access
      source = await platform.copyMusicToAppStorage(filePath, fileName, id);
    } else {
      throw Exception('Invalid file data');
    }

    final newFile = VictoryMusicFile(
      id: id,
      name: fileName,
      source: source,
      addedDate: DateTime.now(),
    );

    _musicFiles.add(newFile);
    await _saveMusicFiles();
  }

  /// Remove a music file by ID.
  Future<void> removeMusicFile(String id) async {
    await initialize();

    // Find the file to remove
    final fileToRemove = _musicFiles.firstWhere(
      (file) => file.id == id,
      orElse: () => throw Exception('Music file not found'),
    );

    // Delete the physical file on native platforms
    if (!kIsWeb && !fileToRemove.source.startsWith('data:')) {
      await platform.deleteMusicFile(fileToRemove.source);
    }

    _musicFiles.removeWhere((file) => file.id == id);
    await _saveMusicFiles();
  }

  /// Clear all music files.
  Future<void> clearAllMusic() async {
    await initialize();

    // Delete all physical files on native platforms
    if (!kIsWeb) {
      for (final file in _musicFiles) {
        if (!file.source.startsWith('data:')) {
          await platform.deleteMusicFile(file.source);
        }
      }
    }

    _musicFiles.clear();
    await _saveMusicFiles();
  }

  /// Check if any custom music is set.
  Future<bool> hasCustomMusic() async {
    await initialize();
    return _musicFiles.isNotEmpty;
  }

  /// Save current music files to storage.
  Future<void> _saveMusicFiles() async {
    if (kIsWeb) {
      final jsonList = _musicFiles.map((f) => f.toJson()).toList();
      await platform.storeMusicFiles(jsonList);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(_musicFiles.map((f) => f.toJson()).toList());
      await prefs.setString('victory_music_files', jsonString);
    }
  }

  String _getMimeType(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.mp3')) return 'audio/mpeg';
    if (lowerName.endsWith('.wav')) return 'audio/wav';
    if (lowerName.endsWith('.ogg')) return 'audio/ogg';
    if (lowerName.endsWith('.aac')) return 'audio/aac';
    return 'audio/mpeg';
  }

  // DEPRECATED METHODS - kept for backwards compatibility

  /// @deprecated Use getRandomMusicSource() instead
  Future<String?> getMusicSource() async {
    return getRandomMusicSource();
  }

  /// @deprecated Use getMusicFiles() instead
  Future<String?> getMusicName() async {
    final files = await getMusicFiles();
    return files.isNotEmpty ? files.first.name : null;
  }

  /// @deprecated Use addMusicFile() instead
  Future<void> saveMusic({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    await addMusicFile(
      fileName: fileName,
      filePath: filePath,
      fileBytes: fileBytes,
    );
  }

  /// @deprecated Use clearAllMusic() instead
  Future<void> clearMusic() async {
    await clearAllMusic();
  }
}
