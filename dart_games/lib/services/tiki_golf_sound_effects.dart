import 'game_announcement_queue_service.dart';

/// Tiki Golf sound effects library
class TikiGolfSoundEffects {
  // Base path for all Tiki Golf sound effects (without 'assets/' prefix for AssetSource)
  static const String _basePath = 'games/tiki_golf/sounds/';

  static const SoundEffectConfig putt = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Putt.mp3',
    startSeconds: 0.0,
    endSeconds: 0.2,
  );

  static const SoundEffectConfig ballDrop = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-BallDrop.mp3',
    startSeconds: 0.0,
    endSeconds: 1.6,
  );

  static const SoundEffectConfig clap = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Clap.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig ukulele = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Ukulele.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig splash = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Splash.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig tikiChime = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-TikiChime.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig victoryFanfare = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-VictoryFanfare.mp3',
    startSeconds: 7.0,
    endSeconds: 11.0,
    fadeOutMs: 500,
  );

  static const SoundEffectConfig mulligan = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Mulligan.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );
}
