// Unit tests for SoundEffectPlayerPool.
//
// These tests exercise only the pure logic that doesn't require a real
// audio platform: fade-volume math, round-robin index advancement, and
// timer cleanup on dispose. The actual `AudioPlayer.play()` call will
// fail under `flutter test` (no audio engine), but the pool wraps every
// player call in try/catch so the test still observes the index/timer
// behaviour. Anything that would require the audio platform (verifying
// a clip actually played, or that the volume was REALLY rendered) is
// deliberately NOT tested here — those would be inherently flaky.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/game_announcement_models.dart';
import 'package:dart_games/services/sound_effect_player_pool.dart';

void main() {
  // AudioPlayer's constructor initializes a MethodChannel, which requires
  // the test binding to be present AND a method-call handler registered
  // for the audioplayers plugin channels. Without the handler the plugin
  // raises MissingPluginException at construction. We register a no-op
  // handler that returns null for every call — the pool's own try/catch
  // blocks then swallow any errors from subsequent play/stop/setVolume
  // calls. The audio engine itself is intentionally NOT exercised; this
  // test file verifies only the pool's own logic (round-robin, fade math,
  // timer cleanup), which is the only part that can be tested
  // deterministically in a unit-test environment.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Two channels the audioplayers package uses: the global init/scope
    // channel and the per-player instance channel(s). The instance
    // channels are named with the player UUID; we register a default
    // handler on the global one which is what the constructor hits.
    Future<Object?> noop(MethodCall _) async => null;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      noop,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      noop,
    );
  });

  group('computeFadeVolume', () {
    test('returns 1.0 before fade region begins', () {
      // fade region: 1000ms - 1500ms (500ms long)
      expect(computeFadeVolume(elapsedMs: 0, fadeStartMs: 1000, fadeOutMs: 500),
          1.0);
      expect(
          computeFadeVolume(
              elapsedMs: 500, fadeStartMs: 1000, fadeOutMs: 500),
          1.0);
      expect(
          computeFadeVolume(
              elapsedMs: 1000, fadeStartMs: 1000, fadeOutMs: 500),
          1.0);
    });

    test('linearly ramps from 1.0 to 0.0 across the fade region', () {
      // Halfway: 250ms into a 500ms fade -> volume 0.5
      expect(
          computeFadeVolume(
              elapsedMs: 1250, fadeStartMs: 1000, fadeOutMs: 500),
          closeTo(0.5, 1e-9));
      // 100ms in -> 0.8
      expect(
          computeFadeVolume(
              elapsedMs: 1100, fadeStartMs: 1000, fadeOutMs: 500),
          closeTo(0.8, 1e-9));
      // 400ms in -> 0.2
      expect(
          computeFadeVolume(
              elapsedMs: 1400, fadeStartMs: 1000, fadeOutMs: 500),
          closeTo(0.2, 1e-9));
    });

    test('returns 0.0 at or after the fade region ends', () {
      expect(
          computeFadeVolume(
              elapsedMs: 1500, fadeStartMs: 1000, fadeOutMs: 500),
          0.0);
      expect(
          computeFadeVolume(
              elapsedMs: 9999, fadeStartMs: 1000, fadeOutMs: 500),
          0.0);
    });

    test('returns 1.0 unconditionally when fadeOutMs is 0 (no fade)', () {
      expect(computeFadeVolume(elapsedMs: 0, fadeStartMs: 1000, fadeOutMs: 0),
          1.0);
      expect(
          computeFadeVolume(
              elapsedMs: 5000, fadeStartMs: 1000, fadeOutMs: 0),
          1.0);
    });

    test('returns 1.0 unconditionally when fadeOutMs is negative', () {
      // Treat negative as no-fade (defensive — config shouldn't produce it).
      expect(
          computeFadeVolume(
              elapsedMs: 9999, fadeStartMs: 0, fadeOutMs: -100),
          1.0);
    });
  });

  group('SoundEffectPlayerPool', () {
    test('default constructor creates a pool of 3 players', () {
      final pool = SoundEffectPlayerPool();
      expect(pool.size, 3);
      pool.dispose();
    });

    test('pool size is configurable', () {
      final small = SoundEffectPlayerPool(size: 1);
      expect(small.size, 1);
      small.dispose();

      final large = SoundEffectPlayerPool(size: 5);
      expect(large.size, 5);
      large.dispose();
    });

    test('nextIndex starts at 0', () {
      final pool = SoundEffectPlayerPool(size: 3);
      expect(pool.nextIndex, 0);
      pool.dispose();
    });

    test('nextIndex advances round-robin on each play call', () async {
      final pool = SoundEffectPlayerPool(size: 3);
      const sfx =
          SoundEffectConfig(assetPath: 'unit-test/nonexistent.mp3');

      // play() may fail at the player-call layer (no audio platform in
      // unit tests) but the index advances first, so the round-robin
      // contract is observable regardless of whether playback succeeded.
      await pool.play(sfx);
      expect(pool.nextIndex, 1);

      await pool.play(sfx);
      expect(pool.nextIndex, 2);

      await pool.play(sfx);
      expect(pool.nextIndex, 0, reason: 'wraps back to 0 after 3 calls');

      await pool.play(sfx);
      expect(pool.nextIndex, 1);

      pool.dispose();
    });

    test('size-1 pool always reuses the same player', () async {
      final pool = SoundEffectPlayerPool(size: 1);
      const sfx =
          SoundEffectConfig(assetPath: 'unit-test/nonexistent.mp3');

      expect(pool.nextIndex, 0);
      await pool.play(sfx);
      expect(pool.nextIndex, 0, reason: 'with size 1, index always wraps to 0');
      await pool.play(sfx);
      expect(pool.nextIndex, 0);

      pool.dispose();
    });

    test('dispose clears every pending timer and is idempotent', () {
      final pool = SoundEffectPlayerPool(size: 3);
      // We can't easily induce active timers without successful playback,
      // but dispose() must at minimum: (a) not throw, (b) leave
      // activeTimerCount at 0, (c) be safe to call twice.
      expect(pool.activeTimerCount, 0);
      pool.dispose();
      expect(pool.activeTimerCount, 0);
      pool.dispose(); // second call must be a no-op, not crash
      expect(pool.activeTimerCount, 0);
    });

    test('play after dispose is a no-op (does not advance index)', () async {
      final pool = SoundEffectPlayerPool(size: 3);
      pool.dispose();
      const sfx =
          SoundEffectConfig(assetPath: 'unit-test/nonexistent.mp3');

      final indexBefore = pool.nextIndex;
      await pool.play(sfx);
      expect(pool.nextIndex, indexBefore,
          reason: 'play() after dispose() must not advance the rotation');
    });
  });
}
