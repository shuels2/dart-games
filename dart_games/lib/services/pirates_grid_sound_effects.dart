import 'game_announcement_models.dart';

/// Sound effect asset definitions for Pirate's Grid.
/// Start/end times trim each clip to the relevant portion.
class PiratesGridSoundEffects {
  static const String _basePath = 'games/pirates_grid/sounds/';

  /// Flag plant sound — plays full clip
  static const SoundEffectConfig flagPlant = SoundEffectConfig(
    assetPath: '${_basePath}PiratesGrid-FlagPlant.mp3',
    startSeconds: 0.0,
  );

  /// Cannon boom for victory — plays 0.0s to 2.0s
  static const SoundEffectConfig cannonBoom = SoundEffectConfig(
    assetPath: '${_basePath}PiratesGrid-CannonBoom.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );

  /// Wave crash for misses and draws — plays 0.0s to 4.0s with a 1.5s tail fade
  static const SoundEffectConfig waveCrash = SoundEffectConfig(
    assetPath: '${_basePath}PiratesGrid-WaveCrash.mp3',
    startSeconds: 0.0,
    endSeconds: 4.0,
    fadeOutMs: 500,
  );

  /// Treasure found jingle for round victory — plays 0.0s to 1.25s
  static const SoundEffectConfig treasureFound = SoundEffectConfig(
    assetPath: '${_basePath}PiratesGrid-TreasureFound.mp3',
    startSeconds: 0.0,
    endSeconds: 1.25,
  );

  /// Ship bell for lifecycle events — plays full clip
  static const SoundEffectConfig shipBell = SoundEffectConfig(
    assetPath: '${_basePath}PiratesGrid-ShipBell.mp3',
    startSeconds: 0.0,
  );

  /// Sword clash for stealing a square — plays full clip
  static const SoundEffectConfig swordClash = SoundEffectConfig(
    assetPath: '${_basePath}PiratesGrid-SwordClash.mp3',
    startSeconds: 0.0,
  );

  /// Timer tick for speed play countdown — plays 0.0s to 2.0s
  static const SoundEffectConfig timerTick = SoundEffectConfig(
    assetPath: '${_basePath}PiratesGrid-TimerTick.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );

  /// Every effect this game uses. Preloaded at game start so
  /// the first play does not pay the asset-load cost.
  static const List<SoundEffectConfig> all = [
    flagPlant,
    cannonBoom,
    waveCrash,
    treasureFound,
    shipBell,
    swordClash,
    timerTick,
  ];
}
