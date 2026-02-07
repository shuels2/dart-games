import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/player.dart';
import '../../../models/target_tag_game.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/target_tag_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/target_tag_audio_queue_service.dart';
import '../../../widgets/target_tag/active_player_panel_widget.dart';
import '../../../widgets/target_tag/game_info_panel_widget.dart';
import '../../../widgets/target_tag/player_card_widget.dart';
import '../../../widgets/target_tag/tech_neon_background.dart';
import '../../../widgets/interactive_dartboard.dart';
import 'target_tag_results_screen.dart';

class TargetTagGameScreen extends StatefulWidget {
  const TargetTagGameScreen({super.key});

  @override
  State<TargetTagGameScreen> createState() => _TargetTagGameScreenState();
}

class _TargetTagGameScreenState extends State<TargetTagGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  TargetTagAudioQueueService? _audioQueue;
  final ScrollController _scrollController = ScrollController();

  bool _hasAnnouncedSuddenDeath = false;
  bool _showDartboard = true; // Controls dartboard emulator visibility

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

    // Initialize audio queue
    _audioQueue = TargetTagAudioQueueService();
    await _audioQueue!.loadSettings();

    // Subscribe to dartboard events
    if (_mockApi != null) {
      _dartboardSubscription = _mockApi!.eventStream.listen((event) {
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
    _dartboardSubscription?.cancel();
    _audioQueue?.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final hitOpponentTargetList = targetTagProvider.getDartThrowHitOpponentTarget(currentPlayer.id);
    final heroBonusHitList = targetTagProvider.getDartThrowHeroBonusHit(currentPlayer.id);

    final didHitOpponentTarget = dartIndex >= 0 && dartIndex < hitOpponentTargetList.length ? hitOpponentTargetList[dartIndex] : false;
    final didHitHeroBonus = dartIndex >= 0 && dartIndex < heroBonusHitList.length ? heroBonusHitList[dartIndex] : false;

    // Parse sector for announcement
    final parsed = _parseSector(sector);
    final isMiss = sector == 'None' || parsed == null;

    // ===== ANNOUNCEMENT ORDER =====

    // 1. Dart score announcement
    if (!isMiss && parsed != null) {
      _audioQueue!.announceHit(
        parsed['number'] as int,
        parsed['multiplier'] as String,
      );
    } else {
      _audioQueue!.announceHit(0, 'single', isMiss: true);
    }

    // 2. Shield status announcements
    if (shieldsAfter > shieldsBefore) {
      // Gained shields
      if (isNowTaggedIn && !wasTaggedIn) {
        // Just reached Tagged In!
        // Get all player names for the announcement
        List<String> playerNames;
        if (currentGame.mode == GameMode.team) {
          // Team mode: announce all team members
          final teamId = currentGame.playerToTeam![currentPlayer.id]!;
          final teamPlayerIds = currentGame.teamPlayers![teamId]!;
          playerNames = teamPlayerIds
              .map((id) => allPlayers.firstWhere((p) => p.id == id).name)
              .toList();
        } else {
          // Solo mode: announce just the current player
          playerNames = [currentPlayer.name];
        }
        _audioQueue!.announceTaggedIn(playerNames);
      } else if (!wasTaggedIn) {
        // Only announce shield count if not already at max shields before this throw
        _audioQueue!.announceShieldGained(
          currentPlayer.name,
          shieldsAfter,
          targetTagProvider.currentGame!.shieldMax,
        );
      }
    }

    // 3. "Tag! Got 'em!" - if hit opponent's target or own hero bonus while tagged-in
    if (wasTaggedIn && (didHitOpponentTarget || didHitHeroBonus)) {
      _audioQueue!.announceSuccessfulTag();
    }

    // 4. "Shield compromised!" - lost tagged-in status
    if (wasTaggedIn && !isNowTaggedIn && shieldsAfter < shieldsBefore) {
      // Get all player names for the announcement
      List<String> playerNames;
      if (currentGame.mode == GameMode.team) {
        // Team mode: announce all team members
        final teamId = currentGame.playerToTeam![currentPlayer.id]!;
        final teamPlayerIds = currentGame.teamPlayers![teamId]!;
        playerNames = teamPlayerIds
            .map((id) => allPlayers.firstWhere((p) => p.id == id).name)
            .toList();
      } else {
        // Solo mode: announce just the current player
        playerNames = [currentPlayer.name];
      }
      _audioQueue!.announceTaggedOut(playerNames);
    }

    // 5. "Warning!" - for each opponent who dropped to 1 shield
    // Only announce if at least one player/team is tagged-in
    final anyoneTaggedIn = currentGame.playerIds.any((id) => targetTagProvider.isTaggedIn(id));
    if (anyoneTaggedIn && wasTaggedIn && (didHitOpponentTarget || didHitHeroBonus)) {
      if (currentGame.mode == GameMode.team) {
        // Team mode: group low shield warnings by team
        final lowShieldTeams = <String, List<String>>{};
        for (final playerId in currentGame.playerIds) {
          if (playerId == currentPlayer.id) continue; // Skip current player

          final shieldsBeforeThis = allShieldsBefore[playerId] ?? 0;
          final shieldsAfterThis = targetTagProvider.getShields(playerId);

          // Check if this opponent dropped to exactly 1 shield
          if (shieldsBeforeThis > 1 && shieldsAfterThis == 1) {
            final teamId = currentGame.playerToTeam![playerId]!;
            if (!lowShieldTeams.containsKey(teamId)) {
              lowShieldTeams[teamId] = [];
            }
            final player = allPlayers.firstWhere((p) => p.id == playerId);
            lowShieldTeams[teamId]!.add(player.name);
          }
        }
        // Announce each team with low shields
        for (final playerNames in lowShieldTeams.values) {
          _audioQueue!.announceLowShields(playerNames);
        }
      } else {
        // Solo mode: announce each player individually
        for (final playerId in currentGame.playerIds) {
          if (playerId == currentPlayer.id) continue; // Skip current player

          final shieldsBeforeThis = allShieldsBefore[playerId] ?? 0;
          final shieldsAfterThis = targetTagProvider.getShields(playerId);

          // Check if this opponent dropped to exactly 1 shield
          if (shieldsBeforeThis > 1 && shieldsAfterThis == 1) {
            final player = allPlayers.firstWhere((p) => p.id == playerId);
            _audioQueue!.announceLowShields([player.name]);
          }
        }
      }
    }

    // 6. "Tagged Out!" - eliminations
    final newlyEliminated = eliminatedAfter.difference(eliminatedBefore);
    if (newlyEliminated.isNotEmpty) {
      if (currentGame.mode == GameMode.team) {
        // Team mode: group eliminated players by team and announce teams together
        final eliminatedTeams = <String, List<String>>{};
        for (final eliminatedId in newlyEliminated) {
          final teamId = currentGame.playerToTeam![eliminatedId]!;
          if (!eliminatedTeams.containsKey(teamId)) {
            eliminatedTeams[teamId] = [];
          }
          final player = allPlayers.firstWhere((p) => p.id == eliminatedId);
          eliminatedTeams[teamId]!.add(player.name);
        }
        // Announce each eliminated team
        for (final playerNames in eliminatedTeams.values) {
          _audioQueue!.announceEliminated(playerNames);
        }
      } else {
        // Solo mode: announce each eliminated player individually
        for (final eliminatedId in newlyEliminated) {
          final eliminatedPlayer = allPlayers.firstWhere((p) => p.id == eliminatedId);
          _audioQueue!.announceEliminated([eliminatedPlayer.name]);
        }
      }
    }

    // Check if turn is over (3 darts or winner)
    if (dartsThrown >= 3 || targetTagProvider.hasWinner) {
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

    setState(() {});
  }

  void _announceCurrentPlayerTurn() {
    final targetTagProvider = context.read<TargetTagProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final currentPlayer = targetTagProvider.getCurrentPlayer(playerProvider.allPlayers);
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
      final scrollOffset = (currentRow * (estimatedTileHeight + rowSpacing)) + 50;

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
    final playerProvider = context.read<PlayerProvider>();
    final targetTagProvider = context.read<TargetTagProvider>();
    final winners = targetTagProvider.getWinners(playerProvider.allPlayers);

    if (winners.isNotEmpty) {
      final winnerNames = winners.map((p) => p.name).toList();
      _audioQueue!.announceWinner(winnerNames);
    }

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TargetTagResultsScreen(),
        ),
      );
    });
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

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
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
                        teamAssignmentMode: null, // Will add later if needed
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Active Player Panel
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          // Get current player's target number (same for whole team in team mode)
                          final currentPlayerTargetNumber = targetTagProvider.getTargetNumber(currentPlayer.id) ?? 0;

                          // Get all opponent target numbers (excluding own team and eliminated players)
                          final opponentNumbers = <int>[];
                          for (final playerId in currentGame.playerIds) {
                            if (playerId != currentPlayer.id && !targetTagProvider.isEliminated(playerId)) {
                              final targetNum = targetTagProvider.getTargetNumber(playerId);
                              // In team mode, exclude teammates' target (which is the same as ours)
                              // In solo mode, exclude our own target
                              if (targetNum != null &&
                                  targetNum != currentPlayerTargetNumber &&
                                  !opponentNumbers.contains(targetNum)) {
                                opponentNumbers.add(targetNum);
                              }
                            }
                          }

                          return ActivePlayerPanelWidget(
                            player: currentPlayer,
                            currentShields: targetTagProvider.getShields(currentPlayer.id),
                            shieldMax: currentGame.shieldMax,
                            targetNumber: currentPlayerTargetNumber,
                            soloHeroBuffNumber: targetTagProvider.isSoloHero(currentPlayer.id)
                                ? targetTagProvider.getSoloHeroBuffNumber(currentPlayer.id)
                                : null,
                            soloHeroBuffMultiplier: targetTagProvider.isSoloHero(currentPlayer.id)
                                ? targetTagProvider.getSoloHeroBuffMultiplier(currentPlayer.id)
                                : null,
                            isTaggedIn: targetTagProvider.isTaggedIn(currentPlayer.id),
                            dartSegments: targetTagProvider.getCurrentTurnDarts(currentPlayer.id),
                            dartTaggedInStatus: targetTagProvider.getDartThrowTaggedInStatus(currentPlayer.id),
                            dartHeroBonusHit: targetTagProvider.getDartThrowHeroBonusHit(currentPlayer.id),
                            dartReachedMax: targetTagProvider.getDartThrowReachedMax(currentPlayer.id),
                            dartCausedElimination: targetTagProvider.getDartThrowCausedElimination(currentPlayer.id),
                            dartHitOpponentTarget: targetTagProvider.getDartThrowHitOpponentTarget(currentPlayer.id),
                            opponentTargetNumbers: opponentNumbers,
                            onSkipTurn: () {
                              final dartsThrown = targetTagProvider.getCurrentPlayerDartsThrown();

                              // Skip the turn
                              targetTagProvider.skipTurn();

                              // If darts were thrown, show "remove darts" sequence
                              if (dartsThrown > 0) {
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
                              } else {
                                // No darts thrown, advance directly without showing modals
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  if (mounted) {
                                    _mockApi?.simulateTakeoutFinished();
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
              color: const Color(0xFF1A1A2E).withOpacity(0.0), // Transparent background
              child: Stack(
                children: [
                  // Use LayoutBuilder to calculate tile size, then use Wrap for centering
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final entityCount = _getEntityCount(currentGame, allPlayers);

                      // Calculate tile dimensions based on 5-column layout with full width
                      const horizontalPadding = 16.0;
                      const crossAxisSpacing = 20.0;
                      const mainAxisSpacing = 20.0;
                      const fixedCrossAxisCount = 5;

                      final availableWidth = constraints.maxWidth - (2 * horizontalPadding);
                      final totalSpacing = crossAxisSpacing * (fixedCrossAxisCount - 1);
                      final tileWidth = (availableWidth - totalSpacing) / fixedCrossAxisCount;

                      // First pass: Build tiles to measure their heights
                      final tempTiles = List.generate(entityCount, (index) {
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
                      for (int i = 0; i < tempTiles.length; i += fixedCrossAxisCount) {
                        final rowTiles = tempTiles.sublist(
                          i,
                          (i + fixedCrossAxisCount).clamp(0, tempTiles.length),
                        );

                        rows.add(
                          IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: rowTiles.map((tile) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: rowTiles.last == tile ? 0 : crossAxisSpacing,
                                  ),
                                  child: tile,
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              for (int i = 0; i < rows.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i < rows.length - 1 ? mainAxisSpacing : 0,
                                  ),
                                  child: rows[i],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Modal overlay for remove darts prompt
                  if (shouldPromptTakeout && !dartboardProvider.isConnected)
                    _buildRemoveDartsModal(currentPlayer),
                ],
              ),
            ),
          ),

          // Dartboard emulator (if not connected and visible)
          if (!dartboardProvider.isConnected && _showDartboard)
            _buildDartboardSection(shouldPromptTakeout, currentPlayer),
            ],
          ),
        ],
      ),
      // Floating button to toggle dartboard visibility (only show when not connected)
      floatingActionButton: !dartboardProvider.isConnected
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _showDartboard = !_showDartboard;
                });
              },
              backgroundColor: const Color(0xFFFF007A),
              icon: Icon(_showDartboard ? Icons.visibility_off : Icons.visibility),
              label: Text(
                _showDartboard ? 'Hide Dartboard' : 'Show Dartboard',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
      final teamPlayers = allPlayers
          .where((p) => teamPlayerIds.contains(p.id))
          .toList()
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
        targetNumber: targetTagProvider.getTargetNumber(teamPlayerIds.first) ?? 0,
        soloHeroBuffNumber: targetTagProvider.isSoloHero(teamPlayerIds.first)
            ? targetTagProvider.getSoloHeroBuffNumber(teamPlayerIds.first)
            : null,
        soloHeroBuffMultiplier: targetTagProvider.isSoloHero(teamPlayerIds.first)
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

  Widget _buildRemoveDartsModal(Player? currentPlayer) {
    final playerName = currentPlayer?.name ?? 'Player';

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.95), // Dark navy
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF007A), // Hot pink border
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pan_tool,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  playerName,
                  style: GoogleFonts.luckiestGuy(
                    color: const Color(0xFFFF007A), // Hot pink
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Remove Your Darts',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _showEditScoreModal(currentPlayer);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF007A).withOpacity(0.85),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Edit player score',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  void _showEditScoreModal(Player? currentPlayer) {
    if (currentPlayer == null) return;

    final targetTagProvider = Provider.of<TargetTagProvider>(context, listen: false);
    final dartSegments = targetTagProvider.getCurrentTurnDarts(currentPlayer.id);

    // Parse current scores for each dart
    final dart1Score = _parseScore(0 < dartSegments.length ? dartSegments[0] : '');
    final dart2Score = _parseScore(1 < dartSegments.length ? dartSegments[1] : '');
    final dart3Score = _parseScore(2 < dartSegments.length ? dartSegments[2] : '');

    Map<int, String?> selectedRings = {
      0: dart1Score['ring'],
      1: dart2Score['ring'],
      2: dart3Score['ring'],
    };

    Map<int, int?> selectedNumbers = {
      0: dart1Score['number'],
      1: dart2Score['number'],
      2: dart3Score['number'],
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Check if all darts have valid selections
            bool isValidSelection = true;
            for (int i = 0; i < 3; i++) {
              final ring = selectedRings[i];
              final number = selectedNumbers[i];

              if (ring == null) {
                isValidSelection = false;
                break;
              }

              // If ring requires a number, check that number is selected
              if (ring == 'Single (inner)' || ring == 'Single (outer)' ||
                  ring == 'Double' || ring == 'Triple') {
                if (number == null) {
                  isValidSelection = false;
                  break;
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF007A),
                    width: 4,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'Edit ${currentPlayer.name}\'s score',
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Three columns - one for each dart
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(3, (dartIndex) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: dartIndex == 0 ? 0 : 8,
                                right: dartIndex == 2 ? 0 : 8,
                              ),
                              child: _buildDartScoreSection(
                                dartIndex,
                                dartSegments,
                                selectedRings,
                                selectedNumbers,
                                setState,
                                targetTagProvider,
                                currentPlayer.id,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.85),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: isValidSelection
                                ? () {
                                    // Build all three dart segments
                                    final newDartSegments = <String>[];
                                    for (int i = 0; i < 3; i++) {
                                      final ring = selectedRings[i]!;
                                      final number = selectedNumbers[i];

                                      String sector;
                                      if (ring == 'Bullseye') {
                                        sector = 'Bull';
                                      } else if (ring == 'Outer Bull') {
                                        sector = '25';
                                      } else if (ring == 'Miss') {
                                        sector = 'Miss';
                                      } else {
                                        // Single (outer), Single (inner), Double, Triple
                                        final prefix = ring == 'Double' ? 'D' : ring == 'Triple' ? 'T' : 'S';
                                        sector = '$prefix$number';
                                      }
                                      newDartSegments.add(sector);
                                    }

                                    // Update all three darts at once (processes in order)
                                    targetTagProvider.updateAllDartScores(
                                      currentPlayer.id,
                                      newDartSegments,
                                    );
                                    Navigator.of(dialogContext).pop();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF007A).withOpacity(0.85),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                              disabledForegroundColor: Colors.white38,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Update score',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _parseScore(String segment) {
    if (segment.isEmpty || segment == '-') {
      return {'ring': null, 'number': null};
    } else if (segment == 'Miss') {
      return {'ring': 'Miss', 'number': null};
    } else if (segment == 'Bull') {
      return {'ring': 'Bullseye', 'number': null};
    } else if (segment == '25') {
      return {'ring': 'Outer Bull', 'number': null};
    } else {
      // Parse D20, T19, S18 format
      final match = RegExp(r'([SDTsdt])(\d+)').firstMatch(segment);
      if (match != null) {
        final prefix = match.group(1)!.toUpperCase();
        final number = int.parse(match.group(2)!);

        String ring;
        if (prefix == 'D') {
          ring = 'Double';
        } else if (prefix == 'T') {
          ring = 'Triple';
        } else {
          // S - default to outer
          ring = 'Single (outer)';
        }
        return {'ring': ring, 'number': number};
      }
    }
    return {'ring': null, 'number': null};
  }

  Widget _buildDartScoreSection(
    int dartIndex,
    List<String> dartSegments,
    Map<int, String?> selectedRings,
    Map<int, int?> selectedNumbers,
    StateSetter setState,
    TargetTagProvider targetTagProvider,
    String playerId,
  ) {
    final segment = dartIndex < dartSegments.length ? dartSegments[dartIndex] : '';
    final dartTaggedInStatus = targetTagProvider.getDartThrowTaggedInStatus(playerId);
    final dartHeroBonusHit = targetTagProvider.getDartThrowHeroBonusHit(playerId);
    final dartReachedMax = targetTagProvider.getDartThrowReachedMax(playerId);
    final dartCausedElimination = targetTagProvider.getDartThrowCausedElimination(playerId);
    final dartHitOpponentTarget = targetTagProvider.getDartThrowHitOpponentTarget(playerId);
    final targetNumber = targetTagProvider.getTargetNumber(playerId) ?? 0;

    Color borderColor = Colors.white38;
    if (dartIndex < dartSegments.length && segment.isNotEmpty) {
      // Use same logic as active player panel for highlighting
      if (dartIndex < dartHeroBonusHit.length && dartHeroBonusHit[dartIndex]) {
        borderColor = const Color(0xFFFFD700); // Gold for hero bonus
      } else if (dartIndex < dartReachedMax.length && dartReachedMax[dartIndex]) {
        borderColor = const Color(0xFF00FFA3); // Green for reaching max
      } else if (dartIndex < dartCausedElimination.length && dartCausedElimination[dartIndex]) {
        borderColor = const Color(0xFFFFD700); // Gold for elimination
      } else {
        final hitNumber = _parseSegmentNumber(segment);
        if (hitNumber == null) {
          borderColor = const Color(0xFFFF007A); // Pink for miss
        } else {
          final wasTaggedIn = dartIndex < dartTaggedInStatus.length ? dartTaggedInStatus[dartIndex] : false;
          if (!wasTaggedIn) {
            borderColor = hitNumber == targetNumber ? const Color(0xFF00FFA3) : const Color(0xFFFF007A);
          } else {
            if (hitNumber == targetNumber) {
              borderColor = const Color(0xFFFF007A);
            } else if (dartIndex < dartHitOpponentTarget.length && dartHitOpponentTarget[dartIndex]) {
              borderColor = const Color(0xFFFFD700);
            } else {
              borderColor = const Color(0xFFFF007A);
            }
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dart label and score box
        Text(
          'D${dartIndex + 1}',
          style: GoogleFonts.fredoka(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              segment.isEmpty ? '-' : segment,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: segment.isEmpty ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Ring buttons
        _buildSmallRingButton('Single (inner)', selectedRings[dartIndex], (ring) {
          setState(() {
            selectedRings[dartIndex] = ring;
          });
        }),
        const SizedBox(height: 6),
        _buildSmallRingButton('Single (outer)', selectedRings[dartIndex], (ring) {
          setState(() {
            selectedRings[dartIndex] = ring;
          });
        }),
        const SizedBox(height: 6),
        _buildSmallRingButton('Double', selectedRings[dartIndex], (ring) {
          setState(() {
            selectedRings[dartIndex] = ring;
          });
        }),
        const SizedBox(height: 6),
        _buildSmallRingButton('Triple', selectedRings[dartIndex], (ring) {
          setState(() {
            selectedRings[dartIndex] = ring;
          });
        }),
        const SizedBox(height: 12),

        // Number grid - 4 rows x 5 columns
        ...List.generate(4, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (colIndex) {
                final num = rowIndex * 5 + colIndex + 1;
                final isSelected = selectedNumbers[dartIndex] == num;
                final isDisabled = selectedRings[dartIndex] == 'Outer Bull' ||
                                  selectedRings[dartIndex] == 'Bullseye' ||
                                  selectedRings[dartIndex] == 'Miss';

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: colIndex == 0 ? 0 : 3,
                      right: colIndex == 4 ? 0 : 3,
                    ),
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: isDisabled ? null : () {
                          setState(() {
                            selectedNumbers[dartIndex] = num;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? const Color(0xFF00FFA3)
                              : const Color(0xFF2A2A3E),
                          foregroundColor: isSelected ? Colors.black : Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          '$num',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),

        const SizedBox(height: 12),

        // Outer Bull, Bullseye, Miss buttons
        _buildSmallRingButton('Outer Bull', selectedRings[dartIndex], (ring) {
          setState(() {
            selectedRings[dartIndex] = ring;
            selectedNumbers[dartIndex] = null;
          });
        }),
        const SizedBox(height: 6),
        _buildSmallRingButton('Bullseye', selectedRings[dartIndex], (ring) {
          setState(() {
            selectedRings[dartIndex] = ring;
            selectedNumbers[dartIndex] = null;
          });
        }),
        const SizedBox(height: 6),
        _buildSmallRingButton('Miss', selectedRings[dartIndex], (ring) {
          setState(() {
            selectedRings[dartIndex] = ring;
            selectedNumbers[dartIndex] = null;
          });
        }),
      ],
    );
  }

  Widget _buildSmallRingButton(String ring, String? currentRing, Function(String) onSelect) {
    final isSelected = currentRing == ring;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          onSelect(ring);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFF00FFA3)
              : const Color(0xFF2A2A3E),
          foregroundColor: isSelected ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          ring,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  int? _parseSegmentNumber(String segment) {
    if (segment.isEmpty || segment == 'Miss') return null;
    final numberStr = segment.replaceAll(RegExp(r'[SDTsdt]'), '');
    return int.tryParse(numberStr);
  }

  Widget _buildDartboardSection(bool disabled, Player? currentPlayer) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AbsorbPointer(
            absorbing: disabled,
            child: Opacity(
              opacity: disabled ? 0.5 : 1.0,
              child: InteractiveDartboard(
                key: _dartboardKey,
                size: 250,
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
                  // This is called when dartboard is cleared
                },
              ),
            ),
          ),
          // Button modal over dartboard for removing darts
          if (disabled)
            _buildDartboardButtonModal(),
        ],
      ),
    );
  }

  Widget _buildDartboardButtonModal() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.9), // Dark navy
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFF007A), // Hot pink border
          width: 3,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pan_tool,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Remove Your Darts',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Simulate takeout finished
                _mockApi?.simulateTakeoutFinished();
                // Also clear the dartboard visually
                _dartboardKey.currentState?.removeDarts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF007A), // Hot pink
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                side: const BorderSide(
                  color: Color(0xFF00FFA3), // Neon green border
                  width: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'DARTS REMOVED',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
