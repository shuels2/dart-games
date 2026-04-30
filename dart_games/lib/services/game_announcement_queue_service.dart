import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';
import 'dart_announcer_service.dart';

export 'game_announcement_models.dart';
import 'game_announcement_models.dart';

/// Global announcement queue service used by all games
///
/// This service manages a priority-based queue of announcements with optional
/// sound effects. All games (Target Tag, Carnival Derby, etc.) use this service
/// to ensure announcements don't overlap and play in the correct order.
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

        // Sort queue by priority (high to low), then by timestamp (FIFO)
        final sortedQueue = _queue.toList()
          ..sort((a, b) {
            final priorityCompare = b.priority.value.compareTo(a.priority.value);
            if (priorityCompare != 0) return priorityCompare;
            return a.queuedAt.compareTo(b.queuedAt);
          });

        // Get highest priority item
        final announcement = sortedQueue.first;
        _queue.remove(announcement);

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

        // Wait for speech to complete with generous buffer
        // Speech takes approximately 500ms per word + extra time for pauses
        final wordCount = announcement.text.split(' ').length;
        final estimatedDuration = Duration(milliseconds: wordCount * 500 + 1500);
        await Future.delayed(estimatedDuration);

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
