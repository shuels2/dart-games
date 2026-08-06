import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/dartboard_provider.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator_controller.dart';
import '../../../widgets/dartboard_emulator/play_to_complete_runner.dart';
import '../../../widgets/dartboard_emulator/play_to_complete_strategy.dart';
import '../../../widgets/dartboard_emulator/play_to_tie_runner.dart';
import '../../../widgets/dartboard_emulator/play_to_tie_strategy.dart';

/// Lifecycle scaffolding shared by every game screen.
///
/// Owns the pieces that were previously re-implemented, near-identically, in
/// all ten `*_game_screen.dart` State classes:
///
/// * the dartboard event subscription and its `throw_detected` /
///   `takeout_finished` routing,
/// * the [MockScoliaApiService] handle taken from [DartboardProvider],
/// * the [DartboardEmulatorController] and the Play-to-Complete runner,
/// * the `_gameCompleted` / `_showSaveModal` flags,
/// * the "announce the winner, wait for the queue to drain, then navigate"
///   sequence, capped at 10s so a wedged TTS engine can't strand the player
///   on the game screen,
/// * the takeout choreography (1500ms "remove your darts" / 3500ms
///   `simulateTakeoutStarted`, or the 500ms zero-dart advance).
///
/// Every delayed callback here runs on a **cancellable** [Timer]. Games
/// previously scheduled them as bare `Future.delayed`s guarded only by
/// `mounted`, which stays true across turn boundaries — so a Skip arriving
/// between the schedule and the fire still let the old callback run against
/// the new turn. [scheduleTakeoutSequence] cancels any sequence still in
/// flight, and [disposeGameScreen] cancels everything.
///
/// Note that a *new dart* deliberately does NOT cancel a pending sequence: a
/// late `throw_detected` (a bounce-out reported after the third dart) is
/// rejected by the provider and must not strip the takeout that is already on
/// its way, or the turn stalls with no way forward.
mixin GameScreenController<T extends StatefulWidget> on State<T> {
  StreamSubscription<Map<String, dynamic>>? _dartboardSubscription;
  MockScoliaApiService? _mockApi;
  PlayToCompleteRunner? _autoPlayRunner;
  PlayToTieRunner? _tieRunner;

  final DartboardEmulatorController dartboardEmulatorController =
      DartboardEmulatorController();

  bool _gameCompleted = false;
  bool _showSaveModal = false;

  Timer? _announceRemoveDartsTimer;
  Timer? _takeoutTimer;
  Timer? _firstTurnTimer;
  Timer? _resultsNavTimer;
  final Set<Timer> _pendingTimers = {};

  // ── Hooks the game screen implements ──────────────────────────────────────

  /// Strategy used by the emulator's "Play to Complete" button.
  PlayToCompleteStrategy get playToCompleteStrategy;

  /// Called for every `throw_detected` dartboard event.
  void onDartThrowEvent(Map<String, dynamic> event);

  /// Called for every `takeout_finished` dartboard event, and by the
  /// zero-dart skip path when no mock API is available.
  void onTakeoutFinished();

  /// Completes when the game's announcement queue has drained. Games return
  /// `_audioQueue?.whenIdle() ?? Future<void>.value()` — the null case is the
  /// init race, where navigation should not block on audio that never started.
  Future<void> whenAnnouncementsIdle();

  // ── State the shell reads ─────────────────────────────────────────────────

  MockScoliaApiService? get mockApi => _mockApi;
  bool get isAutoPlaying => dartboardEmulatorController.isAutoPlaying;
  bool get gameCompleted => _gameCompleted;
  bool get showSaveModal => _showSaveModal;

  void openSaveModal() {
    if (_showSaveModal) return;
    setState(() => _showSaveModal = true);
  }

  // ── Init / dispose ────────────────────────────────────────────────────────

  /// Wires the screen up: grabs the mock API, loads the announcement queue,
  /// hands it to the game so it can build its typed helper, subscribes to the
  /// dartboard event stream, then runs the game's opening announcements.
  ///
  /// [buildAudio] runs before the subscription is created so the first dart
  /// can never arrive at a null helper.
  Future<void> initGameScreen({
    Iterable<SoundEffectConfig>? preloadEffects,
    required void Function(GameAnnouncementQueueService queue) buildAudio,
    VoidCallback? onReady,
    VoidCallback? announceFirstTurn,
    Duration firstTurnDelay = const Duration(milliseconds: 2500),
  }) async {
    final dartboardProvider = context.read<DartboardProvider>();
    _mockApi = dartboardProvider.apiService;
    if (mounted) setState(() {});

    final queue = GameAnnouncementQueueService();
    await queue.loadSettings(preloadEffects: preloadEffects);
    if (!mounted) return;
    buildAudio(queue);

    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen(handleDartboardEvent);
    }

    onReady?.call();

    if (announceFirstTurn != null) {
      _firstTurnTimer = Timer(firstTurnDelay, () {
        if (mounted) announceFirstTurn();
      });
    }
  }

  /// Tears down everything [initGameScreen] and the takeout/auto-play helpers
  /// created. Call from the screen's `dispose()` **before** `super.dispose()`.
  void disposeGameScreen() {
    _autoPlayRunner?.dispose();
    _tieRunner?.dispose();
    _dartboardSubscription?.cancel();
    _dartboardSubscription = null;
    cancelTakeoutSequence();
    _firstTurnTimer?.cancel();
    _resultsNavTimer?.cancel();
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    dartboardEmulatorController.dispose();
  }

  // ── Dartboard events ──────────────────────────────────────────────────────

  void handleDartboardEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'throw_detected') {
      onDartThrowEvent(event);
    } else if (type == 'takeout_finished') {
      onTakeoutFinished();
    }
  }

  // ── Play to Complete / Play to Tie ────────────────────────────────────────

  void startPlayToComplete() => startAutoPlay(playToCompleteStrategy);

  /// Starts the emulator's auto-play runner with [strategy]. Games with a
  /// "Play to Tie" button call this a second time with their tie strategy.
  void startAutoPlay(PlayToCompleteStrategy strategy) {
    if (_mockApi == null) return;
    dartboardEmulatorController.setAutoPlaying(true);
    dartboardEmulatorController.hide();

    _autoPlayRunner = PlayToCompleteRunner(
      strategy: strategy,
      mockApi: _mockApi!,
      context: context,
      onComplete: () {
        if (mounted) dartboardEmulatorController.setAutoPlaying(false);
      },
    );
    _autoPlayRunner!.run();
  }

  /// Starts the emulator's "Play to Tie" runner. Only tie-capable games wire
  /// this up; the runner type differs from [startAutoPlay]'s, so it gets its
  /// own field and its own strategy.
  void startPlayToTie(PlayToTieStrategy strategy) {
    if (_mockApi == null) return;
    dartboardEmulatorController.setAutoPlaying(true);
    dartboardEmulatorController.hide();

    _tieRunner = PlayToTieRunner(
      strategy: strategy,
      mockApi: _mockApi!,
      context: context,
      onComplete: () {
        if (mounted) dartboardEmulatorController.setAutoPlaying(false);
      },
    );
    _tieRunner!.run();
  }

  void cancelAutoPlay() {
    _autoPlayRunner?.cancel();
    _tieRunner?.cancel();
    dartboardEmulatorController.setAutoPlaying(false);
    dartboardEmulatorController.show();
  }

  // ── Takeout choreography ──────────────────────────────────────────────────

  /// Schedules the end-of-turn sequence, cancelling any sequence still in
  /// flight from a previous turn.
  ///
  /// With darts on the board: announce "remove your darts" at 1500ms, then
  /// start the takeout at 3500ms. With an empty board (a skip before the first
  /// dart): advance directly at 500ms, with no modal in between.
  void scheduleTakeoutSequence({
    required bool dartsOnBoard,
    VoidCallback? announceRemoveDarts,
  }) {
    cancelTakeoutSequence();

    if (dartsOnBoard) {
      _announceRemoveDartsTimer = Timer(
        const Duration(milliseconds: 1500),
        () {
          if (mounted) announceRemoveDarts?.call();
        },
      );
      _takeoutTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) _mockApi?.simulateTakeoutStarted();
      });
    } else {
      _takeoutTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (_mockApi != null) {
          _mockApi!.simulateTakeoutFinished();
        } else {
          onTakeoutFinished();
        }
      });
    }
  }

  void cancelTakeoutSequence() {
    _announceRemoveDartsTimer?.cancel();
    _announceRemoveDartsTimer = null;
    _takeoutTimer?.cancel();
    _takeoutTimer = null;
  }

  // ── Screen-scoped delays ──────────────────────────────────────────────────

  /// Runs [action] after [delay], unless the screen is disposed first.
  ///
  /// A drop-in for the `Future.delayed(d, () { if (mounted) ... })` pattern
  /// that every screen used for its post-turn scroll and turn announcement.
  /// The timer is tracked and cancelled in [disposeGameScreen], so the
  /// callback can't outlive the screen.
  void runAfter(Duration delay, VoidCallback action) {
    late final Timer timer;
    timer = Timer(delay, () {
      _pendingTimers.remove(timer);
      if (mounted) action();
    });
    _pendingTimers.add(timer);
  }

  // ── Game over ─────────────────────────────────────────────────────────────

  /// Runs the winner announcement and navigates to the results screen once the
  /// announcement queue drains — or after 10s, whichever comes first.
  ///
  /// Idempotent: the first call latches [gameCompleted], so a duplicate
  /// `takeout_finished` can't push the results route twice.
  void handleGameWon({
    required VoidCallback announceWinner,
    required WidgetBuilder resultsBuilder,
  }) {
    if (_gameCompleted) return;
    _gameCompleted = true;

    void navigateToResults() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: resultsBuilder),
      );
    }

    if (dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
      return;
    }

    announceWinner();
    whenAnnouncementsIdle()
        .timeout(const Duration(seconds: 10), onTimeout: () {})
        .then((_) {
      if (!mounted) return;
      _resultsNavTimer =
          Timer(const Duration(milliseconds: 250), navigateToResults);
    });
  }
}
