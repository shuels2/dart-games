// Priority levels for announcements (higher = more important)
enum AudioPriority {
  turnTransition(1), // Lowest - turn changes
  hitConfirm(2),     // Hit/miss announcements
  shieldStatus(3),   // Shield milestones (Target Tag specific)
  statusChange(4),   // Status changes (tagged in/out, busts, eliminations)
  victory(5);        // Highest - game completion

  final int value;
  const AudioPriority(this.value);
}

// Sound effect configuration (asset path + start/end times)
class SoundEffectConfig {
  final String assetPath;
  final double startSeconds;
  final double? endSeconds; // null = play to end of file

  const SoundEffectConfig({
    required this.assetPath,
    this.startSeconds = 0.0,
    this.endSeconds,
  });
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
