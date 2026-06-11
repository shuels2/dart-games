import 'dart:async';
import 'package:flutter/material.dart';
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

class TreasureDivideGameScreen extends StatefulWidget {
  const TreasureDivideGameScreen({Key? key}) : super(key: key);

  @override
  State<TreasureDivideGameScreen> createState() =>
      _TreasureDivideGameScreenState();
}

class _TreasureDivideGameScreenState extends State<TreasureDivideGameScreen> {
  StreamSubscription? _dartboardSubscription;
  MockScoliaApiService? _mockApi;
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();
  PlayToCompleteRunner? _playToCompleteRunner;
  PlayToTieRunner? _playToTieRunner;
  bool _showSaveModal = false;
  bool _gameCompleted = false;

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

    // Compute opponents for the left column.
    final playerIds = game.playerIds;
    final currentIdx = playerIds.indexOf(currentPlayerId);
    final opponents = <String>[];
    if (game.gameMode == TreasureDivideGameMode.solo) {
      for (int i = 1; i < playerIds.length; i++) {
        opponents.add(playerIds[(currentIdx + i) % playerIds.length]);
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
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/games/treasure_divide/images/TreasureDivide-Background.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: _oceanTeal),
                  ),
                ),
                // 65% Ocean Teal overlay (mandatory)
                Positioned.fill(
                  child: Container(
                    color: _oceanTeal.withOpacity(0.65),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLeftColumn(
                                provider, game, playerProvider, opponents),
                            Expanded(
                              child:
                                  _buildTreasureMapArea(provider, game),
                            ),
                          ],
                        ),
                      ),
                      if (_shouldShowOverflowStrip(opponents.length))
                        _buildOpponentsBottomStrip(
                            provider, game, playerProvider, opponents),
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
    final isTeam = game.gameMode == TreasureDivideGameMode.team;
    final activeTeamId = game.activeTeamId;
    final activeMembers =
        (isTeam && activeTeamId != null) ? (game.teamPlayers[activeTeamId] ?? []) : <String>[];
    final isSoloCrew = isTeam && activeMembers.length == 1;

    final badges = <Widget>[];
    if (game.quarterItEnabled) {
      badges.add(_buildBadge(
        key: TreasureDivideGameKeys.quarterItBadge,
        label: 'QUARTER IT',
        backgroundColor: _bloodRed,
        textColor: _sailWhite,
      ));
    }
    if (game.customTargetsEnabled) {
      badges.add(_buildBadge(
        key: TreasureDivideGameKeys.customBadge,
        label: 'CUSTOM',
        backgroundColor: _treasureGold,
        textColor: _oceanTeal,
      ));
    }
    if (isSoloCrew) {
      badges.add(_buildBadge(
        key: TreasureDivideGameKeys.soloCrewBadge,
        label: 'Solo Crew: 6 darts',
        backgroundColor: _plankBrown,
        textColor: _sailWhite,
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
    List<String> opponents,
  ) {
    final isTeam = game.gameMode == TreasureDivideGameMode.team;
    final maxVisibleOpponents = isTeam ? 5 : 4;
    final visibleOpponents = opponents.take(maxVisibleOpponents).toList();

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActivePlayerPanel(provider, game, playerProvider),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: isTeam
                    ? _buildTeamOpponentTiles(provider, game, playerProvider)
                    : [
                        for (final id in visibleOpponents)
                          _buildSoloOpponentTile(
                              provider, game, playerProvider, id),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    if (isTeam && activeTeamId != null) {
      displayScore = game.totalForTeam(activeTeamId);
      // Sum of hauls for current round from all team members
      int crewRound = 0;
      final members = game.teamPlayers[activeTeamId] ?? [];
      for (final pid in members) {
        crewRound += game.playerRoundScores[pid]?[game.currentRoundIndex] ?? 0;
      }
      roundScore = crewRound;
    } else {
      displayScore = game.totalForPlayer(currentPlayerId);
      roundScore =
          game.playerRoundScores[currentPlayerId]?[game.currentRoundIndex] ?? 0;
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
      constraints: const BoxConstraints(minHeight: 258, maxHeight: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(color: _treasureGold.withOpacity(0.4), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team mode: crest + crew info
          if (isTeam && activeTeamId != null) ...[
            _buildActiveCrewHeader(provider, game, playerProvider,
                activeTeamId, nextTeammateId),
            const SizedBox(height: 4),
          ],

          // Player avatar with pirate theme overlay
          SizedBox(
            key: TreasureDivideGameKeys.playerAvatar,
            width: 80,
            height: 80,
            child: currentPlayer != null
                ? PirateAvatarWidget(
                    player: currentPlayer,
                    themeIndex:
                        game.playerPirateThemes[currentPlayer.id] ?? 0,
                    size: 80,
                    isActive: true,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),

          // Player name
          Text(
            currentPlayer?.name ?? '',
            style: GoogleFonts.pirataOne(fontSize: 16, color: _treasureGold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Treasure score
          Text(
            key: TreasureDivideGameKeys.treasureScore,
            '$displayScore gold',
            style: GoogleFonts.pirataOne(fontSize: 18, color: _treasureGold),
            textAlign: TextAlign.center,
          ),

          // Round score
          Text(
            key: TreasureDivideGameKeys.roundScore,
            '+$roundScore this round',
            style: GoogleFonts.merriweather(
              fontSize: 12,
              color: roundScore > 0 ? _islandGreen : _bloodRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Dart indicators
          _buildDartIndicators(
              dartsThisTurn, dartsThrown, segments, game),
          const SizedBox(height: 6),

          // Skip Turn button
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
                            if (mounted) _audioQueue?.announceRemoveDarts();
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
                side: const BorderSide(color: _treasureGold, width: 1.5),
                foregroundColor: _treasureGold,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              child: Text(
                'Skip Turn',
                style: GoogleFonts.pirataOne(
                    fontSize: 13, color: _treasureGold),
              ),
            ),
          ),
        ],
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
    final crestPath = provider.currentTeamCrestPath;
    final crewTreasure = game.totalForTeam(teamId);
    final nextPlayer = nextTeammateId != null
        ? playerProvider.getPlayerById(nextTeammateId)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crew crest
        if (crestPath != null)
          Container(
            key: TreasureDivideGameKeys.activeCrewCrest,
            width: 40,
            height: 40,
            child: Image.asset(
              crestPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.shield,
                color: _treasureGold,
                size: 32,
              ),
            ),
          ),
        Text(
          'Crew Treasure: $crewTreasure gold',
          style: GoogleFonts.merriweather(
            fontSize: 11,
            color: _sailWhite,
          ),
          textAlign: TextAlign.center,
        ),
        if (nextPlayer != null)
          Text(
            'Next: ${nextPlayer.name}',
            style: GoogleFonts.merriweather(
              fontSize: 10,
              color: _sailWhite.withOpacity(0.75),
            ),
            textAlign: TextAlign.center,
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
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 26,
            height: 26,
            decoration: _dartIndicatorDecoration(i, dartsThrown, segments),
            child: _dartIndicatorChild(i, dartsThrown, segments, game),
          ),
      ],
    );
  }

  BoxDecoration _dartIndicatorDecoration(
      int index, int dartsThrown, List<String> segments) {
    if (index >= dartsThrown) {
      // Empty — outlined circle
      return BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _treasureGold, width: 1.5),
      );
    }
    final seg = index < segments.length ? segments[index] : '';
    final isMiss = seg == 'Miss' || seg == 'None' || seg.isEmpty;
    return BoxDecoration(
      shape: BoxShape.circle,
      color: isMiss ? _bloodRed.withOpacity(0.2) : _islandGreen.withOpacity(0.2),
      border: Border.all(
        color: isMiss ? _bloodRed : _treasureGold,
        width: 1.5,
      ),
    );
  }

  Widget? _dartIndicatorChild(
      int index, int dartsThrown, List<String> segments, TreasureDivideGame game) {
    if (index >= dartsThrown) return null;
    final seg = index < segments.length ? segments[index] : '';
    final isMiss = seg == 'Miss' || seg == 'None' || seg.isEmpty;
    if (isMiss) {
      return Center(
        child: Text(
          'X',
          style: GoogleFonts.merriweather(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _bloodRed,
          ),
        ),
      );
    }
    // Compute hit score for display
    final roundIndex = game.currentRoundIndex;
    final target = roundIndex < game.targetSequence.length
        ? game.targetSequence[roundIndex]
        : 0;
    final scoreText = _scoreTextForSeg(seg, target);
    return Center(
      child: Text(
        scoreText,
        style: GoogleFonts.merriweather(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _islandGreen,
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

  // ─── Overflow strip (Solo 5+ opponents) ──────────────────────────────────────

  bool _shouldShowOverflowStrip(int opponentCount) {
    return opponentCount > 4;
  }

  Widget _buildOpponentsBottomStrip(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    List<String> opponents,
  ) {
    final overflowOpponents = opponents.skip(4).toList();
    return Container(
      height: 64,
      color: _oceanTeal.withOpacity(0.5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final id in overflowOpponents)
            _buildSoloOpponentTile(provider, game, playerProvider, id,
                compact: true),
        ],
      ),
    );
  }

  // ─── Solo opponent tiles ──────────────────────────────────────────────────────

  Widget _buildSoloOpponentTile(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    String playerId, {
    bool compact = false,
  }) {
    final player = playerProvider.getPlayerById(playerId);
    if (player == null) return const SizedBox();

    final treasure = game.totalForPlayer(playerId);
    final timesHalved = game.timesHalvedPerPlayer[playerId] ?? 0;
    final roundScore =
        game.playerRoundScores[playerId]?[game.currentRoundIndex];

    return Container(
      key: TreasureDivideGameKeys.playerTile(playerId),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      // BoxConstraints.expand() inside a SingleChildScrollView (the
      // opponents list in _buildLeftColumn) claims infinite height and
      // fires a RenderFlex overflow on every pump. The Column below sizes
      // itself via mainAxisSize.min, so we only need a minWidth hint for
      // the compact (bottom-strip) layout.
      constraints: compact ? const BoxConstraints(minWidth: 80) : null,
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: _plankBrown.withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with pirate theme
          PirateAvatarWidget(
            player: player,
            themeIndex: game.playerPirateThemes[playerId] ?? 0,
            size: compact ? 36 : 48,
            isActive: playerId == game.currentPlayerId,
          ),
          const SizedBox(height: 2),
          Text(
            player.name,
            style: GoogleFonts.pirataOne(fontSize: 12, color: _sailWhite),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$treasure gold',
            key: TreasureDivideGameKeys.roundStatus(playerId),
            style: GoogleFonts.merriweather(
              fontSize: 11,
              color: _treasureGold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (timesHalved > 0)
            Text(
              '÷${game.quarterItEnabled ? 4 : 2}×$timesHalved',
              style: GoogleFonts.merriweather(
                fontSize: 10,
                color: _bloodRed,
              ),
              textAlign: TextAlign.center,
            ),
          if (roundScore != null)
            Text(
              roundScore > 0 ? '+$roundScore' : '–',
              style: GoogleFonts.merriweather(
                fontSize: 10,
                color: roundScore > 0 ? _islandGreen : _bloodRed,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // ─── Team opponent tiles ──────────────────────────────────────────────────────

  List<Widget> _buildTeamOpponentTiles(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
  ) {
    final teamIds = game.teamPlayers.keys.toList();
    final activeTeamId = game.activeTeamId;
    final opponentTeams =
        teamIds.where((tid) => tid != activeTeamId).toList();
    final crests = game.teamCrestPaths;
    final teamIdList = teamIds;

    return [
      for (final teamId in opponentTeams)
        _buildTeamOpponentTile(
            provider, game, playerProvider, teamId, crests, teamIdList),
    ];
  }

  Widget _buildTeamOpponentTile(
    TreasureDivideProvider provider,
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    String teamId,
    List<String> crests,
    List<String> teamIdList,
  ) {
    final treasure = game.totalForTeam(teamId);
    final timesHalved = game.timesHalvedPerTeam[teamId] ?? 0;
    final crestIdx = teamIdList.indexOf(teamId);
    final crestPath =
        (crestIdx >= 0 && crestIdx < crests.length) ? crests[crestIdx] : null;
    final members = game.teamPlayers[teamId] ?? [];

    return Container(
      key: TreasureDivideGameKeys.crewTile(teamId),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: _plankBrown.withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crew crest
          if (crestPath != null)
            Container(
              key: TreasureDivideGameKeys.crewCrest(teamId),
              width: 28,
              height: 28,
              child: Image.asset(
                crestPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.shield, color: _treasureGold, size: 22),
              ),
            ),
          // Crew treasure
          Text(
            '$treasure gold',
            key: TreasureDivideGameKeys.crewTreasureScore(teamId),
            style: GoogleFonts.merriweather(
              fontSize: 11,
              color: _treasureGold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (timesHalved > 0)
            Text(
              key: TreasureDivideGameKeys.crewRoundStatus(teamId),
              '÷${game.quarterItEnabled ? 4 : 2}×$timesHalved',
              style: GoogleFonts.merriweather(
                fontSize: 10,
                color: _bloodRed,
              ),
              textAlign: TextAlign.center,
            ),
          // Member names
          for (final pid in members)
            Text(
              playerProvider.getPlayerById(pid)?.name ?? pid,
              style: GoogleFonts.merriweather(
                fontSize: 10,
                color: _sailWhite.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
