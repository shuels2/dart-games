import '../models/reef_royale_game.dart';
import 'game_announcement_queue_service.dart';
import 'reef_royale_sound_effects.dart';

/// Announcement helper for Reef Royale.
/// Max 2 announcements per dart throw (priority: claim > score > mark).
/// "Remove your darts" ALWAYS plays.
class ReefRoyaleAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  ReefRoyaleAnnouncementHelper(this._queue);

  // --- Game Events ---

  void announceGameStart() {
    _queue.announce(
      'Dive in! The reef awaits!',
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.bubblePop,
    );
  }

  void announceRandomReefs() {
    _queue.announce(
      'The reef has shifted!',
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.currentWhoosh,
    );
  }

  void announceTurn(String playerName) {
    _queue.announce(
      '$playerName, your turn to swim!',
      AudioPriority.turnTransition,
      soundEffect: ReefRoyaleSoundEffects.turnBell,
    );
  }

  void announceRemoveDarts() {
    _queue.announce(
      'Remove your darts',
      AudioPriority.turnTransition,
    );
  }

  // --- Dart Events (max 2 per dart) ---

  void announceMiss() {
    _queue.announce(
      'That one drifted with the current!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.splash,
    );
  }

  void announceNonTarget() {
    _queue.announce(
      "That reef isn't on the map!",
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.splash,
    );
  }

  void announceSingleMark(String coralName) {
    _queue.announce(
      'A fish arrives at $coralName!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.bubblePop,
    );
  }

  void announceDoubleMark(String coralName) {
    _queue.announce(
      'A school gathers at $coralName!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.doubleBubble,
    );
  }

  void announceTripleMark(String coralName) {
    _queue.announce(
      'A triple! $coralName blooms!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.coralBloom,
    );
  }

  void announceNeighborMark(String coralName) {
    _queue.announce(
      'A neighbor fish drifts to $coralName!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.bubblePop,
    );
  }

  void announceCoralClaimed(String playerName, String coralName) {
    _queue.announce(
      '$playerName claims $coralName! It blooms!',
      AudioPriority.shieldStatus,
      soundEffect: ReefRoyaleSoundEffects.coralBloom,
    );
  }

  void announceReefLocked(String coralName) {
    _queue.announce(
      '$coralName is locked! The reef is sealed!',
      AudioPriority.shieldStatus,
      soundEffect: ReefRoyaleSoundEffects.reefLock,
    );
  }

  void announceScoring(String playerName, int pearls) {
    if (pearls >= 40) {
      _queue.announce(
        'A massive pearl haul! $pearls pearls!',
        AudioPriority.hitConfirm,
        soundEffect: ReefRoyaleSoundEffects.pearlChime,
      );
    } else {
      _queue.announce(
        '$playerName harvests $pearls pearls!',
        AudioPriority.hitConfirm,
        soundEffect: ReefRoyaleSoundEffects.pearlChime,
      );
    }
  }

  void announceCursedScoring(int pearls, String opponentName) {
    _queue.announce(
      'Cursed tide! $pearls pearls weigh down $opponentName!',
      AudioPriority.hitConfirm,
      soundEffect: ReefRoyaleSoundEffects.splash,
    );
  }

  void announceNearVictory(String playerName) {
    _queue.announce(
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

    _queue.announce(
      text,
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.currentWhoosh,
    );
  }

  // --- Game Completion ---

  void announceSpeedPlayEnd() {
    _queue.announce(
      "Time's up! The tides decide the winner!",
      AudioPriority.statusChange,
      soundEffect: ReefRoyaleSoundEffects.currentWhoosh,
    );
  }

  void announceVictory(String playerName) {
    _queue.announce(
      'All hail $playerName, Crown of the Reef!',
      AudioPriority.victory,
      soundEffect: ReefRoyaleSoundEffects.victoryFanfare,
    );
  }

  void announceLockedOnTarget(int target) {
    // Locked target - no effect, no announcement
  }

  void dispose() {
    _queue.dispose();
  }
}
