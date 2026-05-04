import 'game_announcement_queue_service.dart';

/// Sound effects for Clockwork Quest
///
/// All sounds are located in assets/games/clockwork_quest/sounds/
class ClockworkQuestSoundEffects {
  static const String _basePath = 'games/clockwork_quest/sounds/';

  /// Bell chime for turn transitions
  static const SoundEffectConfig turnBell = SoundEffectConfig(
    assetPath: '${_basePath}ClockworkQuest-Bell.mp3',
    startSeconds: 0.0,
    endSeconds: 0.8,
  );

  /// Clock chime for lap complete and bullseye hits
  static const SoundEffectConfig clockChime = SoundEffectConfig(
    assetPath: '${_basePath}ClockworkQuest-ClockChime.mp3',
    startSeconds: 0.0,
    endSeconds: 2.5,
  );

  /// Fanfare for victory
  static const SoundEffectConfig victoryFanfare = SoundEffectConfig(
    assetPath: '${_basePath}ClockworkQuest-Fanfare.mp3',
    startSeconds: 0.0,
    endSeconds: 3.5,
  );

  /// Single gear click for single gear activation
  static const SoundEffectConfig gearClick = SoundEffectConfig(
    assetPath: '${_basePath}ClockworkQuest-GearClick.mp3',
    startSeconds: 0.0,
    endSeconds: 0.4,
  );

  /// Gear spinning for double/triple advance
  static const SoundEffectConfig gearSpin = SoundEffectConfig(
    assetPath: '${_basePath}ClockworkQuest-GearSpin.mp3',
    startSeconds: 0.0,
    endSeconds: 1.2,
  );

  /// Steam hiss for misses
  static const SoundEffectConfig steamHiss = SoundEffectConfig(
    assetPath: '${_basePath}ClockworkQuest-SteamHiss.mp3',
    startSeconds: 0.0,
    endSeconds: 0.6,
  );

  /// Tick tock for speed mode timer (last 5 seconds)
  static const SoundEffectConfig tickTock = SoundEffectConfig(
    assetPath: '${_basePath}ClockworkQuest-TickTock.mp3',
    startSeconds: 0.0,
    endSeconds: 1.0,
  );
}
