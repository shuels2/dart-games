import 'game_announcement_queue_service.dart';

/// Treasure Divide sound effects library.
///
/// Trim times are copied verbatim from the spec Section 4 Sound Effects table.
class TreasureDivideSoundEffects {
  // Base path for all Treasure Divide sound effects (without 'assets/' prefix).
  static const String _basePath = 'games/treasure_divide/sounds/';

  /// Coin Clink — coin dropping into chest for a scoring hit.
  /// Source: TreasureDivide-CoinClink.mp3 (0s → 0.24s, no fade).
  static const SoundEffectConfig coinClink = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-CoinClink.mp3',
    startSeconds: 0.0,
    endSeconds: 0.24,
    fadeOutMs: 0,
  );

  /// Coin Shower — multiple coins for a big score (triple / bull hit).
  /// Source: same file as coinClink but a later slice (2.0s → 3.0s, no fade).
  static const SoundEffectConfig coinShower = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-CoinClink.mp3',
    startSeconds: 2.0,
    endSeconds: 3.0,
    fadeOutMs: 0,
  );

  /// Splash — coins hitting water for a halved score.
  /// Source: TreasureDivide-Splash.mp3 (0.5s → 2.0s, 500ms fade).
  static const SoundEffectConfig splash = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-Splash.mp3',
    startSeconds: 0.5,
    endSeconds: 2.0,
    fadeOutMs: 500,
  );

  /// Map Unfurl — paper unrolling for a new round / game start.
  /// Source: TreasureDivide-MapUnfurl.mp3 (0s → 1.25s, 500ms fade).
  static const SoundEffectConfig mapUnfurl = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-MapUnfurl.mp3',
    startSeconds: 0.0,
    endSeconds: 1.25,
    fadeOutMs: 500,
  );

  /// Miss Splash — small water splash for a miss.
  /// Source: TreasureDivide-MissSplash.mp3 (0s → 0.2s, no fade).
  static const SoundEffectConfig missSplash = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-MissSplash.mp3',
    startSeconds: 0.0,
    endSeconds: 0.2,
    fadeOutMs: 0,
  );

  /// Turn Bell — ship's bell for a turn change.
  /// Source: TreasureDivide-Bell.mp3 (0s → 0.1s, 250ms fade).
  static const SoundEffectConfig turnBell = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-Bell.mp3',
    startSeconds: 0.0,
    endSeconds: 0.1,
    fadeOutMs: 250,
  );

  /// Victory Fanfare — pirate celebration music.
  /// Source: TreasureDivide-Fanfare.mp3 (0s → 4.0s, 500ms fade).
  static const SoundEffectConfig victoryFanfare = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-Fanfare.mp3',
    startSeconds: 0.0,
    endSeconds: 4.0,
    fadeOutMs: 500,
  );

  /// Quarter Storm — dramatic storm sound for the quarter penalty.
  /// Source: TreasureDivide-Storm.mp3 (0s → 1.5s, 500ms fade).
  static const SoundEffectConfig quarterStorm = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-Storm.mp3',
    startSeconds: 0.0,
    endSeconds: 1.5,
    fadeOutMs: 500,
  );

  /// Every effect this game uses. Preloaded at game start so
  /// the first play does not pay the asset-load cost.
  static const List<SoundEffectConfig> all = [
    coinClink,
    coinShower,
    splash,
    mapUnfurl,
    missSplash,
    turnBell,
    victoryFanfare,
    quarterStorm,
  ];
}
