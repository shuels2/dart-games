import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/horse_race_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/carnival_derby_announcement_helper.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/horse_race/race_track_widget.dart';
import '../../../widgets/player_avatar_widget.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/carnival_string_lights.dart';
import '../../../widgets/carnival_target_logo.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../services/play_to_complete/carnival_derby_strategy.dart';
import '../../../widgets/edit_score/edit_score.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import 'horse_race_results_screen.dart';

class HorseRaceGameScreen extends StatefulWidget {
  const HorseRaceGameScreen({super.key});

  @override
  State<HorseRaceGameScreen> createState() => _HorseRaceGameScreenState();
}

class _HorseRaceGameScreenState extends State<HorseRaceGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();

  MockScoliaApiService? _mockApi;
  CarnivalDerbyAnnouncementHelper? _audioQueue;
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();
  final ScrollController _scrollController = ScrollController();
  PlayToCompleteRunner? _playToCompleteRunner;
  bool _gameCompleted = false;
  bool _showSaveModal = false;

  @override
  void initState() {
    super.initState();

    // Get services after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dartboardProvider = context.read<DartboardProvider>();
      _mockApi = dartboardProvider.apiService;
      if (mounted) setState(() {});

      // Initialize global announcement queue with Carnival Derby helper
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = CarnivalDerbyAnnouncementHelper(globalQueue);

      // Subscribe to dartboard events (works for both WebSocket and emulator)
      final eventStream = dartboardProvider.dartboardEventStream;
      if (eventStream != null) {
        _dartboardSubscription = eventStream.listen((event) {
          _handleDartboardEvent(event);
        });
      }

      // Announce the first player's turn
      _announceFirstPlayerTurn();
    });
  }

  void _announceFirstPlayerTurn() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      final horseRaceProvider = context.read<HorseRaceProvider>();
      final playerProvider = context.read<PlayerProvider>();

      final players = horseRaceProvider.currentGame!.playerIds
          .map((id) => playerProvider.getPlayerById(id))
          .whereType<Player>()
          .toList();

      final firstPlayer = horseRaceProvider.getCurrentPlayer(players);
      if (firstPlayer != null) {
        _audioQueue?.announceTurn(firstPlayer.name);
      }
    });
  }

  void _scrollToCurrentPlayer() {
    final horseRaceProvider = context.read<HorseRaceProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentGame = horseRaceProvider.currentGame;

    if (currentGame == null || !_scrollController.hasClients) return;

    final allPlayers = playerProvider.allPlayers;
    final currentPlayer = horseRaceProvider.getCurrentPlayer(allPlayers);
    if (currentPlayer == null) return;

    // Find current player's index in the player list
    final currentPlayerIndex = currentGame.playerIds.indexOf(currentPlayer.id);
    if (currentPlayerIndex == -1) return;

    // Calculate scroll position
    // Each race lane has approximately 80px height (margins + padding + content)
    const estimatedTileHeight = 80.0;

    // Scroll to show the current player's tile
    // If it's the first player (index 0), scroll to top
    // Otherwise, scroll to show the tile with some buffer above it
    if (currentPlayerIndex == 0) {
      // First player - scroll to top
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Calculate scroll offset: position the current player's tile near the top
      // with one tile visible above it for context
      final scrollOffset = (currentPlayerIndex - 1) * estimatedTileHeight;

      _scrollController.animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _playToCompleteRunner?.dispose();
    _dartboardSubscription?.cancel();
    _audioQueue?.dispose();
    _dartboardEmulatorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlayToComplete() {
    if (_mockApi == null) return;
    _dartboardEmulatorController.setAutoPlaying(true);
    _dartboardEmulatorController.hide();

    _playToCompleteRunner = PlayToCompleteRunner(
      strategy: CarnivalDerbyStrategy(),
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
  }

  void _handleDartboardEvent(Map<String, dynamic> event) {
    final type = event['type'];
    final horseRaceProvider = context.read<HorseRaceProvider>();

    if (type == 'throw_detected') {
      final throwData = event['data']['payload'];
      final sector = throwData['sector'];
      final score = _calculateScore(sector);
      final isMiss = sector == 'None';

      // Get player info before processing throw
      final playerProvider = context.read<PlayerProvider>();
      final players = horseRaceProvider.currentGame!.playerIds
          .map((id) => playerProvider.getPlayerById(id))
          .whereType<Player>()
          .toList();
      final currentPlayer = horseRaceProvider.getCurrentPlayer(players);

      // Convert sector to display format for storage
      final dartDisplay = isMiss ? 'Miss' : sector;

      // Process the dart throw with display value
      horseRaceProvider.processDartThrow(
        score,
        dartDisplay: dartDisplay,
      );

      // Check if player busted
      if (horseRaceProvider.currentPlayerBusted) {
        if (!_dartboardEmulatorController.isAutoPlaying &&
            currentPlayer != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _audioQueue?.announceBust(currentPlayer.name);

            Future.delayed(const Duration(milliseconds: 3000), () {
              _audioQueue?.announceRemoveDarts(currentPlayer.name);

              Future.delayed(const Duration(milliseconds: 2000), () {
                _mockApi?.simulateTakeoutStarted();

                Future.delayed(const Duration(milliseconds: 500), () {
                  _mockApi?.simulateTakeoutFinished();
                });
              });
            });
          });
        }
        return;
      }

      if (!_dartboardEmulatorController.isAutoPlaying) {
        if (isMiss) {
          _audioQueue?.announceMiss();
        } else {
          _audioQueue?.announceDart(
            score,
            _getMultiplierFromSector(sector),
          );
        }
      }

      if (!_dartboardEmulatorController.isAutoPlaying) {
        final dartsThrown = horseRaceProvider.getCurrentPlayerDartsThrown();
        if (dartsThrown >= 3 || horseRaceProvider.hasWinner) {
          if (currentPlayer != null) {
            Future.delayed(const Duration(milliseconds: 2500), () {
              _audioQueue?.announceRemoveDarts(currentPlayer.name);
            });
          }
        }
      }
    }

    if (type == 'takeout_finished') {
      _onTakeoutComplete();
    }
  }

  void _onTakeoutComplete() {
    final horseRaceProvider = context.read<HorseRaceProvider>();
    if (!mounted) return;

    if (horseRaceProvider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!horseRaceProvider.isGameActive) return;

    horseRaceProvider.handleTakeoutFinished();

    if (!_dartboardEmulatorController.isAutoPlaying) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToCurrentPlayer();
        }
      });

      final playerProvider = context.read<PlayerProvider>();
      final players = horseRaceProvider.currentGame!.playerIds
          .map((id) => playerProvider.getPlayerById(id))
          .whereType<Player>()
          .toList();
      final nextPlayer = horseRaceProvider.getCurrentPlayer(players);
      if (nextPlayer != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _audioQueue?.announceTurn(nextPlayer.name);
        });
      }
    }

    setState(() {});
  }

  int _calculateScore(String sector) {
    if (sector == 'Bull') return 50;
    if (sector == '25') return 25;
    if (sector == 'None') return 0;

    // Extract number from sector (e.g., "D20" -> 20, "T19" -> 19, "S18" -> 18, "s18" -> 18)
    final match = RegExp(r'[A-Za-z](\d+)').firstMatch(sector);
    if (match == null) return 0;

    final baseScore = int.parse(match.group(1)!);

    if (sector.startsWith('D')) return baseScore * 2;
    if (sector.startsWith('T')) return baseScore * 3;
    if (sector.startsWith('S') || sector.startsWith('s')) return baseScore;

    return 0;
  }

  /// Calculate score from dart display string for UI display
  String _getScoreDisplayFromSegment(String segment) {
    if (segment == 'Miss' || segment.isEmpty) return 'Miss';
    if (segment == 'Skip') return 'Skip';
    if (segment == 'Bull') return '50';
    if (segment == '25') return '25';

    // Calculate score from segment (D13 -> 26, T20 -> 60, etc.)
    final score = _calculateScore(segment);
    return score.toString();
  }

  String _getMultiplierFromSector(String sector) {
    if (sector == 'Bull') return 'bullseye';
    if (sector == '25') return 'outer_bull';
    if (sector == 'None') return 'miss';
    if (sector.startsWith('D')) return 'double';
    if (sector.startsWith('T')) return 'triple';
    if (sector.startsWith('S') || sector.startsWith('s')) return 'single';
    return 'single';
  }

  int _getBaseScoreFromSector(String sector) {
    if (sector == 'Bull') return 50;
    if (sector == '25') return 25;
    if (sector == 'None') return 0;

    final match = RegExp(r'[A-Za-z](\d+)').firstMatch(sector);
    if (match == null) return 0;
    return int.parse(match.group(1)!);
  }

  void _handleGameWon() {
    // Prevent multiple navigations to results screen
    if (_gameCompleted) return;
    _gameCompleted = true;

    void navigateToResults() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HorseRaceResultsScreen(),
        ),
      );
    }

    if (_dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
    } else {
      final horseRaceProvider = context.read<HorseRaceProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final winner = horseRaceProvider.getWinner(playerProvider.allPlayers);
      if (winner != null) {
        _audioQueue?.announceWinner(winner.name);
      }
      Future.delayed(const Duration(milliseconds: 3000), navigateToResults);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final horseRaceProvider = context.watch<HorseRaceProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final currentGame = horseRaceProvider.currentGame;
    final hasDartsThrown =
        currentGame?.totalDartsThrown.values.any((c) => c > 0) ?? false;

    final players = currentGame == null
        ? <Player>[]
        : currentGame.playerIds
            .map((id) => playerProvider.getPlayerById(id))
            .whereType<Player>()
            .toList();
    final currentPlayer = currentGame == null
        ? null
        : horseRaceProvider.getCurrentPlayer(players);
    final dartsThrown = horseRaceProvider.getCurrentPlayerDartsThrown();
    final shouldPromptTakeout = horseRaceProvider.shouldPromptTakeout;

    return PopScope(
      canPop: !hasDartsThrown || _showSaveModal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF8B5E3C), // Warm Cedar base color
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFE63946), // Lava Red (left)
                      Color(0xFFFFD700), // Canary Yellow (center)
                      Color(0xFF48CAE4), // Electric Teal (right)
                    ],
                    stops: [0.0, 0.66, 1.0], // Red lasts twice as long
                  ),
                ),
                child: AppBar(
                  leading: IconButton(
                    key: CarnivalDerbyGameKeys.backButton,
                    icon: Icon(
                      Icons.arrow_back,
                      color: const Color(0xFFF1FAEE), // Cloud Dancer white
                      size: 32, // Bigger size
                      shadows: [
                        const Shadow(
                          color: Color(0xFFFFD700), // Canary Yellow glow
                          blurRadius: 10,
                        ),
                        const Shadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 20,
                        ),
                      ],
                    ),
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
                    'Carnival Derby Race',
                    style: GoogleFonts.rye(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: const Color(0xFFF1FAEE), // Cloud Dancer
                      shadows: [
                        const Shadow(
                          color: Color(0xFFFFD700), // Canary Yellow glow
                          blurRadius: 10,
                        ),
                        const Shadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: DartboardConnectionInfo(
                        config: DartboardConnectionInfoConfig.carnivalDerby(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: Stack(
              children: [
                // Rotated wood plank background
                Positioned.fill(
                  child: Transform.scale(
                    scale: 2.0, // Scale up to ensure coverage
                    child: Transform.rotate(
                      angle: 1.5708, // 90 degrees in radians (Ï€/2)
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF8B5E3C), // Warm Cedar base color
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/games/carnival_derby/images/CarnivalDerby-WoodPlanks.jpg'),
                            fit: BoxFit.cover,
                            repeat: ImageRepeat.repeat,
                            colorFilter: ColorFilter.mode(
                              const Color(0xFF8B5E3C).withOpacity(
                                  0.7), // Lighter tint with reduced opacity
                              BlendMode.multiply,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Radial gradient spotlight overlay - warm overhead lamp effect
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center:
                              const Alignment(0, -0.6), // Top-middle (50% 20%)
                          radius: 1.2,
                          colors: [
                            const Color.fromRGBO(255, 230, 150,
                                0.4), // Warm soft amber center glow
                            const Color.fromRGBO(
                                255, 230, 150, 0.1), // Transparent warm wash
                            const Color.fromRGBO(
                                13, 27, 42, 0.8), // Deep moody navy-black edges
                          ],
                          stops: const [
                            0.0,
                            0.4,
                            1.0
                          ], // Center â†’ Mid-falloff â†’ Outer shadows
                        ),
                        backgroundBlendMode:
                            BlendMode.overlay, // Interact with wood grain
                      ),
                    ),
                  ),
                ),
                // Carnival target logo (centered, in front of background, behind string lights)
                const Center(
                  child: CarnivalTargetLogo(size: 700.0),
                ),
                // Carnival string lights (behind content, in front of background)
                const CarnivalStringLights(),
                // Content
                if (currentGame == null)
                  Center(
                    child: Text(
                      'No active game',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        color: const Color(
                            0xFFF1FAEE), // Cloud Dancer for visibility
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Current player info
                      _buildCurrentPlayerSection(
                        currentPlayer,
                        dartsThrown,
                        currentGame,
                        horseRaceProvider,
                      ),

                      // Race track
                      Expanded(
                        child: RaceTrackWidget(
                          players: players,
                          targetScore: currentGame.targetScore,
                          scrollController: _scrollController,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Floating button to toggle dartboard visibility (only show when not connected)
            floatingActionButton: DartboardEmulatorFAB(
              controller: _dartboardEmulatorController,
              isConnected: !dartboardProvider.isEmulator,
              config: DartboardFABConfig.carnivalDerby(),
              onCancelAutoPlay: _onCancelAutoPlay,
            ),
          ),
          // Outer-Stack modals — paint above Scaffold (incl. AppBar + FAB) so they
          // block ALL screen interactions while shown.
          // RemoveDartsModal sits BEHIND the emulator so DARTS REMOVED stays
          // visible/tappable on top of the takeout overlay.
          if (shouldPromptTakeout)
            RemoveDartsModal(
              config: RemoveDartsModalConfig.carnivalDerby(),
              playerName: currentPlayer?.name ?? 'Player',
              editScoreButtonKey: CarnivalDerbyGameKeys.editScoreButton,
              onEditScore: () {
                if (currentPlayer == null) return;
                showEditScoreDialog(
                  context: context,
                  playerName: currentPlayer.name,
                  initialSegments: horseRaceProvider
                      .getCurrentTurnDartScores(currentPlayer.id),
                  onSubmit: (newSegments) => horseRaceProvider
                      .updateAllDartScores(currentPlayer.id, newSegments),
                  config: EditScoreDialogConfig.carnivalDerby(),
                );
              },
            ),
          // Emulator above RemoveDartsModal; below SaveGameModal so the save
          // modal's Don't Save button isn't intercepted by the emulator.
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
              config: DartboardSectionConfig.carnivalDerby(),
              onPlayToComplete: _mockApi != null ? _onPlayToComplete : null,
              playToCompleteConfig: _mockApi != null
                  ? PlayToCompleteButtonConfig.carnivalDerby()
                  : null,
            ),
          ),
          // Save Game Modal
          if (_showSaveModal)
            SaveGameModal(
              config: SaveGameModalConfig.carnivalDerby(),
              onSave: () async {
                await horseRaceProvider.saveGame(playerProvider.allPlayers);
                if (mounted) Navigator.of(context).pop();
              },
              onDontSave: () => Navigator.of(context).pop(),
            ),
          // Dartboard Paused Modal — last child, paints on top.
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status != DartboardConnectionStatus.connected &&
              dartboardProvider.status != DartboardConnectionStatus.emulator)
            DartboardPausedModal(
              config: DartboardPausedModalConfig.carnivalDerby(),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayerSection(
    Player? currentPlayer,
    int dartsThrown,
    dynamic currentGame,
    HorseRaceProvider provider,
  ) {
    if (currentPlayer == null) return const SizedBox.shrink();

    final score = provider.getPlayerScore(currentPlayer.id);
    final targetScore = currentGame.targetScore;
    final exactScoreMode = currentGame.exactScoreMode;
    final dartScores = provider.getCurrentTurnDartScores(currentPlayer.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3557).withOpacity(0.9), // Midnight Navy
        border: const Border(
          bottom:
              BorderSide(color: Color(0xFFFFD700), width: 3), // Canary Yellow
        ),
      ),
      child: Row(
        children: [
          // Game settings - fixed width
          SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Race to $targetScore points',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 18,
                    color: const Color(0xFFFFD700), // Canary Yellow
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exactScoreMode
                      ? 'Perfect Finish Required'
                      : 'Perfect Finish Not Required',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 18,
                    color: const Color(0xFFF1FAEE), // Cloud Dancer
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Current player info and dart scores - flexible width
          Expanded(
            child: Row(
              children: [
                PlayerAvatarWidget(
                  player: currentPlayer,
                  size: 30.0,
                  showName: false,
                  isHighlighted: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPlayer.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color:
                              const Color(0xFFF1FAEE), // Cloud Dancer (white)
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Score: $score / $targetScore',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 18,
                          color: const Color(0xFFFFD700), // Canary Yellow
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Skip turn button
                ElevatedButton(
                  key: CarnivalDerbyGameKeys.skipTurnButton,
                  onPressed: () {
                    final dartsThrown = provider.getCurrentPlayerDartsThrown();

                    // Skip the turn
                    provider.skipTurn();

                    // If darts were thrown, show "remove darts" sequence
                    if (dartsThrown > 0) {
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        if (mounted) {
                          _audioQueue?.announceRemoveDarts(currentPlayer.name);
                        }
                      });
                      Future.delayed(const Duration(milliseconds: 3500), () {
                        if (mounted) {
                          _mockApi?.simulateTakeoutStarted();
                        }
                      });
                    } else {
                      // No darts thrown, advance directly without showing modals
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          if (_mockApi != null) {
                            _mockApi!.simulateTakeoutFinished();
                          } else {
                            _onTakeoutComplete();
                          }
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946), // Lava Red
                    foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: const BorderSide(
                      color: Color(0xFFFFD700), // Canary Yellow border
                      width: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'SKIP TURN',
                    style: GoogleFonts.bangers(
                      fontSize: 16,
                      letterSpacing: 1.0,
                      color: const Color(0xFFF1FAEE), // Cloud Dancer
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Dart scores on the right
                Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      SizedBox(
                        width: 52, // 30% wider to fit "Miss" without wrapping
                        child: Column(
                          children: [
                            Text(
                              'D${i + 1}',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF1FAEE), // Cloud Dancer
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              i < dartScores.length
                                  ? _getScoreDisplayFromSegment(dartScores[i])
                                  : '-',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 20,
                                color: i < dartScores.length
                                    ? const Color(0xFFFFD700) // Canary Yellow
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
