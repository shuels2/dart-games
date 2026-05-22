import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';
import 'dart_announcer_service.dart';

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
  final DartAnnouncerService _announcer = DartAnnouncerService();
  final Queue<QueuedAnnouncement> _queue = Queue<QueuedAnnouncement>();
  final AudioPlayer _soundEffectPlayer = AudioPlayer();
  bool _isProcessing = false;
  bool _disposed = false;

  // Load announcer settings from API via AppSettings
  Future<void> loadSettings() async {
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
    debugPrint('Queued (${priority.name}): $text${soundEffect != null ? " [SFX: ${soundEffect.assetPath}]" : ""}');

    // Start processing if not already
    if (!_isProcessing) {
      _processQueue();
    }
  }

  // Process the queue (strict FIFO).
  //
  // Loop body for each announcement:
  //   1. Pop FIFO.
  //   2. Kick off the SFX (fire-and-forget; SFX plays in parallel with speech).
  //   3. `await _announcer.speak(text)` — event-driven: ResponsiveVoice's
  //      `onend` callback (or flutter_tts's setCompletionHandler) resolves
  //      the future the moment speech finishes. Wrapped in `.timeout()`
  //      with a tightened fallback estimate (350ms/word + 300ms) as a
  //      safety net in case the engine never fires its completion event.
  //   4. If the SFX is longer than the speech, wait the remaining SFX
  //      time so the next iteration doesn't cut it off.
  //
  // Previous version waited a fixed `wordCount * 500 + 1500ms` after EVERY
  // utterance regardless of how long the speech actually took, plus a
  // 100ms polling loop guarding `_isSpeaking`. That added 2-4 seconds of
  // dead air between announcements on a typical phrase. The user reported
  // it as "noticeable delay between dartboard label updates and audio,
  // and the same between audio segments."
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_queue.isNotEmpty && !_disposed) {
        // Strict FIFO — pop the oldest-queued announcement. Priority is no
        // longer used for ordering (see class doc).
        final announcement = _queue.removeFirst();
        debugPrint('Speaking (${announcement.priority.name}): ${announcement.text}');

        // Play sound effect if provided (fire-and-forget — SFX plays in
        // parallel with the speech below).
        int sfxMs = 0;
        if (announcement.soundEffect != null && !_disposed) {
          try {
            final sfx = announcement.soundEffect!;
            sfxMs = sfx.endSeconds != null
                ? ((sfx.endSeconds! - sfx.startSeconds) * 1000).toInt()
                : 5000; // 5s cap for "play entire file" SFX

            await _soundEffectPlayer.stop(); // Stop any previous sound effect
            await _soundEffectPlayer.setReleaseMode(ReleaseMode.stop);
            await _soundEffectPlayer.play(
              AssetSource(sfx.assetPath),
              position: Duration(milliseconds: (sfx.startSeconds * 1000).toInt()),
            );

            debugPrint('Playing sound effect: ${sfx.assetPath} '
                '(start: ${sfx.startSeconds}s, end: ${sfx.endSeconds != null ? "${sfx.endSeconds}s" : "end of file"})');

            // Schedule SFX stop if end time is set.
            if (sfx.endSeconds != null && !_disposed) {
              Future.delayed(Duration(milliseconds: sfxMs), () {
                if (!_disposed) _soundEffectPlayer.stop();
              });
            }
          } catch (e) {
            debugPrint('Error playing sound effect: $e');
          }
        }

        if (_disposed) break;

        // Event-driven speech: await until the engine's onend / completion
        // callback fires. Tightened wordCount * 350 + 300 acts as a safety
        // timeout if the callback never fires (rare, but possible on some
        // engine/browser combos).
        final wordCount = announcement.text.split(' ').length;
        final ttsFallbackMs = wordCount * 350 + 300;
        final speakStart = DateTime.now();
        await _announcer.speak(announcement.text).timeout(
          Duration(milliseconds: ttsFallbackMs),
          onTimeout: () {
            debugPrint('Speak timed out at fallback (${ttsFallbackMs}ms) — '
                'engine onend may not have fired for: ${announcement.text}');
          },
        );

        if (_disposed) break;

        // If the SFX is longer than the speech that just played, wait
        // out the remainder so it doesn't get clipped by the next
        // iteration's `_soundEffectPlayer.stop()` call.
        final speechElapsedMs =
            DateTime.now().difference(speakStart).inMilliseconds;
        final remainingSfxMs = sfxMs - speechElapsedMs;
        if (remainingSfxMs > 0) {
          await Future.delayed(Duration(milliseconds: remainingSfxMs));
        }
      }
    } catch (e) {
      debugPrint('Announcement queue processing stopped: $e');
    }

    _isProcessing = false;
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
    _soundEffectPlayer.dispose();
    _announcer.dispose();
  }
}
