import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../services/mock_scolia_api_service.dart';
import 'play_to_complete_strategy.dart';

class PlayToCompleteRunner {
  final PlayToCompleteStrategy strategy;
  final MockScoliaApiService mockApi;
  final BuildContext context;
  final VoidCallback? onComplete;

  bool _cancelled = false;
  bool _running = false;
  Completer<void>? _delayCompleter;

  bool get isRunning => _running;

  PlayToCompleteRunner({
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
        if (strategy.isGameComplete(context)) break;

        if (strategy.shouldAutoTakeout(context)) {
          mockApi.simulateTakeoutFinished();
          await _delay(const Duration(milliseconds: 200));
          continue;
        }

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
