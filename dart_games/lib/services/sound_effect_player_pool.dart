import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_announcement_models.dart';

/// Linear fade-out volume at a given moment.
///
/// - Returns 1.0 while the fade hasn't started yet (`elapsedMs <= fadeStartMs`).
/// - Ramps linearly to 0.0 over `fadeOutMs` once the fade region begins.
/// - Returns 0.0 at or after the fade ends.
/// - Returns 1.0 unconditionally when `fadeOutMs <= 0` (the no-fade path).
///
/// Pure function — exposed at the library level so it can be unit-tested
/// without needing an audio platform.
double computeFadeVolume({
  required int elapsedMs,
  required int fadeStartMs,
  required int fadeOutMs,
}) {
  if (fadeOutMs <= 0) return 1.0;
  if (elapsedMs <= fadeStartMs) return 1.0;
  final inFade = elapsedMs - fadeStartMs;
  if (inFade >= fadeOutMs) return 0.0;
  return 1.0 - (inFade / fadeOutMs);
}

/// A small round-robin pool of [AudioPlayer] instances dedicated to
/// sound effects. Each call to [play] grabs the next player in the
/// rotation, schedules its fade/stop on a per-player timer, and kicks
/// off playback as fire-and-forget. Because each clip runs on its own
/// player, the announcement queue does NOT have to wait for the
/// previous SFX to finish before starting the next iteration — the
/// prior clip continues fading/playing on its own player while the
/// queue advances to the next announcement on a different one.
///
/// The pool size is configurable via the constructor; default 3 (one
/// for the currently-active speech's SFX plus up to two prior clips
/// still tailing out). Raise it if you observe SFX getting cut off
/// because three concurrent clips weren't enough; lower it to 1 to
/// emulate the old single-player behaviour.
class SoundEffectPlayerPool {
  SoundEffectPlayerPool({int size = 3})
      : _size = size,
        _players = List.generate(size, (_) => AudioPlayer()),
        _timers = List<Timer?>.filled(size, null, growable: false),
        _generations = List<int>.filled(size, 0, growable: false);

  final int _size;
  final List<AudioPlayer> _players;
  final List<Timer?> _timers;
  // Per-slot generation counter. Incremented every time the slot is
  // assigned a new clip; the async tail of `_playOnPlayer` checks this
  // before scheduling a deferred fade (full-file-with-fade path) to avoid
  // racing with a subsequent `play()` that reuses the same slot.
  final List<int> _generations;
  int _nextIndex = 0;
  bool _disposed = false;

  /// Pool size as set in the constructor.
  int get size => _size;

  /// Index that the NEXT call to [play] will use. Test-only — useful for
  /// asserting round-robin advancement without running real audio.
  @visibleForTesting
  int get nextIndex => _nextIndex;

  /// Number of player slots with a pending fade/stop timer. Test-only —
  /// useful for asserting [dispose] cleans up all in-flight timers.
  @visibleForTesting
  int get activeTimerCount => _timers.where((t) => t != null).length;

  /// Play a sound-effect config on the next available player and schedule
  /// its stop (or fade + stop) based on `sfx.endSeconds` / `sfx.fadeOutMs`.
  ///
  /// This method:
  ///   1. Advances the round-robin index (always).
  ///   2. Cancels any pending fade/stop timer on the reused slot.
  ///   3. Schedules a new fade/stop timer if `sfx.endSeconds` is set.
  ///   4. Fires the player chain (`stop` → `setVolume` → `play`) as
  ///      fire-and-forget — the future is intentionally discarded so
  ///      the queue isn't blocked on the audio engine's response time.
  ///      The chain's errors are caught and logged.
  ///
  /// Returns a `Future<void>` that completes essentially immediately
  /// (it does no `await` of its own). The async signature is preserved
  /// for caller-side API stability with the previous single-player
  /// implementation.
  Future<void> play(SoundEffectConfig sfx) async {
    if (_disposed) return;

    final index = _nextIndex;
    _nextIndex = (_nextIndex + 1) % _size;
    final generation = ++_generations[index];

    final player = _players[index];

    // Cancel any pending fade/stop on this slot — we're reusing it.
    _timers[index]?.cancel();
    _timers[index] = null;

    // Schedule the fade/stop timer FIRST when we know the clip's length
    // up front (endSeconds is set). It runs on Dart's event loop and is
    // unaffected by whether the audio engine actually starts playback.
    // In a unit-test environment with no audio platform, this still sets
    // up correctly; in production it correctly tracks the playing clip's
    // lifetime.
    if (sfx.endSeconds != null) {
      final totalMs = ((sfx.endSeconds! - sfx.startSeconds) * 1000).toInt();
      if (totalMs > 0) {
        _scheduleStopOrFade(index, player, totalMs, sfx.fadeOutMs);
      }
    }

    // Fire-and-forget the player chain. We intentionally do NOT await
    // it — the queue calling us shouldn't be blocked on the audio
    // engine's response time, and in unit tests the calls hang on
    // missing MethodChannel handlers. `unawaited` documents the intent.
    unawaited(_playOnPlayer(index, generation, player, sfx));
  }

  Future<void> _playOnPlayer(
      int index, int generation, AudioPlayer player, SoundEffectConfig sfx) async {
    try {
      await player.stop();
      await player.setVolume(1.0);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(
        AssetSource(sfx.assetPath),
        position: Duration(milliseconds: (sfx.startSeconds * 1000).toInt()),
      );

      // Full-file + fade-out: discover the asset's true duration now that
      // play() has resolved, then schedule the trailing fade based on
      // actual file length. Skip if the slot has already been reused by
      // a newer play() call (generation mismatch) or the pool is gone.
      if (sfx.endSeconds == null && sfx.fadeOutMs > 0 && !_disposed) {
        final Duration? duration = await player.getDuration();
        if (_disposed || duration == null) return;
        if (_generations[index] != generation) return;
        final totalMs =
            duration.inMilliseconds - (sfx.startSeconds * 1000).toInt();
        if (totalMs > 0) {
          _scheduleStopOrFade(index, player, totalMs, sfx.fadeOutMs);
        }
      }
    } catch (e) {
      debugPrint('[SFX] Pool play() error: $e');
    }
  }

  void _scheduleStopOrFade(
      int index, AudioPlayer player, int totalMs, int fadeOutMs) {
    if (fadeOutMs <= 0) {
      // No fade — hard stop at endSeconds (current behaviour preserved).
      _timers[index] = Timer(Duration(milliseconds: totalMs), () {
        if (_disposed) return;
        try {
          player.stop();
        } catch (_) {
          // swallow — player may already be disposed/stopped
        }
        _timers[index] = null;
      });
    } else {
      // Fade-out — ramp volume from 1.0 to 0.0 over the LAST fadeOutMs
      // of the clip via a Timer.periodic that ticks every tickMs.
      const tickMs = 50;
      final fadeStartMs = totalMs - fadeOutMs;
      int elapsedMs = 0;
      _timers[index] =
          Timer.periodic(const Duration(milliseconds: tickMs), (t) {
        if (_disposed) {
          t.cancel();
          return;
        }
        elapsedMs += tickMs;
        if (elapsedMs >= totalMs) {
          t.cancel();
          try {
            player.setVolume(0.0);
            player.stop();
            // Reset volume so the next clip on this player starts at full.
            player.setVolume(1.0);
          } catch (_) {
            // swallow — player may already be disposed/stopped
          }
          _timers[index] = null;
        } else {
          final vol = computeFadeVolume(
            elapsedMs: elapsedMs,
            fadeStartMs: fadeStartMs,
            fadeOutMs: fadeOutMs,
          );
          try {
            player.setVolume(vol);
          } catch (_) {
            // swallow
          }
        }
      });
    }
  }

  /// Cancel every pending fade/stop timer and dispose every player.
  /// After this call, [play] is a no-op.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (var i = 0; i < _size; i++) {
      _timers[i]?.cancel();
      _timers[i] = null;
      try {
        _players[i].dispose();
      } catch (_) {
        // swallow — already disposed or platform missing
      }
    }
  }
}
