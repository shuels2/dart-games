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

  void announcePlayerTurn({required String playerName}) {
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

  // ─── Private moment implementations (mirrors real helper) ─────────────────

  void _announceTouchdown({required String playerName}) {
    _record('Touchdown! $playerName lands on the moon!');
    _record(''); // victory fanfare sound (empty text, sound-only)
  }

  void _announceCrashLanding({
    required String playerName,
    required int revertedAltitude,
  }) {
    _record('Crash landing! $playerName pulls back to $revertedAltitude!');
  }

  void _announceClimbingBack({
    required String playerName,
    required int altitude,
  }) {
    _record('$playerName is climbing back! Altitude: $altitude!');
  }

  void _announceNegativeAltitude({
    required String playerName,
    required int altitude,
  }) {
    _record('$playerName overshot! Altitude: $altitude!');
  }

  void _announceNearLanding({
    required String playerName,
    required int altitude,
  }) {
    _record('Final approach! $playerName at altitude $altitude!');
  }

  void _announceBigDescent({
    required String playerName,
    required int score,
    required int newAltitude,
  }) {
    _record('Major burn! $playerName drops $score! Altitude: $newAltitude!');
  }

  void _announceStandardDescent({
    required String playerName,
    required int score,
    required int newAltitude,
  }) {
    _record('$playerName descends $score! Altitude: $newAltitude!');
  }

  void _announceMiss({required String playerName}) {
    _record('$playerName drifts in orbit!');
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  void dispose() {
    _announcements.clear();
  }
}
