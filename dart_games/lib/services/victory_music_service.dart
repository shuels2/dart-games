import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/victory_music_file.dart';
import 'api/api_client.dart';
import 'game_announcement_queue_service.dart';
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
  Future<void>? _activeInit;
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

  /// Whether the service has been initialized (music list fetched from server).
  /// Useful in tests to confirm getRandomMusicSource() was actually called.
  bool get isInitialized => _initialized;

  /// For testing: reset internal state.
  void resetForTesting() {
    _musicFiles = [];
    _initialized = false;
    _activeInit = null;
  }

  /// Initialize the service and load stored music from the server.
  Future<void> initialize() async {
    if (_initialized) return;

    // Deduplicate concurrent initialize() calls so only one fetch runs.
    if (_activeInit != null) {
      await _activeInit;
      return;
    }

    _activeInit = _doInitialize();
    try {
      await _activeInit;
    } finally {
      _activeInit = null;
    }
  }

  Future<void> _doInitialize() async {
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

  // ─── Playback ─────────────────────────────────────────────────────────

  /// Volume victory music plays at when nothing is being spoken.
  static const double fullVolume = 0.7;

  /// Volume victory music ducks to while an announcement is speaking.
  static const double duckedVolume = 0.25;

  /// Optional bundled fallback, played when the user has uploaded no music.
  ///
  /// Nothing ships at this path today, so with no uploaded music the app is
  /// simply silent. Dropping an mp3 here (and adding `assets/common/sounds/`
  /// to pubspec.yaml) is all that is needed to give it a default — no code
  /// change. It deliberately replaced a hardcoded
  /// `https://assets.mixkit.co/...` URL that every one of the ten results
  /// screens carried: that fetch fails on an offline kiosk, which is exactly
  /// where a dartboard lives.
  static const String fallbackAssetPath = 'common/sounds/victory_fallback.mp3';

  /// Wraps a music source in the right [Source] for what it actually is.
  ///
  /// The ten hand-written copies of this all did
  /// `startsWith('data:') ? UrlSource : DeviceFileSource`, which sent the
  /// server URLs this service returns — `http://host/api/v1/music/<id>/file`,
  /// see [_doInitialize] — down the DEVICE FILE path. A remote URL is not a
  /// file path, so uploaded victory music could never play. http/https now
  /// route to [UrlSource] with the data: case.
  static Source sourceFor(String musicSource) {
    if (musicSource.startsWith('data:') ||
        musicSource.startsWith('http://') ||
        musicSource.startsWith('https://')) {
      return UrlSource(musicSource);
    }
    return DeviceFileSource(musicSource);
  }

  /// Plays victory music on [player], replacing the ~35-line `_playVictoryMusic`
  /// each of the ten results screens used to carry.
  ///
  /// Returns true if playback was started. Never throws — a results screen
  /// must render its winner whatever the audio stack does.
  Future<bool> playVictoryMusic(AudioPlayer player,
      {double volume = fullVolume}) async {
    try {
      final source = await getRandomMusicSource();
      await player.setVolume(volume);

      if (source != null && source.isNotEmpty) {
        await player.play(sourceFor(source)).timeout(
              const Duration(seconds: 5),
              onTimeout: () => debugPrint('Victory music playback timed out'),
            );
        return true;
      }

      // No uploaded music: try the bundled fallback if one was added.
      await player.play(AssetSource(fallbackAssetPath)).timeout(
            const Duration(seconds: 5),
            onTimeout: () => debugPrint('Victory music playback timed out'),
          );
      return true;
    } catch (e) {
      // Includes the expected "asset not found" when no fallback is bundled.
      debugPrint('Victory music not played: $e');
      return false;
    }
  }

  /// Ducks [player] under speech for as long as the returned subscription is
  /// alive: 0.25 while an announcement is speaking, back to 0.7 when it ends.
  ///
  /// Returns a callback the caller MUST invoke from `dispose()` to detach the
  /// listener — the notifier is app-wide and outlives any one screen.
  ///
  /// Ducking rather than sequencing is the point: nine of the ten results
  /// screens have the winner line spoken by the GAME screen's queue while the
  /// music is already playing, so without this the two simply talk over each
  /// other.
  static VoidCallback duckUnderSpeech(AudioPlayer player,
      {double volume = fullVolume, double ducked = duckedVolume}) {
    void listener() {
      final target =
          GameAnnouncementQueueService.speaking.value ? ducked : volume;
      // Fire-and-forget: a volume change failing must never break playback.
      player.setVolume(target).catchError(
          (Object e) => debugPrint('Victory music duck failed: $e'));
    }

    GameAnnouncementQueueService.speaking.addListener(listener);
    listener(); // apply the current state immediately
    return () =>
        GameAnnouncementQueueService.speaking.removeListener(listener);
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
