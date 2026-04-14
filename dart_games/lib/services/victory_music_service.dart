import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../models/victory_music_file.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';

/// Service to manage victory music storage via the backend API.
///
/// Music files are uploaded to the server and played via server URLs.
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

  ApiClient? _apiClient;

  /// Set the API client. Call once at app startup.
  void initializeApi(ApiClient client) {
    _apiClient = client;
  }

  ApiClient get _api {
    if (_apiClient == null) {
      throw StateError(
          'VictoryMusicService not initialized. Call initializeApi() first.');
    }
    return _apiClient!;
  }

  /// For testing: reset internal state.
  void resetForTesting() {
    _musicFiles = [];
    _initialized = false;
  }

  /// Initialize the service and load stored music from the server.
  Future<void> initialize() async {
    if (_initialized) return;

    final musicList = await _api.getMusic();
    _musicFiles = musicList.map((json) {
      return VictoryMusicFile(
        id: json['id'] as String,
        name: json['fileName'] as String,
        source: ApiConfig.url('/api/v1/music/${json['id']}/file'),
        addedDate: DateTime.parse(json['createdAt'] as String),
      );
    }).toList();

    _initialized = true;
  }

  /// Get all stored music files.
  Future<List<VictoryMusicFile>> getMusicFiles() async {
    await initialize();
    return List.unmodifiable(_musicFiles);
  }

  /// Get a random music source URL for playback.
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
  ///
  /// Uploads the file to the server and caches it locally.
  Future<void> addMusicFile({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
    String? dataUrl,
  }) async {
    await initialize();

    String base64Data;

    if (dataUrl != null) {
      // Extract base64 from data URL (data:audio/mpeg;base64,XXXXXX)
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex >= 0) {
        base64Data = dataUrl.substring(commaIndex + 1);
      } else {
        base64Data = dataUrl;
      }
    } else if (fileBytes != null) {
      base64Data = base64Encode(fileBytes);
    } else {
      throw Exception('Invalid file data: provide fileBytes or dataUrl');
    }

    // Upload to server
    final result = await _api.uploadMusic(fileName, base64Data);
    final id = result['id'] as String;

    final newFile = VictoryMusicFile(
      id: id,
      name: fileName,
      source: ApiConfig.url('/api/v1/music/$id/file'),
      addedDate: DateTime.now(),
    );

    _musicFiles.add(newFile);
  }

  /// Remove a music file by ID.
  Future<void> removeMusicFile(String id) async {
    await initialize();

    await _api.deleteMusic(id);
    _musicFiles.removeWhere((file) => file.id == id);
  }

  /// Clear all music files.
  Future<void> clearAllMusic() async {
    await initialize();

    await _api.deleteAllMusic();
    _musicFiles.clear();
  }

  /// Check if any custom music is set.
  Future<bool> hasCustomMusic() async {
    await initialize();
    return _musicFiles.isNotEmpty;
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
