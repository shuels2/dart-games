import 'game_announcement_queue_service.dart';

/// Monster Mash sound effects library
class MonsterMashSoundEffects {
  // Base paths
  static const String _basePath = 'games/monster_mash/sounds/';
  static const String _targetTagPath = 'games/target_tag/sounds/';

  // PRIORITY 5: Victory/Game Events
  static const SoundEffectConfig gameStart = SoundEffectConfig(
    assetPath: '${_basePath}MonsterMash-Organ.mp3',
    startSeconds: 1.75,
    endSeconds: 9.0,
  );

  // PRIORITY 1: Turn Transitions
  static const SoundEffectConfig turnStart = SoundEffectConfig(
    assetPath: '${_basePath}MonsterMash-MonsterScream.mp3',
    startSeconds: 3.0,
    endSeconds: 7.5,
  );

  static const SoundEffectConfig removeDarts = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Swipe.mp3',
    startSeconds: 0.0,
    endSeconds: 3.0,
  );

  // PRIORITY 2: Hit Confirmations
  static const SoundEffectConfig dartHit = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Spring.mp3',
    startSeconds: 3.5,
    endSeconds: null, // Play from 3.5s to end
  );

  static const SoundEffectConfig healing = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Whistle.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig attack = SoundEffectConfig(
    assetPath: '${_basePath}MonsterMash-Growl.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  // PRIORITY 3: Shield/Health Status
  static const SoundEffectConfig healthWarning = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Ominous.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  // PRIORITY 4: Status Changes
  static const SoundEffectConfig elimination = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Villain.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );

  static const SoundEffectConfig hatTrick = SoundEffectConfig(
    assetPath: '${_basePath}MonsterMash-MonsterRoar.mp3',
    startSeconds: 0.0,
    endSeconds: 2.5,
  );

  static const SoundEffectConfig clutchHeal = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Dream.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );

  static const SoundEffectConfig buffActivation = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Fanfare.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Play entire file
  );
}
