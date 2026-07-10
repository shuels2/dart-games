import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/treasure_divide_game.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/treasure_divide_provider.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/save_game_service.dart';
import '../../../services/treasure_divide_announcement_helper.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/edit_score/edit_score_dialog.dart';
import '../../../widgets/edit_score/edit_score_dialog_config.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import '../../../widgets/treasure_divide/pirate_avatar_widget.dart';
import '../../../widgets/treasure_divide/treasure_map_widget.dart';
import '../../../services/play_to_complete/treasure_divide_strategy.dart';
import '../../../services/play_to_tie/treasure_divide_strategy.dart';
import '../../../widgets/dartboard_emulator/play_to_tie_runner.dart';
import 'treasure_divide_results_screen.dart';

// ─── Color palette ────────────────────────────────────────────────────────────
const Color _treasureGold = Color(0xFFFFD700);
const Color _oceanTeal = Color(0xFF008B8B);
const Color _plankBrown = Color(0xFF8B6914);
const Color _sailWhite = Color(0xFFFFF8E7);
const Color _bloodRed = Color(0xFFC41E3A);
const Color _islandGreen = Color(0xFF228B22);

// Signature Treasure Divide text effect — dark drop shadow + ocean-teal glow.
// Matches the setup/menu screen titles and the gameplay app bar.
const List<Shadow> _treasureTextShadows = [
  Shadow(color: Color(0xCC000000), offset: Offset(2, 2), blurRadius: 4),
  Shadow(color: Color(0xAA008B8B), offset: Offset(0, 0), blurRadius: 10),
];

class TreasureDivideGameScreen extends StatefulWidget {
  const TreasureDivideGameScreen({Key? key}) : super(key: key);

  @override
  State<TreasureDivideGameScreen> createState() =>
      _TreasureDivideGameScreenState();
}

class _TreasureDivideGameScreenState extends State<TreasureDivideGameScreen> {
  StreamSubscription? _dartboardSubscription;
  MockScoliaApiService? _mockApi;
  // Key for the InteractiveDartboard inside DartboardEmulatorSection.
  // Required so the emulator's takeout-prompt overlay can dispatch the
  // "Remove Darts" tap via dartboardKey.currentState?.removeDarts().
  // Without it the button silently no-ops on Treasure Divide — every
  // other game passes this through; we just hadn't.
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();
  PlayToCompleteRunner? _playToCompleteRunner;
  PlayToTieRunner? _playToTieRunner;
  bool _showSaveModal = false;
  bool _gameCompleted = false;

  // Emulator-only theme preview. When non-null, every player avatar
  // renders with this theme index instead of the per-player assignment
  // — purely cosmetic for sprite-positioning debugging. Game state
  // (model, scoring, persistence) is unaffected. Null means each
  // player keeps their natural theme.
  int? _themePreviewOverride;

  // Emulator-only island-layout editor. When `_layoutEditMode` is
  // true, each island marker on the treasure map becomes draggable.
  // Dragged positions accumulate into `_islandCoordsOverride` as a
  // list of (x%, y%) records (length = numberOfRounds). The map
  // widget falls through to the canonical constants whenever the
  // override is null or its length doesn't match the round count.
  bool _layoutEditMode = false;
  List<({double x, double y})>? _islandCoordsOverride;

  // ─── Announcement system (Phase 5) ───────────────────────────────────────────
  TreasureDivideAnnouncementHelper? _audioQueue;

  /// Tracks the last leader so we only fire a leader-change announcement when
  /// the leader actually changes (not on the very first turn).
  String? _lastLeaderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    final dartboardProvider = context.read<DartboardProvider>();
    _mockApi = dartboardProvider.apiService;
    if (mounted) setState(() {});

    // ── Audio queue setup ──
    final queueService = GameAnnouncementQueueService();
    await queueService.loadSettings();
    _audioQueue = TreasureDivideAnnouncementHelper(queueService);

    final provider = context.read<TreasureDivideProvider>();
    final game = provider.currentGame;
    if (game != null && !_dartboardEmulatorController.isAutoPlaying) {
      _audioQueue?.announceGameStart(game.numberOfRounds);

      // Announce the first turn after a 2s delay so the game-start audio
      // has time to play before the first player/crew cue fires.
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        _announceCurrentTurn(provider, game);
      });
    }

    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen((event) {
        _handleDartboardEvent(event);
      });
    }
  }

  /// Fires the appropriate turn announcement (player or crew) for the currently
  /// active player based on game mode and within-crew rotation state.
  void _announceCurrentTurn(
      TreasureDivideProvider provider, TreasureDivideGame game) {
    if (_dartboardEmulatorController.isAutoPlaying) return;
    final playerProvider = context.read<PlayerProvider>();
    final playerId = game.currentPlayerId;
    final playerName =
        playerProvider.getPlayerById(playerId)?.name ?? playerId;

    if (game.gameMode == TreasureDivideGameMode.team &&
        game.activeTeamId != null) {
      final teamId = game.activeTeamId!;
      final pointer = game.teamWithinRoundRotationPointer[teamId] ?? 0;
      final crewName = provider.crewNameForTeam(teamId);

      if (pointer == 0) {
        // First player of the crew for this round → Crew Turn announcement.
        _audioQueue?.announceCrewTurn(crewName, playerName);
      } else {
        // Subsequent crew member → standard Player Turn.
        _audioQueue?.announcePlayerTurn(playerName);
      }
    } else {
      _audioQueue?.announcePlayerTurn(playerName);
    }
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    _playToCompleteRunner?.dispose();
    _playToTieRunner?.dispose();
    _dartboardSubscription?.cancel();
    _dartboardEmulatorController.dispose();
    super.dispose();
  }

  void _onPlayToComplete() {
    if (_mockApi == null) return;
    _dartboardEmulatorController.setAutoPlaying(true);
    _dartboardEmulatorController.hide();

    _playToCompleteRunner = PlayToCompleteRunner(
      strategy: TreasureDivideStrategy(),
      mockApi: _mockApi!,
      context: context,
      onComplete: () {
        if (mounted) {
          _dartboardEmulatorController.setAutoPlaying(false);
        }
      },
    );
    _playToCompleteRunner!.run();
  }

  /// Drives the game to a tie via [TreasureDivideTieStrategy]. Same shape
  /// as `_onPlayToComplete`; only one of the two runners is active at any
  /// given moment (the emulator section disables both buttons while
  /// `isAutoPlaying` is true).
  void _onPlayToTie() {
    if (_mockApi == null) return;
    _dartboardEmulatorController.setAutoPlaying(true);
    _dartboardEmulatorController.hide();

    _playToTieRunner = PlayToTieRunner(
      strategy: TreasureDivideTieStrategy(),
      mockApi: _mockApi!,
      context: context,
      onComplete: () {
        if (mounted) {
          _dartboardEmulatorController.setAutoPlaying(false);
        }
      },
    );
    _playToTieRunner!.run();
  }

  void _onCancelAutoPlay() {
    _playToCompleteRunner?.cancel();
    _playToTieRunner?.cancel();
    _dartboardEmulatorController.setAutoPlaying(false);
    _dartboardEmulatorController.show();
  }

  void _handleDartboardEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'throw_detected') {
      _handleDartThrow(event);
    } else if (type == 'takeout_finished') {
      _handleTakeoutFinished();
    }
  }

  void _handleDartThrow(Map<String, dynamic> event) {
    final provider = context.read<TreasureDivideProvider>();
    if (!mounted || !provider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;
    final score = (throwData['score'] as num?)?.toInt() ?? 0;
    final multiplier = (throwData['multiplier'] as String?) ?? 'single';
    final baseScore = (throwData['baseScore'] as num?)?.toInt() ?? 0;

    provider.processDartThrow(
      score: score,
      multiplier: multiplier,
      baseScore: baseScore,
      sector: sector,
    );

    // ── Per-dart announcement (suppressed during Play-to-Complete) ────────────
    if (!_dartboardEmulatorController.isAutoPlaying) {
      _audioQueue?.pickAndAnnounceMoment(
        wasMatched: provider.lastDartWasMatched,
        multiplier: provider.lastDartMultiplier,
        sector: provider.lastDartSector,
        value: provider.lastDartScore,
      );

      // ── Remove Darts — called UNCONDITIONALLY (not inside any else). ────────
      // Fired when the player has thrown all darts (shouldPromptTakeout flipped
      // true inside processDartThrow on the last dart).
      if (provider.shouldPromptTakeout) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _audioQueue?.announceRemoveDarts();
        });
      }
    }

    // Do NOT navigate to results here — wait for DARTS REMOVED (Rule §).
    setState(() {});
  }

  void _handleTakeoutFinished() {
    final provider = context.read<TreasureDivideProvider>();
    if (!mounted) return;

    if (provider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!provider.isGameActive) return;

    // Snapshot announcement-relevant facts BEFORE advancing state.
    final gameBeforeTakeout = provider.currentGame!;
    final isTeam = gameBeforeTakeout.gameMode == TreasureDivideGameMode.team;
    final scoreBeforeTurn = provider.scoreBeforeCurrentTurn;
    final allMissedThisTurn = provider.currentTurnAllMissed;
    final quarterItEnabled = gameBeforeTakeout.quarterItEnabled;
    final customTargetsEnabled = gameBeforeTakeout.customTargetsEnabled;
    final prevRoundIndex = gameBeforeTakeout.currentRoundIndex;

    provider.handleTakeoutFinished();
    setState(() {});

    // Re-check hasWinner AFTER handleTakeoutFinished — the game is only
    // finalized inside handleTakeoutFinished (on the last player's last turn
    // in the last round). Without this second check the navigation to the
    // results screen never fires. (Same pattern as tiki_golf_game_screen.dart
    // lines 397-400.)
    if (provider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (_dartboardEmulatorController.isAutoPlaying) return;

    final gameAfter = provider.currentGame;
    if (gameAfter == null) return;

    // ── Turn-end announcement ─────────────────────────────────────────────────
    if (isTeam) {
      // Only fire on the last player of the crew for this round.
      final completedCrewId = provider.justCompletedCrewId;
      if (completedCrewId != null) {
        final crewName = provider.crewNameForTeam(completedCrewId);
        final crewHaul = provider.justCompletedCrewHaul;

        // Determine if the whole crew missed by checking each member's haul.
        final members = gameBeforeTakeout.teamPlayers[completedCrewId] ?? [];
        bool crewAllMissed = true;
        for (final pid in members) {
          final haul = gameBeforeTakeout.playerRoundScores[pid]
                  ?[prevRoundIndex] ??
              0;
          if (haul > 0) {
            crewAllMissed = false;
            break;
          }
        }
        // Also include the player whose turn JUST ended (haul committed).
        // The current player's round score was just committed by handleTakeoutFinished,
        // so we read from gameAfter:
        for (final pid in members) {
          final haul =
              gameAfter.playerRoundScores[pid]?[prevRoundIndex] ?? 0;
          if (haul > 0) {
            crewAllMissed = false;
            break;
          }
        }

        _audioQueue?.announceTurnEndTeam(
          crewAllMissed: crewAllMissed,
          crewTreasureBefore: scoreBeforeTurn,
          crewHaulThisRound: crewHaul,
          crewName: crewName,
        );
      }
      // Mid-crew turn-ends (crew not yet complete): no turn-end announcement.
    } else {
      // Solo mode — fire turn-end for each player.
      _audioQueue?.announceTurnEndSolo(
        allMissed: allMissedThisTurn,
        quarterItEnabled: quarterItEnabled,
        scoreBeforeTurn: scoreBeforeTurn,
      );
    }

    // ── Round-transition announcement ─────────────────────────────────────────
    if (provider.roundAdvancedOnLastTakeout && !provider.hasWinner) {
      final newRoundIndex = gameAfter.currentRoundIndex;
      final newTarget = newRoundIndex < gameAfter.targetSequence.length
          ? gameAfter.targetSequence[newRoundIndex]
          : 0;
      final isLastRound = newRoundIndex == gameAfter.numberOfRounds - 1;
      _audioQueue?.announceNewRound(
        roundIndex: newRoundIndex,
        target: newTarget,
        totalRounds: gameAfter.numberOfRounds,
        isLastRound: isLastRound,
        customTargetsEnabled: customTargetsEnabled,
      );
    }

    // ── Leader-change announcement ────────────────────────────────────────────
    if (!provider.hasWinner) {
      _maybeAnnounceLeaderChange(provider, gameAfter);
    }

    // ── Next turn announcement (500ms delay to follow turn-end audio) ─────────
    if (!provider.hasWinner) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final freshProvider = context.read<TreasureDivideProvider>();
        final freshGame = freshProvider.currentGame;
        if (freshGame == null || freshProvider.hasWinner) return;
        if (_dartboardEmulatorController.isAutoPlaying) return;
        _announceCurrentTurn(freshProvider, freshGame);
      });
    }
  }

  /// Computes the current top of the leaderboard (which may have ≥ 1
  /// player/crew tied at the same max score) and fires the appropriate
  /// leader announcement if the set of leaders has changed since the last
  /// turn. Single leader → name announcement; tied leaders → score-only
  /// "The leaders have N gold!" announcement.
  void _maybeAnnounceLeaderChange(
      TreasureDivideProvider provider, TreasureDivideGame game) {
    final isTeam = game.gameMode == TreasureDivideGameMode.team;

    // Two-pass: find max score, then collect every id with that score.
    int topScore = -1;
    final List<String> ids = isTeam
        ? game.teamPlayers.keys.toList()
        : game.playerIds.toList();
    final List<int> scores = ids
        .map((id) => isTeam ? game.totalForTeam(id) : game.totalForPlayer(id))
        .toList();
    for (final s in scores) {
      if (s > topScore) topScore = s;
    }
    final List<String> topIds = [
      for (int i = 0; i < ids.length; i++)
        if (scores[i] == topScore) ids[i],
    ];

    if (topIds.isEmpty || topScore <= 0) return;

    // Signature = sorted-joined ids — changes when the set of leaders
    // changes (single → different single, single → tied, tied → tied with
    // different participants). The same set is silent (no re-fire).
    final signature = (List<String>.from(topIds)..sort()).join(',');

    // Don't fire on the very first turn of the game (no prior signature).
    if (_lastLeaderId != null && signature != _lastLeaderId) {
      if (topIds.length == 1) {
        // Single leader — keep the name announcement.
        final leaderId = topIds.first;
        if (isTeam) {
          final crewName = provider.crewNameForTeam(leaderId);
          _audioQueue?.announceLeaderChange(crewName, topScore, isTeam: true);
        } else {
          final playerProvider = context.read<PlayerProvider>();
          final name = playerProvider.getPlayerById(leaderId)?.name ?? leaderId;
          _audioQueue?.announceLeaderChange(name, topScore, isTeam: false);
        }
      } else {
        // Tied — name-free announcement so we don't enumerate names.
        _audioQueue?.announceLeadersTied(topScore);
      }
    }

    _lastLeaderId = signature;
  }

  void _handleGameWon() {
    if (_gameCompleted) return;
    _gameCompleted = true;

    void navigateToResults() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TreasureDivideResultsScreen()),
      );
    }

    if (_dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
    } else {
      final provider = context.read<TreasureDivideProvider>();
      final game = provider.currentGame;
      if (game != null) {
        if (game.gameMode == TreasureDivideGameMode.solo) {
          // Collect EVERY winning player's name. Ties produce
          // winnerIds.length > 1 — the announcement helper pluralizes
          // accordingly ("Divided treasure! A and B share the captain's
          // title!"). Falls back to id if a name lookup misses.
          if (game.winnerIds.isNotEmpty) {
            final playerProvider = context.read<PlayerProvider>();
            final winnerNames = game.winnerIds
                .map((id) =>
                    playerProvider.getPlayerById(id)?.name ?? id)
                .toList();
            _audioQueue?.announceVictory(winnerNames);
          }
        } else {
          // Collect EVERY winning crew's name. Ties produce
          // winnerTeamIds.length > 1 — the helper pluralizes accordingly.
          if (game.winnerTeamIds.isNotEmpty) {
            final winningCrewNames = game.winnerTeamIds
                .map((tid) => provider.crewNameForTeam(tid))
                .toList();
            _audioQueue?.announceTeamVictory(winningCrewNames);
          }
        }
      }
      // Navigate when the audio queue is idle, falling back gracefully:
      // - If `_audioQueue` is null (init race), navigate after the 250ms
      //   pacing delay so the dart-throw flow still completes.
      // - If `whenIdle()` hangs (TTS engine stuck, etc.), cap the wait at
      //   10s so the user never sees a stuck "Remove your darts" screen.
      //   Without this guard, tests that complete a game timed out the
      //   parallel-runner because navigation never fired.
      final whenIdleFuture = _audioQueue?.whenIdle() ?? Future<void>.value();
      whenIdleFuture
          .timeout(const Duration(seconds: 10), onTimeout: () {})
          .then((_) {
        Future.delayed(const Duration(milliseconds: 250), navigateToResults);
      });
    }
  }

  // ─── Theme preview (emulator-only) ──────────────────────────────────────────

  /// Builds the buff-toggle specs for the 8 pirate themes. Active
  /// toggle reflects `_themePreviewOverride`; tapping the same theme
  /// again clears the override (back to natural per-player themes).
  List<BuffToggleSpec<Object>> _buildThemePreviewSpecs() {
    return kThemeDisplayNames.entries
        .map((entry) => BuffToggleSpec<Object>(
              buff: entry.key,
              label: entry.value,
              isActive: _themePreviewOverride == entry.key,
              isEnabled: true,
              config: BuffToggleButtonConfig.treasureDivide(),
              buttonKey: Key('themePreviewToggle_${entry.key}'),
            ))
        .toList();
  }

  void _handleThemePreviewToggle(Object buff) {
    final idx = buff as int;
    setState(() {
      _themePreviewOverride =
          _themePreviewOverride == idx ? null : idx;
    });
  }

  // ─── Island-layout editor (emulator-only) ──────────────────────────────────

  /// Returns the current set of island coords — the live override when
  /// one exists, otherwise a fresh copy of the canonical constants for
  /// the active round count. Always returns a mutable list of records.
  List<({double x, double y})> _currentIslandCoords() {
    final override = _islandCoordsOverride;
    final game = context.read<TreasureDivideProvider>().currentGame;
    final rounds = game?.numberOfRounds ?? 9;
    if (override != null && override.length == rounds) {
      return List<({double x, double y})>.from(override);
    }
    return defaultIslandCoordsFor(rounds);
  }

  void _onIslandDragged(int index, double xPercent, double yPercent) {
    final coords = _currentIslandCoords();
    if (index < 0 || index >= coords.length) return;
    coords[index] = (x: xPercent, y: yPercent);
    setState(() {
      _islandCoordsOverride = coords;
    });
  }

  void _toggleLayoutEditMode() {
    setState(() {
      _layoutEditMode = !_layoutEditMode;
    });
  }

  void _resetLayoutEditor() {
    setState(() {
      _islandCoordsOverride = null;
    });
  }

  /// Stacked emulator-only buttons: Edit Targets toggle + (when
  /// active) Copy Coords and Reset. The controls render in the outer
  /// Stack at the right edge above the dartboard FAB.
  Widget _buildLayoutEditorControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_layoutEditMode) ...[
          _editorButton(
            label: 'Reset',
            icon: Icons.refresh,
            background: _plankBrown,
            onPressed: _resetLayoutEditor,
          ),
          const SizedBox(height: 8),
          _editorButton(
            label: 'Copy Coords',
            icon: Icons.copy,
            background: _treasureGold,
            foreground: _oceanTeal,
            onPressed: _copyIslandCoordsToClipboard,
          ),
          const SizedBox(height: 8),
        ],
        _editorButton(
          label: _layoutEditMode ? 'Done Editing' : 'Edit Targets',
          icon: _layoutEditMode ? Icons.check : Icons.edit_location_alt,
          background: _layoutEditMode ? _islandGreen : _oceanTeal,
          onPressed: _toggleLayoutEditMode,
        ),
      ],
    );
  }

  Widget _editorButton({
    required String label,
    required IconData icon,
    required Color background,
    Color foreground = _sailWhite,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: foreground, size: 18),
      label: Text(
        label,
        style: GoogleFonts.pirataOne(
          fontSize: 18,
          color: foreground,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: _treasureGold.withOpacity(0.6), width: 1),
      ),
    );
  }

  /// Format the current coords as a Dart literal matching the
  /// `_islandCoordsByRoundCount` map entry, copy it to the clipboard,
  /// and pop a SnackBar so the user knows it's done.
  Future<void> _copyIslandCoordsToClipboard() async {
    final game = context.read<TreasureDivideProvider>().currentGame;
    if (game == null) return;
    final coords = _currentIslandCoords();
    final buffer = StringBuffer();
    buffer.writeln('${game.numberOfRounds}: [');
    for (final c in coords) {
      final x = c.x.toStringAsFixed(1);
      final y = c.y.toStringAsFixed(1);
      buffer.writeln('    (x: $x, y: $y),');
    }
    buffer.write('  ],');
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Island coords copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final provider = context.watch<TreasureDivideProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    final game = provider.currentGame;
    if (game == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox();
    }

    final currentPlayerId = game.currentPlayerId;
    final currentPlayer = playerProvider.getPlayerById(currentPlayerId);
    final currentPlayerName = currentPlayer?.name ?? '';

    final shouldPromptTakeout = provider.shouldPromptTakeout;
    final hasDartsThrown = game.totalDartsThrown.values.any((c) => c > 0);

    // Compute opponents for the bottom strip. Solo → other players in turn
    // order; Team → other crews (active crew is on the left column).
    final isTeam = game.gameMode == TreasureDivideGameMode.team;
    final playerIds = game.playerIds;
    final currentIdx = playerIds.indexOf(currentPlayerId);
    final opponentIds = <String>[];
    if (isTeam) {
      opponentIds.addAll(
        game.teamPlayers.keys.where((id) => id != game.activeTeamId),
      );
    } else {
      for (int i = 1; i < playerIds.length; i++) {
        opponentIds.add(playerIds[(currentIdx + i) % playerIds.length]);
      }
    }

    return PopScope(
      canPop: !hasDartsThrown || _showSaveModal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Stack(
        children: [
          // ─── 1. Scaffold ───────────────────────────────────────────────────
          Scaffold(
            appBar: AppBar(
              leading: IconButton(
                key: TreasureDivideGameKeys.backButton,
                icon: const Icon(Icons.arrow_back, color: _treasureGold, size: 32),
                onPressed: () {
                  if (hasDartsThrown) {
                    setState(() => _showSaveModal = true);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
              ),
              title: Text(
                'TREASURE DIVIDE',
                style: GoogleFonts.pirataOne(
                  fontSize: 38,
                  color: _treasureGold,
                  shadows: const [
                    Shadow(
                        color: Color(0xCC000000),
                        offset: Offset(2, 2),
                        blurRadius: 4),
                    Shadow(
                        color: Color(0xAA008B8B),
                        offset: Offset(0, 0),
                        blurRadius: 10),
                  ],
                ),
              ),
              backgroundColor: _oceanTeal,
              actions: [
                DartboardConnectionInfo(
                    config:
                        DartboardConnectionInfoConfig.treasureDivide()),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // Background image — capped at 1280×512 to bound the
                // decoded raster. The source ships at 1584×588 (~3.7 MB
                // RGBA decoded) and on hi-DPI displays Flutter can keep
                // an even larger upscaled bitmap resident. Capping keeps
                // this single full-screen layer under ~2.6 MB.
                // Provider is `const` so the same instance is reused
                // across every Scaffold rebuild (every dart throw fires
                // setState) — no allocation churn through the image
                // cache.
                Positioned.fill(
                  child: Image(
                    image: const ResizeImage(
                      AssetImage(
                          'assets/games/treasure_divide/images/TreasureDivide-Background.png'),
                      width: 1280,
                      height: 512,
                      policy: ResizeImagePolicy.fit,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: _oceanTeal),
                  ),
                ),
                // 10% Ocean Teal overlay — keeps a hint of the brand wash
                // while letting the background art show through.
                Positioned.fill(
                  child: Container(
                    color: _oceanTeal.withOpacity(0.10),
                  ),
                ),
                // Main content — Positioned.fill so the Column has a
                // bounded height for its Expanded child to expand against.
                // Without this the Column shrinks to intrinsic content, the
                // Expanded Row gets zero height, and the treasure map area
                // collapses (recurring naked-Stack-child Flutter quirk).
                Positioned.fill(
                  child: Column(
                    children: [
                      _buildBadgeRow(provider, game),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, contentConstraints) {
                            // Active player panel takes 2 of the 7
                            // baseline slots wide — same slice used
                            // for the active tile in the classic
                            // bottom-strip solo layout.
                            final activePanelWidth =
                                contentConstraints.maxWidth *
                                    2 /
                                    _kOpponentTileBaseline;

                            // Team mode: active panel spans the FULL
                            // available height on the left; the right
                            // side is a Column with the treasure map
                            // on top and the opponent bottom strip
                            // pinned to the bottom. The strip only
                            // spans the right area (5/7 of screen)
                            // instead of stretching under the active
                            // panel — so 4 opponent tiles fill just
                            // that portion.
                            if (isTeam) {
                              return Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildLeftColumn(
                                      provider,
                                      game,
                                      playerProvider,
                                      activePanelWidth),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: _buildTreasureMapArea(
                                              provider, game),
                                        ),
                                        if (opponentIds.isNotEmpty)
                                          _buildOpponentsBottomStrip(
                                            provider,
                                            game,
                                            playerProvider,
                                            opponentIds,
                                            isTeam,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Solo mode: classic layout — active +
                            // map on top, opponent strip along the
                            // bottom.
                            return Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildLeftColumn(
                                          provider,
                                          game,
                                          playerProvider,
                                          activePanelWidth),
                                      Expanded(
                                        child: _buildTreasureMapArea(
                                            provider, game),
                                      ),
                                    ],
                                  ),
                                ),
                                if (opponentIds.isNotEmpty)
                                  _buildOpponentsBottomStrip(
                                    provider,
                                    game,
                                    playerProvider,
                                    opponentIds,
                                    isTeam,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── 2. RemoveDartsModal (behind emulator) ─────────────────────────
          if (shouldPromptTakeout)
            RemoveDartsModal(
              config: RemoveDartsModalConfig.treasureDivide(),
              playerName: currentPlayerName,
              editScoreButtonKey: TreasureDivideGameKeys.editScoreButton,
              onEditScore: () {
                final segs =
                    game.currentTurnDartSegments[currentPlayerId] ?? [];
                showEditScoreDialog(
                  context: context,
                  playerName: currentPlayerName,
                  config: EditScoreDialogConfig.treasureDivide(),
                  initialSegments: segs,
                  onSubmit: (newSegments) {
                    provider.editPlayerScore(
                      playerId: currentPlayerId,
                      roundIndex: game.currentRoundIndex,
                      newSegments: newSegments,
                    );
                  },
                );
              },
            ),

          // ─── 3. DartboardEmulatorSection ───────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DartboardEmulatorSection(
              config: DartboardSectionConfig.treasureDivide(),
              controller: _dartboardEmulatorController,
              dartboardKey: _dartboardKey,
              isConnected: !dartboardProvider.isEmulator,
              shouldPromptTakeout: shouldPromptTakeout,
              onDartThrow: (score, multiplier, baseScore, position) {
                _mockApi?.simulateDartThrow(
                  score: score,
                  multiplier: multiplier,
                  playerName: currentPlayerName,
                  baseScore: baseScore,
                  widgetX: position.dx,
                  widgetY: position.dy,
                  widgetSize: 250,
                );
              },
              onRemoveDarts: () {
                _mockApi?.simulateTakeoutFinished();
              },
              onPlayToComplete:
                  _mockApi != null ? _onPlayToComplete : null,
              playToCompleteConfig: _mockApi != null
                  ? PlayToCompleteButtonConfig.treasureDivide()
                  : null,
              // Play-to-Tie. Same `_mockApi != null` gate as PlayToComplete
              // so the button only renders in emulator mode. TD ties are
              // reachable from any settings combination — the strategy's
              // `canProduceTie` is always true, so we set the enabled
              // flag here statically too.
              onPlayToTie: _mockApi != null ? _onPlayToTie : null,
              playToTieConfig: _mockApi != null
                  ? PlayToTieButtonConfig.treasureDivide()
                  : null,
              playToTieEnabled: true,
              // Emulator-only theme preview — overrides every player's
              // pirate theme for sprite-position debugging. Game logic
              // ignores this entirely; it only routes through the
              // PirateAvatarWidget themeIndex prop.
              buffToggles:
                  _mockApi != null ? _buildThemePreviewSpecs() : null,
              onBuffToggle: _mockApi != null ? _handleThemePreviewToggle : null,
            ),
          ),

          // ─── 4. DartboardEmulatorFAB ───────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 16,
            child: DartboardEmulatorFAB(
              controller: _dartboardEmulatorController,
              isConnected: !dartboardProvider.isEmulator,
              config: DartboardFABConfig.treasureDivide(),
              onCancelAutoPlay: _onCancelAutoPlay,
            ),
          ),

          // ─── 4b. Layout editor controls (emulator-only) ────────────────────
          // Stacked above the FAB at the right edge. The Edit toggle
          // shows whenever the emulator is on; Copy + Reset appear only
          // while edit mode is engaged.
          if (_mockApi != null)
            Positioned(
              right: 16,
              bottom: 96,
              child: _buildLayoutEditorControls(),
            ),

          // ─── 5. SaveGameModal ──────────────────────────────────────────────
          if (_showSaveModal)
            SaveGameModal(
              config: SaveGameModalConfig.treasureDivide(),
              onSave: () async {
                final saveService = SaveGameService();
                await provider.saveGame(saveService);
                if (mounted) {
                  setState(() => _showSaveModal = false);
                  Navigator.of(context).pop();
                }
              },
              onDontSave: () {
                setState(() => _showSaveModal = false);
                Navigator.of(context).pop();
              },
            ),

          // ─── 6. DartboardPausedModal (LAST) ───────────────────────────────
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status !=
                  DartboardConnectionStatus.connected &&
              dartboardProvider.status !=
                  DartboardConnectionStatus.emulator)
            DartboardPausedModal(
                config: DartboardPausedModalConfig.treasureDivide()),
        ],
      ),
    );
  }

  // ─── Badge row ────────────────────────────────────────────────────────────────

  Widget _buildBadgeRow(TreasureDivideProvider provider, TreasureDivideGame game) {
    final badges = <Widget>[];
    // QUARTER IT is rendered inline with the Island counter on the
    // treasure map widget (see TreasureMapWidget.quarterItEnabled) so
    // it isn't added to this top badge row anymore.
    //
    // "Solo Crew: 6 darts" pill is also no longer rendered here — it
    // moved to the on-deck slot at the bottom of the active player
    // panel (see _buildOnDeckTeammateRow — solo crew branch). Sized
    // like the treasure map's Island counter pill, it fills the
    // vertical space the "Up next" row would occupy for a doubles
    // crew.
    if (game.customTargetsEnabled) {
      badges.add(_buildBadge(
        key: TreasureDivideGameKeys.customBadge,
        label: 'CUSTOM',
        backgroundColor: _treasureGold,
        textColor: _oceanTeal,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (int i = 0; i < badges.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            badges[i],
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({
    required Key key,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.pirataOne(
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }

  // ─── Left column ──────────────────────────────────────────────────────────────

  Widget _buildLeftColumn(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Expanded(
            child: _buildActivePlayerPanel(provider, game, playerProvider),
          ),
        ],
      ),
    );
  }

  // Height of the bottom strip containing opponent tiles.
  // Originally 360, shrunk to 220 so the aspect-locked treasure map
  // could fill the row width. Bumped 220 → 235 to give the opponent
  // column ~15 px more headroom — the previous setting overflowed by
  // ~9 px when both conditional rows (round score + halved) were
  // visible on a tile, and shrinking the opponent avatar to fit had
  // been rejected. The 15 px reclaim costs only ~13 px of letterbox
  // on a typical 16:9 viewport (map row 774 → 759; map aspect 1.773
  // wants ~1346 wide vs row width 1372).
  static const double _kBottomStripHeight = 235.0;
  // Sizing baseline for opponent tiles — 8-player Solo is the maximum so
  // 7 opponent tiles fill the strip edge-to-edge. With fewer opponents,
  // each tile keeps this same width and the strip leaves empty space on
  // the right.
  static const int _kOpponentTileBaseline = 7;
  // Team-mode baseline — with at most 4 opponent crews we fill the
  // strip edge-to-edge instead of falling back to the solo 7-slot
  // baseline (which left the right side empty).
  static const int _kTeamOpponentTileBaseline = 4;

  Widget _buildActivePlayerPanel(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
  ) {
    final currentPlayerId = game.currentPlayerId;
    final currentPlayer = playerProvider.getPlayerById(currentPlayerId);
    final isTeam = game.gameMode == TreasureDivideGameMode.team;
    final activeTeamId = game.activeTeamId;

    // Compute display score
    int displayScore;
    int roundScore;
    // Live in-progress haul for the player throwing right now — added
    // to the committed totals so the gold/round numbers tick up after
    // every dart hit instead of jumping at end of turn. Halving on
    // an all-miss turn is still applied at takeout, so the
    // optimistic add can never go negative.
    final liveHaul = provider.currentTurnHaul;
    int timesHalved;
    if (isTeam && activeTeamId != null) {
      // Team mode: the big "N gold" number below the active player
      // shows THIS PLAYER'S THIS-TURN earnings only, not the whole
      // crew total. The cumulative crew treasure is surfaced by the
      // crew header at the top of the tile (see _buildActiveCrewHeader
      // which reads totalForTeam + provider.currentTurnHaul). Prior
      // to this split, both the header and the main number showed
      // the same running crew total.
      displayScore = liveHaul;
      // Sum of hauls for current round from all team members,
      // plus the in-progress turn's accumulating haul.
      int crewRound = 0;
      final members = game.teamPlayers[activeTeamId] ?? [];
      for (final pid in members) {
        crewRound += game.playerRoundScores[pid]?[game.currentRoundIndex] ?? 0;
      }
      roundScore = crewRound + liveHaul;
      timesHalved = game.timesHalvedPerTeam[activeTeamId] ?? 0;
    } else {
      displayScore = game.totalForPlayer(currentPlayerId) + liveHaul;
      roundScore =
          (game.playerRoundScores[currentPlayerId]?[game.currentRoundIndex] ??
                  0) +
              liveHaul;
      timesHalved = game.timesHalvedPerPlayer[currentPlayerId] ?? 0;
    }

    // Compute dart indicators
    final dartsThisTurn = game.dartsThisTurn;
    final dartsThrown = game.dartsThrown;
    final segments = game.currentTurnDartSegments[currentPlayerId] ?? [];

    // Find the teammate coming next (Team mode only)
    String? nextTeammateId;
    if (isTeam && activeTeamId != null) {
      final members = game.teamPlayers[activeTeamId] ?? [];
      final idx = members.indexOf(currentPlayerId);
      if (idx >= 0 && idx + 1 < members.length) {
        nextTeammateId = members[idx + 1];
      }
    }

    return Container(
      // Team mode: symmetric 24px top/bottom padding so the crew
      // badge floats near the top and the "Up next" row mirrors it at
      // the bottom. Solo mode keeps its tight 2px so the centered
      // content isn't pushed downward on a shorter tile.
      margin: const EdgeInsets.fromLTRB(6, 2, 6, 2),
      padding: isTeam
          ? const EdgeInsets.fromLTRB(10, 24, 10, 24)
          : const EdgeInsets.fromLTRB(10, 2, 10, 2),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _treasureGold.withOpacity(0.5), width: 2),
      ),
      // Stack so the crew header can paint IN FRONT of the active
      // player's avatar + theme decorations (pirate hats extend
      // upward outside the 360px avatar box via Clip.none and would
      // otherwise cover the crest / "Crew Treasure" label). The
      // base Column carries an invisible placeholder for the header
      // to reserve its spatial position; the same header is then
      // rendered again as a Stack overlay (last child) so it paints
      // on top of everything below. Solo mode skips the overlay
      // since there's no crew header to protect.
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Column(
        // Team mode gets spaceBetween — crew header pinned to the top
        // edge, on-deck row pinned to the bottom edge, middle content
        // in between. Solo mode falls back to center so the single
        // middle group sits vertically centered as before.
        mainAxisAlignment: isTeam
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          // ── Top: invisible placeholder for the crew header. Real
          //         header is painted from the Stack overlay below so
          //         pirate-hat overflow can't cover it.
          if (isTeam && activeTeamId != null)
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: _buildActiveCrewHeader(provider, game,
                  playerProvider, activeTeamId, nextTeammateId),
            ),

          // ── Middle: avatar + player stats + Skip button ──
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player avatar — kept at 360 in both modes.
              SizedBox(
                key: TreasureDivideGameKeys.playerAvatar,
                width: 360,
                height: 360,
                child: currentPlayer != null
                    ? PirateAvatarWidget(
                        player: currentPlayer,
                        themeIndex: _themePreviewOverride ??
                            game.playerPirateThemes[currentPlayer.id] ??
                            0,
                        size: 360,
                        isActive: true,
                      )
                    : const SizedBox.shrink(),
              ),
              // No spacer here — the trim from 8 → 4 → 0 was needed
              // to keep the active-panel Column from overflowing the
              // 622px constraint in solo mode. Avatar sits directly
              // above the player name; the avatar's own bottom edge
              // is the visual gap.

              // Player name.
              Text(
                currentPlayer?.name ?? '',
                style: GoogleFonts.pirataOne(
                  fontSize: 44,
                  color: _sailWhite,
                  shadows: _treasureTextShadows,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Treasure score.
              Text(
                key: TreasureDivideGameKeys.treasureScore,
                '$displayScore gold',
                style: GoogleFonts.pirataOne(
                  fontSize: 44,
                  color: _treasureGold,
                  shadows: _treasureTextShadows,
                ),
                textAlign: TextAlign.center,
              ),

              // Halving / quartering history.
              if (timesHalved > 0)
                Text(
                  '${game.quarterItEnabled ? "Quartered" : "Halved"} '
                  '$timesHalved ${timesHalved == 1 ? "time" : "times"}',
                  style: GoogleFonts.merriweather(
                    fontSize: 20,
                    color: const Color(0xFFFF8C42),
                    shadows: _treasureTextShadows,
                  ),
                  textAlign: TextAlign.center,
                ),

              // Round score.
              Text(
                key: TreasureDivideGameKeys.roundScore,
                '+$roundScore this round',
                style: GoogleFonts.merriweather(
                  fontSize: 32,
                  color: _sailWhite,
                  shadows: _treasureTextShadows,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Dart indicators.
              _buildDartIndicators(
                  dartsThisTurn, dartsThrown, segments, game),
              // No spacer here — same rationale as after the avatar
              // (see comment above). Skip Turn sits directly under
              // the dart indicators; the button's own OutlinedButton
              // padding is the visual gap.

              // Skip Turn button — +4pt on the label (23 → 27).
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: TreasureDivideGameKeys.skipTurnButton,
                  onPressed: provider.shouldPromptTakeout
                      ? null
                      : () {
                          final dt = game.dartsThrown;
                          provider.skipTurn();
                          if (dt > 0) {
                            // Darts on board — wait for physical takeout.
                            // Remove Darts is called unconditionally at 1500ms.
                            if (!_dartboardEmulatorController.isAutoPlaying) {
                              Future.delayed(
                                  const Duration(milliseconds: 1500), () {
                                if (mounted) {
                                  _audioQueue?.announceRemoveDarts();
                                }
                              });
                            }
                            Future.delayed(
                                const Duration(milliseconds: 3500), () {
                              if (mounted) _mockApi?.simulateTakeoutStarted();
                            });
                          } else {
                            // No darts — auto-finish immediately
                            Future.delayed(
                                const Duration(milliseconds: 500), () {
                              if (mounted) {
                                if (_mockApi != null) {
                                  _mockApi!.simulateTakeoutFinished();
                                } else {
                                  _handleTakeoutFinished();
                                }
                              }
                            });
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _treasureGold, width: 2),
                    foregroundColor: _treasureGold,
                    // Vertical padding trimmed 10 → 6 to reclaim ~8px
                    // of vertical space so the active-panel Column
                    // content fits inside the panel constraint in
                    // solo mode without the RenderFlex overflow that
                    // was breaking the parallel UI test runner.
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'Skip Turn',
                    style: GoogleFonts.pirataOne(
                        fontSize: 23, color: _treasureGold),
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom: on-deck teammate row (team-mode doubles only) ──
          // Only rendered when in team mode with a doubles crew AND
          // there's another crew member to call out. Sits pinned to
          // the bottom edge of the tile via the outer Column's
          // spaceBetween alignment.
          if (isTeam && activeTeamId != null)
            _buildOnDeckTeammateRow(
              provider,
              game,
              playerProvider,
              activeTeamId,
            )
          else
            // Placeholder to keep spaceBetween anchoring middle group
            // centered in solo mode / solo crews. Zero-height widget
            // simply satisfies the third-child requirement.
            const SizedBox.shrink(),
        ],
          ),
          // Overlay — real crew header painted LAST so pirate hats
          // and theme decorations from the 360px active-player
          // avatar (which paint outside the avatar box via
          // Clip.none) can't cover the crest or "Crew Treasure"
          // label. Only rendered in team mode; matches the
          // placeholder position via alignment: topCenter.
          if (isTeam && activeTeamId != null)
            _buildActiveCrewHeader(provider, game, playerProvider,
                activeTeamId, nextTeammateId),
        ],
      ),
    );
  }

  // ─── On-deck teammate row (bottom of active tile, team mode only) ───────────

  Widget _buildOnDeckTeammateRow(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    String activeTeamId,
  ) {
    final members = game.teamPlayers[activeTeamId] ?? const [];
    // Solo crew (1 player) → no teammate to surface, so drop the
    // "Solo Crew: 6 darts" pill in the on-deck slot. Sized to match
    // the treasure map's "Island X / Y" pill (25pt PirataOne, 18h/7v
    // padding, plank-brown bg, treasure-gold border). The compact
    // version of this pill in _buildBadgeRow is skipped when the
    // active crew is solo so we don't render it twice.
    if (members.length < 2) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Center(
          child: Container(
            key: TreasureDivideGameKeys.soloCrewBadge,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: _plankBrown,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: _treasureGold, width: 2.5),
            ),
            child: Text(
              'Solo Crew: 6 darts',
              style: GoogleFonts.pirataOne(
                fontSize: 25,
                color: _sailWhite,
                shadows: _treasureTextShadows,
              ),
            ),
          ),
        ),
      );
    }

    final currentId = game.currentPlayerId;
    final teammateId = members.firstWhere(
      (id) => id != currentId,
      orElse: () => '',
    );
    if (teammateId.isEmpty) return const SizedBox.shrink();
    final teammate = playerProvider.getPlayerById(teammateId);
    if (teammate == null) return const SizedBox.shrink();

    final roundIdx = game.currentRoundIndex;
    final teammateHaul = game.playerRoundScores[teammateId]?[roundIdx];
    final hasPlayed = teammateHaul != null;

    // Wrapped in Transform.translate so we can nudge the on-deck row
    // 10px DOWN visually without touching layout. Padding around it
    // would grow the widget's height — and because the outer active
    // Column uses mainAxisAlignment.spaceBetween, a taller on-deck
    // widget squeezes the middle content up. Transform-translate
    // shifts paint only, leaving every other child of the panel
    // exactly where it was.
    return Transform.translate(
      offset: const Offset(0, 10),
      child: Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Themed avatar off to the LEFT of the name — was 73 (30%
          // larger than the original 56); +20% again → 88, matching
          // the extra visual weight the enlarged badge / gold up
          // top now carry.
          SizedBox(
            width: 88,
            height: 88,
            child: PirateAvatarWidget(
              player: teammate,
              themeIndex: _themePreviewOverride ??
                  game.playerPirateThemes[teammate.id] ??
                  0,
              size: 88,
              isActive: false,
            ),
          ),
          // Extra breathing room between the on-deck avatar and the
          // text block so the two feel like separate elements rather
          // than crowding each other.
          const SizedBox(width: 28),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPlayed ? teammate.name : 'Up next: ${teammate.name}',
                  // +6pt (22 → 28) to match the larger avatar.
                  style: GoogleFonts.pirataOne(
                    fontSize: 28,
                    color: _sailWhite,
                    shadows: _treasureTextShadows,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasPlayed)
                  Text(
                    teammateHaul > 0
                        ? '+$teammateHaul gold this round'
                        : 'No gold this round',
                    // +4pt (14 → 18).
                    style: GoogleFonts.merriweather(
                      fontSize: 18,
                      color: teammateHaul > 0
                          ? _treasureGold
                          : _sailWhite.withOpacity(0.7),
                      shadows: _treasureTextShadows,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildActiveCrewHeader(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    String teamId,
    String? nextTeammateId,
  ) {
    // nextTeammateId retained for signature compatibility but the
    // teammate is now surfaced by the bottom on-deck bar; the crew
    // header no longer needs the resolved Player.
    final crestPath = provider.currentTeamCrestPath;
    // Real-time cumulative crew treasure. Three pieces:
    //   • game.totalForTeam(teamId) — completed rounds only; the
    //     model deliberately skips a round until every crew member
    //     has thrown so the halving-on-all-miss rule can fire, so
    //     this alone does NOT include the current in-flight round.
    //   • roundInFlight — the sum of round scores from crew members
    //     who have ALREADY finished their turn in the current round
    //     (e.g. teammate went first, current player still throwing).
    //     Reading playerRoundScores directly is safe because those
    //     entries only exist for players who have completed the turn.
    //   • provider.currentTurnHaul — live haul of the player currently
    //     throwing. Because this helper is only called for the ACTIVE
    //     team (teamId == game.activeTeamId at all call sites), this
    //     is always the right team.
    // Without the roundInFlight piece the header appeared to "reset"
    // to the current player's live haul once the round had rolled
    // over to the second teammate (bug reported by user).
    final activeMembers = game.teamPlayers[teamId] ?? const [];
    int roundInFlight = 0;
    for (final pid in activeMembers) {
      final rs = game.playerRoundScores[pid]?[game.currentRoundIndex];
      if (rs != null) roundInFlight += rs;
    }
    final crewTreasure = game.totalForTeam(teamId) +
        roundInFlight +
        provider.currentTurnHaul;

    // Crew crest (135) + "Crew Treasure: N gold" now sit side by side
    // in a Row: badge on the LEFT, label on the RIGHT. The "$N gold"
    // portion takes the same treasure-gold color as the main gold
    // total in the active panel below so the two read as the same
    // stat. Full text shadows applied for BG legibility.
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (crestPath != null) ...[
          Container(
            key: TreasureDivideGameKeys.activeCrewCrest,
            width: 135,
            height: 135,
            child: Image(
              image: ResizeImage(
                AssetImage(crestPath),
                width: 384,
                height: 384,
              ),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.shield,
                color: _treasureGold,
                size: 108,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Crew Treasure:\n',
                  style: GoogleFonts.merriweather(
                    fontSize: 30,
                    color: _sailWhite,
                    shadows: _treasureTextShadows,
                  ),
                ),
                TextSpan(
                  text: '$crewTreasure gold',
                  style: GoogleFonts.merriweather(
                    fontSize: 30,
                    color: _treasureGold,
                    fontWeight: FontWeight.bold,
                    shadows: _treasureTextShadows,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDartIndicators(
    int dartsThisTurn,
    int dartsThrown,
    List<String> segments,
    TreasureDivideGame game,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < dartsThisTurn; i++)
          Container(
            key: TreasureDivideGameKeys.dartIndicator(i),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 55,
            height: 55,
            decoration:
                _dartIndicatorDecoration(i, dartsThrown, segments, game),
            child: _dartIndicatorChild(i, dartsThrown, segments, game),
          ),
      ],
    );
  }

  /// Returns true when the dart [seg] actually contributed gold given
  /// the current round's [target]. A hit that doesn't match the target
  /// (e.g. S5 on a target=20 round) counts as a non-scoring dart —
  /// visually the same as a miss for indicator-color purposes.
  bool _dartScoredGold(String seg, int target) {
    if (seg == 'Miss' || seg == 'None' || seg.isEmpty) return false;
    // -1 = AnyDouble sentinel from kTargetAnyDouble.
    if (target == -1) {
      return seg.toUpperCase().startsWith('D');
    }
    // -2 = AnyTriple sentinel from kTargetAnyTriple.
    if (target == -2) {
      return seg.toUpperCase().startsWith('T');
    }
    // 25 = Bull round — Bull (50) or outer bull (25) counts.
    if (target == 25) {
      return seg == 'Bull' || seg == '25';
    }
    // Numeric target — any S/D/T multiplier of the same base number.
    final match = RegExp(r'^([SDTsdt])(\d+)$').firstMatch(seg);
    if (match != null) {
      final base = int.tryParse(match.group(2)!) ?? 0;
      return base == target;
    }
    return false;
  }

  BoxDecoration _dartIndicatorDecoration(int index, int dartsThrown,
      List<String> segments, TreasureDivideGame game) {
    if (index >= dartsThrown) {
      // Not yet thrown — sail-white ring. Reads as pending against
      // the teal active-panel background; the prior plank-brown was
      // too low-contrast to spot. Bright treasure-gold is reserved
      // for hits below so the gold ring carries meaning.
      return BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _sailWhite, width: 2.5),
      );
    }
    final seg = index < segments.length ? segments[index] : '';
    final roundIndex = game.currentRoundIndex;
    final target = roundIndex < game.targetSequence.length
        ? game.targetSequence[roundIndex]
        : 0;
    // Background uses TREASURE GOLD when the dart added gold, RED
    // otherwise — including missed darts AND non-target hits like
    // landing on S5 during a target=20 round. The bright gold ring is
    // distinct from the pending plank-brown ring above so a scoring
    // dart pops visually. The label still distinguishes true misses
    // ('X') from non-scoring hits (renders the dart's actual score).
    final scored = _dartScoredGold(seg, target);
    return BoxDecoration(
      shape: BoxShape.circle,
      color: scored
          ? _treasureGold.withOpacity(0.35)
          : _bloodRed.withOpacity(0.2),
      border: Border.all(
        color: scored ? _treasureGold : _bloodRed,
        width: 2.5,
      ),
    );
  }

  Widget? _dartIndicatorChild(
      int index, int dartsThrown, List<String> segments, TreasureDivideGame game) {
    if (index >= dartsThrown) return null;
    final seg = index < segments.length ? segments[index] : '';
    final isMiss = seg == 'Miss' || seg == 'None' || seg.isEmpty;
    // Both miss and hit labels render in sail white — the per-state
    // background tint (blood-red wash for misses, island-green wash
    // for hits) already conveys the outcome, and the previous dark
    // colored text on a dark colored tint had poor contrast against
    // the per-state ring color. Fonts bumped 18 → 22 / 16 → 20 (~25%)
    // to match the larger 55 px circles.
    if (isMiss) {
      return Center(
        child: Text(
          'X',
          style: GoogleFonts.merriweather(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: _sailWhite,
          ),
        ),
      );
    }
    final roundIndex = game.currentRoundIndex;
    final target = roundIndex < game.targetSequence.length
        ? game.targetSequence[roundIndex]
        : 0;
    final scoreText = _scoreTextForSeg(seg, target);
    return Center(
      child: Text(
        scoreText,
        style: GoogleFonts.merriweather(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: _sailWhite,
        ),
      ),
    );
  }

  String _scoreTextForSeg(String seg, int target) {
    if (seg == 'Bull') return '50';
    if (seg == '25') return '25';
    final match = RegExp(r'^([SDTsdt])(\d+)$').firstMatch(seg);
    if (match == null) return seg;
    final prefix = match.group(1)!.toUpperCase();
    final num = int.tryParse(match.group(2)!) ?? 0;
    switch (prefix) {
      case 'D':
        return '${num * 2}';
      case 'T':
        return '${num * 3}';
      default:
        return '$num';
    }
  }

  // ─── Treasure Map area ────────────────────────────────────────────────────────

  Widget _buildTreasureMapArea(
      TreasureDivideProvider provider, TreasureDivideGame game) {
    return TreasureMapWidget(
      key: TreasureDivideGameKeys.treasureMap,
      targetSequence: game.targetSequence,
      currentRoundIndex: game.currentRoundIndex,
      numberOfRounds: game.numberOfRounds,
      chestImagePath: _getChestImagePath(game),
      floaterText: null, // Phase 5 will wire up "+XX" floater text
      customTargetsEnabled: game.customTargetsEnabled,
      quarterItEnabled: game.quarterItEnabled,
      quarterItBadgeKey: TreasureDivideGameKeys.quarterItBadge,
      // Layout-editor wiring — only effective when the emulator is on
      // and the user has tapped the Edit Targets toggle. The widget
      // falls back to the canonical constants when the override is
      // null or its length doesn't match the round count.
      coordsOverride: _islandCoordsOverride,
      editMode: _layoutEditMode,
      onIslandDragged: _onIslandDragged,
    );
  }

  String _getChestImagePath(TreasureDivideGame game) {
    // Show halved chest if the active player got 0 gold this round.
    final currentPlayerId = game.currentPlayerId;
    final roundScore =
        game.playerRoundScores[currentPlayerId]?[game.currentRoundIndex];
    if (roundScore != null && roundScore == 0 && game.dartsThrown == 0) {
      // Turn just ended with 0 haul — show halved chest
      return 'assets/games/treasure_divide/pieces/TreasureChestHalved.png';
    }
    return 'assets/games/treasure_divide/pieces/TreasureChestFull.png';
  }

  // ─── Bottom strip of opponent tiles (Solo & Team) ────────────────────────────

  /// Renders every opponent (Solo: other players; Team: other crews) in a
  /// single horizontal row. Each tile is sized as if there were 7
  /// opponents (8-player Solo max), so with fewer opponents the strip
  /// leaves empty space on the right rather than stretching the tiles.
  Widget _buildOpponentsBottomStrip(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    List<String> opponentIds,
    bool isTeam,
  ) {
    return SizedBox(
      height: _kBottomStripHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Solo: footprint per tile slot = stripWidth / 7 (max 7
          // opponents in 8-player solo). Team: stripWidth / 4 so the
          // ≤4 opponent crews fill the strip edge-to-edge. Each tile
          // carries an EdgeInsets.all(3) margin (6px total horizontal),
          // so the container width = footprint − 6.
          final baseline = isTeam
              ? _kTeamOpponentTileBaseline
              : _kOpponentTileBaseline;
          final tileWidth =
              (constraints.maxWidth / baseline) - 6;
          final teamCrests = isTeam ? game.teamCrestPaths : const <String>[];
          final teamIdList =
              isTeam ? game.teamPlayers.keys.toList() : const <String>[];
          return Row(
            children: [
              for (final id in opponentIds)
                isTeam
                    ? _buildTeamOpponentTile(
                        provider,
                        game,
                        playerProvider,
                        id,
                        teamCrests,
                        teamIdList,
                        tileWidth: tileWidth,
                      )
                    : _buildSoloOpponentTile(
                        provider,
                        game,
                        playerProvider,
                        id,
                        tileWidth: tileWidth,
                      ),
            ],
          );
        },
      ),
    );
  }

  // ─── Solo opponent tiles ──────────────────────────────────────────────────────

  Widget _buildSoloOpponentTile(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    String playerId, {
    required double tileWidth,
  }) {
    final player = playerProvider.getPlayerById(playerId);
    if (player == null) return const SizedBox();

    final treasure = game.totalForPlayer(playerId);
    final timesHalved = game.timesHalvedPerPlayer[playerId] ?? 0;
    // Show the opponent's most recent COMMITTED round score, not just
    // the current round's. After a round transitions, the player who
    // just finished has playerRoundScores[id][currentRoundIndex] = null
    // (they haven't thrown the new round yet); falling back to the
    // last non-null score keeps the "+N" pill visible until they
    // throw their next dart of the new round. Active player display
    // uses the live in-progress haul, handled separately.
    int? roundScore;
    final scores = game.playerRoundScores[playerId];
    if (scores != null) {
      for (int i = game.currentRoundIndex; i >= 0; i--) {
        if (i < scores.length && scores[i] != null) {
          roundScore = scores[i];
          break;
        }
      }
    }

    return Container(
      key: TreasureDivideGameKeys.playerTile(playerId),
      // Margin + padding aggressively trimmed (vs 6 / (12,10) previously)
      // so the bulk of the strip height goes to the visible content.
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.center,
      constraints: BoxConstraints(minWidth: tileWidth, maxWidth: tileWidth),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: _plankBrown.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PirateAvatarWidget(
            player: player,
            themeIndex: _themePreviewOverride ??
                game.playerPirateThemes[playerId] ??
                0,
            // Avatar at 120 to keep opponent tiles at the size set
            // when the strip was shrunk to 220 — the larger active-
            // player tile fonts/dart indicators must not bleed
            // downward into the opponent strip; that's handled by
            // trimming active-panel padding, not by shrinking these
            // tiles further. Hat / accessory overflow still paints
            // outside the box (PirateAvatarWidget uses Clip.none
            // internally).
            size: 120,
            isActive: playerId == game.currentPlayerId,
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            style: GoogleFonts.pirataOne(
              fontSize: 22,
              color: _sailWhite,
              shadows: _treasureTextShadows,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Gold total + most-recent round contribution on a single
          // line — "200 gold (+78)" or "200 gold (–)". Collapsing the
          // standalone "+N" row into this line eliminates the bottom-
          // overflow case when both halved and round-score conditional
          // rows wanted to render at once. The round-score span is
          // omitted entirely when the player hasn't committed a round
          // yet so the very first turn renders as just "0 gold".
          Text.rich(
            key: TreasureDivideGameKeys.roundStatus(playerId),
            TextSpan(
              children: [
                TextSpan(
                  text: '$treasure gold',
                  style: GoogleFonts.pirataOne(
                    fontSize: 22,
                    color: _treasureGold,
                    fontWeight: FontWeight.bold,
                    shadows: _treasureTextShadows,
                  ),
                ),
                if (roundScore != null)
                  TextSpan(
                    text:
                        roundScore > 0 ? '  (+$roundScore)' : '  (–)',
                    style: GoogleFonts.pirataOne(
                      fontSize: 22,
                      // Always white + signature shadow effect — even
                      // on the all-miss "(–)" state. The previous
                      // blood-red zero had poor contrast against the
                      // ocean-teal tile background; the dash glyph
                      // alone is enough to signal "nothing scored".
                      color: _sailWhite,
                      shadows: _treasureTextShadows,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          // Halving indicator — surfaces the historical penalty (each
          // all-miss turn halves or quarters the player's gold).
          // Rendered as "Halved N times" / "Quartered N times" instead
          // of the prior cramped "÷N×M" shorthand. Coral-orange
          // (warm warning hue) stands out against the ocean-teal tile
          // background without competing with the treasure-gold total
          // above or the blood-red used on the dart indicators.
          if (timesHalved > 0)
            Text(
              '${game.quarterItEnabled ? "Quartered" : "Halved"} '
              '$timesHalved ${timesHalved == 1 ? "time" : "times"}',
              style: GoogleFonts.merriweather(
                fontSize: 16,
                color: const Color(0xFFFF8C42), // warm coral / amber
                shadows: _treasureTextShadows,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // ─── Team opponent tiles ──────────────────────────────────────────────────────

  Widget _buildTeamOpponentTile(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    String teamId,
    List<String> crests,
    List<String> teamIdList, {
    required double tileWidth,
  }) {
    final treasure = game.totalForTeam(teamId);
    final timesHalved = game.timesHalvedPerTeam[teamId] ?? 0;
    final crestIdx = teamIdList.indexOf(teamId);
    final crestPath =
        (crestIdx >= 0 && crestIdx < crests.length) ? crests[crestIdx] : null;
    final members = game.teamPlayers[teamId] ?? [];

    // Text overlay column — used twice: once as an invisible size
    // placeholder in the base layer (so the avatar row sits below
    // it) and once as the visible top layer (so pirate hats from
    // the avatar row that extend upward can't hide the crest/gold).
    //
    // Layout: [crest][gold + halved stacked in a Column]. Putting the
    // Halved/Quartered tally directly UNDER the gold count (instead
    // of on its own row spanning the full width beneath the crest)
    // keeps the whole text block roughly the crest's height and
    // stops the tile from overflowing the 235px strip when the
    // halved indicator is visible.
    Widget textColumn() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (crestPath != null) ...[
              SizedBox(
                key: TreasureDivideGameKeys.crewCrest(teamId),
                width: 75,
                height: 75,
                child: Image(
                  image: ResizeImage(
                    AssetImage(crestPath),
                    width: 256,
                    height: 256,
                  ),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.shield, color: _treasureGold, size: 56),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$treasure gold',
                    key: TreasureDivideGameKeys.crewTreasureScore(teamId),
                    style: GoogleFonts.merriweather(
                      fontSize: 30,
                      color: _treasureGold,
                      fontWeight: FontWeight.bold,
                      shadows: _treasureTextShadows,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (timesHalved > 0)
                    Text(
                      key: TreasureDivideGameKeys.crewRoundStatus(teamId),
                      '${game.quarterItEnabled ? "Quartered" : "Halved"} '
                      '$timesHalved ${timesHalved == 1 ? "time" : "times"}',
                      style: GoogleFonts.merriweather(
                        fontSize: 14,
                        color: const Color(0xFFFF8C42),
                        shadows: _treasureTextShadows,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        );

    return Container(
      key: TreasureDivideGameKeys.crewTile(teamId),
      margin: const EdgeInsets.all(3),
      // Vertical padding trimmed 6 → 2 so the reclaimed space can go
      // into the enlarged 104px avatars. Container alignment moved
      // from `center` to `topCenter` so the tile content anchors to
      // the top edge — this is what pulls the badge + gold count up
      // (previously the auto-centering wrapped ~23px of empty space
      // above them).
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      alignment: Alignment.topCenter,
      constraints: BoxConstraints(minWidth: tileWidth, maxWidth: tileWidth),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: _plankBrown.withOpacity(0.5), width: 2),
      ),
      // Stack ensures the crest+gold+halved text always paints in
      // front of the pirate-hat / accessory overhang from the
      // avatars below. The base layer uses a Visibility placeholder
      // to reserve the exact vertical footprint of the text block,
      // then paints the real avatar row underneath; the overlay
      // paints the text a second time, this time visibly, on top.
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Base layer.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: textColumn(),
              ),
              // Spacer between the text block and the avatar row —
              // bumped 6 → 26 so the avatars sit ~20% of the avatar
              // size lower down the tile without touching the crest
              // + gold overlay above.
              const SizedBox(height: 26),
              // Themed avatars — names removed, avatars +15% (90 → 104).
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (final pid in members)
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Builder(builder: (context) {
                          final memberPlayer =
                              playerProvider.getPlayerById(pid);
                          if (memberPlayer == null) {
                            return const SizedBox(width: 104, height: 104);
                          }
                          return Center(
                            child: SizedBox(
                              width: 104,
                              height: 104,
                              child: PirateAvatarWidget(
                                player: memberPlayer,
                                themeIndex: _themePreviewOverride ??
                                    game.playerPirateThemes[pid] ??
                                    0,
                                size: 104,
                                isActive: false,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Overlay — visible text painted last so hats/theme layers
          // from the avatars can't cover the crest or gold count.
          // Padded 10px from the tile top so the badge + gold sit a
          // bit lower without moving the avatars below (the base
          // column's Visibility placeholder + SizedBox stay the same
          // size, so the avatar row keeps its position).
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: textColumn(),
          ),
        ],
      ),
    );
  }
}
