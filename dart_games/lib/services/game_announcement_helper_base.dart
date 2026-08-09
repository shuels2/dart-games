import 'package:flutter/foundation.dart';

import 'game_announcement_models.dart';
import 'game_announcement_queue_service.dart';

/// Shared scaffolding for the ten per-game announcement helpers (WS02 §2.10).
///
/// Each helper wraps one [GameAnnouncementQueueService] and exposes
/// game-specific phrasing. What they all carried identically was the field,
/// the constructor, `whenIdle`, `dispose`, and — in three of them,
/// byte-for-byte — a private `_joinWithAnd`.
///
/// ─── DELIBERATELY ABSENT: pause / reconnect ────────────────────────────────
/// There is no `announceGamePaused` or `announceConnectionRestored` here, and
/// there must never be. [GlobalConnectionAnnouncer] owns those, wired once in
/// `main.dart`. Every game helper used to carry its own dead copies whose doc
/// comments claimed `DartboardStatusAnnouncer` fired them — an invitation for
/// game #11 to wire both and have the same line spoken twice through two
/// queues. They were deleted; this base class is where someone would
/// reasonably look to re-add them, so the prohibition is recorded here.
///
/// ─── DELIBERATELY ABSENT: a single remove-darts wording ────────────────────
/// The plan sketched one shared `announceRemoveDarts`. The ten wordings are
/// NOT interchangeable: some address the player by name ("Alice, remove your
/// darts"), some do not, and Tiki Golf's is a mulligan line
/// ("Mulligan! Remove your darts and try again, Alice!"). Unifying them would
/// change what the app says out loud, which is a product decision and is
/// covered by per-game announcement tests. Raised for Fable rather than
/// decided here.
abstract class GameAnnouncementHelperBase {
  GameAnnouncementHelperBase(this.queue);

  /// The queue this helper speaks through.
  @protected
  final GameAnnouncementQueueService queue;

  /// Enqueue a line. Thin, but it keeps subclasses from reaching for
  /// `queue.announce` with a different argument order each time.
  @protected
  void say(String text, AudioPriority priority, {SoundEffectConfig? sfx}) {
    queue.announce(text, priority, soundEffect: sfx);
  }

  /// "Alice", "Alice and Bob", "Alice, Bob, and Carol".
  ///
  /// Was three byte-identical private copies (Reef Royale, Tiki Golf,
  /// Treasure Divide) — the games that can end in a multi-way tie.
  static String joinWithAnd(List<String> parts) {
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.single;
    if (parts.length == 2) return '${parts[0]} and ${parts[1]}';
    final head = parts.sublist(0, parts.length - 1).join(', ');
    return '$head, and ${parts.last}';
  }

  /// Resolves when everything queued has finished speaking.
  Future<void> whenIdle() => queue.whenIdle();

  void dispose() => queue.dispose();
}
