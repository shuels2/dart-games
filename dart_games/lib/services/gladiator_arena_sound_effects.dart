import 'game_announcement_models.dart';

/// Sound effect asset definitions for Gladiator Arena.
/// Start/end times trim each clip to the relevant portion.
class GladiatorArenaSoundEffects {
  static const String _basePath = 'games/gladiator_arena/sounds/';

  /// Sword clash — plays full clip
  static const SoundEffectConfig swordClash = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-SwordClash.mp3',
  );

  /// Crowd cheer — plays 0.0s to 3.0s with a 1.5s tail fade
  static const SoundEffectConfig crowdCheer = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-CrowdCheer.mp3',
    startSeconds: 0.0,
    endSeconds: 3.0,
    fadeOutMs: 500,
  );

  /// Crowd gasp — plays from 0.0s to 1.5s
  static const SoundEffectConfig crowdGasp = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-CrowdGasp.mp3',
    startSeconds: 0.0,
    endSeconds: 1.5,
  );

  /// Shield block — plays full clip
  static const SoundEffectConfig shieldBlock = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-ShieldBlock.mp3',
  );

  /// Trumpet fanfare — plays full clip
  static const SoundEffectConfig trumpetFanfare = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-TrumpetFanfare.mp3',
  );

  /// Turn bell — plays from 0.0s to 2.0s with a 1.0s tail fade
  static const SoundEffectConfig turnBell = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-TurnBell.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
    fadeOutMs: 500,
  );

  /// Miss thud — plays full clip
  static const SoundEffectConfig missThud = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-MissThud.mp3',
  );

  /// Timer tick — plays from 0.0s to 2.0s
  static const SoundEffectConfig timerTick = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-TimerTick.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );
}
