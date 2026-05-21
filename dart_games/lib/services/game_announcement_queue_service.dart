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
  bool _isSpeaking = false;
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

      debugPrint('Game announcement queue loaded settings: engine=$voiceEngine, style=$announcerVoice');
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

  // Process the queue (priority-based FIFO)
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_queue.isNotEmpty && !_disposed) {
        // Wait if currently speaking
        while (_isSpeaking && !_disposed) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (_disposed) break;

        // Strict FIFO — pop the oldest-queued announcement. Priority is no
        // longer used for ordering (see class doc).
        final announcement = _queue.removeFirst();

        // Speak the announcement and play sound effect simultaneously
        _isSpeaking = true;
        debugPrint('Speaking (${announcement.priority.name}): ${announcement.text}');

        // Play sound effect if provided
        if (announcement.soundEffect != null && !_disposed) {
          try {
            final sfx = announcement.soundEffect!;
            await _soundEffectPlayer.stop(); // Stop any previous sound effect

            // Set release mode to stop (don't loop or release)
            await _soundEffectPlayer.setReleaseMode(ReleaseMode.stop);

            // Play from start position
            await _soundEffectPlayer.play(
              AssetSource(sfx.assetPath),
              position: Duration(milliseconds: (sfx.startSeconds * 1000).toInt()),
            );

            debugPrint('Playing sound effect: ${sfx.assetPath} (start: ${sfx.startSeconds}s, end: ${sfx.endSeconds != null ? "${sfx.endSeconds}s" : "end of file"})');

            // If there's an end time, schedule stopping the audio
            if (sfx.endSeconds != null && !_disposed) {
              final duration = sfx.endSeconds! - sfx.startSeconds;
              Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
                if (!_disposed) _soundEffectPlayer.stop();
              });
            }
          } catch (e) {
            debugPrint('Error playing sound effect: $e');
          }
        }

        if (_disposed) break;

        // Speak the announcement (happens simultaneously with sound effect)
        await _announcer.speak(announcement.text);

        if (_disposed) break;

        // Wait long enough for BOTH the TTS estimate AND the sound effect
        // to finish, so the next iteration doesn't interrupt either one.
        // - TTS: approx 500ms/word + 1500ms buffer
        // - Sound effect: explicit (endSeconds - startSeconds) when set,
        //   otherwise a 5-second cap for "play entire file" SFX. Most
        //   game SFX are short clips well under 5s; longer ones would
        //   still get cut, but that's an acceptable tradeoff vs. blocking
        //   the queue indefinitely.
        final wordCount = announcement.text.split(' ').length;
        final ttsMs = wordCount * 500 + 1500;
        int sfxMs = 0;
        if (announcement.soundEffect != null) {
          final sfx = announcement.soundEffect!;
          if (sfx.endSeconds != null) {
            sfxMs = ((sfx.endSeconds! - sfx.startSeconds) * 1000).toInt();
          } else {
            sfxMs = 5000;
          }
        }
        final waitMs = ttsMs > sfxMs ? ttsMs : sfxMs;
        await Future.delayed(Duration(milliseconds: waitMs));

        _isSpeaking = false;
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
    _isSpeaking = false;
    _isProcessing = false;
    _soundEffectPlayer.dispose();
    _announcer.dispose();
  }
}
