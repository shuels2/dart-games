import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart_announcer_service.dart';
import 'target_tag_sound_effects.dart';

// Priority levels for announcements (higher = more important)
enum AudioPriority {
  turnTransition(1), // Lowest - turn changes
  hitConfirm(2),     // Hit/miss announcements
  shieldStatus(3),   // Shield milestones
  statusChange(4),   // Tagged In, Tagged Out, Eliminated
  victory(5);        // Highest - game completion

  final int value;
  const AudioPriority(this.value);
}

// Queued announcement with priority, timestamp, and optional sound effect
class QueuedAnnouncement {
  final String text;
  final AudioPriority priority;
  final DateTime queuedAt;
  final SoundEffectConfig? soundEffect; // Optional sound effect to play with announcement

  QueuedAnnouncement({
    required this.text,
    required this.priority,
    DateTime? queuedAt,
    this.soundEffect,
  }) : queuedAt = queuedAt ?? DateTime.now();
}

class TargetTagAudioQueueService {
  final DartAnnouncerService _announcer = DartAnnouncerService();
  final Queue<QueuedAnnouncement> _queue = Queue<QueuedAnnouncement>();
  final AudioPlayer _soundEffectPlayer = AudioPlayer();
  bool _isSpeaking = false;
  bool _isProcessing = false;

  // Load announcer settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load voice engine
      final engineStr = prefs.getString('voice_engine') ?? 'responsiveVoice';
      final voiceEngine = VoiceEngine.values.firstWhere(
        (e) => e.toString().split('.').last == engineStr,
        orElse: () => VoiceEngine.responsiveVoice,
      );

      // Load announcer style
      final styleStr = prefs.getString('announcer_style') ?? 'professional';
      final announcerVoice = AnnouncerVoice.values.firstWhere(
        (e) => e.toString().split('.').last == styleStr,
        orElse: () => AnnouncerVoice.professional,
      );

      _announcer.setVoice(announcerVoice);

      // Configure voice engine
      if (voiceEngine == VoiceEngine.responsiveVoice) {
        _announcer.useResponsiveVoice();
        final responsiveVoice = prefs.getString('responsive_voice') ?? 'Australian Female';
        _announcer.setResponsiveVoice(responsiveVoice);
      } else if (voiceEngine == VoiceEngine.browser) {
        _announcer.useBrowserVoices();
        final systemVoice = prefs.getString('system_voice');
        if (systemVoice != null) {
          _announcer.setSystemVoice(systemVoice);
        }
      }

      debugPrint('Target Tag audio queue loaded settings: engine=$voiceEngine, style=$announcerVoice');
    } catch (e) {
      debugPrint('Error loading announcer settings: $e');
    }
  }

  // Add announcement to queue with priority and optional sound effect
  void announce(String text, AudioPriority priority, {SoundEffectConfig? soundEffect}) {
    if (text.isEmpty) return;

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

    while (_queue.isNotEmpty) {
      // Wait if currently speaking
      while (_isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

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
      if (announcement.soundEffect != null) {
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
          if (sfx.endSeconds != null) {
            final duration = sfx.endSeconds! - sfx.startSeconds;
            Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
              _soundEffectPlayer.stop();
            });
          }
        } catch (e) {
          debugPrint('Error playing sound effect: $e');
        }
      }

      // Speak the announcement (happens simultaneously with sound effect)
      await _announcer.speak(announcement.text);

      // Wait for speech to complete with generous buffer
      // Speech takes approximately 500ms per word + extra time for pauses
      final wordCount = announcement.text.split(' ').length;
      final estimatedDuration = Duration(milliseconds: wordCount * 500 + 1500);
      await Future.delayed(estimatedDuration);

      _isSpeaking = false;
    }

    _isProcessing = false;
  }

  // Clear all queued announcements
  void clearQueue() {
    _queue.clear();
    debugPrint('Audio queue cleared');
  }

  // Dispose resources
  void dispose() {
    _queue.clear();
    _isSpeaking = false;
    _isProcessing = false;
    _soundEffectPlayer.dispose();
    _announcer.dispose();
  }

  // === Game-Specific Announcement Methods ===
  // Sound effects are automatically applied based on announcement type

  // Announce dart hit
  void announceHit(int number, String multiplier, {bool isMiss = false}) {
    SoundEffectConfig? sfx;

    if (isMiss) {
      sfx = TargetTagSoundEffects.miss;
      announce('Miss', AudioPriority.hitConfirm, soundEffect: sfx);
      return;
    }

    String text = '';
    if (number == 50) {
      text = 'Bullseye!';
      sfx = TargetTagSoundEffects.bullseye;
    } else if (number == 25) {
      text = 'Outer bull';
      sfx = TargetTagSoundEffects.outerBull;
    } else {
      final mult = multiplier == 'double' ? 'Double' : (multiplier == 'triple' ? 'Triple' : 'Single');
      text = '$mult $number';

      // Select sound effect based on multiplier
      if (multiplier == 'double') {
        sfx = TargetTagSoundEffects.doubleHit;
      } else if (multiplier == 'triple') {
        sfx = TargetTagSoundEffects.tripleHit;
      } else {
        sfx = TargetTagSoundEffects.singleHit;
      }
    }

    announce(text, AudioPriority.hitConfirm, soundEffect: sfx);
  }

  // Announce shield gained
  void announceShieldGained(String playerName, int shields, int shieldMax) {
    announce('$shields shields', AudioPriority.shieldStatus, soundEffect: TargetTagSoundEffects.shieldGained);
  }

  // Announce player(s) reached Tagged In status
  void announceTaggedIn(List<String> playerNames) {
    String names;
    if (playerNames.length == 1) {
      names = '${playerNames[0]} is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]} are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last} are';
    }
    announce('JACKPOT! $names TAGGED IN!', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.taggedIn);
  }

  // Announce player(s) lost Tagged In status
  void announceTaggedOut(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = playerNames[0];
      verb = 'is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}';
      verb = 'are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are';
    }
    announce('Shield compromised! $names $verb back on the hunt.', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.taggedOut);
  }

  // Announce low shields warning
  void announceLowShields(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = '${playerNames[0]}\'s';
      verb = 'are';  // Changed from 'is' to 'are' for grammatical correctness
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}\'s';
      verb = 'are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}\'s';
      verb = 'are';
    }
    announce('Warning! $names shields $verb almost gone!', AudioPriority.shieldStatus, soundEffect: TargetTagSoundEffects.lowShields);
  }

  // Announce player(s) eliminated
  void announceEliminated(List<String> playerNames) {
    String names;
    if (playerNames.length == 1) {
      names = '${playerNames[0]} is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]} are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last} are';
    }
    announce('$names Tagged Out! Better luck next time!', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.eliminated);
  }

  // Announce successful tag on opponent
  void announceSuccessfulTag() {
    announce('Tag! Got \'em!', AudioPriority.hitConfirm, soundEffect: TargetTagSoundEffects.successfulTag);
  }

  // Announce turn change
  void announceTurn(String playerName) {
    announce('$playerName, your turn', AudioPriority.turnTransition, soundEffect: TargetTagSoundEffects.turnStart);
  }

  // Announce game start
  void announceGameStart() {
    announce('Welcome to Target Tag! Fill those shields!', AudioPriority.victory, soundEffect: TargetTagSoundEffects.gameStart);
  }

  // Announce winner(s)
  void announceWinner(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = playerNames[0];
      verb = 'is the Target Tag Champion';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}';
      verb = 'are the Target Tag Champions';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are the Target Tag Champions';
    }
    announce('GAME OVER! $names $verb!', AudioPriority.victory);
  }

  // Announce remove darts
  void announceRemoveDarts() {
    announce('Remove your darts', AudioPriority.turnTransition, soundEffect: TargetTagSoundEffects.removeDarts);
  }
}
