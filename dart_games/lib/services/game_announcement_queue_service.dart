import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'app_settings.dart';
import 'dart_announcer_service.dart';
import 'sound_effect_player_pool.dart';

export 'game_announcement_models.dart';
import 'game_announcement_models.dart';

/// Global announcement queue service used by all games
///
/// This service manages a FIFO queue of announcements with optional sound
/// effects. All games use this service to ensure announcements don't overlap
/// and play in the order they were queued. Each announcement runs to its full
/// estimated duration (max of TTS estimate + sound effect length) before the
/// next iteration starts, so short SFX never get cut off.
///
/// (Historical note: the queue used to sort by AudioPriority and preempt
/// lower-priority items mid-flight. That existed to handle announcement
/// stacking but the game screens now prevent redundant queues at the call
/// site, so strict FIFO is the desired behavior — `priority` is retained on
/// `QueuedAnnouncement` only for backwards compatibility and debug logging.)
///
/// Usage:
/// ```dart
/// final queue = GameAnnouncementQueueService();
/// await queue.loadSettings();
///
/// queue.announce(
///   'Player name, your turn',
///   AudioPriority.turnTransition,
///   soundEffect: GameSoundEffects.turnStart,
/// );
/// ```
class GameAnnouncementQueueService {
  GameAnnouncementQueueService({int sfxPoolSize = 3})
      : _sfxPool = SoundEffectPlayerPool(size: sfxPoolSize);

  // App-wide shared instance so voice settings applied via the Options
  // screen (which uses the home screen's announcer) are also what games
  // and the app-root pause/reconnect announcer speak with. Previously
  // each queue created its own DartAnnouncerService, and a fresh
  // instance querying Chrome's speechSynthesis.getVoices() before the
  // browser fired `voiceschanged` got an empty voice list — flutter_tts
  // then never called SpeechSynthesisUtterance.voice = ..., so speech
  // fell through to the OS default (German on a de-DE Windows kiosk).
  // See [DartAnnouncerService.shared].
  final DartAnnouncerService _announcer = DartAnnouncerService.shared;
  final Queue<QueuedAnnouncement> _queue = Queue<QueuedAnnouncement>();

  // Pool of AudioPlayer instances. Each SFX runs on the next player in
  // the round-robin so a still-playing/fading clip on one player does
  // NOT block the queue from starting the next clip + speech. Replaces
  // the previous single `_soundEffectPlayer` which forced the queue
  // loop to wait `remainingSfxMs` for any SFX longer than the matching
  // speech. Pool size 3 by default; configurable per-instance via the
  // constructor for games (or tests) that need more headroom.
  final SoundEffectPlayerPool _sfxPool;

  bool _isProcessing = false;
  bool _disposed = false;
  final List<Completer<void>> _idleWaiters = [];

  // Load announcer settings from API via AppSettings
  Future<void> loadSettings() async {
    // Wait for the announcer's TTS init to finish populating its
    // available-voices list. Without this, a freshly-constructed
    // DartAnnouncerService (each game screen makes one) hits
    // setSystemVoice() before flutter_tts has enumerated voices;
    // the internal firstWhere() throws, the catch swallows it, and
    // the browser silently keeps its OS-default voice — which on a
    // German-locale Windows kiosk means the game speaks German
    // even though the user saved an English voice.
    //
    // Kept OUTSIDE the outer try/catch and swallowed independently:
    // if TTS init genuinely failed, the ResponsiveVoice branch below
    // still needs to configure itself, and rate/enabled still need
    // to be applied. Only the browser-voice path depends on the
    // available-voices list.
    try {
      await _announcer.ready;
    } catch (_) {
      // Init failed — proceed anyway; browser-voice setup will just
      // be a no-op if _availableVoices is empty.
    }

    try {
      // Check if voice is enabled
      final voiceEnabled = await AppSettings.getVoiceEnabled();
      if (!voiceEnabled) {
        _announcer.setEnabled(false);
        debugPrint('Game announcement queue disabled (voice_enabled=false)');
        return;
      }

      // Load voice engine
      final engineStr = await AppSettings.getVoiceEngine() ?? 'responsiveVoice';
      final voiceEngine = VoiceEngine.values.firstWhere(
        (e) => e.toString().split('.').last == engineStr,
        orElse: () => VoiceEngine.responsiveVoice,
      );

      // Load announcer style
      final styleStr = await AppSettings.getAnnouncerStyle() ?? 'professional';
      final announcerVoice = AnnouncerVoice.values.firstWhere(
        (e) => e.toString().split('.').last == styleStr,
        orElse: () => AnnouncerVoice.professional,
      );

      _announcer.setVoice(announcerVoice);

      // Configure voice engine
      if (voiceEngine == VoiceEngine.responsiveVoice) {
        _announcer.useResponsiveVoice();
        final responsiveVoice = await AppSettings.getResponsiveVoice() ?? 'Australian Female';
        _announcer.setResponsiveVoice(responsiveVoice);
      } else if (voiceEngine == VoiceEngine.browser) {
        _announcer.useBrowserVoices();
        final systemVoice = await AppSettings.getSystemVoice();
        if (systemVoice != null) {
          _announcer.setSystemVoice(systemVoice);
        }
      }

      // User-configurable playback rate (1.0 = normal). Applied to both
      // engines on the next speak() call.
      final rate = await AppSettings.getVoicePlaybackRate();
      _announcer.setPlaybackRate(rate);

      debugPrint('Game announcement queue loaded settings: '
          'engine=$voiceEngine, style=$announcerVoice, rate=$rate');
    } catch (e) {
      debugPrint('Error loading announcer settings: $e');
    }
  }

  // Add announcement to queue with priority and optional sound effect
  void announce(String text, AudioPriority priority, {SoundEffectConfig? soundEffect}) {
    if (text.isEmpty || _disposed || !_announcer.enabled) return;

    final announcement = QueuedAnnouncement(
      text: text,
      priority: priority,
      soundEffect: soundEffect,
    );

    _queue.add(announcement);
    debugPrint('[Audio] Queued (depth=${_queue.length}, pri=${priority.name}): '
        '"$text"${soundEffect != null ? " [SFX: ${soundEffect.assetPath}]" : ""}');

    // Start processing if not already
    if (!_isProcessing) {
      _processQueue();
    }
  }

  // Process the queue (strict FIFO).
  //
  // Loop body for each announcement:
  //   1. Pop FIFO.
  //   2. Kick off the SFX on the next pool player (each SFX gets its
  //      own AudioPlayer, so a long-tail clip on the previous iteration
  //      keeps playing/fading on its own player while THIS speech runs).
  //   3. `await _announcer.speak(text)` — event-driven via ResponsiveVoice
  //      `onend` / flutter_tts setCompletionHandler. Wrapped in
  //      `.timeout(wordCount * 1000 + 1500)` as a safety net if the
  //      engine never fires completion.
  //
  // Previous design (replaced 2026-05-23): one shared AudioPlayer for
  // SFX meant the next iteration had to wait for the prior SFX to play
  // out (`remainingSfxMs` Future.delayed at the bottom of the loop)
  // before the next iteration's _soundEffectPlayer.stop() call would
  // chop it off. With the pool, no such wait is needed — old SFX runs
  // on its own player and is unaffected by the next iteration's calls.
  //
  // Historical note: an earlier "wordCount * 500 + 1500ms" fixed-wait
  // gating speech alone added 2-4s of dead air between every two
  // announcements; replaced 2026-05-22 with the event-driven speech
  // completion above.
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_queue.isNotEmpty && !_disposed) {
        // Strict FIFO — pop the oldest-queued announcement. Priority is no
        // longer used for ordering (see class doc).
        final announcement = _queue.removeFirst();
        final speakIssuedAt = DateTime.now().millisecondsSinceEpoch;
        debugPrint('[Audio] Speaking (depth=${_queue.length} remain): '
            '"${announcement.text}"');

        // Kick off the SFX on the next pool player. play() is awaited
        // here so the play-start happens before speech starts (gives
        // the two a clean shared start moment), but the pool's internal
        // fade/stop timer runs independently — we will NOT wait for
        // the SFX to finish before starting the next iteration.
        if (announcement.soundEffect != null && !_disposed) {
          final sfx = announcement.soundEffect!;
          debugPrint('Playing sound effect: ${sfx.assetPath} '
              '(start: ${sfx.startSeconds}s, '
              'end: ${sfx.endSeconds != null ? "${sfx.endSeconds}s" : "end of file"}, '
              'fadeOut: ${sfx.fadeOutMs}ms)');
          await _sfxPool.play(sfx);
        }

        if (_disposed) break;

        // Event-driven speech: await until the engine's onend / completion
        // callback fires. Past tuning iteration:
        //   - Original: wordCount * 500 + 1500 (no event-driven path)
        //   - First "tightened" pass: wordCount * 350 + 300 — TOO
        //     aggressive. Diagnostic run on Monster Mash showed onend
        //     reliably fires but at 450-880 ms/word once per-call
        //     overhead is included (e.g. "Single 20" at 1756 ms for
        //     2 words). The timeout consistently beat onend, causing
        //     the queue to advance early, calling _soundEffectPlayer
        //     .stop() on the NEXT iteration which clipped the still-
        //     playing SFX of the current announcement.
        //   - Current: wordCount * 1000 + 1500 — generous safety net
        //     that should only ever fire if onend genuinely hangs
        //     (page hidden, JS error). Observed onend max is ~880 ms/
        //     word, so the new fallback has 100%+ headroom.
        final wordCount = announcement.text.split(' ').length;
        final ttsFallbackMs = wordCount * 1000 + 1500;
        final speakStart = DateTime.now();
        bool timedOut = false;
        await _announcer.speak(announcement.text).timeout(
          Duration(milliseconds: ttsFallbackMs),
          onTimeout: () {
            timedOut = true;
            debugPrint('[Audio] TIMEOUT after ${ttsFallbackMs}ms — engine '
                'onend did NOT fire for: "${announcement.text}". This is '
                'the slow path; if it fires often the fallback is '
                'effectively the inter-announcement gap.');
          },
        );
        final speechElapsedMs =
            DateTime.now().difference(speakStart).inMilliseconds;
        debugPrint('[Audio] Done (${timedOut ? "TIMEOUT" : "onend"}, '
            'elapsed=${speechElapsedMs}ms, queue-to-start='
            '${speakStart.millisecondsSinceEpoch - speakIssuedAt}ms): '
            '"${announcement.text}"');

        if (_disposed) break;

        // No SFX-tail wait. The previous SFX (if any) continues playing
        // on its own pool player and will stop or fade-out on its own
        // schedule. The next iteration can start immediately.
      }
    } catch (e) {
      debugPrint('Announcement queue processing stopped: $e');
    }

    _isProcessing = false;
    for (final c in _idleWaiters) {
      if (!c.isCompleted) c.complete();
    }
    _idleWaiters.clear();
  }

  Future<void> whenIdle() {
    if (!_isProcessing && _queue.isEmpty) return Future.value();
    final c = Completer<void>();
    _idleWaiters.add(c);
    return c.future;
  }

  // Clear all queued announcements
  void clearQueue() {
    _queue.clear();
    debugPrint('Audio queue cleared');
  }

  // Get access to underlying announcer for direct dart announcements
  // (Carnival Derby uses this for announceDart method)
  DartAnnouncerService get announcer => _announcer;

  // Dispose resources
  void dispose() {
    _disposed = true;
    _queue.clear();
    _isProcessing = false;
    for (final c in _idleWaiters) {
      if (!c.isCompleted) c.complete();
    }
    _idleWaiters.clear();
    _sfxPool.dispose();
    _announcer.dispose();
  }
}
