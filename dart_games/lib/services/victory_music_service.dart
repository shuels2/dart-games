import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import for web
import 'victory_music_web.dart' if (dart.library.io) 'victory_music_native.dart' as platform;

/// Service to manage victory music storage.
/// On web, stores audio data in IndexedDB (persistent, supports large files).
/// On native platforms, stores file path in SharedPreferences.
class VictoryMusicService {
  static final VictoryMusicService _instance = VictoryMusicService._internal();
  factory VictoryMusicService() => _instance;
  VictoryMusicService._internal();

  // In-memory cache
  String? _cachedDataUrl;
  String? _musicName;
  bool _initialized = false;

  /// Initialize the service and load any stored music.
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      final stored = await platform.loadStoredMusic();
      if (stored != null) {
        _cachedDataUrl = stored['dataUrl'];
        _musicName = stored['name'];
      }
    }
    _initialized = true;
  }

  /// Get the music source for playback.
  Future<String?> getMusicSource() async {
    await initialize();

    if (kIsWeb) {
      return _cachedDataUrl;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('victory_music_path');
    }
  }

  /// Get the music file name for display.
  Future<String?> getMusicName() async {
    await initialize();

    if (kIsWeb) {
      return _musicName;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('victory_music_name');
    }
  }

  /// Save music from file picker.
  Future<void> saveMusic({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    _musicName = fileName;

    if (kIsWeb && fileBytes != null) {
      // Convert bytes to data URL for web
      final lowerName = fileName.toLowerCase();
      String mimeType;
      if (lowerName.endsWith('.mp3')) {
        mimeType = 'audio/mpeg';
      } else if (lowerName.endsWith('.wav')) {
        mimeType = 'audio/wav';
      } else if (lowerName.endsWith('.ogg')) {
        mimeType = 'audio/ogg';
      } else if (lowerName.endsWith('.aac')) {
        mimeType = 'audio/aac';
      } else {
        mimeType = 'audio/mpeg';
      }
      final base64Data = base64Encode(fileBytes);
      _cachedDataUrl = 'data:$mimeType;base64,$base64Data';

      // Store in IndexedDB for persistence
      await platform.storeMusic(fileName, _cachedDataUrl!);
    } else if (filePath != null) {
      // Native platform - store path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('victory_music_path', filePath);
      await prefs.setString('victory_music_name', fileName);
    }
  }

  /// Clear saved music.
  Future<void> clearMusic() async {
    _cachedDataUrl = null;
    _musicName = null;

    if (kIsWeb) {
      await platform.clearStoredMusic();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('victory_music_path');
    await prefs.remove('victory_music_name');
  }

  /// Check if custom music is set.
  Future<bool> hasCustomMusic() async {
    await initialize();

    if (kIsWeb) {
      return _cachedDataUrl != null;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('victory_music_path');
      return path != null && path.isNotEmpty;
    }
  }
}
