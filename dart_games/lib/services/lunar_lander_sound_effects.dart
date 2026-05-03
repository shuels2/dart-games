import 'game_announcement_models.dart';

/// Sound effect asset definitions for Lunar Lander.
/// Start/end times trim each clip to the relevant portion.
class LunarLanderSoundEffects {
  static const String _basePath = 'assets/games/lunar_lander/sounds/';

  /// Rocket thruster burn — plays from 0.5s to 3.0s
  static const SoundEffectConfig thrusterBurn = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-ThrusterBurn.mp3',
    startSeconds: 0.5,
    endSeconds: 3.0,
  );

  /// Crash landing — plays full clip
  static const SoundEffectConfig crashLanding = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-CrashLanding.mp3',
    startSeconds: 0.0,
  );

  /// Radio beep — plays full clip
  static const SoundEffectConfig radioBeep = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-RadioBeep.mp3',
    startSeconds: 0.0,
  );

  /// Touchdown — plays full clip
  static const SoundEffectConfig touchdown = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-Touchdown.mp3',
    startSeconds: 0.0,
  );

  /// Mission control chatter — plays 0s to 1.25s
  static const SoundEffectConfig missionControl = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-MissionControl.mp3',
    startSeconds: 0.0,
    endSeconds: 1.25,
  );

  /// Warning alarm — plays full clip
  static const SoundEffectConfig warningAlarm = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-WarningAlarm.mp3',
    startSeconds: 0.0,
  );

  /// Drift sound — plays 1.0s to 4.0s
  static const SoundEffectConfig driftSound = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-DriftSound.mp3',
    startSeconds: 1.0,
    endSeconds: 4.0,
  );

  /// Victory fanfare — plays 0.5s to 8.0s
  static const SoundEffectConfig victoryFanfare = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-VictoryFanfare.mp3',
    startSeconds: 0.5,
    endSeconds: 8.0,
  );
}
