import '../models/reef_royale_game.dart';
import 'game_announcement_helper_base.dart';
import 'game_announcement_queue_service.dart';
import 'reef_royale_sound_effects.dart';

/// Announcement helper for Reef Royale.
/// Max 2 announcements per dart throw (priority: claim > score > mark).
/// "Remove your darts" ALWAYS plays.
class ReefRoyaleAnnouncementHelper extends GameAnnouncementHelperBase {

  ReefRoyaleAnnouncementHelper(super.queue);

  // --- Game Events ---

  void announceGameStart() {
    queue.announce(
      'Dive in! The reef awaits!',
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.bubblePop,
    );
  }

  void announceRandomReefs() {
    queue.announce(
      'The reef has shifted!',
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.currentWhoosh,
    );
  }

  void announceTurn(String playerName) {
    queue.announce(
      '$playerName, your turn to swim!',
      AudioPriority.turnTransition,
      soundEffect: ReefRoyaleSoundEffects.turnBell,
    );
  }

  void announceRemoveDarts() {
    queue.announce(
      'Remove your darts',
      AudioPriority.turnTransition,
    );
  }

  // --- Dart Events (max 2 per dart) ---

  void announceMiss() {
    queue.announce(
      'That one drifted with the current!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.splash,
    );
  }

  void announceNonTarget() {
    queue.announce(
      "That reef isn't on the map!",
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.splash,
    );
  }

  void announceSingleMark(String coralName) {
    queue.announce(
      'A fish arrives at $coralName!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.bubblePop,
    );
  }

  void announceDoubleMark(String coralName) {
    queue.announce(
      'A school gathers at $coralName!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.doubleBubble,
    );
  }

  void announceTripleMark(String coralName) {
    queue.announce(
      'A triple! $coralName blooms!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.coralBloom,
    );
  }

  void announceNeighborMark(String coralName) {
    queue.announce(
      'A neighbor fish drifts to $coralName!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.bubblePop,
    );
  }

  void announceCoralClaimed(String playerName, String coralName) {
    queue.announce(
      '$playerName claims $coralName! It blooms!',
      AudioPriority.shieldStatus,
      soundEffect: ReefRoyaleSoundEffects.coralBloom,
    );
  }

  void announceReefLocked(String coralName) {
    queue.announce(
      '$coralName is locked! The reef is sealed!',
      AudioPriority.shieldStatus,
      soundEffect: ReefRoyaleSoundEffects.reefLock,
    );
  }

  void announceScoring(String playerName, int pearls) {
    if (pearls >= 40) {
      queue.announce(
        'A massive pearl haul! $pearls pearls!',
        AudioPriority.hitConfirm,
        soundEffect: ReefRoyaleSoundEffects.pearlChime,
      );
    } else {
      queue.announce(
        '$pearls pearls harvested!',
        AudioPriority.hitConfirm,
        soundEffect: ReefRoyaleSoundEffects.pearlChime,
      );
    }
  }

  void announceCursedScoring(int pearls, List<String> affectedNames, {required List<String> allOpponentNames}) {
    final String text;
    if (affectedNames.length == allOpponentNames.length) {
      text = 'Cursed tide! $pearls pearls weigh down all opponents!';
    } else if (affectedNames.length <= 3) {
      final names = affectedNames.join(' and ');
      text = 'Cursed tide! $pearls pearls weigh down $names!';
    } else {
      final excludedNames = allOpponentNames.where((n) => !affectedNames.contains(n)).toList();
      final excluded = excludedNames.join(' and ');
      text = 'Cursed tide! $pearls pearls weigh down all opponents except $excluded!';
    }
    queue.announce(
      text,
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.splash,
    );
  }

  void announceNearVictory(String playerName) {
    queue.announce(
      '$playerName has six corals! One more!',
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.pearlChime,
    );
  }

  // --- Buff Events ---

  void announceBuff(ReefBuff buff) {
    String text;
    switch (buff) {
      case ReefBuff.riptideRush:
        text = 'Riptide rush! Double marks this round!';
      case ReefBuff.pearlFever:
        text = 'Pearl fever! Double pearls this round!';
      case ReefBuff.inkCloud:
        text = 'Ink cloud! The reef goes dark!';
    }

    queue.announce(
      text,
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.currentWhoosh,
    );
  }

  // --- Game Completion ---

  void announceSpeedPlayEnd() {
    queue.announce(
      "Time's up! The tides decide the winner!",
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.currentWhoosh,
    );
  }

  /// Victory announcement. Accepts a list of winner names so ties are
  /// announced with EVERY name spoken (matches Treasure Divide / Tiki
  /// Golf ties). Reef Royale's model computes winnerIds explicitly for
  /// ties (multiple players hitting the required-corals target on the
  /// same turn), so the announcer must be tie-aware or ties go silent.
  ///
  /// - 1 winner:  "All hail {name}, Crown of the Reef!"
  /// - 2 winners: "The reef is shared! {a} and {b} tie for the Crown of the Reef!"
  /// - 3+ winners: "The reef is shared! {a}, {b}, and {c} tie for the Crown of the Reef!"
  void announceVictory(List<String> winnerNames) {
    if (winnerNames.isEmpty) return;
    if (winnerNames.length == 1) {
      queue.announce(
        'All hail ${winnerNames.first}, Crown of the Reef!',
        AudioPriority.victory,
        soundEffect: ReefRoyaleSoundEffects.victoryFanfare,
      );
      return;
    }
    final names = GameAnnouncementHelperBase.joinWithAnd(winnerNames);
    queue.announce(
      'The reef is shared! $names tie for the Crown of the Reef!',
      AudioPriority.victory,
      soundEffect: ReefRoyaleSoundEffects.victoryFanfare,
    );
  }

  /// Joins a list of strings with commas + "and" at the end:
  /// ['A']            => 'A'
  /// ['A', 'B']       => 'A and B'
  /// ['A', 'B', 'C']  => 'A, B, and C' (Oxford comma)

  void announceLockedOnTarget(int target) {
    // Locked target - no effect, no announcement
  }

}
