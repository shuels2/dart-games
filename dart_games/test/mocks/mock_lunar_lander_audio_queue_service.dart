import 'package:flutter/foundation.dart';

/// Mock announcement helper for Lunar Lander tests.
///
/// Records all method calls so tests can assert on the announcement sequence
/// without touching any real audio APIs.
///
/// Usage:
/// ```dart
/// final mock = MockLunarLanderAudioQueueService();
/// mock.announceGameStart(startingAltitude: 200);
/// expect(mock.recordedAnnouncements, ['Mission control, altitude 200! Begin descent!']);
/// ```
class MockLunarLanderAudioQueueService {
  final List<String> _announcements = [];

  // ─── Public accessors ──────────────────────────────────────────────────────

  /// All announcement texts recorded in the order they were queued.
  List<String> get recordedAnnouncements => List.unmodifiable(_announcements);

  /// Total count of announcements queued.
  int get announcementCount => _announcements.length;

  /// Clear all recorded announcements (call between assertion groups).
  void clearAnnouncements() {
    _announcements.clear();
  }

  // ─── Internal record helper ────────────────────────────────────────────────

  void _record(String text) {
    _announcements.add(text);
    debugPrint('Mock LunarLander announcement: $text');
  }

  // ─── Lifecycle / standalone ────────────────────────────────────────────────

  void announceGameStart({required int startingAltitude}) {
    _record('Mission control, altitude $startingAltitude! Begin descent!');
  }

  void announcePlayerTurn({
    required String playerName,
    required int altitude,
  }) {
    _record('$playerName, you have the controls!');
  }

  /// Always-fires remove-darts prompt (unconditional, never suppressed).
  void announceRemoveDarts() {
    _record('Remove your darts');
  }

  // ─── Moment announcement — one per dart ───────────────────────────────────

  /// Applies the same precedence chain as the real helper and records the
  /// single winning announcement (+ victory fanfare text for touchdown).
  ///
  /// Mirrors `LunarLanderAnnouncementHelper.announceMomentForDart` exactly.
  void announceMomentForDart({
    required String playerName,
    required int dartScore,
    required int previousAltitude,
    required int newAltitude,
    required bool wasBust,
    required bool hasWinner,
    required bool hardLandingEnabled,
  }) {
    if (hasWinner) {
      return;
    } else if (wasBust) {
      _announceCrashLanding(playerName: playerName, revertedAltitude: newAltitude);
    } else if (!hardLandingEnabled &&
        previousAltitude < 0 &&
        newAltitude > previousAltitude &&
        newAltitude < 0) {
      _announceClimbingBack(playerName: playerName, altitude: newAltitude);
    } else if (!hardLandingEnabled && newAltitude < 0) {
      _announceNegativeAltitude(score: dartScore);
    } else if (newAltitude > 0 && newAltitude <= 20) {
      _announceNearLanding(playerName: playerName, altitude: newAltitude);
    } else if (dartScore >= 40) {
      _announceBigDescent(playerName: playerName, score: dartScore);
    } else if (dartScore >= 1) {
      _announceStandardDescent(playerName: playerName, score: dartScore);
    } else {
      _announceMiss(playerName: playerName);
    }
  }

  // ─── Private moment implementations (mirrors real helper) ─────────────────

  void _announceTouchdown({required String playerName}) {
    _record('Touchdown! $playerName lands on the moon!');
    _record(''); // victory fanfare sound (empty text, sound-only)
  }

  void announceWinner(String playerName) {
    _announceTouchdown(playerName: playerName);
  }

  void _announceCrashLanding({
    required String playerName,
    required int revertedAltitude,
  }) {
    _record('Crash landing! Pulling back to $revertedAltitude.');
  }

  void _announceClimbingBack({
    required String playerName,
    required int altitude,
  }) {
    _record('Climbing back! Altitude $altitude.');
  }

  void _announceNegativeAltitude({
    required int score,
  }) {
    _record('Rough landing! Descending $score.');
  }

  void _announceNearLanding({
    required String playerName,
    required int altitude,
  }) {
    _record('Final approach! Altitude $altitude!');
  }

  void _announceBigDescent({
    required String playerName,
    required int score,
  }) {
    _record('Major burn! Descending $score.');
  }

  void _announceStandardDescent({
    required String playerName,
    required int score,
  }) {
    _record('Descending $score!');
  }

  void _announceMiss({required String playerName}) {
    _record('Whiff. Drifting in orbit!');
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
    _announcements.clear();
  }
}
