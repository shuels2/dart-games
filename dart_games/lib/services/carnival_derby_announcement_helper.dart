import 'game_announcement_queue_service.dart';
import 'carnival_derby_sound_effects.dart';

/// Carnival Derby-specific announcement helper
/// Wraps the global GameAnnouncementQueueService with convenience methods
/// and automatically applies Carnival Derby sound effects
class CarnivalDerbyAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  CarnivalDerbyAnnouncementHelper(this._queue);

  // Announce player's turn
  void announceTurn(String playerName) {
    _queue.announce(
      '$playerName, it\'s your turn',
      AudioPriority.turnTransition,
      soundEffect: CarnivalDerbySoundEffects.horseraceStart,
    );
  }

  // Announce dart hit with appropriate sound effect.
  //
  // NORMAL_PER_DART announcement: gated by the System Settings →
  // Gameplay → "Per-dart score announcements" toggle. When the toggle
  // is OFF (the default), this method returns early — the player still
  // hears the dart-hit SFX from the game screen + the dartboard label
  // updates immediately, but the "Single 20 / Triple 14 / Bullseye!"
  // voice line is suppressed so per-turn audio stays short.
  void announceDart(int score, String multiplier) {
    if (!_queue.perDartScoreAnnouncementsEnabled) return;

    // Determine sound effect based on multiplier type
    SoundEffectConfig? soundEffect;

    switch (multiplier) {
      case 'bullseye':
        soundEffect = CarnivalDerbySoundEffects.bullseye;
        break;
      case 'outer_bull':
        soundEffect = CarnivalDerbySoundEffects.outerBull;
        break;
      case 'triple':
        soundEffect = CarnivalDerbySoundEffects.tripleHit;
        break;
      case 'double':
        soundEffect = CarnivalDerbySoundEffects.doubleHit;
        break;
      case 'single':
        soundEffect = CarnivalDerbySoundEffects.singleHit;
        break;
      case 'miss':
        // Miss is handled by announceMiss() method
        soundEffect = null;
        break;
      default:
        soundEffect = null;
    }

    // Get the announcement text from the dart announcer
    // We need to use the announcer's phrase generation logic
    // Since we can't easily extract just the phrase, we'll format it ourselves
    String announcement = _formatDartAnnouncement(score, multiplier);

    // Queue the announcement with sound effect
    _queue.announce(
      announcement,
      AudioPriority.hitConfirm,
      soundEffect: soundEffect,
    );
  }

  // Format dart announcement text (simplified version of DartAnnouncerService logic)
  String _formatDartAnnouncement(int score, String multiplier) {
    if (multiplier == 'bullseye') {
      return 'Bullseye! 50 points!';
    }

    if (multiplier == 'outer_bull') {
      return '25. Outer bull.';
    }

    if (multiplier == 'miss') {
      return 'Miss. No score.';
    }

    // Regular scoring announcements
    final baseScore = _getBaseScore(score, multiplier);
    final multiplierText = _getMultiplierText(multiplier);

    if (multiplierText.isEmpty) {
      return '$score';
    }
    return '$multiplierText $baseScore for $score';
  }

  int _getBaseScore(int score, String multiplier) {
    if (multiplier == 'double') return score ~/ 2;
    if (multiplier == 'triple') return score ~/ 3;
    return score;
  }

  String _getMultiplierText(String multiplier) {
    switch (multiplier) {
      case 'double':
        return 'double';
      case 'triple':
        return 'triple';
      default:
        return '';
    }
  }

  // Announce miss. Same NORMAL_PER_DART gate as announceDart — see its
  // comment for rationale.
  void announceMiss() {
    if (!_queue.perDartScoreAnnouncementsEnabled) return;
    _queue.announce(
      'Miss',
      AudioPriority.hitConfirm,
      soundEffect: CarnivalDerbySoundEffects.miss,
    );
  }

  // Announce player bust
  void announceBust(String playerName) {
    _queue.announce(
      '$playerName, you busted and your turn is over',
      AudioPriority.statusChange,
      soundEffect: CarnivalDerbySoundEffects.bust,
    );
  }

  // Announce remove darts
  void announceRemoveDarts(String playerName) {
    // Disabled 2026-05-22 by user direction: the "Remove your darts"
    // announcement (text + SFX) adds noticeable per-turn audio. The
    // original queue call is left intact below as documentation and a
    // one-line revert — drop the `return;` to re-enable.
    return;
    // ignore: dead_code
    _queue.announce(
      '$playerName, remove your darts',
      AudioPriority.turnTransition,
      soundEffect: CarnivalDerbySoundEffects.removeDarts,
    );
  }

  // Announce game completion
  void announceGameComplete() {
    _queue.announce(
      'The game is complete',
      AudioPriority.victory,
      soundEffect: CarnivalDerbySoundEffects.gameComplete,
    );
  }

  // Announce winner (no sound effect as specified by user)
  void announceWinner(String playerName) {
    _queue.announce(
      '$playerName is the winner',
      AudioPriority.victory,
    );
  }

  // Dispose the underlying queue
  void dispose() {
    _queue.dispose();
  }
}
