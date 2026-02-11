import 'game_announcement_queue_service.dart';

/// Carnival Derby sound effects library
/// Reuses some Target Tag sound effects where appropriate
class CarnivalDerbySoundEffects {
  // Base path for Carnival Derby-specific sound effects
  static const String _basePath = 'sounds/carnival_derby/';
  static const String _targetTagPath = 'sounds/target_tag/';

  // PRIORITY 1: Turn Transitions
  static const SoundEffectConfig horseraceStart = SoundEffectConfig(
    assetPath: '${_basePath}CarnivalDerby-HorseRace-Start.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig removeDarts = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Swipe.mp3',
    startSeconds: 0.0,
    endSeconds: 3.0,
  );

  // PRIORITY 2: Dart Score Confirmations
  static const SoundEffectConfig miss = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Teasing.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig singleHit = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Spring.mp3',
    startSeconds: 3.5,
    endSeconds: null, // Play from 3.5s to end
  );

  static const SoundEffectConfig doubleHit = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Blink.mp3',
    startSeconds: 0.5,
    endSeconds: 1.25,
  );

  static const SoundEffectConfig tripleHit = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Dream.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );

  static const SoundEffectConfig bullseye = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Choir.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig outerBull = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Whistle.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  // PRIORITY 3: Status Updates
  static const SoundEffectConfig bust = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Ominous.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  // PRIORITY 4: Victory
  static const SoundEffectConfig gameComplete = SoundEffectConfig(
    assetPath: '${_basePath}CarnivalDerby-Horse-Gallop.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  // Winner announcement has no sound effect (as specified by user)
}
