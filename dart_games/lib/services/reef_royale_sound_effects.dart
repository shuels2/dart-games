import 'game_announcement_queue_service.dart';

/// Reef Royale sound effects library
class ReefRoyaleSoundEffects {
  static const String _basePath = 'games/reef_royale/sounds/';

  // Bubble Pop - single mark
  static const SoundEffectConfig bubblePop = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-BubblePop.mp3',
    startSeconds: 0.0,
    endSeconds: 0.25,
  );

  // Double Bubble - double mark
  static const SoundEffectConfig doubleBubble = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-BubblePop.mp3',
    startSeconds: 0.0,
    endSeconds: 0.65,
  );

  // Coral Bloom - claiming a coral
  static const SoundEffectConfig coralBloom = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-Chime.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Full file
  );

  // Pearl Chime - scoring pearls
  static const SoundEffectConfig pearlChime = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-ChimeScore.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Full file
  );

  // Splash - missed throw
  static const SoundEffectConfig splash = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-Splash.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Full file
  );

  // Current Whoosh - buff activation
  static const SoundEffectConfig currentWhoosh = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-RushingWater.mp3',
    startSeconds: 0.0,
    endSeconds: 3.0,
  );

  // Victory Fanfare
  static const SoundEffectConfig victoryFanfare = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-Fanfare.mp3',
    startSeconds: 5.8,
    endSeconds: 8.9,
  );

  // Turn Bell - turn change
  static const SoundEffectConfig turnBell = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-Bell.mp3',
    startSeconds: 0.0,
    endSeconds: 1.0,
  );

  // Reef Lock - all players claimed
  static const SoundEffectConfig reefLock = SoundEffectConfig(
    assetPath: '${_basePath}ReefRoyale-Lock.mp3',
    startSeconds: 11.0,
    endSeconds: 14.25,
  );
}
