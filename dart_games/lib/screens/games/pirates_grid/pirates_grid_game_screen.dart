import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/pirates_grid_game.dart';
import '../../../models/player.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/pirates_grid_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/pirates_grid_announcement_helper.dart';
import '../../../services/play_to_complete/pirates_grid_strategy.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator_config.dart';
import '../../../widgets/dartboard_emulator/play_to_complete_runner.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/edit_score/edit_score.dart';
import '../../../widgets/edit_score/edit_score_dialog_config.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal_config.dart';
import '../../../widgets/interactive_dartboard.dart';
import 'pirates_grid_results_screen.dart';

class PiratesGridGameScreen extends StatefulWidget {
  const PiratesGridGameScreen({super.key});

  @override
  State<PiratesGridGameScreen> createState() => _PiratesGridGameScreenState();
}

class _PiratesGridGameScreenState extends State<PiratesGridGameScreen>
    with TickerProviderStateMixin {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();

  PlayToCompleteRunner? _playToCompleteRunner;
  bool _gameCompleted = false;
  bool _showSaveModal = false;
  PiratesGridAnnouncementHelper? _audioQueue;

  // Speed Play timer
  Timer? _speedPlayTimer;
  int _speedPlaySecondsRemaining = 15;

  // Pulsing animation for timer critical state
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Palette
  static const Color _oceanNavy = Color(0xFF1B2838);
  static const Color _bloodRed = Color(0xFF8B0000);
  static const Color _treasureGold = Color(0xFFDAA520);
  static const Color _compassBronze = Color(0xFFCD7F32);
  static const Color _seaFoamTeal = Color(0xFF2E8B8B);
  static const Color _parchmentTan = Color(0xFFF5E6C8);
  static const Color _inkBlack = Color(0xFF1A1A1A);

  // P1 / P2 flag colors
  static const Color _p1FlagColor = Color(0xFF8B0000); // Blood Red
  static const Color _p2FlagColor = Color(0xFF2E8B8B); // Sea Foam Teal

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGame());
  }

  Future<void> _initializeGame() async {
    final dartboardProvider = context.read<DartboardProvider>();
    _mockApi = dartboardProvider.apiService;
    if (mounted) setState(() {});

    // Initialize announcement queue
    final globalQueue = GameAnnouncementQueueService();
    await globalQueue.loadSettings();
    _audioQueue = PiratesGridAnnouncementHelper(globalQueue);

    // Announce game start
    _audioQueue?.announceGameStart();

    // Announce first player turn after 2-second delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final provider = context.read<PiratesGridProvider>();
        final game = provider.currentGame;
        if (game != null) {
          final playerProvider = context.read<PlayerProvider>();
          final currentPlayerId = game.getCurrentPlayerId();
          final playerName = playerProvider.getPlayerById(currentPlayerId)?.name ??
              'Player ${game.currentPlayerIndex + 1}';
          if (!_dartboardEmulatorController.isAutoPlaying) {
            _audioQueue?.announcePlayerTurn(playerName);
          }
        }
      }
    });

    // Subscribe to dartboard events
    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen(_handleDartboardEvent);
    }

    // Start Speed Play timer if applicable
    final provider = context.read<PiratesGridProvider>();
    final game = provider.currentGame;
    if (game != null && game.speedPlay) {
      _startSpeedPlayTimerForCurrentPlayer(game);
    }
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    _playToCompleteRunner?.dispose();
    _dartboardSubscription?.cancel();
    _dartboardEmulatorController.dispose();
    _speedPlayTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPlayToComplete() {
    if (_mockApi == null) return;
    _dartboardEmulatorController.setAutoPlaying(true);
    _dartboardEmulatorController.hide();
    _speedPlayTimer?.cancel();

    _playToCompleteRunner = PlayToCompleteRunner(
      strategy: PiratesGridStrategy(),
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
    _dartboardEmulatorController.setAutoPlaying(false);
    _dartboardEmulatorController.show();

    // Restart timer if applicable
    final game = context.read<PiratesGridProvider>().currentGame;
    if (game != null && game.speedPlay) {
      _startSpeedPlayTimerForCurrentPlayer(game);
    }
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
    final provider = context.read<PiratesGridProvider>();
    if (!mounted || !provider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;
    final parsed = _parseSector(sector);

    final int score = parsed != null ? parsed['score'] as int : 0;
    final int multiplier = parsed != null ? parsed['multiplier'] as int : 1;
    final String processedSector = parsed != null ? sector : 'Miss';

    final playerProvider = context.read<PlayerProvider>();

    // ── Capture pre-throw state ─────────────────────────────────────────────
    final game = provider.currentGame!;
    final playerId = game.getCurrentPlayerId();
    final opponentId = game.getOpponentPlayerId(playerId);
    final playerName = playerProvider.getPlayerById(playerId)?.name ??
        'Player ${game.currentPlayerIndex + 1}';
    final opponentName = playerProvider.getPlayerById(opponentId)?.name ??
        'Player ${(game.currentPlayerIndex == 0 ? 1 : 0) + 1}';

    final beforeMatchWinner = game.matchWinnerId;
    final beforeRoundWinner = game.winnerId;
    final beforeRoundDraw = game.isDraw;
    final beforeMatchDraw = game.isMatchDraw;

    // Determine what cell the dart would hit (before processing)
    GridCell? hitCell;
    int hitRow = -1;
    int hitCol = -1;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (game.grid[r][c].target.matches(score, multiplier)) {
          hitCell = game.grid[r][c];
          hitRow = r;
          hitCol = c;
          break;
        }
      }
      if (hitCell != null) break;
    }

    final wasMatched = hitCell != null;
    final wasMatchedCellEmpty = wasMatched && hitCell!.claimedBy == null;
    final wasMatchedCellOwn = wasMatched && hitCell!.claimedBy == playerId;
    final wasMatchedCellOpponent = wasMatched && hitCell!.claimedBy == opponentId;

    // Build target label for announcements
    String cellTargetLabel = '';
    if (wasMatched && hitRow >= 0) {
      final target = game.grid[hitRow][hitCol].target;
      if (target.requirement == CellRequirement.bull) {
        cellTargetLabel = 'Bull';
      } else if (game.targetDifficulty == TargetDifficulty.hard) {
        switch (target.requirement) {
          case CellRequirement.tripleOnly:
            cellTargetLabel = 'T${target.number}';
            break;
          case CellRequirement.doubleOnly:
            cellTargetLabel = 'D${target.number}';
            break;
          default:
            cellTargetLabel = '${target.number}';
        }
      } else {
        cellTargetLabel = '${target.number}';
      }
    }

    // ── Process the dart ────────────────────────────────────────────────────
    provider.processDartThrow(
      score: score,
      multiplier: multiplier,
      sector: processedSector,
    );

    // ── Gather facts post-throw ─────────────────────────────────────────────
    final gameAfter = provider.currentGame!;
    final justWonMatch =
        beforeMatchWinner == null && gameAfter.matchWinnerId != null;
    final justWonRound = beforeRoundWinner == null &&
        gameAfter.winnerId != null &&
        !justWonMatch;
    final justDrewMatch = !beforeMatchDraw && gameAfter.isMatchDraw;
    final justDrewRound = !beforeRoundDraw &&
        gameAfter.isDraw &&
        !justWonRound &&
        !justWonMatch &&
        !justDrewMatch;
    final justPlantedFlag = wasMatched &&
        wasMatchedCellEmpty &&
        !justWonMatch &&
        !justWonRound &&
        !justDrewMatch &&
        !justDrewRound;
    final justStole = wasMatched &&
        wasMatchedCellOpponent &&
        gameAfter.stealMode &&
        !justWonMatch &&
        !justWonRound &&
        !justDrewMatch &&
        !justDrewRound;
    final justAlreadyOwn = wasMatched && wasMatchedCellOwn;
    final justAlreadyOpponent =
        wasMatched && wasMatchedCellOpponent && !gameAfter.stealMode;
    final justMissed = !wasMatched;
    final justGotTwoInARow = (justPlantedFlag || justStole) &&
        _hasTwoInARowWithEmpty(gameAfter, playerId);

    // ── Pick winner from precedence chain (skip if isAutoPlaying) ──────────
    if (!_dartboardEmulatorController.isAutoPlaying) {
      if (justWonMatch) {
        _audioQueue?.announceMatchVictory(playerName);
      } else if (justWonRound) {
        _audioQueue?.announceRoundVictory(playerName);
      } else if (justDrewMatch) {
        _audioQueue?.announceMatchDraw();
      } else if (justDrewRound) {
        _audioQueue?.announceRoundDraw();
      } else if (justGotTwoInARow) {
        _audioQueue?.announceTwoInARow(playerName);
      } else if (justPlantedFlag) {
        _audioQueue?.announceFlagPlanted(playerName, cellTargetLabel);
      } else if (justStole) {
        _audioQueue?.announceSquareStolen(playerName, opponentName);
      } else if (justAlreadyOwn) {
        _audioQueue?.announceAlreadyClaimed(isOwn: true);
      } else if (justAlreadyOpponent) {
        _audioQueue?.announceAlreadyClaimed(isOwn: false);
      } else if (justMissed) {
        _audioQueue?.announceMiss();
      }
    }

    // ── UNCONDITIONALLY announce remove darts when takeout is needed ────────
    if (provider.shouldPromptTakeout && !_dartboardEmulatorController.isAutoPlaying) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _audioQueue?.announceRemoveDarts(playerName);
      });
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) _mockApi?.simulateTakeoutStarted();
      });
    }

    setState(() {});
  }

  /// Returns true if [playerId] has exactly 2 flags in a line with
  /// the third cell still empty — i.e. a "two-in-a-row" threat.
  bool _hasTwoInARowWithEmpty(PiratesGridGame game, String playerId) {
    const lines = [
      [(0, 0), (0, 1), (0, 2)],
      [(1, 0), (1, 1), (1, 2)],
      [(2, 0), (2, 1), (2, 2)],
      [(0, 0), (1, 0), (2, 0)],
      [(0, 1), (1, 1), (2, 1)],
      [(0, 2), (1, 2), (2, 2)],
      [(0, 0), (1, 1), (2, 2)],
      [(0, 2), (1, 1), (2, 0)],
    ];
    for (final line in lines) {
      int playerCount = 0;
      int emptyCount = 0;
      for (final pos in line) {
        final claim = game.grid[pos.$1][pos.$2].claimedBy;
        if (claim == playerId) {
          playerCount++;
        } else if (claim == null) {
          emptyCount++;
        }
      }
      if (playerCount == 2 && emptyCount == 1) return true;
    }
    return false;
  }

  Map<String, dynamic>? _parseSector(String sector) {
    if (sector == 'None') return null;
    if (sector == 'Bull') return {'score': 50, 'multiplier': 1};
    if (sector == '25') return {'score': 25, 'multiplier': 1};

    final match = RegExp(r'([SDTsdt])(\d+)').firstMatch(sector);
    if (match == null) return null;

    final prefix = match.group(1)!.toUpperCase();
    final number = int.parse(match.group(2)!);
    int multiplier = 1;
    if (prefix == 'D') multiplier = 2;
    if (prefix == 'T') multiplier = 3;

    return {'score': number, 'multiplier': multiplier};
  }

  void _handleTakeoutFinished() {
    final provider = context.read<PiratesGridProvider>();
    if (!mounted) return;

    if (provider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!provider.isGameActive) return;

    // Capture round before transition
    final gameBefore = provider.currentGame;
    final roundBefore = gameBefore?.currentRound ?? 1;
    final wasRoundFinished = provider.isCurrentRoundFinished;

    provider.handleTakeoutFinished();

    // Reset Speed Play timer for next player
    final game = provider.currentGame;
    if (game != null && game.speedPlay && !_dartboardEmulatorController.isAutoPlaying) {
      _startSpeedPlayTimerForCurrentPlayer(game);
    }

    // Announce round transition or next player turn (with 500ms delay)
    if (!_dartboardEmulatorController.isAutoPlaying && game != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final newRound = game.currentRound;
        if (wasRoundFinished && newRound > roundBefore) {
          _audioQueue?.announceRoundTransition(newRound);
        }
        final playerProvider = context.read<PlayerProvider>();
        final currentPlayerId = game.getCurrentPlayerId();
        final playerName = playerProvider.getPlayerById(currentPlayerId)?.name ??
            'Player ${game.currentPlayerIndex + 1}';
        _audioQueue?.announcePlayerTurn(playerName);
      });
    }

    setState(() {});
  }

  void _handleGameWon() {
    if (_gameCompleted) return;
    _gameCompleted = true;
    _speedPlayTimer?.cancel();

    void navigateToResults() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PiratesGridResultsScreen()),
      );
    }

    if (_dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
    } else {
      final game = context.read<PiratesGridProvider>().currentGame;
      final winnerId = game?.matchWinnerId;
      final playerProvider = context.read<PlayerProvider>();
      final winnerName = playerProvider.getPlayerById(winnerId ?? '')?.name ?? '';
      _audioQueue?.announceWinner(winnerName);
      Future.delayed(const Duration(milliseconds: 3000), navigateToResults);
    }
  }

  // ─── Speed Play timer ──────────────────────────────────────────────────────

  void _startSpeedPlayTimerForCurrentPlayer(PiratesGridGame game) {
    if (!game.speedPlay) return;
    _speedPlayTimer?.cancel();
    setState(() => _speedPlaySecondsRemaining = 15);
    _speedPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _speedPlaySecondsRemaining--);

      // Timer tick sound at 5-1
      if (_speedPlaySecondsRemaining >= 1 && _speedPlaySecondsRemaining <= 5) {
        _audioQueue?.announceTimerExpired(); // plays TimerTick SFX
      }

      if (_speedPlaySecondsRemaining <= 0) {
        timer.cancel();
        _onSpeedPlayTimerExpired();
      }
    });
  }

  void _onSpeedPlayTimerExpired() {
    if (!mounted) return;
    _audioQueue?.announceTimerExpired();
    final provider = context.read<PiratesGridProvider>();
    provider.skipTurn();
    final dartsThrown = provider.getCurrentPlayerDartsThrown();
    if (dartsThrown > 0) {
      final playerProvider = context.read<PlayerProvider>();
      final game = provider.currentGame;
      final playerId = game?.getCurrentPlayerId() ?? '';
      final playerName =
          playerProvider.getPlayerById(playerId)?.name ?? 'Player';
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _audioQueue?.announceRemoveDarts(playerName);
      });
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) _mockApi?.simulateTakeoutStarted();
      });
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final provider = context.watch<PiratesGridProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    final game = provider.currentGame;
    if (game == null) {
      return const Scaffold(body: Center(child: Text('No game in progress')));
    }

    final players = game.playerIds
        .map((id) => playerProvider.getPlayerById(id))
        .whereType<Player>()
        .toList();
    final currentPlayerId = game.getCurrentPlayerId();
    final dartsThrown = provider.getCurrentPlayerDartsThrown();
    final hasDartsThrown = game.totalDartsThrown.values.any((c) => c > 0);
    final shouldPromptTakeout = provider.shouldPromptTakeout;

    // Current turn dart segments
    final currentDartSegments = provider.getCurrentTurnDartSegments(currentPlayerId);

    return PopScope(
      canPop: !hasDartsThrown || _showSaveModal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Stack(
        children: [
          // 1. Scaffold — AppBar + body content; NO floatingActionButton
          Scaffold(
            backgroundColor: _oceanNavy,
            appBar: AppBar(
              backgroundColor: _oceanNavy,
              leading: IconButton(
                key: PiratesGridGameKeys.backButton,
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
                "PIRATE'S GRID",
                style: GoogleFonts.pirataOne(
                  fontSize: 24,
                  color: _treasureGold,
                  letterSpacing: 1.5,
                ),
              ),
              actions: [
                // Skip Turn button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton(
                    key: PiratesGridGameKeys.skipTurnButton,
                    onPressed: shouldPromptTakeout
                        ? null
                        : () {
                            _speedPlayTimer?.cancel();
                            final p = context.read<PiratesGridProvider>();
                            final pp = context.read<PlayerProvider>();
                            final g = p.currentGame;
                            final pid = g?.getCurrentPlayerId() ?? '';
                            final pName =
                                pp.getPlayerById(pid)?.name ?? 'Player';
                            final darts = p.getCurrentPlayerDartsThrown();
                            p.skipTurn();
                            if (darts > 0) {
                              Future.delayed(const Duration(milliseconds: 1500), () {
                                if (mounted) _audioQueue?.announceRemoveDarts(pName);
                              });
                              Future.delayed(const Duration(milliseconds: 3500), () {
                                if (mounted) _mockApi?.simulateTakeoutStarted();
                              });
                            } else {
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _compassBronze, width: 1.5),
                      foregroundColor: _compassBronze,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      'SKIP TURN',
                      style: GoogleFonts.pirataOne(
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // D1, D2, D3 dart indicators
                ...List.generate(3, (i) {
                  final hasSegment = i < currentDartSegments.length;
                  final segment = hasSegment ? currentDartSegments[i] : null;
                  final isSkip = segment == 'Skip';
                  final isMiss = segment == 'Miss';
                  final hasScore = hasSegment && !isSkip;

                  Color slotColor;
                  String scoreLabel;
                  if (!hasSegment) {
                    slotColor = _compassBronze.withOpacity(0.5);
                    scoreLabel = '—';
                  } else if (isSkip || isMiss) {
                    slotColor = _parchmentTan.withOpacity(0.5);
                    scoreLabel = '—';
                  } else {
                    slotColor = _seaFoamTeal;
                    scoreLabel = segment ?? '—';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Container(
                      key: PiratesGridGameKeys.dartIndicator(i),
                      width: 50,
                      decoration: BoxDecoration(
                        color: hasScore
                            ? slotColor.withOpacity(0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasScore
                              ? slotColor
                              : _compassBronze.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          scoreLabel,
                          style: GoogleFonts.pirataOne(
                            fontSize: 10,
                            color: hasScore
                                ? slotColor
                                : _compassBronze.withOpacity(0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.piratesGrid(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/games/pirates_grid/images/PiratesGrid-Background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Ocean Navy 0.65 overlay
                Positioned.fill(
                  child: Container(color: const Color(0xA61B2838)),
                ),
                // Main game content
                _buildGameArea(game, players, currentPlayerId, dartsThrown),
              ],
            ),
          ),
          // 2. RemoveDartsModal (conditional)
          if (shouldPromptTakeout)
            RemoveDartsModal(
              config: RemoveDartsModalConfig.piratesGrid(),
              playerName: players
                      .where((p) => p.id == currentPlayerId)
                      .map((p) => p.name)
                      .firstOrNull ??
                  'Player',
              editScoreButtonKey: PiratesGridGameKeys.editScoreButton,
              onEditScore: () {
                final currentPlayer =
                    players.where((p) => p.id == currentPlayerId).firstOrNull;
                if (currentPlayer == null) return;
                final segments =
                    provider.getCurrentTurnDartSegments(currentPlayerId);
                // Convert thrown misses (score 0 darts) to 'Miss' for dialog
                final initialSegments = segments
                    .where((s) => s != 'Skip')
                    .map((s) => (s.isEmpty || s == '-') ? 'Miss' : s)
                    .toList();
                showEditScoreDialog(
                  context: context,
                  playerName: currentPlayer.name,
                  initialSegments: initialSegments,
                  onSubmit: (newSegments) {
                    final cleanedSegments = <String>[];
                    for (final seg in newSegments) {
                      if (seg.isEmpty || seg == '-') continue;
                      cleanedSegments.add(seg);
                    }
                    provider.editPlayerScore(
                      playerId: currentPlayerId,
                      newSegments: cleanedSegments,
                    );
                  },
                  config: EditScoreDialogConfig.piratesGrid(),
                );
              },
            ),
          // 3. DartboardEmulatorSection — Positioned bottom 0
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
              config: DartboardSectionConfig.piratesGrid(),
              onPlayToComplete: _mockApi != null ? _onPlayToComplete : null,
              playToCompleteConfig:
                  _mockApi != null ? PlayToCompleteButtonConfig.piratesGrid() : null,
            ),
          ),
          // 4. DartboardEmulatorFAB — Positioned bottom-right 16,16
          Positioned(
            right: 16,
            bottom: 16,
            child: DartboardEmulatorFAB(
              controller: _dartboardEmulatorController,
              isConnected: !dartboardProvider.isEmulator,
              config: DartboardFABConfig.piratesGrid(),
              onCancelAutoPlay: _onCancelAutoPlay,
            ),
          ),
          // 5. SaveGameModal (conditional)
          if (_showSaveModal)
            SaveGameModal(
              config: SaveGameModalConfig.piratesGrid(),
              onSave: () async {
                await provider.saveGame(players);
                if (mounted) Navigator.of(context).pop();
              },
              onDontSave: () => Navigator.of(context).pop(),
            ),
          // 6. DartboardPausedModal — last child, paints on top
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status != DartboardConnectionStatus.connected &&
              dartboardProvider.status != DartboardConnectionStatus.emulator)
            DartboardPausedModal(
              config: DartboardPausedModalConfig.piratesGrid(),
            ),
        ],
      ),
    );
  }

  Widget _buildGameArea(
    PiratesGridGame game,
    List<Player> players,
    String currentPlayerId,
    int dartsThrown,
  ) {
    final p1Id = game.playerIds[0];
    final p2Id = game.playerIds[1];

    final p1 = players.where((p) => p.id == p1Id).firstOrNull;
    final p2 = players.where((p) => p.id == p2Id).firstOrNull;

    final isP1Active = currentPlayerId == p1Id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
      child: Column(
        children: [
          // Round tracker (only for Bo3+)
          if (game.bestOf > 1)
            _buildRoundTracker(game, p1, p2, p1Id, p2Id),
          // Main game row: P1 | grid | P2
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left player column (P1)
                Expanded(
                  flex: 1,
                  child: _buildPlayerColumn(
                    game: game,
                    player: p1,
                    playerId: p1Id,
                    playerIndex: 0,
                    isActive: isP1Active,
                    dartsThrown: isP1Active ? dartsThrown : 0,
                    currentDartSegments: isP1Active
                        ? context
                            .read<PiratesGridProvider>()
                            .getCurrentTurnDartSegments(p1Id)
                        : [],
                  ),
                ),
                // Center column (grid)
                _buildGrid(game),
                // Right player column (P2)
                Expanded(
                  flex: 1,
                  child: _buildPlayerColumn(
                    game: game,
                    player: p2,
                    playerId: p2Id,
                    playerIndex: 1,
                    isActive: !isP1Active,
                    dartsThrown: !isP1Active ? dartsThrown : 0,
                    currentDartSegments: !isP1Active
                        ? context
                            .read<PiratesGridProvider>()
                            .getCurrentTurnDartSegments(p2Id)
                        : [],
                  ),
                ),
              ],
            ),
          ),
          // Steal Mode badge (only when stealMode ON)
          if (game.stealMode)
            Container(
              key: PiratesGridGameKeys.stealModeBadge,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _bloodRed,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _compassBronze, width: 1.5),
              ),
              child: Text(
                '⚔ STEAL MODE',
                style: GoogleFonts.pirataOne(
                  fontSize: 15,
                  color: _parchmentTan,
                  letterSpacing: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundTracker(
    PiratesGridGame game,
    Player? p1,
    Player? p2,
    String p1Id,
    String p2Id,
  ) {
    final p1Wins = game.roundsWon[p1Id] ?? 0;
    final p2Wins = game.roundsWon[p2Id] ?? 0;
    final p1Name = p1?.name ?? 'Player 1';
    final p2Name = p2?.name ?? 'Player 2';

    return Container(
      key: PiratesGridGameKeys.roundTracker,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _oceanNavy.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _compassBronze, width: 1.5),
      ),
      child: Text(
        'Round ${game.currentRound}/${game.bestOf}  —  $p1Name: $p1Wins  $p2Name: $p2Wins',
        style: GoogleFonts.pirataOne(
          fontSize: 16,
          color: _parchmentTan,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPlayerColumn({
    required PiratesGridGame game,
    required Player? player,
    required String playerId,
    required int playerIndex,
    required bool isActive,
    required int dartsThrown,
    required List<String> currentDartSegments,
  }) {
    final playerName = player?.name ?? 'Player ${playerIndex + 1}';
    final flagColor = playerIndex == 0 ? _p1FlagColor : _p2FlagColor;
    final flagsPlanted = game.getFlagsPlanted(playerId);

    // Character asset: fixed by player index
    final characterPath = playerIndex == 0
        ? 'assets/games/pirates_grid/characters/CaptainCrossbones.png'
        : 'assets/games/pirates_grid/characters/CaptainRedbeard.png';

    final double charSize = isActive ? 200 : 140;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Character image
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Opacity(
            opacity: isActive ? 1.0 : 0.75,
            child: Container(
              key: isActive
                  ? PiratesGridGameKeys.playerAvatarActive
                  : PiratesGridGameKeys.playerAvatarInactive,
              width: charSize,
              height: charSize,
              decoration: BoxDecoration(
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: flagColor.withOpacity(0.7),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Image.asset(
                characterPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  color: flagColor,
                  size: charSize * 0.7,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Player name
        Text(
          playerName,
          style: GoogleFonts.pirataOne(
            fontSize: 20,
            color: isActive ? _parchmentTan : _parchmentTan.withOpacity(0.7),
            shadows: isActive
                ? const [Shadow(color: _inkBlack, offset: Offset(1, 1), blurRadius: 3)]
                : null,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Flags counter
        Text(
          '🚩 $flagsPlanted planted',
          key: PiratesGridGameKeys.flagsCounter(playerId),
          style: GoogleFonts.pirataOne(
            fontSize: 16,
            color: isActive ? flagColor : flagColor.withOpacity(0.7),
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 10),
          // Speed Play timer (active player only)
          if (game.speedPlay) _buildSpeedPlayTimer(),
          const SizedBox(height: 8),
          // Skip turn button (active player only) — no key here, canonical key is in AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: context.read<PiratesGridProvider>().shouldPromptTakeout
                    ? null
                    : () {
                        _speedPlayTimer?.cancel();
                        final p = context.read<PiratesGridProvider>();
                        final pp = context.read<PlayerProvider>();
                        final g = p.currentGame;
                        final pid = g?.getCurrentPlayerId() ?? '';
                        final pName =
                            pp.getPlayerById(pid)?.name ?? playerName;
                        final darts = p.getCurrentPlayerDartsThrown();
                        p.skipTurn();
                        if (darts > 0) {
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            if (mounted) _audioQueue?.announceRemoveDarts(pName);
                          });
                          Future.delayed(const Duration(milliseconds: 3500), () {
                            if (mounted) _mockApi?.simulateTakeoutStarted();
                          });
                        } else {
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
                style: OutlinedButton.styleFrom(
                  backgroundColor: _compassBronze,
                  side: const BorderSide(color: _treasureGold, width: 1.5),
                  foregroundColor: _parchmentTan,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'SKIP TURN',
                  style: GoogleFonts.pirataOne(
                    fontSize: 14,
                    color: _parchmentTan,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpeedPlayTimer() {
    final secs = _speedPlaySecondsRemaining;

    Color timerColor;
    if (secs >= 6) {
      timerColor = _treasureGold;
    } else if (secs >= 3) {
      timerColor = _compassBronze;
    } else {
      timerColor = _bloodRed;
    }

    Widget timerWidget = Text(
      '$secs',
      key: PiratesGridGameKeys.speedPlayTimer,
      style: GoogleFonts.pirataOne(
        fontSize: 36,
        color: timerColor,
        shadows: [
          Shadow(color: timerColor.withOpacity(0.6), blurRadius: 8),
        ],
      ),
    );

    // Pulsing animation for critical (2-0s)
    if (secs <= 2) {
      timerWidget = RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
          child: timerWidget,
        ),
      );
    }

    return timerWidget;
  }

  Widget _buildGrid(PiratesGridGame game) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (col) {
              return _buildGridCell(game, row, col);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildGridCell(PiratesGridGame game, int row, int col) {
    final cell = game.grid[row][col];
    final claimedBy = cell.claimedBy;

    // Determine cell color/border based on ownership
    Color borderColor;
    Color bgColor;
    if (claimedBy == game.playerIds[0]) {
      borderColor = _p1FlagColor;
      bgColor = _p1FlagColor.withOpacity(0.2);
    } else if (claimedBy == game.playerIds[1]) {
      borderColor = _p2FlagColor;
      bgColor = _p2FlagColor.withOpacity(0.2);
    } else {
      borderColor = _compassBronze.withOpacity(0.6);
      bgColor = _oceanNavy.withOpacity(0.6);
    }

    // Highlight winning line cells
    final isWinningCell = game.winningLine?.any(
          (pos) => pos.row == row && pos.col == col,
        ) ??
        false;

    if (isWinningCell) {
      borderColor = _treasureGold;
      bgColor = _treasureGold.withOpacity(0.25);
    }

    // Build target label
    final target = cell.target;
    String targetLabel;
    if (target.requirement == CellRequirement.bull) {
      targetLabel = 'Bull';
    } else if (game.targetDifficulty == TargetDifficulty.hard) {
      switch (target.requirement) {
        case CellRequirement.tripleOnly:
          targetLabel = 'T${target.number}';
          break;
        case CellRequirement.doubleOnly:
          targetLabel = 'D${target.number}';
          break;
        default:
          targetLabel = '${target.number}';
      }
    } else {
      targetLabel = '${target.number}';
    }

    return Container(
      key: PiratesGridGameKeys.gridCell(row, col),
      width: 90,
      height: 90,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: isWinningCell ? 3 : 2,
        ),
        boxShadow: isWinningCell
            ? [
                BoxShadow(
                  color: _treasureGold.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Empty square texture when unclaimed
          if (claimedBy == null)
            Positioned.fill(
              child: Image.asset(
                'assets/games/pirates_grid/pieces/PiratesGrid-EmptySquare.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.3),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          // Flag image when claimed
          if (claimedBy != null)
            Positioned.fill(
              child: Image.asset(
                claimedBy == game.playerIds[0]
                    ? 'assets/games/pirates_grid/pieces/PiratesGrid-Flag-Red.png'
                    : 'assets/games/pirates_grid/pieces/PiratesGrid-Flag-Teal.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          // Target label (centered)
          Center(
            child: Text(
              targetLabel,
              style: GoogleFonts.pirataOne(
                fontSize: game.targetDifficulty == TargetDifficulty.hard ? 22 : 28,
                color: claimedBy != null
                    ? Colors.white.withOpacity(0.9)
                    : _treasureGold,
                shadows: [
                  const Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
