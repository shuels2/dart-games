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

// Sound effect configuration (asset path + start/end times + fade-out)
class SoundEffectConfig {
  final String assetPath;
  final double startSeconds;
  final double? endSeconds; // null = play to end of file

  /// Linear fade-out duration in milliseconds, applied over the LAST
  /// `fadeOutMs` of the clip. For clips with an explicit `endSeconds`,
  /// the fade starts at `endSeconds - fadeOutMs/1000` and reaches volume
  /// 0 at `endSeconds`. For full-file clips (`endSeconds == null`), the
  /// pool queries the asset's true duration via `AudioPlayer.getDuration()`
  /// after `play()` resolves and applies the same trailing fade over the
  /// file's last `fadeOutMs`. Defaults to 0 — hard stop at the clip's
  /// end with no fade, matching the original engine behaviour.
  final int fadeOutMs;

  const SoundEffectConfig({
    required this.assetPath,
    this.startSeconds = 0.0,
    this.endSeconds,
    this.fadeOutMs = 0,
  });
}

// Queued announcement with priority, timestamp, and optional sound effect
class QueuedAnnouncement {
  final String text;
  final AudioPriority priority;
  final DateTime queuedAt;
  final SoundEffectConfig? soundEffect; // Optional sound effect to play with announcement

  /// How long this line stays worth saying. Once it has waited longer than
  /// this in the queue it is dropped instead of spoken — a "your turn" line
  /// arriving after the next player has thrown is worse than silence.
  /// Null (default) means it never expires.
  final Duration? maxAge;

  /// Announcements sharing a key supersede one another while queued: adding
  /// a new one removes any earlier queued line with the same key. Use for
  /// state that is only interesting in its latest form (whose turn it is,
  /// the current score). The line already being spoken is never replaced.
  final String? coalesceKey;

  QueuedAnnouncement({
    required this.text,
    required this.priority,
    DateTime? queuedAt,
    this.soundEffect,
    this.maxAge,
    this.coalesceKey,
  }) : queuedAt = queuedAt ?? DateTime.now();

  /// True when this has waited past [maxAge] and should be dropped.
  bool get isStale {
    final limit = maxAge;
    if (limit == null) return false;
    return DateTime.now().difference(queuedAt) > limit;
  }
}
