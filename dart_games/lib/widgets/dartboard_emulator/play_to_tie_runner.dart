import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../services/mock_scolia_api_service.dart';
import 'play_to_tie_strategy.dart';

/// Drives a [PlayToTieStrategy] to completion (game ends in a tie/draw).
///
/// Structurally identical to [PlayToCompleteRunner]: poll the strategy
/// for the next dart, simulate it through the mock API, sleep briefly,
/// repeat until the strategy reports `isGameComplete` or `getNextThrow`
/// returns null. We keep this as a separate class (rather than reusing
/// PlayToCompleteRunner) so the strategy types stay distinct — the
/// game-screen code that owns the runner doesn't have to runtime-check
/// which kind of strategy it's running, and the Section widget's
/// mutual-exclusion logic can hold one of each runner type.
class PlayToTieRunner {
  final PlayToTieStrategy strategy;
  final MockScoliaApiService mockApi;
  final BuildContext context;
  final VoidCallback? onComplete;

  bool _cancelled = false;
  bool _running = false;
  Completer<void>? _delayCompleter;

  bool get isRunning => _running;

  PlayToTieRunner({
    required this.strategy,
    required this.mockApi,
    required this.context,
    this.onComplete,
  });

  Future<void> run() async {
    if (_running) return;
    _running = true;
    _cancelled = false;

    try {
      while (!_cancelled && context.mounted) {
        if (strategy.shouldAutoTakeout(context)) {
          mockApi.simulateTakeoutFinished();
          await _delay(const Duration(milliseconds: 200));
          continue;
        }

        if (strategy.isGameComplete(context)) break;

        final dart = strategy.getNextThrow(context);
        if (dart == null) break;

        mockApi.simulateDartThrow(
          score: dart.score,
          multiplier: dart.multiplier,
          playerName: 'AutoPlay',
          baseScore: dart.baseScore,
          widgetX: 125,
          widgetY: 125,
          widgetSize: 250,
        );

        await _delay(const Duration(milliseconds: 250));
      }
    } finally {
      _running = false;
      if (!_cancelled && context.mounted) {
        onComplete?.call();
      }
    }
  }

  Future<void> _delay(Duration duration) async {
    _delayCompleter = Completer<void>();
    final timer = Timer(duration, () {
      if (!_delayCompleter!.isCompleted) {
        _delayCompleter!.complete();
      }
    });

    try {
      await _delayCompleter!.future;
    } finally {
      timer.cancel();
    }
  }

  void cancel() {
    _cancelled = true;
    if (_delayCompleter != null && !_delayCompleter!.isCompleted) {
      _delayCompleter!.complete();
    }
  }

  void dispose() {
    cancel();
  }
}
