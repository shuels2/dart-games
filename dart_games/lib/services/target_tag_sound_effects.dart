import 'game_announcement_queue_service.dart';

/// Target Tag sound effects library
class TargetTagSoundEffects {
  // Base path for all Target Tag sound effects (without 'assets/' prefix for AssetSource)
  static const String _basePath = 'games/target_tag/sounds/';

  // PRIORITY 1: Turn Transitions
  static const SoundEffectConfig turnStart = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Fanfare.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig removeDarts = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Swipe.mp3',
    startSeconds: 0.0,
    endSeconds: 3.0,
  );

  // PRIORITY 2: Hit Confirmations
  static const SoundEffectConfig singleHit = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Spring.mp3',
    startSeconds: 3.5,
    endSeconds: null, // Play from 3.5s to end
  );

  static const SoundEffectConfig doubleHit = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Blink.mp3',
    startSeconds: 0.5,
    endSeconds: 1.25,
  );

  static const SoundEffectConfig tripleHit = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Dream.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );

  static const SoundEffectConfig bullseye = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Choir.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig outerBull = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Whistle.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig miss = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Teasing.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  // PRIORITY 3: Shield Status
  static const SoundEffectConfig shieldGained = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-WindUp.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );

  // PRIORITY 4: Status Changes
  static const SoundEffectConfig taggedIn = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Launch.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig eliminated = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Villain.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  // PRIORITY 5: Victory/Game Events
  static const SoundEffectConfig gameStart = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Magical.mp3',
    startSeconds: 0.0,
    endSeconds: 8.0,
  );

  // Additional Status/Event Sounds
  static const SoundEffectConfig successfulTag = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-PianoRoll.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig lowShields = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-Ominous.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig taggedOut = SoundEffectConfig(
    assetPath: '${_basePath}TargetTag-BananaSlip.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );
}
