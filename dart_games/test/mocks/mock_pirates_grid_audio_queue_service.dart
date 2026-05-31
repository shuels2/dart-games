import 'package:flutter/foundation.dart';

/// Mock announcement helper for Pirate's Grid tests.
///
/// Records every announcement call so tests can assert on the announcement
/// sequence without touching any real audio APIs.
///
/// Usage:
/// ```dart
/// final mock = MockPiratesGridAudioQueueService();
/// mock.announceGameStart();
/// expect(mock.recordedAnnouncements, ['Set sail! The grid awaits, captains!']);
/// ```
class MockPiratesGridAudioQueueService {
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
    debugPrint('Mock PiratesGrid announcement: $text');
  }

  // ─── Lifecycle / standalone ────────────────────────────────────────────────

  void announceGameStart() {
    _record('Set sail! The grid awaits, captains!');
  }

  void announcePlayerTurn(String playerName) {
    _record('$playerName, take the helm!');
  }

  void announceRoundTransition(int round) {
    _record('Round $round! Reset the grid!');
  }

  void announceSpeedTimerWarning() {
    _record('The wind is picking up!');
  }

  void announceTimerExpired() {
    _record("Time's up! The wind takes yer darts!");
  }

  // ─── Per-dart moment announcements ────────────────────────────────────────

  void announceFlagPlanted(String playerName, String target) {
    _record('Flag planted at $target!');
  }

  void announceSquareStolen(String playerName, String target, String opponentName) {
    _record('Mutiny! $playerName steals $target!');
  }

  void announceMiss() {
    _record('Lost at sea! No square claimed.');
  }

  void announceAlreadyClaimed({required bool isOwn}) {
    final text = isOwn
        ? 'Yer flag already flies there, captain!'
        : 'That square is defended!';
    _record(text);
  }

  void announceTwoInARow(String playerName, String target) {
    _record('$target claimed! That\'s two in a row! One more for treasure!');
  }

  void announceRoundVictory(String playerName) {
    _record('Treasure found! $playerName claims the map!');
  }

  void announceRoundDraw() {
    _record('A stalemate! Neither captain claims the map!');
  }

  void announceMatchVictory(String playerName) {
    _record('Captain $playerName rules the seas!');
  }

  void announceMatchDraw() {
    _record('The seas remain unclaimed! A true stalemate!');
  }

  // ─── Always-fires ──────────────────────────────────────────────────────────

  /// Always-fires remove-darts prompt (unconditional, never suppressed).
  void announceRemoveDarts(String playerName) {
    _record('$playerName, remove your darts');
  }

  // ─── Alias ────────────────────────────────────────────────────────────────

  void announceWinner(String playerName) {
    announceMatchVictory(playerName);
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
