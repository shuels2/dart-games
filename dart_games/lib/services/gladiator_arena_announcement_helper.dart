import 'game_announcement_queue_service.dart';
import 'gladiator_arena_sound_effects.dart';

/// Gladiator Arena-specific announcement helper.
///
/// Wraps the global [GameAnnouncementQueueService] with game-specific
/// convenience methods. Implements a "gather facts, pick winner" precedence
/// chain so that at most ONE moment announcement fires per dart event.
///
/// Precedence (highest → lowest):
///   1.  Victory            — hasWinner == true
///   2.  Knockoff!          — knockoff occurred this turn, shield NOT active
///   3.  Shield Block       — score match blocked by isShieldRound
///   4.  Bust (overshoot)   — DF ON AND prospective > target
///   5.  Bust (no double)   — DF ON AND prospective == target AND last segment NOT 'D'
///   6.  Bull inner (50)    — sector == 'Bull'
///   7.  Bull outer (25)    — sector == '25'
///   8.  Triple Hit         — multiplier == 'triple'
///   9.  Great Hit (40+)    — dart value >= 40 AND multiplier != 'triple'
///  10.  Good Hit (20-39)   — dart value 20-39 AND multiplier == 'single'
///  11.  Small Hit (1-19)   — dart value 1-19 AND multiplier == 'single'
///  12.  Miss               — dart value 0
class GladiatorArenaAnnouncementHelper {
  final GameAnnouncementQueueService _queueService;

  GladiatorArenaAnnouncementHelper({required GameAnnouncementQueueService queueService})
      : _queueService = queueService;

  // ─── Lifecycle / standalone ──────────────────────────────────────────────────

  /// Fires immediately after game initialisation with the target score.
  void announceGameStart(int targetScore) {
    _queueService.announce(
      'Gladiators, enter the arena! Race to $targetScore!',
      AudioPriority.statusChange,
      soundEffect: GladiatorArenaSoundEffects.trumpetFanfare,
    );
  }

  /// Fires at the start of each player's turn.
  void announcePlayerTurn(String playerName) {
    _queueService.announce(
      '$playerName, step into the arena!',
      AudioPriority.turnTransition,
      soundEffect: GladiatorArenaSoundEffects.turnBell,
    );
  }

  /// Fires when a shield round begins.
  void announceShieldRoundStart() {
    _queueService.announce(
      'Shield round! The arena grants mercy!',
      AudioPriority.statusChange,
      soundEffect: GladiatorArenaSoundEffects.shieldBlock,
    );
  }

  /// Fires when the active player enters double range (DF ON).
  void announceDoubleRange(String playerName) {
    _queueService.announce(
      '$playerName enters double range!',
      AudioPriority.statusChange,
      soundEffect: GladiatorArenaSoundEffects.swordClash,
    );
  }

  /// Fires when the active player is close to the target score.
  void announceNearVictory(String playerName) {
    _queueService.announce(
      '$playerName is close to glory!',
      AudioPriority.statusChange,
      soundEffect: GladiatorArenaSoundEffects.trumpetFanfare,
    );
  }

  /// Fires when the speed-play timer is running low.
  void announceSpeedTimerWarning() {
    _queueService.announce(
      'The sands are running out!',
      AudioPriority.statusChange,
      soundEffect: GladiatorArenaSoundEffects.timerTick,
    );
  }

  /// Fires when the speed-play timer reaches zero.
  void announceSpeedTimerExpired() {
    _queueService.announce(
      'Time! The arena waits for no one!',
      AudioPriority.statusChange,
      soundEffect: GladiatorArenaSoundEffects.turnBell,
    );
  }

  /// Fires UNCONDITIONALLY when the remove-darts prompt becomes active.
  ///
  /// This is ALWAYS called unconditionally at takeout — it is NEVER gated by
  /// the moment-announcement precedence chain.
  void announceRemoveDarts() {
    _queueService.announce(
      'Remove your darts',
      AudioPriority.turnTransition,
    );
  }

  // ─── Per-dart moment announcements ──────────────────────────────────────────

  void announceVictory(String playerName) {
    _queueService.announce(
      'All hail $playerName, Champion of the Arena!',
      AudioPriority.victory,
      soundEffect: GladiatorArenaSoundEffects.trumpetFanfare,
    );
  }

  void announceKnockoff(String victimName) {
    _queueService.announce(
      '$victimName is knocked off! Back to zero!',
      AudioPriority.shieldStatus,
      soundEffect: GladiatorArenaSoundEffects.crowdGasp,
    );
  }

  void announceShieldBlock(String victimName) {
    _queueService.announce(
      'Shields up! $victimName is protected!',
      AudioPriority.shieldStatus,
      soundEffect: GladiatorArenaSoundEffects.shieldBlock,
    );
  }

  void announceBustOvershoot(String playerName) {
    _queueService.announce(
      '$playerName overshoots! Score unchanged!',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.crowdGasp,
    );
  }

  void announceBustNoDouble() {
    _queueService.announce(
      'Not a double! The champion must earn their laurel!',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.crowdGasp,
    );
  }

  void announceBullInner() {
    _queueService.announce(
      'Bullseye! 50 glory points!',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.crowdCheer,
    );
  }

  void announceBullOuter() {
    _queueService.announce(
      'Outer bull! 25 glory points!',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.swordClash,
    );
  }

  void announceTripleHit(int n) {
    _queueService.announce(
      'A triple! $n glory points!',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.crowdCheer,
    );
  }

  void announceGreatHit(int n) {
    _queueService.announce(
      'The crowd goes wild! $n points!',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.crowdCheer,
    );
  }

  void announceGoodHit(int n) {
    _queueService.announce(
      'A mighty strike! $n points!',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.swordClash,
    );
  }

  void announceSmallHit(String playerName, int n) {
    _queueService.announce(
      '$n points.',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.swordClash,
    );
  }

  void announceMiss() {
    _queueService.announce(
      'The dart finds only sand!',
      AudioPriority.hitConfirm,
      soundEffect: GladiatorArenaSoundEffects.missThud,
    );
  }

  // ─── Precedence-chain dispatcher ────────────────────────────────────────────

  /// Selects and fires exactly ONE moment announcement based on the precedence
  /// chain for the outcome of a single dart throw.
  ///
  /// Call this ONCE per dart in the game screen (after [processDartThrow]).
  /// Do NOT call the individual announce* moment methods directly from the screen.
  ///
  /// Parameters:
  ///   [playerName]        — current player's display name
  ///   [dartValue]         — computed dart value (e.g. 60 for T20, 0 for miss)
  ///   [multiplier]        — raw multiplier string: 'single', 'double', 'triple',
  ///                         'bull', 'miss'
  ///   [sector]            — raw sector string from the dartboard event (e.g. 'T20',
  ///                         'D10', 'Bull', '25', 'Miss')
  ///   [hasWinner]         — true if this dart caused a win (read AFTER processDartThrow)
  ///   [knockoffVictimName]— non-null if a knockoff occurred this turn; the name
  ///                         of the player who was knocked off
  ///   [shieldBlockedName] — non-null if a shield round blocked a would-be knockoff;
  ///                         the name of the player who would have been knocked off
  ///   [wasBustOvershoot]  — true if DF ON AND prospective > target
  ///   [wasBustNoDouble]   — true if DF ON AND prospective == target AND last
  ///                         dart segment was NOT a double
  void pickAndAnnounceMoment({
    required String playerName,
    required int dartValue,
    required String multiplier,
    required String sector,
    required bool hasWinner,
    String? knockoffVictimName,
    String? shieldBlockedName,
    required bool wasBustOvershoot,
    required bool wasBustNoDouble,
  }) {
    // 1. Victory
    if (hasWinner) {
      announceVictory(playerName);
      return;
    }

    // 2. Knockoff!
    if (knockoffVictimName != null) {
      announceKnockoff(knockoffVictimName);
      return;
    }

    // 3. Shield Block
    if (shieldBlockedName != null) {
      announceShieldBlock(shieldBlockedName);
      return;
    }

    // 4. Bust (overshoot)
    if (wasBustOvershoot) {
      announceBustOvershoot(playerName);
      return;
    }

    // 5. Bust (no double)
    if (wasBustNoDouble) {
      announceBustNoDouble();
      return;
    }

    // 6. Bull inner (50 pts)
    if (sector == 'Bull') {
      announceBullInner();
      return;
    }

    // 7. Bull outer (25 pts)
    if (sector == '25') {
      announceBullOuter();
      return;
    }

    // 8. Triple Hit
    if (multiplier == 'triple') {
      announceTripleHit(dartValue);
      return;
    }

    // 9. Great Hit (40+, not triple)
    if (dartValue >= 40) {
      announceGreatHit(dartValue);
      return;
    }

    // 10. Good Hit (20-39)
    if (dartValue >= 20) {
      announceGoodHit(dartValue);
      return;
    }

    // 11. Small Hit (1-19)
    if (dartValue >= 1) {
      announceSmallHit(playerName, dartValue);
      return;
    }

    // 12. Miss
    announceMiss();
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

  // ─── Dispose ─────────────────────────────────────────────────────────────────

  void dispose() {
    _queueService.dispose();
  }
}
