/// Unit tests for `runConcurrent` — the batched-parallel utility the
/// System Settings → Load Test Data flow uses to run its photo uploads
/// with at most N in flight at any moment.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_games/utils/concurrent_runner.dart';

void main() {
  group('runConcurrent — concurrency contract', () {
    test('all items are processed exactly once', () async {
      final items = List<int>.generate(20, (i) => i);
      final seen = <int>{};
      await runConcurrent<int>(
        items,
        limit: 4,
        worker: (item, index) async {
          expect(seen.contains(item), isFalse,
              reason: 'each item must be processed exactly once, got $item twice');
          seen.add(item);
        },
      );
      expect(seen, items.toSet());
    });

    test('never more than `limit` workers active at once', () async {
      const limit = 3;
      const totalItems = 20;
      int inFlight = 0;
      int peakInFlight = 0;
      await runConcurrent<int>(
        List<int>.generate(totalItems, (i) => i),
        limit: limit,
        worker: (item, index) async {
          inFlight++;
          if (inFlight > peakInFlight) peakInFlight = inFlight;
          // Small async gap so multiple workers can genuinely overlap.
          await Future<void>.delayed(const Duration(milliseconds: 5));
          inFlight--;
        },
      );
      expect(peakInFlight, lessThanOrEqualTo(limit),
          reason: 'expected at most $limit concurrent workers, saw $peakInFlight');
      expect(peakInFlight, greaterThan(1),
          reason: 'sanity: the limit was NOT saturated at all — did the '
              'runner sequentially await each item?');
    });

    test('limit clamps to at least 1 (limit=0 becomes sequential)', () async {
      final order = <int>[];
      await runConcurrent<int>(
        [10, 20, 30],
        limit: 0,
        worker: (item, index) async {
          order.add(item);
        },
      );
      expect(order, [10, 20, 30],
          reason: 'clamped-limit=1 behaves like a sequential for-loop');
    });

    test('empty items list is a no-op (does not throw or hang)', () async {
      var workerCalls = 0;
      await runConcurrent<int>(
        <int>[],
        limit: 4,
        worker: (item, index) async {
          workerCalls++;
        },
      );
      expect(workerCalls, 0);
    });

    test('single-item list still runs the worker once', () async {
      final captured = <int>[];
      await runConcurrent<int>(
        [42],
        limit: 4,
        worker: (item, index) async {
          captured.add(item);
        },
      );
      expect(captured, [42]);
    });
  });

  group('runConcurrent — error handling', () {
    test('worker exceptions are swallowed; remaining items still run',
        () async {
      final completed = <int>[];
      await runConcurrent<int>(
        [1, 2, 3, 4, 5],
        limit: 2,
        worker: (item, index) async {
          if (item == 3) {
            throw StateError('deliberate failure on item 3');
          }
          completed.add(item);
        },
      );
      // Item 3 threw; 1, 2, 4, 5 all completed.
      expect(completed.toSet(), {1, 2, 4, 5});
    });

    test(
        'onProgress fires once per item — success AND failure — with the '
        'running completion count', () async {
      final progress = <int>[];
      await runConcurrent<int>(
        [1, 2, 3, 4, 5],
        limit: 2,
        worker: (item, index) async {
          if (item == 3) throw StateError('boom');
        },
        onProgress: (done) => progress.add(done),
      );
      // 5 items, 5 onProgress fires. The sequence must be monotonically
      // increasing 1..5 (concurrency may interleave completion order,
      // but the counter still moves forward once per completion).
      expect(progress, hasLength(5));
      for (var i = 0; i < progress.length; i++) {
        expect(progress[i], i + 1,
            reason: 'expected progress $i to be ${i + 1}, got ${progress[i]}');
      }
    });
  });

  group('runConcurrent — progress callback contract', () {
    test('onProgress is invoked exactly items.length times', () async {
      var callCount = 0;
      await runConcurrent<int>(
        List<int>.generate(10, (i) => i),
        limit: 4,
        worker: (item, index) async {},
        onProgress: (_) => callCount++,
      );
      expect(callCount, 10);
    });

    test('onProgress is safe to omit', () async {
      // Should complete without throwing.
      await runConcurrent<int>(
        [1, 2, 3],
        limit: 2,
        worker: (item, index) async {},
      );
    });
  });
}
