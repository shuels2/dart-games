import 'game_announcement_helper_base.dart';
import '../services/game_announcement_queue_service.dart';
import '../services/clockwork_quest_sound_effects.dart';
import '../models/player.dart';

/// Announcement helper for Clockwork Quest
///
/// Manages all game announcements following the rule: MAX 2 announcements per event.
/// Priority: victory > lap complete > advance > miss
class ClockworkQuestAnnouncementHelper extends GameAnnouncementHelperBase {

  ClockworkQuestAnnouncementHelper(super.queue);

  /// Game Start
  void announceGameStart() {
    queue.announce(
      'Wind the gears! The quest begins!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.gearSpin,
    );
  }

  /// Player Turn
  void announcePlayerTurn(Player player) {
    queue.announce(
      '${player.name}, your turn to tinker!',
      AudioPriority.turnTransition,
      soundEffect: ClockworkQuestSoundEffects.turnBell,
    );
  }

  /// Single Gear Activated
  void announceGearActivated(int gearNumber) {
    queue.announce(
      'Gear $gearNumber turns! Onward!',
      AudioPriority.hitConfirm,
      soundEffect: ClockworkQuestSoundEffects.gearClick,
    );
  }

  /// Miss (wrong number)
  void announceMiss() {
    queue.announce(
      'That\'s not the right gear!',
      AudioPriority.hitConfirm,
      soundEffect: ClockworkQuestSoundEffects.steamHiss,
    );
  }

  /// Bullseye Target (when player reaches gear 21)
  void announceBullseyeTarget() {
    queue.announce(
      'One final gear! Hit the bullseye to crown the clock!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.gearClick,
    );
  }

  /// Bullseye Hit
  void announceBullseyeHit() {
    queue.announce(
      'The crown gear turns! Magnificent!',
      AudioPriority.hitConfirm,
      soundEffect: ClockworkQuestSoundEffects.clockChime,
    );
  }

  /// Halfway (gear 10)
  void announceHalfway(Player player) {
    queue.announce(
      '${player.name} is halfway! The clock is ticking!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.gearSpin,
    );
  }

  /// Near Victory (gear 18+)
  void announceNearVictory(Player player, int gearsLeft) {
    queue.announce(
      '${player.name} is almost there! Just $gearsLeft gears left!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.gearSpin,
    );
  }

  /// Lap Complete
  void announceLapComplete() {
    queue.announce(
      'Lap complete! Wind it again!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.clockChime,
    );
  }

  /// Speed Mode Timer Expiry
  void announceTimeExpiry() {
    queue.announce(
      'Time\'s up! The gears wait for no one!',
      AudioPriority.statusChange,
      soundEffect: ClockworkQuestSoundEffects.tickTock,
    );
  }

  /// Victory
  void announceVictory(Player winner) {
    queue.announce(
      '${winner.name} wins the Clockwork Crown!',
      AudioPriority.victory,
      soundEffect: ClockworkQuestSoundEffects.victoryFanfare,
    );
  }

  /// Remove Darts (end of turn)
  void announceRemoveDarts(Player player) {
    queue.announce(
      '${player.name}, remove your darts!',
      AudioPriority.turnTransition,
    );
  }

}
