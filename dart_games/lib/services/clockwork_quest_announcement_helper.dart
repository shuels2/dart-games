import '../services/game_announcement_queue_service.dart';
import '../services/clockwork_quest_sound_effects.dart';
import '../models/player.dart';

/// Announcement helper for Clockwork Quest
///
/// Manages all game announcements following the rule: MAX 2 announcements per event.
/// Priority: victory > lap complete > advance > miss
class ClockworkQuestAnnouncementHelper {
  final GameAnnouncementQueueService _queueService;

  ClockworkQuestAnnouncementHelper(this._queueService);

  /// Game Start
  void announceGameStart() {
    _queueService.announce(
      'Wind the gears! The quest begins!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.gearSpin,
    );
  }

  /// Player Turn
  void announcePlayerTurn(Player player) {
    _queueService.announce(
      '${player.name}, your turn to tinker!',
      AudioPriority.turnTransition,
      soundEffect: ClockworkQuestSoundEffects.turnBell,
    );
  }

  /// Single Gear Activated
  void announceGearActivated(int gearNumber) {
    _queueService.announce(
      'Gear $gearNumber turns! Onward!',
      AudioPriority.hitConfirm,
      soundEffect: ClockworkQuestSoundEffects.gearClick,
    );
  }

  /// Double Advance
  void announceDoubleAdvance(Player player) {
    _queueService.announce(
      '${player.name} hits a double! Two gears turn!',
      AudioPriority.hitConfirm,
      soundEffect: ClockworkQuestSoundEffects.gearSpin,
    );
  }

  /// Triple Advance
  void announceTripleAdvance(Player player) {
    _queueService.announce(
      '${player.name} hits a triple! Three gears turn!',
      AudioPriority.hitConfirm,
      soundEffect: ClockworkQuestSoundEffects.gearSpin,
    );
  }

  /// Miss (wrong number)
  void announceMiss() {
    _queueService.announce(
      'Steam vents! That\'s not the right gear!',
      AudioPriority.hitConfirm,
      soundEffect: ClockworkQuestSoundEffects.steamHiss,
    );
  }

  /// Bullseye Target (when player reaches gear 21)
  void announceBullseyeTarget() {
    _queueService.announce(
      'One final gear! Hit the bullseye to crown the clock!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.gearClick,
    );
  }

  /// Bullseye Hit
  void announceBullseyeHit() {
    _queueService.announce(
      'The crown gear turns! Magnificent!',
      AudioPriority.hitConfirm,
      soundEffect: ClockworkQuestSoundEffects.clockChime,
    );
  }

  /// Halfway (gear 10)
  void announceHalfway(Player player) {
    _queueService.announce(
      '${player.name} is halfway! The clock is ticking!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.gearSpin,
    );
  }

  /// Near Victory (gear 18+)
  void announceNearVictory(Player player, int gearsLeft) {
    _queueService.announce(
      '${player.name} is almost there! Just $gearsLeft gears left!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.gearSpin,
    );
  }

  /// Lap Complete
  void announceLapComplete() {
    _queueService.announce(
      'Lap complete! Wind it again!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.clockChime,
    );
  }

  /// Speed Mode Timer Expiry
  void announceTimeExpiry() {
    _queueService.announce(
      'Time\'s up! The gears wait for no one!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.tickTock,
    );
  }

  /// Victory
  void announceVictory(Player winner) {
    _queueService.announce(
      'All gears turn! ${winner.name} wins the Clockwork Crown!',
      AudioPriority.victory,
      soundEffect: ClockworkQuestSoundEffects.victoryFanfare,
    );
  }

  /// Remove Darts (end of turn)
  void announceRemoveDarts(Player player) {
    _queueService.announce(
      '${player.name}, remove your darts!',
      AudioPriority.turnTransition,
    );
  }

  void dispose() {
    _queueService.dispose();
  }
}
