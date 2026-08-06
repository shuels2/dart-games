import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/test_keys.dart';
import '../../../models/tiki_golf_game.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/tiki_golf_provider.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/play_to_complete/tiki_golf_strategy.dart';
import '../../../services/play_to_tie/tiki_golf_strategy.dart';
import '../../../widgets/dartboard_emulator/play_to_tie_runner.dart';
import '../../../services/save_game_service.dart';
import '../../../services/tiki_golf_announcement_helper.dart';
import '../../../services/tiki_golf_sound_effects.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/edit_score/edit_score.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/auto_save_on_pause.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import 'tiki_golf_results_screen.dart';

// ─── Color palette ────────────────────────────────────────────────────────────
const Color _lagoonBlue = Color(0xFF00B4D8);
const Color _palmGreen = Color(0xFF2D6A4F);
const Color _tikiBrown = Color(0xFF8B5E3C);
const Color _hibiscusPink = Color(0xFFFF69B4);
const Color _sandWhite = Color(0xFFFFF5E1);
const Color _tropicalOrange = Color(0xFFFF8C42); // substitution — NOT 0xFFFF6B35

// 4-corner outline text shadow in Tiki Brown (matches menu + results AppBar
// titles).
List<Shadow> _outlineShadow() => const [
      Shadow(color: _tikiBrown, offset: Offset(1, 1), blurRadius: 0),
      Shadow(color: _tikiBrown, offset: Offset(-1, -1), blurRadius: 0),
      Shadow(color: _tikiBrown, offset: Offset(1, -1), blurRadius: 0),
      Shadow(color: _tikiBrown, offset: Offset(-1, 1), blurRadius: 0),
    ];

// Heavy 8-direction stroke outline for dart-slot labels (HIT / MISS) so the
// text reads clearly against the same-hue tinted slot backgrounds.
List<Shadow> _heavyOutline(Color stroke) => [
      // Cardinal 2px offsets
      Shadow(color: stroke, offset: const Offset(2, 0), blurRadius: 0),
      Shadow(color: stroke, offset: const Offset(-2, 0), blurRadius: 0),
      Shadow(color: stroke, offset: const Offset(0, 2), blurRadius: 0),
      Shadow(color: stroke, offset: const Offset(0, -2), blurRadius: 0),
      // Diagonal 2px offsets
      Shadow(color: stroke, offset: const Offset(2, 2), blurRadius: 0),
      Shadow(color: stroke, offset: const Offset(-2, -2), blurRadius: 0),
      Shadow(color: stroke, offset: const Offset(2, -2), blurRadius: 0),
      Shadow(color: stroke, offset: const Offset(-2, 2), blurRadius: 0),
      // Soft drop shadow for a bit of depth
      Shadow(color: Colors.black.withOpacity(0.45), offset: const Offset(0, 2), blurRadius: 3),
    ];

// Hole names matching holeImagePaths canonical order
const List<String> _kHoleNames = [
  'Volcano',
  'Waterfall',
  'Tiki Statue',
  'Palm Tree',
  'Lagoon',
  'Shipwreck',
  'Bamboo Temple',
  'Coral Reef',
  'Sunset Pier',
];

const List<String> _kHoleImagePaths = [
  'assets/games/tiki_golf/pieces/Volcano.png',
  'assets/games/tiki_golf/pieces/Waterfall.png',
  'assets/games/tiki_golf/pieces/TikiStatue.png',
  'assets/games/tiki_golf/pieces/PalmTree.png',
  'assets/games/tiki_golf/pieces/Lagoon.png',
  'assets/games/tiki_golf/pieces/Shipwreck.png',
  'assets/games/tiki_golf/pieces/BambooTemple.png',
  'assets/games/tiki_golf/pieces/CoralReef.png',
  'assets/games/tiki_golf/pieces/SunsetPier.png',
];

/// Returns the canonical hole name for a given image path.
String _holeNameFromPath(String imagePath) {
  final index = _kHoleImagePaths.indexOf(imagePath);
  if (index >= 0 && index < _kHoleNames.length) return _kHoleNames[index];
  return 'Hole';
}

// ─────────────────────────────────────────────────────────────────────────────

class TikiGolfGameScreen extends StatefulWidget {
  const TikiGolfGameScreen({super.key});

  @override
  State<TikiGolfGameScreen> createState() => _TikiGolfGameScreenState();
}

class _TikiGolfGameScreenState extends State<TikiGolfGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();

  PlayToCompleteRunner? _playToCompleteRunner;
  PlayToTieRunner? _playToTieRunner;
  bool _gameCompleted = false;
  bool _showSaveModal = false;

  // Raw dart-segment strings (e.g. 'S20', 'T14', 'Bull', 'Miss') for the
  // CURRENT player's CURRENT turn. Feeds Edit Score so the dialog opens with
  // the player's actual throws instead of placeholder 'Miss' entries.
  // Cleared on turn transitions (takeout finished, mulligan used, skip turn).
  final List<String> _currentTurnSegments = [];

  // ─── Announcement helper ──────────────────────────────────────────────────────
  TikiGolfAnnouncementHelper? _audioQueue;

  // Cached state for mulligan-reminder transition detection
  bool _lastShowMulliganModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGame());
  }

  Future<void> _initializeGame() async {
    if (!mounted) return;
    final dartboardProvider = context.read<DartboardProvider>();
    _mockApi = dartboardProvider.apiService;
    if (mounted) setState(() {});

    // Subscribe to dartboard events (works for both WebSocket and emulator)
    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen(_handleDartboardEvent);
    }

    // ── Announcement helper ───────────────────────────────────────────────────
    final queueService = GameAnnouncementQueueService();
    await queueService.loadSettings(preloadEffects: TikiGolfSoundEffects.all);
    _audioQueue = TikiGolfAnnouncementHelper(queueService);

    if (!mounted) return;

    // Game start announcement
    _audioQueue?.announceGameStart();

    // First player turn announcement (delayed so game start audio plays first)
    final provider = context.read<TikiGolfProvider>();
    final firstPlayerId = provider.currentGame?.activePlayerId;
    final firstPlayerName = firstPlayerId != null
        ? context.read<PlayerProvider>().byId(firstPlayerId)?.name ?? firstPlayerId
        : null;
    if (firstPlayerName != null) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) _audioQueue?.announcePlayerTurn(firstPlayerName);
      });
    }
  }

  @override
  void dispose() {
    _playToCompleteRunner?.dispose();
    _playToTieRunner?.dispose();
    _dartboardSubscription?.cancel();
    _dartboardEmulatorController.dispose();
    _audioQueue?.dispose(); // line ~152 — dispose announcement helper
    super.dispose();
  }

  // ─── Play-to-Complete ────────────────────────────────────────────────────────

  void _onPlayToComplete() {
    if (_mockApi == null) return;
    _dartboardEmulatorController.setAutoPlaying(true);
    _dartboardEmulatorController.hide();

    _playToCompleteRunner = PlayToCompleteRunner(
      strategy: TikiGolfStrategy(),
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

  void _onCancelAutoPlay() {
    _playToCompleteRunner?.cancel();
    _playToTieRunner?.cancel();
    _dartboardEmulatorController.setAutoPlaying(false);
    _dartboardEmulatorController.show();
  }

  void _onPlayToTie() {
    if (_mockApi == null) return;
    _dartboardEmulatorController.setAutoPlaying(true);
    _dartboardEmulatorController.hide();

    _playToTieRunner = PlayToTieRunner(
      strategy: TikiGolfTieStrategy(),
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

  // ─── Dartboard event routing ─────────────────────────────────────────────────

  void _handleDartboardEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'throw_detected') {
      _handleDartThrow(event);
    } else if (type == 'takeout_finished') {
      _handleTakeoutFinished();
    }
  }

  void _handleDartThrow(Map<String, dynamic> event) {
    if (!mounted) return;
    final provider = context.read<TikiGolfProvider>();
    if (!provider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;
    final score = throwData['score'] as int? ?? 0;

    // Track the raw segment string for Edit Score (real throws, not 'Miss'
    // placeholders). Provider doesn't persist per-dart segments today. Scolia
    // reports misses as 'None'; the shared Edit Score dialog only understands
    // 'Miss', so normalize at the write site.
    _currentTurnSegments.add(sector == 'None' ? 'Miss' : sector);

    provider.processDartThrow(sector: sector, score: score);

    // ── Per-dart announcement (auto-play guard) ───────────────────────────────
    if (!_dartboardEmulatorController.isAutoPlaying) { // auto-play guard line
      final game = provider.currentGame;
      if (game != null) {
        _fireDartAnnouncement(game, provider);
      }
    }

    // Schedule takeout-started signal for emulator section transition
    if (!_dartboardEmulatorController.isAutoPlaying) {
      final game = provider.currentGame;
      if (game != null && game.currentTurnEnded) {
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (mounted) _mockApi?.simulateTakeoutStarted();
        });
      }
    }

    setState(() {});
  }

  /// Computes fact flags from current game state and fires the single
  /// highest-priority moment announcement via the precedence chain.
  /// Also fires Remove Darts UNCONDITIONALLY when the turn ended.
  void _fireDartAnnouncement(TikiGolfGame game, TikiGolfProvider provider) {
    final throwerId = game.activePlayerId;
    if (throwerId == null) return;

    final holeIndex = game.currentHole - 1;
    final dartsThrown = game.dartsThrown[throwerId] ?? 0;
    final holeScore = game.playerHoleScores[throwerId]?[holeIndex];
    final currentTurnEnded = game.currentTurnEnded;
    final hasWinner = game.hasWinner;

    // ── Compute fact flags ──────────────────────────────────────────────────
    final victory = false; // Victory deferred to _handleGameWon (after takeout)

    // holeComplete: turn-end AND every player has scored this hole AND we
    // still have holes left. Without the isAtFinalHole guard, the last
    // dart on hole 9 announces "On to hole 10!" (there is no hole 10) —
    // the provider correctly caps currentHole and calls _endGame(), but
    // the announcer's pickAndAnnounceMoment saw currentTurnEnded &&
    // isCurrentHoleComplete && !hasWinner (winner is only set inside
    // confirmTurnEnd, which runs AFTER this method) and fired the
    // hole-transition line. Gating on !isAtFinalHole lets rank 5 (score)
    // announce on the final hole's last dart instead, and _handleGameWon
    // then fires the victory line after takeout.
    final holeComplete = currentTurnEnded &&
        !hasWinner &&
        game.isCurrentHoleComplete &&
        !game.isAtFinalHole;

    final mulliganAlreadyUsed =
        (game.playerMulligansUsed[throwerId] ?? 0) == 1;
    final wasSplash =
        holeScore != null && holeScore == game.maxStrokes + 1;
    final mulliganReminder = currentTurnEnded &&
        wasSplash &&
        game.mulliganEnabled &&
        !mulliganAlreadyUsed &&
        !holeComplete;

    String? scoreLabel;
    if (currentTurnEnded && holeScore != null) {
      // Splash (never hit) takes priority over the bogey-flavor buckets so
      // that holeScore == maxStrokes+1 always announces Splash regardless of
      // which numeric stroke that lands on.
      if (holeScore == game.maxStrokes + 1) {
        scoreLabel = 'splash';
      } else if (holeScore == 1) {
        scoreLabel = 'birdie';
      } else if (holeScore == 2) {
        scoreLabel = 'par';
      } else if (holeScore == 3) {
        scoreLabel = 'bogey';
      } else if (holeScore == 4) {
        scoreLabel = 'doubleBogey';
      } else if (holeScore == 5) {
        scoreLabel = 'tripleBogey';
      } else if (holeScore == 6) {
        scoreLabel = 'quadrupleBogey';
      }
    }

    // almostThere: fire only after dart 1 missed, when the next dart can
    // still land Par (holeScore == 2). dartsThrown == 1 → player has thrown
    // 1 dart, dart 2 is next. Past that falls through to the `miss` handler.
    final almostThere = !currentTurnEnded &&
        dartsThrown == 1 &&
        holeScore == null;

    // miss: mid-turn non-hit that does not end the turn and is not penultimate
    final miss = !currentTurnEnded && holeScore == null && !almostThere;

    // Player display name
    final playerName = context.read<PlayerProvider>().byId(throwerId)?.name ??
        throwerId;

    // Winner names (solo or team). List — supports ties. See
    // TikiGolfAnnouncementHelper.announceVictory for the 1/2/3+ phrasing.
    // The victory branch is currently dead code here (victory is always
    // false at this call site — _handleGameWon owns the actual victory
    // announcement post-takeout) but resolving the list keeps the
    // pickAndAnnounceMoment contract honest for any future call site
    // that wires victory=true here directly.
    List<String>? winnerNames;
    if (victory) {
      winnerNames = _resolveWinnerNames(game);
    }

    // ── Fire moment announcement (precedence chain) ─────────────────────────
    _audioQueue?.pickAndAnnounceMoment(
      victory: victory,
      victoryWinnerNames: winnerNames,
      holeComplete: holeComplete,
      holeCompleteNextHole: holeComplete ? game.currentHole + 1 : null,
      mulliganReminder: mulliganReminder,
      mulliganReminderPlayerName: mulliganReminder ? playerName : null,
      score: scoreLabel,
      scorePlayerName: scoreLabel != null ? playerName : null,
      almostThere: almostThere,
      almostTherePlayerName: almostThere ? playerName : null,
      miss: miss,
    );

    // ── Remove Darts: on turn-end, EXCEPT when the splash+mulligan modal is
    //    about to appear. In that case the player must first pick Use
    //    Mulligan (→ "Mulligan! Remove your darts and try again") or Next
    //    Player (→ standard remove-darts fired from the button handler).
    //    Firing the generic remove-darts line here would race with the
    //    modal and confuse the player into skipping the mulligan choice.
    if (currentTurnEnded && !mulliganReminder) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _audioQueue?.announceRemoveDarts(playerName);
      });
    }
  }

  // ─── Takeout / turn-advance ──────────────────────────────────────────────────

  void _handleTakeoutFinished() {
    final provider = context.read<TikiGolfProvider>();
    if (!mounted) return;

    if (provider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!provider.isGameActive) return;

    final prevHole = provider.currentGame?.currentHole ?? 1;

    provider.confirmTurnEnd();
    // Previous player's turn has ended — clear tracked segments so the next
    // turn starts fresh.
    _currentTurnSegments.clear();

    // After confirmTurnEnd, check hasWinner AGAIN — unlike most games where
    // the winning dart sets hasWinner directly, in Tiki Golf the win is only
    // detected when the last player completes hole 9 (which happens inside
    // confirmTurnEnd → _advanceToNextHole → _endGame). Without this recheck,
    // the navigation to results never fires.
    if (provider.hasWinner) {
      _handleGameWon();
      return;
    }

    setState(() {});

    // ── Post-takeout announcements (auto-play guard) ─────────────────────────
    if (_dartboardEmulatorController.isAutoPlaying) return;

    final game = provider.currentGame;
    if (game == null) return;

    final newPlayerId = game.activePlayerId;
    if (newPlayerId == null) return;

    final newPlayerName =
        context.read<PlayerProvider>().byId(newPlayerId)?.name ?? newPlayerId;
    final newHole = game.currentHole;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (newHole != prevHole) {
        // Hole changed: announce New Hole
        final targetNumber = game.holeTargets[newHole - 1];
        _audioQueue?.announceNewHole(newHole, targetNumber);

        // Near Win: start of final hole when leader has a notable lead
        if (newHole == 9) {
          _maybeAnnounceNearWin(game);
        }
      } else {
        // Same hole: announce Player Turn
        _audioQueue?.announcePlayerTurn(newPlayerName);
      }
    });
  }

  /// Fires a Near Win announcement if one player is notably ahead on hole 9.
  void _maybeAnnounceNearWin(TikiGolfGame game) {
    if (game.gameMode == TikiGolfGameMode.solo) {
      final totals = {
        for (final pid in game.playerIds)
          pid: game.totalForPlayer(pid),
      };
      if (totals.length < 2) return;
      final sorted = totals.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final leader = sorted.first;
      final runnerUp = sorted[1];
      final leadBy = runnerUp.value - leader.value;
      if (leadBy >= 3) {
        // Significant lead — announce Near Win
        final leaderName =
            context.read<PlayerProvider>().byId(leader.key)?.name ??
                leader.key;
        _audioQueue?.announceNearWin(leaderName, leadBy);
      }
    }
  }

  void _handleGameWon() {
    if (_gameCompleted) return;
    _gameCompleted = true;

    void navigateToResults() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TikiGolfResultsScreen()),
      );
    }

    if (_dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
    } else {
      // Fire victory announcement. Reads winnerIds / winnerTeamIds (both
      // lists populated by _determineSoloWinner / _determineTeamWinner in
      // the provider), so a solo tie or team tie announces EVERY winner
      // — not just the first. Falls back to the legacy single-winner
      // fields for older saved games loaded before the tie support was
      // added.
      final game = context.read<TikiGolfProvider>().currentGame;
      if (game != null) {
        final winnerNames = _resolveWinnerNames(game);
        if (winnerNames.isNotEmpty) {
          _audioQueue?.announceVictory(winnerNames);
        }
      }
      (_audioQueue?.whenIdle() ?? Future<void>.value())
          .timeout(const Duration(seconds: 10), onTimeout: () {})
          .then((_) {
        Future.delayed(const Duration(milliseconds: 250), navigateToResults);
      });
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final provider = context.watch<TikiGolfProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    final game = provider.currentGame;
    if (game == null) return const SizedBox.shrink();

    final activePlayerId = game.activePlayerId;
    final activeTeamId = game.activeTeamId;
    final currentTurnEnded = game.currentTurnEnded;
    final hasWinner = game.hasWinner;
    final dartsThrown = game.dartsThrown[activePlayerId] ?? 0;

    // Tiki Golf's shouldPromptTakeout: modal fires ONLY on turn-end
    // (not after a fixed dart count). See asset_paths.md turn-management rule 3.
    final shouldPromptTakeout = currentTurnEnded || hasWinner; // line 218

    // Splash+Mulligan modal variant conditions
    final currentHoleIndex = game.currentHole - 1;
    final currentHoleScore =
        game.playerHoleScores[activePlayerId]?[currentHoleIndex];
    final wasSplash = currentHoleScore == game.maxStrokes + 1;
    final mulliganAlreadyUsed =
        (game.playerMulligansUsed[activePlayerId] ?? 0) == 1;
    final showMulliganModal = currentTurnEnded &&     // line 226
        wasSplash &&
        game.mulliganEnabled &&
        !mulliganAlreadyUsed;

    // Current player name for remove-darts modal
    final currentPlayer = activePlayerId != null
        ? playerProvider.byId(activePlayerId)
        : null;
    final currentPlayerName = currentPlayer?.name ?? 'Player';

    // Has any dart been thrown across the whole game (for PopScope / back button)
    final hasDartsThrown =
        game.dartsThrown.values.any((c) => c > 0) ||
        game.totalTurns.values.any((c) => c > 0);

    return AutoSaveOnPause(
      onPaused: () {
        if (!hasDartsThrown) return;
        provider.saveGame(
          SaveGameService(),
          playerNames:
              playerProvider.allPlayers.map((p) => p.name).toList(),
          isAutoSave: true,
        );
      },
      child: PopScope(
      canPop: !hasDartsThrown || _showSaveModal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Stack(
        children: [
          // ── 1. Main Scaffold ────────────────────────────────────────────────
          Scaffold(
            appBar: AppBar(
              // 3-stop left-to-right gradient through Hibiscus Pink
              // -> Tropical Orange -> Palm Green (hibiscus -> sunset
              // -> jungle) — unified across all three Tiki Golf
              // screens.
              backgroundColor: Colors.transparent,
              foregroundColor: _sandWhite,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_hibiscusPink, _tropicalOrange, _palmGreen],
                  ),
                ),
              ),
              leading: IconButton(
                key: TikiGolfGameKeys.backButton,
                icon: const Icon(Icons.arrow_back, color: _sandWhite, size: 32),
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
                'TIKI GOLF',
                style: GoogleFonts.boogaloo(
                  fontSize: 36,
                  color: _sandWhite,
                  shadows: _outlineShadow(),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: DartboardConnectionInfo(
                    config: DartboardConnectionInfoConfig.tikiGolf(),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Background
                Positioned.fill(
                  child: Image.asset(
                    'assets/games/tiki_golf/images/TikiGolf-Background.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: _palmGreen),
                  ),
                ),
                // Palm Green overlay (0.60 opacity)
                Positioned.fill(
                  child: Container(
                    color: _palmGreen.withOpacity(0.60),
                  ),
                ),
                // Main game content
                game.gameMode == TikiGolfGameMode.solo
                    ? _buildSoloLayout(
                        game: game,
                        provider: provider,
                        playerProvider: playerProvider,
                        activePlayerId: activePlayerId,
                        activeTeamId: activeTeamId,
                        shouldPromptTakeout: shouldPromptTakeout,
                        dartsThrown: dartsThrown,
                      )
                    : _buildTeamLayout(
                        game: game,
                        provider: provider,
                        playerProvider: playerProvider,
                        activePlayerId: activePlayerId,
                        activeTeamId: activeTeamId,
                        shouldPromptTakeout: shouldPromptTakeout,
                        dartsThrown: dartsThrown,
                      ),
              ],
            ),
          ),

          // ── 2. RemoveDartsModal — BEHIND the emulator (canonical layer
          //      order per skill §907-§966). DARTS REMOVED inside the emulator
          //      section must paint on top of this overlay so the user can
          //      finish the takeout. Edit Score lives in the modal's centered
          //      card, which the emulator's bottom strip doesn't cover.
          if (shouldPromptTakeout && !showMulliganModal)
            RemoveDartsModal(
              key: TikiGolfGameKeys.removeDartsModal,
              config: RemoveDartsModalConfig.tikiGolf(),
              playerName: currentPlayerName,
              editScoreButtonKey: TikiGolfGameKeys.editScoreButton,
              onEditScore: activePlayerId != null
                  ? () {
                      final initialSegments =
                          _buildInitialSegments(game, activePlayerId);
                      showEditScoreDialog(
                        context: context,
                        playerName: currentPlayerName,
                        initialSegments: initialSegments,
                        onSubmit: (newSegments) {
                          if (activePlayerId != null) {
                            provider.editPlayerScore(
                              playerId: activePlayerId,
                              holeIndex: game.currentHole - 1,
                              newDartSegments: newSegments,
                            );
                          }
                        },
                        config: EditScoreDialogConfig.tikiGolf(),
                      );
                    }
                  : null,
            ),

          // ── 3. Dartboard Emulator Section — ABOVE RemoveDartsModal so the
          //      DARTS REMOVED button stays visible and tappable.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DartboardEmulatorSection(
              controller: _dartboardEmulatorController,
              isConnected: !dartboardProvider.isEmulator,
              shouldPromptTakeout: shouldPromptTakeout,
              dartboardKey: _dartboardKey,
              onDartThrow: (score, multiplier, baseScore, position) {
                if (_mockApi != null) {
                  _mockApi!.simulateDartThrow(
                    score: score,
                    multiplier: multiplier,
                    playerName: 'Player',
                    baseScore: baseScore,
                    widgetX: position.dx,
                    widgetY: position.dy,
                    widgetSize: 250,
                  );
                }
              },
              onRemoveDarts: () {
                _mockApi?.simulateTakeoutFinished();
              },
              config: DartboardSectionConfig.tikiGolf(),
              // Hide Play-to-Complete button during takeout so the emulator
              // doesn't overlap the RemoveDartsModal's Edit Score button.
              onPlayToComplete: (_mockApi != null && !shouldPromptTakeout)
                  ? _onPlayToComplete
                  : null,
              playToCompleteConfig: (_mockApi != null && !shouldPromptTakeout)
                  ? PlayToCompleteButtonConfig.tikiGolf()
                  : null,
              // Play to Draw — Tiki Golf can always produce a tie
              // (every player hits the hole target on dart 1 → all
              // 9 strokes → tied).
              onPlayToTie: (_mockApi != null && !shouldPromptTakeout)
                  ? _onPlayToTie
                  : null,
              playToTieConfig: (_mockApi != null && !shouldPromptTakeout)
                  ? PlayToTieButtonConfig.tikiGolf()
                  : null,
            ),
          ),

          // ── 4. Dartboard Emulator FAB ────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 16,
            child: DartboardEmulatorFAB(
              controller: _dartboardEmulatorController,
              isConnected: !dartboardProvider.isEmulator,
              config: DartboardFABConfig.tikiGolf(),
              onCancelAutoPlay: _onCancelAutoPlay,
            ),
          ),

          // ── 4b. Splash + Mulligan modal (Tiki Golf takeout variant) —
          //       ABOVE the emulator section. This modal does NOT rely on
          //       DARTS REMOVED: its own USE MULLIGAN / NEXT PLAYER / Edit
          //       Score buttons drive the flow. It must therefore block the
          //       emulator's DARTS REMOVED so the user can't bypass the
          //       splash decision by tapping the emulator button underneath.
          if (shouldPromptTakeout && showMulliganModal)
            _buildSplashMulliganModal(
              game: game,
              provider: provider,
              playerProvider: playerProvider,
              activePlayerId: activePlayerId!,
              currentPlayerName: currentPlayerName,
            ),

          // ── 5. Save Game Modal ───────────────────────────────────────────────
          if (_showSaveModal)
            SaveGameModal(
              key: TikiGolfGameKeys.saveGameModal,
              config: SaveGameModalConfig.tikiGolf(),
              onSave: () async {
                final nav = Navigator.of(context);
                final allPlayers = playerProvider.allPlayers;
                await provider.saveGame(
                  SaveGameService(),
                  playerNames:
                      allPlayers.map((p) => p.name).toList(),
                );
                if (mounted) nav.pop();
              },
              onDontSave: () => Navigator.of(context).pop(),
            ),

          // ── 6. Dartboard Paused Modal (last child) ──────────────────────────
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status != DartboardConnectionStatus.connected &&
              dartboardProvider.status != DartboardConnectionStatus.emulator)
            DartboardPausedModal(
              config: DartboardPausedModalConfig.tikiGolf(),
            ),
        ],
      ),
      ),
    );
  }

  // ─── Solo layout ─────────────────────────────────────────────────────────────

  Widget _buildSoloLayout({
    required TikiGolfGame game,
    required TikiGolfProvider provider,
    required PlayerProvider playerProvider,
    required String? activePlayerId,
    required String? activeTeamId,
    required bool shouldPromptTakeout,
    required int dartsThrown,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hole info row
          _buildHoleInfoRow(game),
          const SizedBox(height: 16),
          // Hole image row (main + neighbor previews)
          _buildHoleImageRow(game),
          const SizedBox(height: 16),
          // Above the scorecard: Par + dart slots on the left, Skip Turn
          // button on the right edge (lined up with the scorecard's right
          // edge — the scorecard below fills the same horizontal extent).
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDartRow(
                game: game,
                provider: provider,
                activePlayerId: activePlayerId,
                shouldPromptTakeout: shouldPromptTakeout,
                dartsThrown: dartsThrown,
              ),
              const Spacer(),
              _buildSkipTurnButton(
                game: game,
                provider: provider,
                shouldPromptTakeout: shouldPromptTakeout,
                dartsThrown: dartsThrown,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Scorecard (all players) — full width below the dart/skip row
          Expanded(
            child: SingleChildScrollView(
              child: _buildScorecard(
                game: game,
                playerProvider: playerProvider,
                displayPlayerIds: game.playerIds,
                activePlayerId: activePlayerId,
                caption: null,
              ),
            ),
          ),
          // The emulator overlays the bottom via Positioned in the outer Stack;
          // do NOT reserve inline space here (skill Rule §36).
        ],
      ),
    );
  }

  // ─── Team layout ──────────────────────────────────────────────────────────────

  Widget _buildTeamLayout({
    required TikiGolfGame game,
    required TikiGolfProvider provider,
    required PlayerProvider playerProvider,
    required String? activePlayerId,
    required String? activeTeamId,
    required bool shouldPromptTakeout,
    required int dartsThrown,
  }) {
    final teamIds = game.teamPlayers.keys.toList();
    // Team scorecard shows ONLY the current team's players (per skill Rule §50)
    final currentTeamPlayers = activeTeamId != null
        ? (game.teamPlayers[activeTeamId] ?? [])
        : game.playerIds;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Teams panel (224px, transparent — per skill Rule §49) ──────────
        SizedBox(
          width: 224,
          child: _buildTeamsPanel(
            game: game,
            playerProvider: playerProvider,
            teamIds: teamIds,
            activeTeamId: activeTeamId,
          ),
        ),

        // ── Center content ─────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHoleInfoRow(game),
                const SizedBox(height: 16),
                _buildHoleImageRow(game),
                const SizedBox(height: 16),
                // Above the scorecard: Par + dart slots on the left, Skip
                // Turn on the right. Per-team caption removed — Teams panel
                // on the left already shows the active team.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildDartRow(
                      game: game,
                      provider: provider,
                      activePlayerId: activePlayerId,
                      shouldPromptTakeout: shouldPromptTakeout,
                      dartsThrown: dartsThrown,
                    ),
                    const Spacer(),
                    _buildSkipTurnButton(
                      game: game,
                      provider: provider,
                      shouldPromptTakeout: shouldPromptTakeout,
                      dartsThrown: dartsThrown,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildScorecard(
                      game: game,
                      playerProvider: playerProvider,
                      // Team layout — only active team's players (Rule §50)
                      displayPlayerIds: currentTeamPlayers,
                      activePlayerId: activePlayerId,
                      caption: null,
                    ),
                  ),
                ),
                // Emulator overlays bottom — no inline space (Rule §36).
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Teams panel ──────────────────────────────────────────────────────────────

  /// Transparent teams panel — no per-team backgrounds, per skill Rule §49.
  /// Shows team crest (56×56) + ± par score only. No team name text.
  Widget _buildTeamsPanel({
    required TikiGolfGame game,
    required PlayerProvider playerProvider,
    required List<String> teamIds,
    required String? activeTeamId,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final availH = constraints.maxHeight;
      final teamCount = teamIds.length;
      // Reserve ~50px for header + padding. Distribute rest among teams.
      final perTeamH = (availH - 50) / teamCount;
      final crestSize = (perTeamH * 0.72).clamp(60.0, 200.0);
      final scoreFontSize = (crestSize * 0.155).clamp(15.0, 26.0);
      final headerFontSize = (crestSize * 0.175).clamp(17.0, 28.0);
      final teamSpacing = (perTeamH * 0.04).clamp(2.0, 12.0);

      return Container(
      key: TikiGolfGameKeys.teamsPanel,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'TEAMS',
            style: GoogleFonts.boogaloo(
              fontSize: headerFontSize,
              fontWeight: FontWeight.bold,
              color: _sandWhite,
              shadows: _outlineShadow(),
            ),
          ),
          SizedBox(height: teamSpacing),
          ...teamIds.asMap().entries.map((entry) {
            final index = entry.key;
            final teamId = entry.value;
            final isActive = teamId == activeTeamId;

            // Team ± par score (real-time)
            // Count holes the TEAM has actually completed (≥1 teammate has
            // played that hole — `bestBallForTeam` returns non-null). This
            // updates immediately when the first team member finishes a hole,
            // instead of waiting until `currentHole` advances after ALL teams
            // are done.
            final teamTotal = game.totalForTeam(teamId);
            int teamCompletedHoles = 0;
            for (int h = 0; h < 9; h++) {
              if (game.bestBallForTeam(teamId, h) != null) {
                teamCompletedHoles += 1;
              }
            }
            final parScore = teamTotal - (teamCompletedHoles * 2);
            final parLabel = parScore == 0
                ? 'E'
                : parScore > 0
                    ? '+$parScore'
                    : '$parScore';
            final parColor = parScore < 0
                ? _lagoonBlue
                : parScore == 0
                    ? _sandWhite
                    : _tropicalOrange;

            // Team crest
            final crestPath = index < game.teamCrestPaths.length
                ? game.teamCrestPaths[index]
                : null;

            return Opacity(
              opacity: isActive ? 1.0 : 0.60,
              child: Container(
                key: TikiGolfGameKeys.teamBox(teamId),
                margin: EdgeInsets.only(bottom: teamSpacing),
                decoration: isActive
                    ? BoxDecoration(
                        border: const Border(
                          left: BorderSide(color: _lagoonBlue, width: 6),
                        ),
                        color: _lagoonBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                padding:
                    EdgeInsets.only(left: isActive ? 12 : 0, top: 4, bottom: 4),
                child: Column(
                  children: [
                    // Team crest — 184px (+25% from 147)
                    if (crestPath != null)
                      Image.asset(
                        crestPath,
                        width: crestSize,
                        height: crestSize,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: crestSize,
                          height: crestSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _lagoonBlue.withOpacity(0.3),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: crestSize,
                        height: crestSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lagoonBlue.withOpacity(0.3),
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Team strokes (± par) — same "strokes (diff)" format
                    // used in the scorecard Total cell. Strokes in Sand
                    // White, the (diff) suffix colored by the diff sign.
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.boogaloo(
                          fontSize: scoreFontSize,
                          fontWeight: FontWeight.bold,
                          color: _sandWhite,
                          shadows: _outlineShadow(),
                        ),
                        children: [
                          TextSpan(text: '$teamTotal'),
                          const WidgetSpan(child: SizedBox(width: 8)),
                          TextSpan(
                            text: '($parLabel)',
                            style: GoogleFonts.boogaloo(
                              fontSize: scoreFontSize,
                              fontWeight: FontWeight.bold,
                              color: parColor,
                              shadows: _outlineShadow(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
    });
  }

  // ─── Hole info row ────────────────────────────────────────────────────────────

  Widget _buildHoleInfoRow(TikiGolfGame game) {
    final holeIndex = game.currentHole - 1;
    final holeImagePath =
        holeIndex >= 0 && holeIndex < game.holeImagePaths.length
            ? game.holeImagePaths[holeIndex]
            : null;
    final holeName =
        holeImagePath != null ? _holeNameFromPath(holeImagePath) : 'Hole';
    final target =
        holeIndex >= 0 && holeIndex < game.holeTargets.length
            ? game.holeTargets[holeIndex]
            : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // "Hole X/9"
        Text(
          key: TikiGolfGameKeys.holeCounter,
          'Hole ${game.currentHole}/9',
          style: GoogleFonts.boogaloo(
            fontSize: 50,
            color: _sandWhite,
            shadows: [
              ..._heavyOutline(_tikiBrown),
              const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Hole name
        Text(
          key: TikiGolfGameKeys.holeName,
          holeName,
          style: GoogleFonts.boogaloo(
            fontSize: 50,
            color: _hibiscusPink,
            shadows: [
              ..._heavyOutline(_tikiBrown),
              const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
            ],
          ),
        ),
        const SizedBox(width: 48),
        // Target label
        Text(
          'Target: ',
          style: GoogleFonts.boogaloo(
            fontSize: 50,
            color: _sandWhite,
            shadows: [
              ..._heavyOutline(_tikiBrown),
              const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
            ],
          ),
        ),
        Text(
          key: TikiGolfGameKeys.targetNumber,
          '$target',
          style: GoogleFonts.boogaloo(
            fontSize: 50,
            color: _hibiscusPink,
            shadows: [
              ..._heavyOutline(_tikiBrown),
              const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Hole image row (main + invisible-placeholder neighbor previews) ──────────

  /// Invisible-placeholder pattern for neighbor previews (per skill Rule §55).
  /// Current hole 1 → 0 played holes → 2 invisible left placeholders.
  /// Current hole 5 → 2 played holes → 2 visible left previews.
  ///
  /// All 5 images are HEIGHT-constrained (width follows aspect ratio) so that
  /// images with different intrinsic aspect ratios all render at the same
  /// height — preventing tall portrait-ish hole images from pushing the rest
  /// of the screen layout down. The Row uses `spaceBetween` so the widths
  /// distribute naturally regardless of how wide each image ends up.
  Widget _buildHoleImageRow(TikiGolfGame game) {
    final holeIndex = game.currentHole - 1; // 0-based

    // Current hole image
    final currentPath =
        holeIndex >= 0 && holeIndex < game.holeImagePaths.length
            ? game.holeImagePaths[holeIndex]
            : null;

    // Left neighbors (inner = holeIndex-1, outer = holeIndex-2)
    final innerLeftIndex = holeIndex - 1;
    final outerLeftIndex = holeIndex - 2;
    final innerLeftPath = innerLeftIndex >= 0
        ? game.holeImagePaths[innerLeftIndex]
        : null;
    final outerLeftPath = outerLeftIndex >= 0
        ? game.holeImagePaths[outerLeftIndex]
        : null;

    // Right neighbors (inner = holeIndex+1, outer = holeIndex+2)
    final innerRightIndex = holeIndex + 1;
    final outerRightIndex = holeIndex + 2;
    final innerRightPath = innerRightIndex < 9
        ? game.holeImagePaths[innerRightIndex]
        : null;
    final outerRightPath = outerRightIndex < 9
        ? game.holeImagePaths[outerRightIndex]
        : null;

    // Target HEIGHTS at full scale. Width is intrinsic per image (driven by
    // each image's own aspect ratio) — only the height is the layout invariant.
    const double targetOuterH = 158;
    const double targetInnerH = 205;
    const double targetMainH = 450;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Allow the row to scale heights DOWN on tall-but-short viewports
        // (e.g. landscape tablets where vertical space is tight) so the image
        // row doesn't dominate the screen. Cap at 1.0 — never grow above the
        // target heights. We use available HEIGHT as the budget here since the
        // images are now height-driven.
        // Budget = the full image row gets at most ~55% of the screen height.
        final double mediaHeight = MediaQuery.of(context).size.height;
        final double heightBudget = mediaHeight * 0.55;
        final double scale =
            (heightBudget / targetMainH).clamp(0.0, 1.0);

        final double outerH = targetOuterH * scale;
        final double innerH = targetInnerH * scale;
        final double mainH = targetMainH * scale;

        // FittedBox(scaleDown) handles the case where the 5 intrinsic-width
        // images sum to more than the row's available width (happens on team-
        // mode layouts where the side panel takes ~224px). The Row uses
        // mainAxisSize.min so it reports its natural width to FittedBox, with
        // explicit 24px spacers replacing the spaceBetween distribution.
        // scaleDown is a no-op when content fits; otherwise it shrinks the
        // whole row proportionally to avoid the RenderFlex layout assertion.
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNeighborPreview(outerLeftPath, outerH),
                const SizedBox(width: 24),
                _buildNeighborPreview(innerLeftPath, innerH),
                const SizedBox(width: 24),
                // Main hole image — height-constrained, width intrinsic
                currentPath != null
                    ? Image.asset(
                        key: TikiGolfGameKeys.holeImage,
                        currentPath,
                        height: mainH,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            SizedBox(height: mainH, width: mainH),
                      )
                    : SizedBox(
                        height: mainH,
                        width: mainH,
                        key: TikiGolfGameKeys.holeImage,
                      ),
                const SizedBox(width: 24),
                _buildNeighborPreview(innerRightPath, innerH),
                const SizedBox(width: 24),
                _buildNeighborPreview(outerRightPath, outerH),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns an invisible-placeholder SizedBox when [path] is null (square
  /// shape, sized to the target height for stable row geometry); otherwise
  /// returns a faded preview image (opacity 0.70) constrained to the target
  /// height with intrinsic width.
  Widget _buildNeighborPreview(String? path, double height) {
    if (path == null) {
      // Invisible placeholder — square so the column reserves a sensible
      // amount of horizontal space whether or not the slot is populated.
      return SizedBox(width: height, height: height);
    }
    return Opacity(
      opacity: 0.70,
      child: Image.asset(
        path,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SizedBox(height: height, width: height),
      ),
    );
  }

  // ─── Dart row ────────────────────────────────────────────────────────────────

  /// Pattern B (Dart Throw Display): indicator slots show raw segment strings
  /// (S20, T14, Bull, Miss) NOT calculated point values.
  Widget _buildDartRow({
    required TikiGolfGame game,
    required TikiGolfProvider provider,
    required String? activePlayerId,
    required bool shouldPromptTakeout,
    required int dartsThrown,
  }) {
    // Collect current-turn segment strings for the active player
    // Tiki Golf tracks darts via dartsThrown count; the raw segments are
    // tracked via _dartSegmentsForTurn helper (built from event log).
    // For Pass 2, we render the slot state from dartsThrown count only
    // (segments are wired in Phase 5). Slots filled = dartsThrown.

    return Row(
      key: TikiGolfGameKeys.dartRow,
      // Compact, left-aligned — the parent Row positions us next to the
      // Skip Turn button above the scorecard.
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Par: 2" — "2" rendered in lagoon blue to match the target number
        // styling above. parLabel key lives here (moved from the title row).
        RichText(
          key: TikiGolfGameKeys.parLabel,
          text: TextSpan(children: [
            TextSpan(
              text: 'Par: ',
              style: GoogleFonts.boogaloo(
                fontSize: 28,
                color: _sandWhite,
                shadows: _outlineShadow(),
              ),
            ),
            TextSpan(
              text: '2',
              style: GoogleFonts.boogaloo(
                fontSize: 28,
                color: _lagoonBlue,
                shadows: _outlineShadow(),
              ),
            ),
            TextSpan(
              text: '  ',
              style: GoogleFonts.boogaloo(fontSize: 28),
            ),
          ]),
        ),
        // Dart indicator slots (maxStrokes, dynamic)
        ...List.generate(game.maxStrokes, (i) {
          final isFilled = i < dartsThrown;
          final isHit = isFilled && _wasTurnEndedByHit(game, activePlayerId, i);

          Color slotBg;
          Color slotBorder;
          String label;

          // Deeper-tint slot backgrounds + high-contrast Sand White text with
          // a heavy stroke outline. Same-hue text on background (the prior
          // brown-on-brown / blue-on-blue) was washing the labels out.
          Color textColor;
          Color outlineColor;
          if (!isFilled) {
            slotBg = _sandWhite.withOpacity(0.10);
            slotBorder = _sandWhite.withOpacity(0.50);
            label = '—';
            textColor = _sandWhite;
            outlineColor = _tikiBrown;
          } else if (isHit) {
            slotBg = _lagoonBlue.withOpacity(0.55); // deeper tint
            slotBorder = _lagoonBlue;
            label = 'HIT!';
            textColor = _sandWhite;
            outlineColor = const Color(0xFF0A4D5C); // deep teal — Lagoon shadow
          } else {
            slotBg = _tikiBrown.withOpacity(0.55); // deeper tint
            slotBorder = _tikiBrown;
            label = 'MISS';
            textColor = _sandWhite;
            outlineColor = const Color(0xFF3D2818); // near-black brown
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              key: TikiGolfGameKeys.dartIndicator(i),
              // Slightly larger slot to host the punchier text.
              width: 64,
              height: 44,
              decoration: BoxDecoration(
                color: slotBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: slotBorder, width: 2),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.boogaloo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1.0,
                    shadows: isFilled
                        ? _heavyOutline(outlineColor)
                        : _outlineShadow(),
                  ),
                ),
              ),
            ),
          );
        }),
        // Skip Turn button moved to the right of the scorecard.
      ],
    );
  }

  /// Heuristic to determine if the last filled slot was a hit (vs a miss).
  /// If the turn ended AND the hole score < maxStrokes+1 it was a hit.
  bool _wasTurnEndedByHit(TikiGolfGame game, String? playerId, int slotIndex) {
    if (playerId == null) return false;
    final holeIndex = game.currentHole - 1;
    final score = game.playerHoleScores[playerId]?[holeIndex];
    if (score == null) return false;
    // Slot at index slotIndex is the "hit" slot if score == slotIndex+1
    // (i.e. hit on dart slotIndex+1 means all prior darts were misses).
    return score == slotIndex + 1;
  }

  Widget _buildSkipTurnButton({
    required TikiGolfGame game,
    required TikiGolfProvider provider,
    required bool shouldPromptTakeout,
    required int dartsThrown,
  }) {
    return ElevatedButton(
      key: TikiGolfGameKeys.skipTurnButton,
      onPressed: shouldPromptTakeout
          ? null
          : () {
              provider.skipTurn();
              // Skip ends the turn — clear tracked segments.
              _currentTurnSegments.clear();
              if (dartsThrown > 0) {
                // Darts are on the board — fire takeoutStarted after delay
                Future.delayed(const Duration(milliseconds: 3500), () {
                  if (mounted) _mockApi?.simulateTakeoutStarted();
                });
              } else {
                // 0 darts on board — auto-finish takeout (no "remove darts" UX)
                Future.delayed(const Duration(milliseconds: 500), () {
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
      style: ElevatedButton.styleFrom(
        backgroundColor: _tikiBrown,
        foregroundColor: _sandWhite,
        disabledBackgroundColor: _tikiBrown.withOpacity(0.40),
        disabledForegroundColor: _sandWhite.withOpacity(0.60),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
        elevation: 2,
      ),
      child: Text(
        'SKIP TURN',
        style: GoogleFonts.boogaloo(fontSize: 17),
      ),
    );
  }

  // ─── Scorecard ────────────────────────────────────────────────────────────────

  /// Renders the scorecard. [displayPlayerIds] controls which player rows appear
  /// (all players in Solo mode; active team's players in Team mode — per Rule §50).
  Widget _buildScorecard({
    required TikiGolfGame game,
    required PlayerProvider playerProvider,
    required List<String> displayPlayerIds,
    required String? activePlayerId,
    required String? caption,
  }) {
    final maxHolesShown = 9; // always render all 9 columns
    // 130 (was 90) so the inline "strokes (diff)" Total cell content
    // (e.g. "27 (+9)") fits without wrapping or ellipsizing.
    const totalColWidth = 130.0;

    return Container(
      key: TikiGolfGameKeys.scorecard,
      decoration: BoxDecoration(
        color: _palmGreen.withOpacity(0.70),
        border: Border.all(color: _tikiBrown, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: {
          // Player column wider so longer player names fit without
          // ellipsis. Per-hole columns reduced to absorb the extra
          // space; Total column unchanged. Net table width changes by
          // only ~1px so the surrounding layout stays the same.
          0: const FixedColumnWidth(200), // Player name column (was 130)
          for (int h = 1; h <= maxHolesShown; h++)
            h: const FixedColumnWidth(42), // (was 50)
          maxHolesShown + 1: const FixedColumnWidth(totalColWidth),
        },
        border: TableBorder.all(color: _tikiBrown.withOpacity(0.40), width: 0.5),
        // Row height is driven by the player name cell (default `top`
        // alignment). Score cells individually wrap their Container in a
        // TableCell with `fill` so the current-hole borders span the
        // entire row height (fixes the "blue line through the middle of
        // the current player row"). See _scoreCell below.
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: _tikiBrown.withOpacity(0.30),
            ),
            children: [
              _headerCell('Player'),
              for (int h = 1; h <= maxHolesShown; h++) _headerCell('H$h'),
              _headerCell('Total'),
            ],
          ),
          // Player rows
          ...displayPlayerIds.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final playerId = entry.value;
            final isActive = playerId == activePlayerId;
            final isFirstRow = rowIndex == 0;
            final isLastRow = rowIndex == displayPlayerIds.length - 1;
            final player = playerProvider.byId(playerId);
            final playerName = player?.name ?? playerId;
            final scores = game.playerHoleScores[playerId] ?? [];
            final total = game.totalForPlayer(playerId);
            final holesCompleted =
                scores.where((s) => s != null).length;

            return TableRow(
              key: TikiGolfGameKeys.scorecardPlayerRow(playerId),
              decoration: BoxDecoration(
                color: isActive
                    ? _lagoonBlue.withOpacity(0.12)
                    : Colors.transparent,
              ),
              children: [
                // Player name cell
                _playerNameCell(playerName, isActive),
                // Hole score cells
                for (int h = 0; h < maxHolesShown; h++)
                  _scoreCell(
                    key: TikiGolfGameKeys.scorecardCell(playerId, h + 1),
                    score: h < scores.length ? scores[h] : null,
                    par: 2,
                    maxStrokes: game.maxStrokes,
                    isCurrent: h == game.currentHole - 1,
                    isActive: isActive,
                    isFirstRow: isFirstRow,
                    isLastRow: isLastRow,
                  ),
                // Total
                _totalCell(total: total, holesCompleted: holesCompleted),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.boogaloo(
          fontSize: 23,
          color: _sandWhite,
          shadows: _outlineShadow(),
        ),
      ),
    );
  }

  Widget _playerNameCell(String name, bool isActive) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: isActive
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: _lagoonBlue, width: 3),
              ),
            )
          : null,
      child: Text(
        name,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.boogaloo(
          fontSize: 24,
          color: isActive ? _lagoonBlue : _sandWhite,
          shadows: _outlineShadow(),
        ),
      ),
    );
  }

  /// Builds the current-hole highlight border for a single cell.
  /// Top edge only on the first player row, bottom edge only on the last —
  /// so the entire column reads as one outlined box rather than a stack of
  /// inner horizontal lines between every row.
  Border? _currentHoleBorder({
    required bool isCurrent,
    required bool isFirstRow,
    required bool isLastRow,
  }) {
    if (!isCurrent) return null;
    return Border(
      top: isFirstRow
          ? const BorderSide(color: _lagoonBlue, width: 2)
          : BorderSide.none,
      bottom: isLastRow
          ? const BorderSide(color: _lagoonBlue, width: 2)
          : BorderSide.none,
    );
  }

  Widget _scoreCell({
    required Key key,
    required int? score,
    required int par,
    required int maxStrokes,
    required bool isCurrent,
    required bool isActive,
    required bool isFirstRow,
    required bool isLastRow,
  }) {
    final border = _currentHoleBorder(
      isCurrent: isCurrent,
      isFirstRow: isFirstRow,
      isLastRow: isLastRow,
    );

    if (score == null) {
      // Not yet played — TableCell.fill so the current-hole borders span
      // the row's full height (player name cell drives the row height).
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.fill,
        child: Container(
          key: key,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(border: border),
          child: const SizedBox.shrink(),
        ),
      );
    }

    final isSplash = score == maxStrokes + 1;
    Color cellColor;
    String label;

    if (isSplash) {
      cellColor = _tropicalOrange;
      label = 'X';
    } else if (score < par) {
      // Birdie or better
      cellColor = _lagoonBlue;
      label = '$score';
    } else if (score == par) {
      cellColor = _sandWhite;
      label = '$score';
    } else {
      // Bogey
      cellColor = _hibiscusPink;
      label = '$score';
    }

    // Per-hole cells show only the stroke label (or 'X' for splash). The
    // to-par diff is shown ONLY on the Total cell, per user request.
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: Container(
        key: key,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(border: border),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.boogaloo(
            fontSize: 24,
            color: cellColor,
            shadows: _outlineShadow(),
          ),
        ),
      ),
    );
  }

  /// Golf-relative-to-par formatting helper (matches results screen).
  String _formatDiff(int diff) {
    if (diff < 0) return '−${diff.abs()}';
    if (diff > 0) return '+$diff';
    return 'E';
  }

  /// Diff color: blue under par, white at par, orange over par
  /// (matches results screen).
  Color _diffColor(int diff) {
    if (diff < 0) return _lagoonBlue;
    if (diff > 0) return _tropicalOrange;
    return _sandWhite;
  }

  Widget _totalCell({required int total, required int holesCompleted}) {
    final totalDiff = total - (holesCompleted * 2); // par=2 per hole
    const double fontSize = 22; // strokes and diff render at the same size
    if (holesCompleted == 0) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          '—',
          textAlign: TextAlign.center,
          style: GoogleFonts.boogaloo(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: _sandWhite,
            shadows: _outlineShadow(),
          ),
        ),
      );
    }
    // Inline "strokes (diff)" per user request — diff to the right of the
    // strokes at the same font size, colored by the diff sign.
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.boogaloo(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: _sandWhite,
            shadows: _outlineShadow(),
          ),
          children: [
            TextSpan(text: '$total'),
            const WidgetSpan(child: SizedBox(width: 8)),
            TextSpan(
              text: '(${_formatDiff(totalDiff)})',
              style: GoogleFonts.boogaloo(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: _diffColor(totalDiff),
                shadows: _outlineShadow(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Splash + Mulligan modal (custom inline takeout variant) ─────────────────

  /// Shown instead of the standard RemoveDartsModal when:
  ///   currentTurnEnded && wasSplash && mulliganEnabled && !mulliganAlreadyUsed
  Widget _buildSplashMulliganModal({
    required TikiGolfGame game,
    required TikiGolfProvider provider,
    required PlayerProvider playerProvider,
    required String activePlayerId,
    required String currentPlayerName,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withOpacity(0.55), // dark scrim
        child: Center(
          child: Container(
            width: 540,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _palmGreen.withOpacity(0.95),
              border: Border.all(color: _tikiBrown, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title: "SPLASH!"
                Text(
                  'SPLASH!',
                  style: GoogleFonts.boogaloo(
                    fontSize: 28,
                    color: _tropicalOrange,
                    shadows: _outlineShadow(),
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  '$currentPlayerName missed every dart',
                  style: GoogleFonts.boogaloo(
                    fontSize: 18,
                    color: _sandWhite,
                    shadows: _outlineShadow(),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Body
                Text(
                  'Use your mulligan? You have ONE per game.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: _sandWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Edit Player Score button — title case + 18pt bold +
                // 14px vertical padding to match the Use Mulligan / Next
                // Player buttons below. The shared remove-darts modal's
                // Edit Player Score button is title case too, so this
                // keeps the modal label and the regular button aligned.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: TikiGolfGameKeys.editScoreButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tikiBrown,
                      foregroundColor: _sandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final initialSegments =
                          _buildInitialSegments(game, activePlayerId);
                      showEditScoreDialog(
                        context: context,
                        playerName: currentPlayerName,
                        initialSegments: initialSegments,
                        onSubmit: (newSegments) {
                          provider.editPlayerScore(
                            playerId: activePlayerId,
                            holeIndex: game.currentHole - 1,
                            newDartSegments: newSegments,
                          );
                        },
                        config: EditScoreDialogConfig.tikiGolf(),
                      );
                    },
                    child: Text(
                      'Edit Player Score',
                      style: GoogleFonts.boogaloo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Use Mulligan button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: TikiGolfGameKeys.useMulliganButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lagoonBlue,
                      foregroundColor: _sandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Announce Mulligan Used before resetting state
                      _audioQueue?.announceMulliganUsed(currentPlayerName);
                      provider.useMulligan();
                      // Reset segment tracking — the prior turn's darts are
                      // wiped, the player re-throws from scratch.
                      _currentTurnSegments.clear();
                      // Clear the emulator's yellow dart indicators so
                      // the re-throw starts on a clean board. Emulator-
                      // mode only — real games show no indicators here.
                      // We loop removeSingleDart() instead of calling
                      // removeDarts() because the latter also fires the
                      // onRemoveDarts callback (= simulateTakeoutFinished),
                      // which would advance to the next player. Mulligan
                      // must NOT advance — the player re-throws.
                      if (_mockApi != null) {
                        final dartboardState = _dartboardKey.currentState;
                        while (dartboardState?.removeSingleDart() == true) {}
                      }
                      // currentTurnEnded becomes false → modal disappears
                      setState(() {});
                    },
                    child: Text(
                      'Use Mulligan',
                      style: GoogleFonts.boogaloo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Next Player button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: TikiGolfGameKeys.nextPlayerButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hibiscusPink,
                      foregroundColor: _sandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Fire the deferred remove-darts cue that the
                      // dispatch loop skipped while the modal was open —
                      // the player has now chosen "lock in the splash",
                      // so the standard end-of-turn instruction applies.
                      _audioQueue?.announceRemoveDarts(currentPlayerName);
                      // Record the Splash as final and advance
                      _handleTakeoutFinished();
                    },
                    child: Text(
                      'Next Player',
                      style: GoogleFonts.boogaloo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Builds the initial segment list for the Edit Score dialog using the
  /// actual segment strings tracked across the current turn (sector strings
  /// from `processDartThrow`, e.g. 'S20', 'T14', 'Bull', 'Miss'). The list
  /// is trimmed to `dartsThrown` so a stale segment doesn't leak in if the
  /// provider trimmed darts (e.g. on mulligan).
  List<String> _buildInitialSegments(TikiGolfGame game, String playerId) {
    final count = (game.dartsThrown[playerId] ?? 0).clamp(0, game.maxStrokes);
    if (_currentTurnSegments.isEmpty) {
      // No tracked segments (e.g. resumed game, edge case) — fall back to
      // 'Miss' placeholders so Edit Score still opens with the right count.
      return List.generate(count, (_) => 'Miss');
    }
    return List<String>.from(_currentTurnSegments.take(count));
  }

  /// Builds the ordered list of winner display names for the victory
  /// announcement. Prefers the plural [TikiGolfGame.winnerIds] /
  /// [TikiGolfGame.winnerTeamIds] fields (populated in every code path
  /// added with tie support) and falls back to the legacy singular
  /// [TikiGolfGame.winnerId] / [TikiGolfGame.winnerTeamId] fields for
  /// older saved games. Returns an empty list if the game has no
  /// resolved winner yet — callers should guard on isEmpty before
  /// announcing.
  List<String> _resolveWinnerNames(TikiGolfGame game) {
    final playerProvider = context.read<PlayerProvider>();
    final soloIds = (game.winnerIds != null && game.winnerIds!.isNotEmpty)
        ? game.winnerIds!
        : (game.winnerId != null ? [game.winnerId!] : const <String>[]);
    if (soloIds.isNotEmpty) {
      return [
        for (final id in soloIds) playerProvider.byId(id)?.name ?? id,
      ];
    }
    final teamIds =
        (game.winnerTeamIds != null && game.winnerTeamIds!.isNotEmpty)
            ? game.winnerTeamIds!
            : (game.winnerTeamId != null ? [game.winnerTeamId!] : const <String>[]);
    return [for (final id in teamIds) _teamDisplayName(id)];
  }

  /// Formats a team display name from its teamId (e.g. 'team_1' → 'Team 1').
  String _teamDisplayName(String? teamId) {
    if (teamId == null) return 'Team';
    // teamId is 'team_1', 'team_2', etc.
    final parts = teamId.split('_');
    if (parts.length >= 2) {
      final number = parts.last;
      return 'Team $number';
    }
    return teamId;
  }
}
