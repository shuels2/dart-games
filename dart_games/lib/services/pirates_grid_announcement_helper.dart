import 'game_announcement_queue_service.dart';
import 'pirates_grid_sound_effects.dart';

/// Pirate's Grid–specific announcement helper.
///
/// Wraps the global [GameAnnouncementQueueService] with game-specific
/// convenience methods. Implements a "gather facts, pick winner" precedence
/// chain so that at most ONE moment announcement fires per dart event.
///
/// Precedence (highest → lowest):
///   1. Match Victory  — matchWinnerId changed
///   2. Round Victory  — round winnerId changed
///   3. Round Draw     — isDraw became true
///   4. Match Draw     — isMatchDraw became true
///   5. Two in a Row   — player has 2-in-a-row with empty third cell
///   6. Flag Planted   — cell was empty, now claimed by current player
///   7. Square Stolen  — cell had opponent flag, stealMode ON, now claimed
///   8. Already Claimed (own)       — matched cell is already own flag
///   9. Already Claimed (opponent)  — matched cell is opponent's, stealMode OFF
///  10. Miss           — dart hit no cell at all
class PiratesGridAnnouncementHelper {
  final GameAnnouncementQueueService _queueService;

  PiratesGridAnnouncementHelper(this._queueService);

  // ─── Lifecycle / standalone ──────────────────────────────────────────────────

  /// Game start announcement — fires once after queue loads.
  void announceGameStart() {
    _queueService.announce(
      'Set sail! The grid awaits, captains!',
      AudioPriority.statusChange,
      soundEffect: PiratesGridSoundEffects.shipBell,
    );
  }

  /// Player turn announcement — fires at start of each turn.
  void announcePlayerTurn(String playerName) {
    _queueService.announce(
      '$playerName, take the helm!',
      AudioPriority.turnTransition,
      soundEffect: PiratesGridSoundEffects.shipBell,
    );
  }

  /// Round transition announcement — fires between rounds in Best Of 3/5.
  void announceRoundTransition(int round) {
    _queueService.announce(
      'Round $round! Reset the grid!',
      AudioPriority.statusChange,
      soundEffect: PiratesGridSoundEffects.shipBell,
    );
  }

  /// Speed Play timer expired — fires when turn auto-ends.
  void announceTimerExpired() {
    _queueService.announce(
      "Time's up! The wind takes yer darts!",
      AudioPriority.statusChange,
      soundEffect: PiratesGridSoundEffects.timerTick,
    );
  }

  // ─── Per-dart moment announcements ──────────────────────────────────────────

  /// Flag planted on an empty cell.
  void announceFlagPlanted(String playerName, String target) {
    _queueService.announce(
      '$playerName plants a flag at $target!',
      AudioPriority.hitConfirm,
      soundEffect: PiratesGridSoundEffects.flagPlant,
    );
  }

  /// Square stolen from opponent (Steal Mode ON).
  void announceSquareStolen(String playerName, String opponentName) {
    _queueService.announce(
      'Mutiny! $playerName steals the square from $opponentName!',
      AudioPriority.hitConfirm,
      soundEffect: PiratesGridSoundEffects.swordClash,
    );
  }

  /// Dart matched no cell on the grid.
  void announceMiss() {
    _queueService.announce(
      'Lost at sea! No square claimed.',
      AudioPriority.hitConfirm,
      soundEffect: PiratesGridSoundEffects.waveCrash,
    );
  }

  /// Dart matched a cell already occupied.
  ///
  /// [isOwn] — true if the cell belongs to the current player,
  ///           false if it belongs to the opponent (Steal Mode OFF).
  void announceAlreadyClaimed({required bool isOwn}) {
    final text = isOwn
        ? 'Yer flag already flies there, captain!'
        : 'That square is defended!';
    _queueService.announce(
      text,
      AudioPriority.hitConfirm,
      soundEffect: PiratesGridSoundEffects.waveCrash,
    );
  }

  /// Player has exactly 2 flags in a line with the third cell still empty.
  void announceTwoInARow(String playerName) {
    _queueService.announce(
      '$playerName has two in a row! One more for treasure!',
      AudioPriority.statusChange,
      soundEffect: PiratesGridSoundEffects.flagPlant,
    );
  }

  /// Round winner determined (3-in-a-row claimed).
  void announceRoundVictory(String playerName) {
    _queueService.announce(
      'Treasure found! $playerName claims the map!',
      AudioPriority.victory,
      soundEffect: PiratesGridSoundEffects.treasureFound,
    );
  }

  /// Round ended in a draw (all 9 squares filled, no 3-in-a-row).
  void announceRoundDraw() {
    _queueService.announce(
      'A stalemate! Neither captain claims the map!',
      AudioPriority.statusChange,
      soundEffect: PiratesGridSoundEffects.waveCrash,
    );
  }

  /// Match winner determined (Best Of reached).
  void announceMatchVictory(String playerName) {
    _queueService.announce(
      'Captain $playerName rules the seas!',
      AudioPriority.victory,
      soundEffect: PiratesGridSoundEffects.cannonBoom,
    );
  }

  /// Match ended in a draw (all rounds played, no winner).
  void announceMatchDraw() {
    _queueService.announce(
      'The seas remain unclaimed! A true stalemate!',
      AudioPriority.statusChange,
      soundEffect: PiratesGridSoundEffects.waveCrash,
    );
  }

  // ─── Always-fires ────────────────────────────────────────────────────────────

  /// "Remove your darts" prompt — ALWAYS called unconditionally in the
  /// takeout handler. NEVER suppressed by the precedence chain.
  void announceRemoveDarts(String playerName) {
    _queueService.announce(
      '$playerName, remove your darts',
      AudioPriority.turnTransition,
    );
  }

  // ─── Alias ───────────────────────────────────────────────────────────────────

  /// Alias for [announceMatchVictory] — used by the canonical
  /// `_handleGameWon` pattern in the game screen.
  void announceWinner(String playerName) {
    announceMatchVictory(playerName);
  }

  // ─── Connection-status announcements ────────────────────────────────────────

  /// Voice-only "game paused — dartboard disconnected" announcement.
  /// Fired by [DartboardStatusAnnouncer] when the dartboard drops mid-game.
  void announceGamePaused() {
    _queueService.announce(
      'Dartboard disconnected. Game paused. Will resume when the connection is restored.',
      AudioPriority.statusChange,
    );
  }

  /// Voice-only "dartboard reconnected" announcement, fired by
  /// [DartboardStatusAnnouncer] when the dartboard returns to connected.
  void announceConnectionRestored() {
    _queueService.announce(
      'Dartboard reconnected. Resume play when ready.',
      AudioPriority.statusChange,
    );
  }

  Future<void> whenIdle() => _queueService.whenIdle();

  void dispose() {
    _queueService.dispose();
  }
}
