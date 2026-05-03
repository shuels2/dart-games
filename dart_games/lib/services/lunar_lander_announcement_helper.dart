import 'game_announcement_queue_service.dart';
import 'lunar_lander_sound_effects.dart';

/// Lunar Lander-specific announcement helper.
///
/// Wraps the global [GameAnnouncementQueueService] with game-specific
/// convenience methods. Implements a "gather facts, pick winner" precedence
/// chain so that at most ONE moment announcement fires per dart event.
///
/// Precedence (highest → lowest):
///   1. Touchdown  — hasWinner == true
///   2. Crash Landing — hardLandingEnabled + wasBust
///   3. Climbing Back — HL OFF + prevAlt < 0 + newAlt > prevAlt + newAlt < 0
///   4. Negative Altitude — HL OFF + newAlt < 0
///   5. Near Landing — newAlt in (0, 20]
///   6. Big Descent — dartScore >= 40
///   7. Standard Descent — dartScore in [1, 39]
///   8. Miss / Drift — dartScore == 0
class LunarLanderAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  LunarLanderAnnouncementHelper(this._queue);

  // ─── Lifecycle / standalone ──────────────────────────────────────────────────

  /// Plays the game-start announcement once, immediately after the queue loads.
  void announceGameStart({required int startingAltitude}) {
    _queue.announce(
      'Mission control, altitude $startingAltitude! Begin descent!',
      AudioPriority.statusChange,
      soundEffect: LunarLanderSoundEffects.missionControl,
    );
  }

  /// Plays the player-turn announcement (e.g. after takeout).
  void announcePlayerTurn({required String playerName}) {
    _queue.announce(
      '$playerName, you have the controls!',
      AudioPriority.turnTransition,
      soundEffect: LunarLanderSoundEffects.radioBeep,
    );
  }

  /// Plays the "Remove your darts" prompt.
  ///
  /// This is ALWAYS called unconditionally at takeout — it is NEVER gated by
  /// the moment-announcement precedence chain.
  void announceRemoveDarts() {
    _queue.announce(
      'Remove your darts',
      AudioPriority.turnTransition,
    );
  }

  // ─── Moment announcement — one per dart ─────────────────────────────────────

  /// Selects and plays exactly ONE moment announcement based on the precedence
  /// chain for the outcome of a single dart throw.
  ///
  /// Call this ONCE per dart in the game screen. Do NOT call the private
  /// announce* methods directly from outside this class.
  ///
  /// Parameters:
  ///   [playerName]        — current player's display name
  ///   [dartScore]         — computed dart value (e.g. 60 for triple-20)
  ///   [previousAltitude]  — altitude at the START of this dart's processing
  ///   [newAltitude]       — altitude AFTER the dart was processed (post-revert
  ///                         if bust, or post-overshoot if HL OFF)
  ///   [wasBust]           — true if hardLandingEnabled AND this dart caused a bust
  ///   [hasWinner]         — true if this dart caused a win
  ///   [hardLandingEnabled]— game option value
  void announceMomentForDart({
    required String playerName,
    required int dartScore,
    required int previousAltitude,
    required int newAltitude,
    required bool wasBust,
    required bool hasWinner,
    required bool hardLandingEnabled,
  }) {
    // Pick ONE moment announcement based on precedence (highest first).
    if (hasWinner) {
      _announceTouchdown(playerName: playerName);
    } else if (wasBust) {
      _announceCrashLanding(playerName: playerName, revertedAltitude: newAltitude);
    } else if (!hardLandingEnabled &&
        previousAltitude < 0 &&
        newAltitude > previousAltitude &&
        newAltitude < 0) {
      _announceClimbingBack(playerName: playerName, altitude: newAltitude);
    } else if (!hardLandingEnabled && newAltitude < 0) {
      _announceNegativeAltitude(playerName: playerName, altitude: newAltitude);
    } else if (newAltitude > 0 && newAltitude <= 20) {
      _announceNearLanding(playerName: playerName, altitude: newAltitude);
    } else if (dartScore >= 40) {
      _announceBigDescent(playerName: playerName, score: dartScore, newAltitude: newAltitude);
    } else if (dartScore >= 1) {
      _announceStandardDescent(playerName: playerName, score: dartScore, newAltitude: newAltitude);
    } else {
      _announceMiss(playerName: playerName);
    }
  }

  // ─── Private moment-announcement implementations ─────────────────────────────

  void _announceTouchdown({required String playerName}) {
    _queue.announce(
      'Touchdown! $playerName lands on the moon!',
      AudioPriority.victory,
      soundEffect: LunarLanderSoundEffects.touchdown,
    );
    // Queue victory fanfare as a separate sound announcement (no voice text)
    _queue.announce(
      '',
      AudioPriority.victory,
      soundEffect: LunarLanderSoundEffects.victoryFanfare,
    );
  }

  void _announceCrashLanding({
    required String playerName,
    required int revertedAltitude,
  }) {
    _queue.announce(
      'Crash landing! $playerName pulls back to $revertedAltitude!',
      AudioPriority.hitConfirm,
      soundEffect: LunarLanderSoundEffects.crashLanding,
    );
  }

  void _announceClimbingBack({
    required String playerName,
    required int altitude,
  }) {
    _queue.announce(
      '$playerName is climbing back! Altitude: $altitude!',
      AudioPriority.hitConfirm,
      soundEffect: LunarLanderSoundEffects.thrusterBurn,
    );
  }

  void _announceNegativeAltitude({
    required String playerName,
    required int altitude,
  }) {
    _queue.announce(
      '$playerName overshot! Altitude: $altitude!',
      AudioPriority.hitConfirm,
      soundEffect: LunarLanderSoundEffects.crashLanding,
    );
  }

  void _announceNearLanding({
    required String playerName,
    required int altitude,
  }) {
    _queue.announce(
      'Final approach! $playerName at altitude $altitude!',
      AudioPriority.statusChange,
      soundEffect: LunarLanderSoundEffects.warningAlarm,
    );
  }

  void _announceBigDescent({
    required String playerName,
    required int score,
    required int newAltitude,
  }) {
    _queue.announce(
      'Major burn! $playerName drops $score! Altitude: $newAltitude!',
      AudioPriority.hitConfirm,
      soundEffect: LunarLanderSoundEffects.thrusterBurn,
    );
  }

  void _announceStandardDescent({
    required String playerName,
    required int score,
    required int newAltitude,
  }) {
    _queue.announce(
      '$playerName descends $score! Altitude: $newAltitude!',
      AudioPriority.hitConfirm,
      soundEffect: LunarLanderSoundEffects.thrusterBurn,
    );
  }

  void _announceMiss({required String playerName}) {
    _queue.announce(
      '$playerName drifts in orbit!',
      AudioPriority.hitConfirm,
      soundEffect: LunarLanderSoundEffects.driftSound,
    );
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────────

  void dispose() {
    _queue.dispose();
  }
}
