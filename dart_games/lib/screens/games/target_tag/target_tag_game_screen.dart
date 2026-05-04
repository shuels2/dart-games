import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../models/target_tag_game.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/target_tag_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/target_tag_announcement_helper.dart';
import '../../../widgets/target_tag/active_player_panel_widget.dart';
import '../../../widgets/target_tag/game_info_panel_widget.dart';
import '../../../widgets/target_tag/player_card_widget.dart';
import '../../../widgets/target_tag/tech_neon_background.dart';
import '../../../services/play_to_complete/target_tag_strategy.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/edit_score/edit_score.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import 'target_tag_results_screen.dart';

class TargetTagGameScreen extends StatefulWidget {
  const TargetTagGameScreen({super.key});

  @override
  State<TargetTagGameScreen> createState() => _TargetTagGameScreenState();
}

class _TargetTagGameScreenState extends State<TargetTagGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  TargetTagAnnouncementHelper? _audioQueue;
  final ScrollController _scrollController = ScrollController();
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();

  PlayToCompleteRunner? _playToCompleteRunner;
  bool _hasAnnouncedSuddenDeath = false;
  bool _gameCompleted = false;
  bool _showSaveModal = false;

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

    // Initialize global announcement queue with Target Tag helper
    final globalQueue = GameAnnouncementQueueService();
    await globalQueue.loadSettings();
    _audioQueue = TargetTagAnnouncementHelper(globalQueue);

    // Subscribe to dartboard events (works for both WebSocket and emulator)
    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen((event) {
        _handleDartboardEvent(event);
      });
    }

    // Announce game start
    _audioQueue!.announceGameStart();

    // Announce first player
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _announceCurrentPlayerTurn();
      }
    });
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
      strategy: TargetTagStrategy(),
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

    if (type == 'throw_detected') {
      _handleDartThrow(event);
    } else if (type == 'takeout_finished') {
      _handleTakeoutFinished();
    }
  }

  void _handleDartThrow(Map<String, dynamic> event) {
    final targetTagProvider = context.read<TargetTagProvider>();
    if (!mounted || !targetTagProvider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;

    // Get current player info before processing
    final playerProvider = context.read<PlayerProvider>();
    final allPlayers = playerProvider.allPlayers;
    final currentPlayer = targetTagProvider.getCurrentPlayer(allPlayers);
    if (currentPlayer == null) return;

    final wasTaggedIn = targetTagProvider.isTaggedIn(currentPlayer.id);
    final shieldsBefore = targetTagProvider.getShields(currentPlayer.id);

    // Track ALL players' shields BEFORE processing (for low shields warning)
    final currentGame = targetTagProvider.currentGame!;
    final allShieldsBefore = <String, int>{};
    for (final playerId in currentGame.playerIds) {
      allShieldsBefore[playerId] = targetTagProvider.getShields(playerId);
    }

    // Track eliminated players BEFORE processing
    final eliminatedBefore = currentGame.playerIds
        .where((id) => targetTagProvider.isEliminated(id))
        .toSet();

    // Process the dart throw
    targetTagProvider.processDartThrow(sector);

    // Track eliminated players AFTER processing
    final eliminatedAfter = currentGame.playerIds
        .where((id) => targetTagProvider.isEliminated(id))
        .toSet();

    // Get state after processing
    final shieldsAfter = targetTagProvider.getShields(currentPlayer.id);
    final isNowTaggedIn = targetTagProvider.isTaggedIn(currentPlayer.id);
    final dartsThrown = targetTagProvider.getCurrentPlayerDartsThrown();

    // Get dart throw tracking info for the current dart (last one thrown)
    final dartIndex = dartsThrown - 1;
    final hitOpponentTargetList =
        targetTagProvider.getDartThrowHitOpponentTarget(currentPlayer.id);
    final heroBonusHitList =
        targetTagProvider.getDartThrowHeroBonusHit(currentPlayer.id);

    final didHitOpponentTarget =
        dartIndex >= 0 && dartIndex < hitOpponentTargetList.length
            ? hitOpponentTargetList[dartIndex]
            : false;
    final didHitHeroBonus =
        dartIndex >= 0 && dartIndex < heroBonusHitList.length
            ? heroBonusHitList[dartIndex]
            : false;

    // Parse sector for announcement
    final parsed = _parseSector(sector);
    final isMiss = sector == 'None' || parsed == null;

    // ===== PHASE 1: GATHER FACTS =====

    // Check current player shield changes
    final hasShieldGain = !wasTaggedIn &&
        !isMiss &&
        parsed != null &&
        shieldsAfter > shieldsBefore;
    final hasTaggedIn = isNowTaggedIn && !wasTaggedIn;
    final hasSuccessfulTag =
        didHitOpponentTarget || (didHitHeroBonus && wasTaggedIn);

    // Check opponent status changes
    final newlyEliminated = eliminatedAfter.difference(eliminatedBefore);
    final hasElimination = newlyEliminated.isNotEmpty;

    // Check for opponents who lost tagged-in status
    final lostTaggedInPlayers = <String>[];
    for (final playerId in currentGame.playerIds) {
      if (playerId == currentPlayer.id) continue;
      final wasPreviouslyTaggedIn = currentGame.playerIds.contains(playerId) &&
          (allShieldsBefore[playerId] ?? 0) >= currentGame.shieldMax;
      final isStillTaggedIn = targetTagProvider.isTaggedIn(playerId);
      // Use actual tagged-in tracking from the game state
      if (targetTagProvider.isTaggedIn(playerId) != true) {
        // Check if they WERE tagged-in before this dart
        final shieldsBeforeThis = allShieldsBefore[playerId] ?? 0;
        final shieldsAfterThis = targetTagProvider.getShields(playerId);
        if (shieldsBeforeThis >= currentGame.shieldMax &&
            shieldsAfterThis < currentGame.shieldMax) {
          lostTaggedInPlayers.add(playerId);
        }
      }
    }
    final hasTaggedOut = lostTaggedInPlayers.isNotEmpty;

    // Check for opponents at low shields (exactly 1)
    final lowShieldPlayers = <String>[];
    for (final playerId in currentGame.playerIds) {
      if (targetTagProvider.isEliminated(playerId)) continue;
      if (playerId == currentPlayer.id) continue;
      final sb = allShieldsBefore[playerId] ?? 0;
      final sn = targetTagProvider.getShields(playerId);
      if (sb > 1 && sn == 1) {
        lowShieldPlayers.add(playerId);
      }
    }
    final hasLowShields = lowShieldPlayers.isNotEmpty;

    // Check for opponents at vulnerable (exactly 0 shields, not eliminated)
    final vulnerablePlayers = <String>[];
    for (final playerId in currentGame.playerIds) {
      if (targetTagProvider.isEliminated(playerId)) continue;
      if (playerId == currentPlayer.id) continue;
      final sb = allShieldsBefore[playerId] ?? 0;
      final sn = targetTagProvider.getShields(playerId);
      if (sb > 0 && sn == 0) {
        vulnerablePlayers.add(playerId);
      }
    }
    final hasVulnerable = vulnerablePlayers.isNotEmpty;

    // Determine if any secondary effect exists
    final hasSecondary = hasShieldGain ||
        hasTaggedIn ||
        hasSuccessfulTag ||
        hasTaggedOut ||
        hasLowShields ||
        hasVulnerable ||
        hasElimination;

    // ===== PHASE 2: APPLY PRECEDENCE (max 1 moment announcement) =====

    if (!_dartboardEmulatorController.isAutoPlaying) {
      // Hit/Miss: only fire if NO secondary effect exists
      if (!hasSecondary) {
        if (!isMiss && parsed != null) {
          _audioQueue!.announceHit(
            parsed['number'] as int,
            parsed['multiplier'] as String,
          );
        } else {
          _audioQueue!.announceHit(0, 'single', isMiss: true);
        }
      }

      // Pick highest-priority moment and fire exactly one
      if (hasElimination) {
        if (currentGame.mode == GameMode.team) {
          final eliminatedTeams = <String, List<String>>{};
          for (final eliminatedId in newlyEliminated) {
            final teamId = currentGame.playerToTeam![eliminatedId]!;
            if (!eliminatedTeams.containsKey(teamId)) {
              eliminatedTeams[teamId] = [];
            }
            final player = allPlayers.firstWhere((p) => p.id == eliminatedId);
            eliminatedTeams[teamId]!.add(player.name);
          }
          for (final playerNames in eliminatedTeams.values) {
            _audioQueue!.announceEliminated(playerNames);
          }
        } else {
          for (final eliminatedId in newlyEliminated) {
            final eliminatedPlayer =
                allPlayers.firstWhere((p) => p.id == eliminatedId);
            _audioQueue!.announceEliminated([eliminatedPlayer.name]);
          }
        }
      } else if (hasVulnerable) {
        if (currentGame.mode == GameMode.team) {
          final vulnerableTeams = <String, List<String>>{};
          for (final playerId in vulnerablePlayers) {
            final teamId = currentGame.playerToTeam![playerId]!;
            if (!vulnerableTeams.containsKey(teamId)) {
              vulnerableTeams[teamId] = [];
            }
          }
          for (final teamId in vulnerableTeams.keys) {
            final teamPlayerIds = currentGame.teamPlayers![teamId]!;
            final playerNames = teamPlayerIds
                .map((id) => allPlayers.firstWhere((p) => p.id == id).name)
                .toList();
            _audioQueue!.announceVulnerable(playerNames);
          }
        } else {
          for (final playerId in vulnerablePlayers) {
            final player = allPlayers.firstWhere((p) => p.id == playerId);
            _audioQueue!.announceVulnerable([player.name]);
          }
        }
      } else if (hasLowShields) {
        if (currentGame.mode == GameMode.team) {
          final lowShieldTeams = <String, List<String>>{};
          for (final playerId in lowShieldPlayers) {
            final teamId = currentGame.playerToTeam![playerId]!;
            if (!lowShieldTeams.containsKey(teamId)) {
              lowShieldTeams[teamId] = [];
            }
          }
          for (final teamId in lowShieldTeams.keys) {
            final teamPlayerIds = currentGame.teamPlayers![teamId]!;
            final playerNames = teamPlayerIds
                .map((id) => allPlayers.firstWhere((p) => p.id == id).name)
                .toList();
            _audioQueue!.announceLowShields(playerNames);
          }
        } else {
          for (final playerId in lowShieldPlayers) {
            final player = allPlayers.firstWhere((p) => p.id == playerId);
            _audioQueue!.announceLowShields([player.name]);
          }
        }
      } else if (hasTaggedOut) {
        if (currentGame.mode == GameMode.team) {
          final lostByTeam = <String, List<String>>{};
          for (final playerId in lostTaggedInPlayers) {
            final teamId = currentGame.playerToTeam![playerId]!;
            lostByTeam[teamId] ??= [];
          }
          for (final teamId in lostByTeam.keys) {
            final teamPlayerIds = currentGame.teamPlayers![teamId]!;
            final playerNames = teamPlayerIds
                .map((id) => allPlayers.firstWhere((p) => p.id == id).name)
                .toList();
            _audioQueue!.announceTaggedOut(playerNames);
          }
        } else {
          final lostNames = lostTaggedInPlayers
              .map((id) => allPlayers.firstWhere((p) => p.id == id).name)
              .toList();
          _audioQueue!.announceTaggedOut(lostNames);
        }
      } else if (hasSuccessfulTag) {
        _audioQueue!.announceSuccessfulTag();
      } else if (hasTaggedIn) {
        List<String> playerNames;
        if (currentGame.mode == GameMode.team) {
          final teamId = currentGame.playerToTeam![currentPlayer.id]!;
          final teamPlayerIds = currentGame.teamPlayers![teamId]!;
          playerNames = teamPlayerIds
              .map((id) => allPlayers.firstWhere((p) => p.id == id).name)
              .toList();
        } else {
          playerNames = [currentPlayer.name];
        }
        _audioQueue!.announceTaggedIn(playerNames);
      } else if (hasShieldGain) {
        _audioQueue!.announceShieldGained(
          currentPlayer.name,
          shieldsAfter,
          targetTagProvider.currentGame!.shieldMax,
        );
      }
    }

    // Check if turn is over (3 darts or winner)
    if (!_dartboardEmulatorController.isAutoPlaying &&
        (dartsThrown >= 3 || targetTagProvider.hasWinner)) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _audioQueue!.announceRemoveDarts();
        }
      });

      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) {
          _mockApi?.simulateTakeoutStarted();
        }
      });
    }

    setState(() {});
  }

  Map<String, dynamic>? _parseSector(String sector) {
    if (sector == 'Bull') return {'number': 50, 'multiplier': 'single'};
    if (sector == '25') return {'number': 25, 'multiplier': 'single'};
    if (sector == 'None') return null;

    final match = RegExp(r'[A-Za-z](\d+)').firstMatch(sector);
    if (match == null) return null;

    final baseNumber = int.parse(match.group(1)!);
    String multiplier = 'single';
    if (sector.startsWith('D') || sector.startsWith('d')) multiplier = 'double';
    if (sector.startsWith('T') || sector.startsWith('t')) multiplier = 'triple';

    return {'number': baseNumber, 'multiplier': multiplier};
  }

  void _handleTakeoutFinished() {
    final targetTagProvider = context.read<TargetTagProvider>();
    if (!mounted) return;

    // Check for winner first (game may be in finished state)
    if (targetTagProvider.hasWinner) {
      // Game over!
      _handleGameWon();
      return;
    }

    // Only proceed with next turn if game is still active
    if (!targetTagProvider.isGameActive) return;

    targetTagProvider.handleTakeoutFinished();

    if (!_dartboardEmulatorController.isAutoPlaying) {
      // Scroll to current player's tile if needed
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToCurrentPlayer();
        }
      });

      // Next player's turn
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _announceCurrentPlayerTurn();
        }
      });
    }

    setState(() {});
  }

  void _announceCurrentPlayerTurn() {
    final targetTagProvider = context.read<TargetTagProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final currentPlayer =
        targetTagProvider.getCurrentPlayer(playerProvider.allPlayers);
    if (currentPlayer != null) {
      _audioQueue!.announceTurn(currentPlayer.name);
    }
  }

  void _scrollToCurrentPlayer() {
    final targetTagProvider = context.read<TargetTagProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentGame = targetTagProvider.currentGame;

    if (currentGame == null || !_scrollController.hasClients) return;

    final allPlayers = playerProvider.allPlayers;
    final currentPlayer = targetTagProvider.getCurrentPlayer(allPlayers);
    if (currentPlayer == null) return;

    // Calculate current player's index in the entity list
    int currentEntityIndex = -1;

    if (currentGame.mode == GameMode.solo) {
      // Solo mode: find player index in playerIds
      currentEntityIndex = currentGame.playerIds.indexOf(currentPlayer.id);
    } else {
      // Team mode: find team index
      final teamId = currentGame.playerToTeam?[currentPlayer.id];
      if (teamId != null) {
        final teamIds = currentGame.teamPlayers!.keys.toList();
        currentEntityIndex = teamIds.indexOf(teamId);
      }
    }

    if (currentEntityIndex == -1) return;

    // Calculate which row the current player is in (5 tiles per row)
    const tilesPerRow = 5;
    final currentRow = currentEntityIndex ~/ tilesPerRow;

    // Scroll based on row
    if (currentRow >= 1) {
      // Second row or later - scroll down to show the entire tile
      // Use estimated tile height (tiles now size to content, not aspect ratio)
      const estimatedTileHeight = 400.0; // Approximate height based on content
      const rowSpacing = 20.0;

      // Scroll to show the full tile: (row height × row number) + buffer
      // Add extra buffer to ensure entire tile is visible
      final scrollOffset =
          (currentRow * (estimatedTileHeight + rowSpacing)) + 50;

      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // First row - scroll to top
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
          builder: (context) => const TargetTagResultsScreen(),
        ),
      );
    }

    if (_dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
    } else {
      final playerProvider = context.read<PlayerProvider>();
      final targetTagProvider = context.read<TargetTagProvider>();
      final winners = targetTagProvider.getWinners(playerProvider.allPlayers);
      if (winners.isNotEmpty) {
        final winnerNames = winners.map((p) => p.name).toList();
        _audioQueue!.announceWinner(winnerNames);
      }
      Future.delayed(const Duration(milliseconds: 3000), navigateToResults);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetTagProvider = context.watch<TargetTagProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final dartboardProvider = context.watch<DartboardProvider>();

    final currentGame = targetTagProvider.currentGame;
    if (currentGame == null) {
      return const Scaffold(
        body: Center(child: Text('No game in progress')),
      );
    }

    final allPlayers = playerProvider.allPlayers;
    final currentPlayer = targetTagProvider.getCurrentPlayer(allPlayers);
    final playerIds = currentGame.playerIds;
    final shouldPromptTakeout = targetTagProvider.shouldPromptTakeout;

    final hasDartsThrown =
        currentGame.totalDartsThrown.values.any((c) => c > 0);

    return PopScope(
      canPop: !hasDartsThrown || _showSaveModal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF1A1A2E),
            appBar: AppBar(
              leading: IconButton(
                key: TargetTagGameKeys.backButton,
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 32),
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
              title: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Target Tag Game On!',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 36,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              backgroundColor: const Color(0xFFFF007A), // Hot pink
              foregroundColor: Colors.white,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: DartboardConnectionInfo(
                    config: DartboardConnectionInfoConfig.targetTag(),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Tech/Neon background
                const Positioned.fill(
                  child: TechNeonBackground(),
                ),
                // Main content
                Column(
                  children: [
                    // Top panel row: Game Info + Active Player
                    if (currentPlayer != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Game Info Panel
                              SizedBox(
                                width: 240,
                                child: GameInfoPanelWidget(
                                  mode: currentGame.mode,
                                  shieldMax: currentGame.shieldMax,
                                  soloHeroBonus: currentGame.soloHeroBonus,
                                  teamAssignmentMode:
                                      null, // Will add later if needed
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Active Player Panel
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    // Get current player's target number (same for whole team in team mode)
                                    final currentPlayerTargetNumber =
                                        targetTagProvider.getTargetNumber(
                                                currentPlayer.id) ??
                                            0;

                                    // Get all opponent target numbers (excluding own team and eliminated players)
                                    final opponentNumbers = <int>[];
                                    for (final playerId
                                        in currentGame.playerIds) {
                                      if (playerId != currentPlayer.id &&
                                          !targetTagProvider
                                              .isEliminated(playerId)) {
                                        final targetNum = targetTagProvider
                                            .getTargetNumber(playerId);
                                        // In team mode, exclude teammates' target (which is the same as ours)
                                        // In solo mode, exclude our own target
                                        if (targetNum != null &&
                                            targetNum !=
                                                currentPlayerTargetNumber &&
                                            !opponentNumbers
                                                .contains(targetNum)) {
                                          opponentNumbers.add(targetNum);
                                        }
                                      }
                                    }

                                    return ActivePlayerPanelWidget(
                                      player: currentPlayer,
                                      currentShields: targetTagProvider
                                          .getShields(currentPlayer.id),
                                      shieldMax: currentGame.shieldMax,
                                      targetNumber: currentPlayerTargetNumber,
                                      soloHeroBuffNumber: targetTagProvider
                                              .isSoloHero(currentPlayer.id)
                                          ? targetTagProvider
                                              .getSoloHeroBuffNumber(
                                                  currentPlayer.id)
                                          : null,
                                      soloHeroBuffMultiplier: targetTagProvider
                                              .isSoloHero(currentPlayer.id)
                                          ? targetTagProvider
                                              .getSoloHeroBuffMultiplier(
                                                  currentPlayer.id)
                                          : null,
                                      isTaggedIn: targetTagProvider
                                          .isTaggedIn(currentPlayer.id),
                                      dartSegments:
                                          targetTagProvider.getCurrentTurnDarts(
                                              currentPlayer.id),
                                      dartTaggedInStatus: targetTagProvider
                                          .getDartThrowTaggedInStatus(
                                              currentPlayer.id),
                                      dartHeroBonusHit: targetTagProvider
                                          .getDartThrowHeroBonusHit(
                                              currentPlayer.id),
                                      dartReachedMax: targetTagProvider
                                          .getDartThrowReachedMax(
                                              currentPlayer.id),
                                      dartCausedElimination: targetTagProvider
                                          .getDartThrowCausedElimination(
                                              currentPlayer.id),
                                      dartHitOpponentTarget: targetTagProvider
                                          .getDartThrowHitOpponentTarget(
                                              currentPlayer.id),
                                      opponentTargetNumbers: opponentNumbers,
                                      onSkipTurn: () {
                                        final dartsThrown = targetTagProvider
                                            .getCurrentPlayerDartsThrown();

                                        // Skip the turn
                                        targetTagProvider.skipTurn();

                                        // If darts were thrown, show "remove darts" sequence
                                        if (dartsThrown > 0) {
                                          Future.delayed(
                                              const Duration(
                                                  milliseconds: 1500), () {
                                            if (mounted) {
                                              _audioQueue!
                                                  .announceRemoveDarts();
                                            }
                                          });
                                          Future.delayed(
                                              const Duration(
                                                  milliseconds: 3500), () {
                                            if (mounted) {
                                              _mockApi
                                                  ?.simulateTakeoutStarted();
                                            }
                                          });
                                        } else {
                                          // No darts thrown, advance directly without showing modals.
                                          Future.delayed(
                                              const Duration(milliseconds: 500),
                                              () {
                                            if (mounted) {
                                              if (_mockApi != null) {
                                                _mockApi!
                                                    .simulateTakeoutFinished();
                                              } else {
                                                _handleTakeoutFinished();
                                              }
                                            }
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Player cards grid with modal overlay
                    Expanded(
                      child: Container(
                        color: const Color(0xFF1A1A2E)
                            .withOpacity(0.0), // Transparent background
                        child: Stack(
                          children: [
                            // Use LayoutBuilder to calculate tile size, then use Wrap for centering
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final entityCount =
                                    _getEntityCount(currentGame, allPlayers);

                                // Calculate tile dimensions based on 5-column layout with full width
                                const horizontalPadding = 16.0;
                                const crossAxisSpacing = 20.0;
                                const mainAxisSpacing = 20.0;
                                const fixedCrossAxisCount = 5;

                                final availableWidth = constraints.maxWidth -
                                    (2 * horizontalPadding);
                                final totalSpacing = crossAxisSpacing *
                                    (fixedCrossAxisCount - 1);
                                final tileWidth =
                                    (availableWidth - totalSpacing) /
                                        fixedCrossAxisCount;

                                // First pass: Build tiles to measure their heights
                                final tempTiles =
                                    List.generate(entityCount, (index) {
                                  return SizedBox(
                                    width: tileWidth,
                                    child: _buildPlayerCard(
                                      context,
                                      currentGame,
                                      allPlayers,
                                      playerIds,
                                      index,
                                    ),
                                  );
                                });

                                // Use LayoutBuilder to ensure all tiles on a row have the same height
                                // by wrapping in IntrinsicHeight per row
                                final rows = <Widget>[];
                                for (int i = 0;
                                    i < tempTiles.length;
                                    i += fixedCrossAxisCount) {
                                  final rowTiles = tempTiles.sublist(
                                    i,
                                    (i + fixedCrossAxisCount)
                                        .clamp(0, tempTiles.length),
                                  );

                                  rows.add(
                                    IntrinsicHeight(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: rowTiles.map((tile) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              right: rowTiles.last == tile
                                                  ? 0
                                                  : crossAxisSpacing,
                                            ),
                                            child: tile,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: horizontalPadding),
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    child: Column(
                                      children: [
                                        for (int i = 0; i < rows.length; i++)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              bottom: i < rows.length - 1
                                                  ? mainAxisSpacing
                                                  : 0,
                                            ),
                                            child: rows[i],
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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
              config: DartboardFABConfig.targetTag(),
              onCancelAutoPlay: _onCancelAutoPlay,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
          // Outer-Stack modals — paint above Scaffold (incl. AppBar + FAB) so they
          // block ALL screen interactions while shown.
          // RemoveDartsModal sits BEHIND the emulator so DARTS REMOVED stays
          // visible/tappable on top of the takeout overlay.
          if (shouldPromptTakeout)
            RemoveDartsModal(
              config: RemoveDartsModalConfig.targetTag(),
              playerName: currentPlayer?.name ?? 'Player',
              editScoreButtonKey: TargetTagGameKeys.editScoreButton,
              onEditScore: () {
                if (currentPlayer == null) return;
                final targetTagProvider =
                    Provider.of<TargetTagProvider>(context, listen: false);
                showEditScoreDialog(
                  context: context,
                  playerName: currentPlayer.name,
                  initialSegments:
                      targetTagProvider.getCurrentTurnDarts(currentPlayer.id),
                  onSubmit: (newSegments) => targetTagProvider
                      .updateAllDartScores(currentPlayer.id, newSegments),
                  config: EditScoreDialogConfig.targetTag(),
                  dartBorderColors: _computeDartBorderColors(currentPlayer.id),
                );
              },
            ),
          // Emulator above RemoveDartsModal; below SaveGameModal.
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
              config: DartboardSectionConfig.targetTag(),
              onPlayToComplete: _mockApi != null ? _onPlayToComplete : null,
              playToCompleteConfig: _mockApi != null
                  ? PlayToCompleteButtonConfig.targetTag()
                  : null,
            ),
          ),
          // Save Game Modal
          if (_showSaveModal)
            SaveGameModal(
              config: SaveGameModalConfig.targetTag(),
              onSave: () async {
                await targetTagProvider.saveGame(allPlayers);
                if (mounted) Navigator.of(context).pop();
              },
              onDontSave: () => Navigator.of(context).pop(),
            ),
          // Dartboard Paused Modal — last child, paints on top.
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status != DartboardConnectionStatus.connected &&
              dartboardProvider.status != DartboardConnectionStatus.emulator)
            DartboardPausedModal(
              config: DartboardPausedModalConfig.targetTag(),
            ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  int _getEntityCount(dynamic game, List<Player> allPlayers) {
    if (game.mode.toString().contains('solo')) {
      return game.playerIds.length;
    } else {
      return game.teamPlayers.keys.length;
    }
  }

  Widget _buildPlayerCard(
    BuildContext context,
    dynamic game,
    List<Player> allPlayers,
    List<String> playerIds,
    int index,
  ) {
    final targetTagProvider = context.read<TargetTagProvider>();

    final currentPlayerId = targetTagProvider.getCurrentPlayerId();

    if (game.mode.toString().contains('solo')) {
      // Solo mode: one card per player
      final playerId = playerIds[index];
      final player = allPlayers.firstWhere((p) => p.id == playerId);
      final isCurrentPlayer = playerId == currentPlayerId;

      return PlayerCardWidget(
        player: player,
        currentShields: targetTagProvider.getShields(playerId),
        shieldMax: game.shieldMax,
        targetNumber: targetTagProvider.getTargetNumber(playerId) ?? 0,
        soloHeroBuffNumber: targetTagProvider.isSoloHero(playerId)
            ? targetTagProvider.getSoloHeroBuffNumber(playerId)
            : null,
        soloHeroBuffMultiplier: targetTagProvider.isSoloHero(playerId)
            ? targetTagProvider.getSoloHeroBuffMultiplier(playerId)
            : null,
        isTaggedIn: targetTagProvider.isTaggedIn(playerId),
        isEliminated: targetTagProvider.isEliminated(playerId),
        isCurrentPlayer: isCurrentPlayer,
        isTeamMode: false,
      );
    } else {
      // Team mode: one card per team
      final teamIds = game.teamPlayers.keys.toList();
      if (index >= teamIds.length) return const SizedBox();

      final teamId = teamIds[index];
      final teamPlayerIds = targetTagProvider.getTeamPlayers(teamId) ?? [];

      // Sort team players by their turn order (order in playerIds list)
      final teamPlayers =
          allPlayers.where((p) => teamPlayerIds.contains(p.id)).toList()
            ..sort((a, b) {
              final aIndex = playerIds.indexOf(a.id);
              final bIndex = playerIds.indexOf(b.id);
              return aIndex.compareTo(bIndex);
            });

      if (teamPlayers.isEmpty) return const SizedBox();

      final firstPlayer = teamPlayers.first;
      final isCurrentPlayer = teamPlayerIds.contains(currentPlayerId);

      return PlayerCardWidget(
        player: firstPlayer,
        currentShields: targetTagProvider.getShields(teamPlayerIds.first),
        shieldMax: game.shieldMax,
        targetNumber:
            targetTagProvider.getTargetNumber(teamPlayerIds.first) ?? 0,
        soloHeroBuffNumber: targetTagProvider.isSoloHero(teamPlayerIds.first)
            ? targetTagProvider.getSoloHeroBuffNumber(teamPlayerIds.first)
            : null,
        soloHeroBuffMultiplier: targetTagProvider
                .isSoloHero(teamPlayerIds.first)
            ? targetTagProvider.getSoloHeroBuffMultiplier(teamPlayerIds.first)
            : null,
        isTaggedIn: targetTagProvider.isTaggedIn(teamPlayerIds.first),
        isEliminated: targetTagProvider.isEliminated(teamPlayerIds.first),
        isCurrentPlayer: isCurrentPlayer,
        isTeamMode: true,
        teamIconPath: targetTagProvider.getTeamIcon(teamId),
        teamMembers: teamPlayers,
      );
    }
  }

  /// Computes per-dart score box border colors for the edit score dialog.
  /// Returns a list of 3 colors (one per dart), where null means use the
  /// config default (shown for unthrown darts).
  List<Color?> _computeDartBorderColors(String playerId) {
    final targetTagProvider =
        Provider.of<TargetTagProvider>(context, listen: false);
    final dartSegments = targetTagProvider.getCurrentTurnDarts(playerId);
    final dartHeroBonusHit =
        targetTagProvider.getDartThrowHeroBonusHit(playerId);
    final dartReachedMax = targetTagProvider.getDartThrowReachedMax(playerId);
    final dartCausedElimination =
        targetTagProvider.getDartThrowCausedElimination(playerId);
    final dartTaggedInStatus =
        targetTagProvider.getDartThrowTaggedInStatus(playerId);
    final dartHitOpponentTarget =
        targetTagProvider.getDartThrowHitOpponentTarget(playerId);
    final targetNumber = targetTagProvider.getTargetNumber(playerId) ?? 0;

    return List.generate(3, (dartIndex) {
      final segment =
          dartIndex < dartSegments.length ? dartSegments[dartIndex] : '';
      if (segment.isEmpty) return null;

      if (dartIndex < dartHeroBonusHit.length && dartHeroBonusHit[dartIndex]) {
        return const Color(0xFFFFD700); // Gold for hero bonus
      } else if (dartIndex < dartReachedMax.length &&
          dartReachedMax[dartIndex]) {
        return const Color(0xFF00FFA3); // Green for reaching max
      } else if (dartIndex < dartCausedElimination.length &&
          dartCausedElimination[dartIndex]) {
        return const Color(0xFFFFD700); // Gold for elimination
      } else {
        final hitNumber = _parseSegmentNumber(segment);
        if (hitNumber == null) {
          return const Color(0xFFFF007A); // Pink for miss
        } else {
          final wasTaggedIn = dartIndex < dartTaggedInStatus.length
              ? dartTaggedInStatus[dartIndex]
              : false;
          if (!wasTaggedIn) {
            return hitNumber == targetNumber
                ? const Color(0xFF00FFA3)
                : const Color(0xFFFF007A);
          } else {
            if (hitNumber == targetNumber) {
              return const Color(0xFFFF007A);
            } else if (dartIndex < dartHitOpponentTarget.length &&
                dartHitOpponentTarget[dartIndex]) {
              return const Color(0xFFFFD700);
            } else {
              return const Color(0xFFFF007A);
            }
          }
        }
      }
    });
  }

  int? _parseSegmentNumber(String segment) {
    if (segment.isEmpty || segment == 'Miss') return null;
    final numberStr = segment.replaceAll(RegExp(r'[SDTsdt]'), '');
    return int.tryParse(numberStr);
  }
}
