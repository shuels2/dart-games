import 'dart:async';

/// Runs [worker] over every item in [items] with at most [limit] futures
/// in flight at any moment. Preserves per-item ordering ONLY for the
/// launch sequence — completion order depends on how fast each worker
/// finishes. Return value of [worker] is discarded; if the caller needs
/// results, they should mutate an outer list at `[index]` inside the
/// worker closure.
///
/// Errors thrown by [worker] are swallowed silently, matching the
/// existing per-item `try { … } catch { debugPrint(...) }` pattern the
/// test-data loader was using before it moved to this helper. Callers
/// that need visibility into per-item failure should catch inside the
/// worker closure themselves.
///
/// [onProgress] fires once per completed item with the running
/// completion count (1..items.length). Safe to call from a
/// `ValueNotifier` update without extra debouncing since each fire is
/// aligned with a completed future.
///
/// [limit] is clamped to `>= 1`. Passing `1` behaves like a sequential
/// `for` loop.
///
/// ```dart
/// await runConcurrent<Player>(
///   testPlayers,
///   limit: 4,
///   worker: (player, index) async {
///     await uploadFor(player);
///   },
///   onProgress: (completed) =>
///       setProgress(2, 'Uploading', completed, testPlayers.length),
/// );
/// ```
Future<void> runConcurrent<T>(
  List<T> items, {
  required int limit,
  required Future<void> Function(T item, int index) worker,
  void Function(int completed)? onProgress,
}) async {
  if (items.isEmpty) return;
  final effectiveLimit = limit < 1 ? 1 : limit;

  // Round-robin index handed out via a single mutable counter. Dart's
  // async model guarantees that each `next++` between awaits is
  // atomic — no locking needed for a single-isolate scheduler.
  var next = 0;
  var completed = 0;

  Future<void> runWorker() async {
    while (true) {
      if (next >= items.length) return;
      final myIdx = next++;
      try {
        await worker(items[myIdx], myIdx);
      } catch (_) {
        // Silently swallowed — see doc comment. Callers should catch
        // inside the worker closure if they want per-item error
        // visibility.
      } finally {
        completed++;
        if (onProgress != null) onProgress(completed);
      }
    }
  }

  final futures = List.generate(effectiveLimit, (_) => runWorker());
  await Future.wait(futures);
}
