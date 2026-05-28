import 'package:flutter/foundation.dart';

/// Mock announcement helper for Gladiator Arena tests.
///
/// Records all method calls so tests can assert on the announcement sequence
/// without touching any real audio APIs.
///
/// The mock mirrors [GladiatorArenaAnnouncementHelper] exactly — same public
/// API, same precedence logic in [pickAndAnnounceMoment], but only records
/// calls instead of queuing real audio.
///
/// Usage:
/// ```dart
/// final mock = MockGladiatorArenaAudioQueueService();
/// mock.announceGameStart(200);
/// expect(mock.queuedTexts, ['Gladiators, enter the arena! Race to 200!']);
/// ```
class MockGladiatorArenaAudioQueueService {
  final List<String> _texts = [];
  bool _removeDartsAnnounced = false;

  // ─── Public accessors ──────────────────────────────────────────────────────

  /// All announcement texts recorded in the order they were queued.
  List<String> get queuedTexts => List.unmodifiable(_texts);

  /// True when [announceRemoveDarts] has been called at least once since last [clear].
  bool get removeDartsAnnounced => _removeDartsAnnounced;

  /// Total number of announcements queued.
  int get announcementCount => _texts.length;

  /// Reset all recorded state between tests.
  void clear() {
    _texts.clear();
    _removeDartsAnnounced = false;
  }

  // ─── Internal record helper ───────────────────────────────────────────────

  void _record(String text) {
    _texts.add(text);
    debugPrint('Mock GladiatorArena announcement: $text');
  }

  // ─── Lifecycle / standalone ───────────────────────────────────────────────

  void announceGameStart(int targetScore) {
    _record('Gladiators, enter the arena! Race to $targetScore!');
  }

  void announcePlayerTurn(String playerName) {
    _record('$playerName, step into the arena!');
  }

  void announceShieldRoundStart() {
    _record('Shield round! The arena grants mercy!');
  }

  void announceDoubleRange(String playerName) {
    _record('$playerName enters double range!');
  }

  void announceNearVictory(String playerName) {
    _record('$playerName is close to glory!');
  }

  void announceSpeedTimerWarning() {
    _record('The sands are running out!');
  }

  void announceSpeedTimerExpired() {
    _record('Time! The arena waits for no one!');
  }

  /// Always-fires remove-darts prompt (unconditional, never suppressed).
  void announceRemoveDarts() {
    _removeDartsAnnounced = true;
    _record('Remove your darts');
  }

  // ─── Per-dart moment announcements ───────────────────────────────────────

  void announceVictory(String playerName) {
    _record('All hail $playerName, Champion of the Arena!');
  }

  void announceKnockoff(String victimName) {
    _record('$victimName is knocked off! Back to zero!');
  }

  void announceShieldBlock(String victimName) {
    _record('Shields up! $victimName is protected!');
  }

  void announceBustOvershoot(String playerName) {
    _record('$playerName overshoots! Score unchanged!');
  }

  void announceBustNoDouble() {
    _record('Not a double! The champion must earn their laurel!');
  }

  void announceBullInner() {
    _record('Bullseye! 50 glory points!');
  }

  void announceBullOuter() {
    _record('Outer bull! 25 glory points!');
  }

  void announceTripleHit(int n) {
    _record('A triple! $n glory points!');
  }

  void announceGreatHit(int n) {
    _record('The crowd goes wild! $n points!');
  }

  void announceGoodHit(int n) {
    _record('A mighty strike! $n points!');
  }

  void announceSmallHit(String playerName, int n) {
    _record('$n points.');
  }

  void announceMiss() {
    _record('The dart finds only sand!');
  }

  // ─── Precedence-chain dispatcher ─────────────────────────────────────────

  /// Mirrors [GladiatorArenaAnnouncementHelper.pickAndAnnounceMoment] exactly.
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

    // 10. Good Hit (20-39, single)
    if (dartValue >= 20 && multiplier == 'single') {
      announceGoodHit(dartValue);
      return;
    }

    // 11. Small Hit (1-19, single)
    if (dartValue >= 1 && multiplier == 'single') {
      announceSmallHit(playerName, dartValue);
      return;
    }

    // 12. Miss
    announceMiss();
  }

  // ─── Connection-status announcements ──────────────────────────────────────

  void announceGamePaused() {
    _record(
      'Dartboard disconnected. Game paused. Will resume when the connection is restored.',
    );
  }

  void announceConnectionRestored() {
    _record('Dartboard reconnected. Resume play when ready.');
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  void dispose() {
    _texts.clear();
  }
}
