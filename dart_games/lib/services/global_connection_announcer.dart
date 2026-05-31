import 'game_announcement_queue_service.dart';

/// App-root scoped announcer for dartboard pause / reconnect voice lines.
///
/// Why this exists instead of the per-game announcement helpers:
/// [DartboardPausedModal] is rendered on ALL 28 screens (home + 9 game
/// menus + 9 game screens + 9 results screens) whenever the dartboard
/// drops connection. The per-game audio helpers only exist while the
/// user is inside a game screen — so a disconnect on the home screen
/// would have no audio companion. This service owns its own
/// [GameAnnouncementQueueService] that persists for the lifetime of
/// the app, so the announcement fires regardless of which route is
/// active.
///
/// Initialized once from [main] and consumed via [instance].
class GlobalConnectionAnnouncer {
  GlobalConnectionAnnouncer._();
  static final GlobalConnectionAnnouncer instance =
      GlobalConnectionAnnouncer._();

  // sfxPoolSize 1: this service is voice-only — no SFX is ever passed
  // to its announce calls — so the smallest possible pool is correct.
  final GameAnnouncementQueueService _queue =
      GameAnnouncementQueueService(sfxPoolSize: 1);

  bool _initialized = false;

  /// Load voice settings into the underlying queue. Call once from
  /// [main] before the widget tree mounts.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _queue.loadSettings();
  }

  /// Plays "Dartboard disconnected. Game paused. Will resume when the
  /// connection is restored." — fired by the app-root
  /// [DartboardStatusAnnouncer] when the WS drops mid-anywhere.
  void announceGamePaused() {
    _queue.announce(
      'Dartboard disconnected. Game paused. Will resume when the connection is restored.',
      AudioPriority.statusChange,
    );
  }

  /// Plays "Dartboard reconnected. Resume play when ready." — fired by
  /// the app-root [DartboardStatusAnnouncer] when the WS comes back.
  void announceConnectionRestored() {
    _queue.announce(
      'Dartboard reconnected. Resume play when ready.',
      AudioPriority.statusChange,
    );
  }
}
