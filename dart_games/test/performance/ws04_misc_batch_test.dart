// test/performance/ws04_misc_batch_test.dart
//
// Cover for the WS04 §4.8 "misc batch" items that are testable without a
// rendered frame. Each group states the waste it removes, because the fix is
// invisible from the outside — these all make the app do LESS, and a
// regression would simply be slow rather than wrong.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/dartboard.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/widgets/player_avatar_widget.dart';

void main() {
  group('4.8 avatar provider cache evicts stale cache-busted entries', () {
    setUp(PlayerAvatarWidget.clearPhotoProviderCacheForTesting);
    tearDown(PlayerAvatarWidget.clearPhotoProviderCacheForTesting);

    // The cache is keyed by cache-busted URL, so re-uploading a headshot
    // used to leave one ResizeImage per upload pinned forever in an
    // unbounded static map — each holding up to ~1MB of decoded pixels.
    testWidgets('re-uploading the same photo keeps exactly one entry',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Column(
          children: [
            for (final v in ['1', '2', '3'])
              PlayerAvatarWidget(
                player: _playerWithPhoto(
                    'https://host/api/v1/players/p1/avatar.png?v=$v'),
                size: 40,
              ),
          ],
        ),
      ));

      expect(PlayerAvatarWidget.photoProviderCacheSizeForTesting, 1,
          reason: 'Only the newest cache-busted URL should be retained');
    });

    testWidgets('different players each keep their own entry',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Column(
          children: [
            for (final id in ['p1', 'p2', 'p3'])
              PlayerAvatarWidget(
                player: _playerWithPhoto(
                    'https://host/api/v1/players/$id/avatar.png?v=1'),
                size: 40,
              ),
          ],
        ),
      ));

      expect(PlayerAvatarWidget.photoProviderCacheSizeForTesting, 3,
          reason: 'Eviction must be scoped to the same base path only');
    });
  });

  group('4.8 DartboardProvider.whenStatusResolved', () {
    test('returns immediately when the status is already settled', () async {
      final provider = DartboardProvider();
      // Default status is disconnected, i.e. already resolved.
      final resolved = await provider
          .whenStatusResolved(timeout: const Duration(milliseconds: 50));
      expect(resolved, DartboardConnectionStatus.disconnected);
      provider.dispose();
    });

    test('times out to the current status rather than hanging', () async {
      final provider = DartboardProvider();
      // Never leaves `connecting`, so the timeout path is the one exercised.
      provider.setStatusForTesting(DartboardConnectionStatus.connecting);

      final sw = Stopwatch()..start();
      final resolved = await provider
          .whenStatusResolved(timeout: const Duration(milliseconds: 100));
      sw.stop();

      expect(resolved, DartboardConnectionStatus.connecting);
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(90));
      provider.dispose();
    });

    test('completes as soon as the status leaves connecting', () async {
      final provider = DartboardProvider();
      provider.setStatusForTesting(DartboardConnectionStatus.connecting);

      final future = provider
          .whenStatusResolved(timeout: const Duration(seconds: 5));
      // Resolve well inside the timeout; the old code would still have burned
      // its remaining 100ms poll ticks.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      provider.setStatusForTesting(DartboardConnectionStatus.connected);

      expect(await future, DartboardConnectionStatus.connected);
      provider.dispose();
    });

    test('detaches its listener once resolved', () async {
      final provider = DartboardProvider();
      provider.setStatusForTesting(DartboardConnectionStatus.connecting);

      final future =
          provider.whenStatusResolved(timeout: const Duration(seconds: 5));
      provider.setStatusForTesting(DartboardConnectionStatus.connected);
      await future;

      // A leaked listener would fire (and could complete an already-completed
      // Completer) on every later status change.
      expect(
          () => provider
              .setStatusForTesting(DartboardConnectionStatus.error),
          returnsNormally);
      provider.dispose();
    });
  });
}

Player _playerWithPhoto(String path) => Player(
      id: path.hashCode.toString(),
      name: 'Test',
      photoPath: path,
      createdAt: DateTime(2026, 1, 1),
    );
