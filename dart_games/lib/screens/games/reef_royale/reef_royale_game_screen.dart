import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../models/reef_royale_game.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/reef_royale_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/reef_royale_announcement_helper.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/edit_score/edit_score.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import 'reef_royale_results_screen.dart';

class ReefRoyaleGameScreen extends StatefulWidget {
  const ReefRoyaleGameScreen({super.key});

  @override
  State<ReefRoyaleGameScreen> createState() => _ReefRoyaleGameScreenState();
}

class _ReefRoyaleGameScreenState extends State<ReefRoyaleGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  ReefRoyaleAnnouncementHelper? _audioQueue;
  final DartboardEmulatorController _dartboardEmulatorController = DartboardEmulatorController();
  bool _gameCompleted = false;

  // Reef Royale color palette
  static const _deepReefBlue = Color(0xFF0B3D91);
  static const _seafoamGreen = Color(0xFF48D1CC);
  static const _sunlitAqua = Color(0xFF00CED1);
  static const _pearlWhite = Color(0xFFFFF8F0);
  static const _sandyGold = Color(0xFFF4D03F);
  static const _coralPink = Color(0xFFFF6B6B);
  static const _biolumPurple = Color(0xFF9B59B6);

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

    // Initialize audio
    final globalQueue = GameAnnouncementQueueService();
    await globalQueue.loadSettings();
    _audioQueue = ReefRoyaleAnnouncementHelper(globalQueue);

    if (_mockApi != null) {
      _dartboardSubscription = _mockApi!.eventStream.listen((event) {
        _handleDartboardEvent(event);
      });
    }

    // Announce game start
    final reefProvider = context.read<ReefRoyaleProvider>();
    _audioQueue!.announceGameStart();

    if (reefProvider.currentGame?.randomReefs ?? false) {
      _audioQueue!.announceRandomReefs();
    }

    // Announce first player turn
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _announceCurrentPlayerTurn();
    });
  }

  @override
  void dispose() {
    _dartboardSubscription?.cancel();
    _audioQueue?.dispose();
    _dartboardEmulatorController.dispose();
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
    final reefProvider = context.read<ReefRoyaleProvider>();
    if (!mounted || !reefProvider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;

    // Capture player ID before processing
    final playerId = reefProvider.getCurrentPlayerId()!;

    reefProvider.processDartThrow(sector);

    // Announce dart result
    _announceDartResult(reefProvider, playerId, sector);

    final dartsThrown = reefProvider.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3 || reefProvider.hasWinner) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _audioQueue?.announceRemoveDarts();
      });
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) _mockApi?.simulateTakeoutStarted();
      });
    }

    setState(() {});
  }

  void _handleTakeoutFinished() {
    final reefProvider = context.read<ReefRoyaleProvider>();
    if (!mounted) return;

    if (reefProvider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!reefProvider.isGameActive) return;

    // Capture buff before advancing
    final buffBefore = reefProvider.getActiveBuff();

    reefProvider.handleTakeoutFinished();

    // Check for buff change (new round)
    final buffAfter = reefProvider.getActiveBuff();
    if (buffAfter != null && buffAfter != buffBefore) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _audioQueue?.announceBuff(buffAfter);
      });
    }

    if (reefProvider.hasWinner) {
      // Speed play end
      _audioQueue?.announceSpeedPlayEnd();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _handleGameWon();
      });
      return;
    }

    // Announce next player's turn
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _announceCurrentPlayerTurn();
    });

    setState(() {});
  }

  void _handleGameWon() {
    if (_gameCompleted) return;
    _gameCompleted = true;

    // Announce victory
    final reefProvider = context.read<ReefRoyaleProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final winnerId = reefProvider.currentGame?.winnerId;
    if (winnerId != null) {
      final winner = playerProvider.allPlayers.firstWhere((p) => p.id == winnerId);
      _audioQueue?.announceVictory(winner.name);
    }

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReefRoyaleResultsScreen()),
      );
    });
  }

  void _announceDartResult(ReefRoyaleProvider provider, String playerId, String sector) {
    if (_audioQueue == null) return;
    final currentGame = provider.currentGame;
    if (currentGame == null) return;

    final dartIndex = provider.getCurrentPlayerDartsThrown() - 1;
    if (dartIndex < 0) return;

    final targetList = provider.getDartThrowTargetNumber(playerId);
    final target = dartIndex < targetList.length ? targetList[dartIndex] : null;

    // Miss or non-target
    if (target == null) {
      if (sector == 'None' || sector.isEmpty) {
        _audioQueue!.announceMiss();
      } else {
        _audioQueue!.announceNonTarget();
      }
      return;
    }

    // Valid target hit - check what happened
    final claimedList = provider.getDartThrowClaimedCoral(playerId);
    final lockedList = provider.getDartThrowLockedReef(playerId);
    final pearlsList = provider.getDartThrowPearlsScored(playerId);
    final marksAddedList = provider.getDartThrowMarksAdded(playerId);
    final isNeighborList = provider.getDartThrowIsNeighbor(playerId);
    final recipientList = provider.getDartThrowPearlRecipientId(playerId);

    final justClaimed = dartIndex < claimedList.length && claimedList[dartIndex];
    final justLocked = dartIndex < lockedList.length && lockedList[dartIndex];
    final pearlsScored = dartIndex < pearlsList.length ? pearlsList[dartIndex] : 0;
    final marksAdded = dartIndex < marksAddedList.length ? marksAddedList[dartIndex] : 0;
    final isNeighbor = dartIndex < isNeighborList.length && isNeighborList[dartIndex];
    final recipientId = dartIndex < recipientList.length ? recipientList[dartIndex] : null;

    // Locked target - no announcement
    if (marksAdded == 0 && !justClaimed && pearlsScored == 0) return;

    final coralName = currentGame.getCoralDisplayName(target);
    final playerProvider = context.read<PlayerProvider>();
    final playerName = playerProvider.allPlayers.firstWhere((p) => p.id == playerId).name;

    // Priority: claim > lock > score > mark (max 2 per dart)
    int count = 0;

    if (justClaimed && count < 2) {
      _audioQueue!.announceCoralClaimed(playerName, coralName);
      count++;
    }

    if (justLocked && count < 2) {
      _audioQueue!.announceReefLocked(coralName);
      count++;
    }

    if (pearlsScored > 0 && count < 2) {
      if (currentGame.gameMode == ReefRoyaleGameMode.cursedTide && recipientId != null) {
        final opponentName = playerProvider.allPlayers.firstWhere((p) => p.id == recipientId).name;
        _audioQueue!.announceCursedScoring(pearlsScored, opponentName);
      } else {
        _audioQueue!.announceScoring(playerName, pearlsScored);
      }
      count++;
    }

    if (!justClaimed && count < 2 && marksAdded > 0) {
      if (isNeighbor) {
        _audioQueue!.announceNeighborMark(coralName);
      } else if (marksAdded >= 3) {
        _audioQueue!.announceTripleMark(coralName);
      } else if (marksAdded >= 2) {
        _audioQueue!.announceDoubleMark(coralName);
      } else {
        _audioQueue!.announceSingleMark(coralName);
      }
    }

    // Near victory: 6 of 7 corals claimed
    if (justClaimed && provider.getPlayerClaimedCount(playerId) == 6) {
      _audioQueue!.announceNearVictory(playerName);
    }
  }

  void _announceCurrentPlayerTurn() {
    final reefProvider = context.read<ReefRoyaleProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentPlayerId = reefProvider.getCurrentPlayerId();
    if (currentPlayerId == null) return;

    final player = playerProvider.allPlayers.firstWhere(
      (p) => p.id == currentPlayerId,
      orElse: () => playerProvider.allPlayers.first,
    );
    _audioQueue?.announceTurn(player.name);
  }

  @override
  Widget build(BuildContext context) {
    final reefProvider = context.watch<ReefRoyaleProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final dartboardProvider = context.watch<DartboardProvider>();

    final currentGame = reefProvider.currentGame;
    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No game in progress')));
    }

    final allPlayers = playerProvider.allPlayers;
    final currentPlayerId = reefProvider.getCurrentPlayerId();
    final currentPlayer = currentPlayerId != null
        ? allPlayers.firstWhere((p) => p.id == currentPlayerId, orElse: () => allPlayers.first)
        : null;
    final shouldPromptTakeout = reefProvider.shouldPromptTakeout;

    return Scaffold(
      backgroundColor: _deepReefBlue,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _pearlWhite, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reef Royale',
          style: GoogleFonts.fredoka(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _pearlWhite,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_deepReefBlue, _deepReefBlue, _seafoamGreen],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: _pearlWhite,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DartboardConnectionInfo(
              config: DartboardConnectionInfoConfig.reefRoyale(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/games/reef_royale/images/ReefRoyale-Background.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.3),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Main game area
          Positioned.fill(
            child: Column(
              children: [
                // Buff banner (if active)
                if (currentGame.bonusBuffsEnabled && currentGame.activeBuff != null)
                  _buildBuffBanner(currentGame.activeBuff!),

                // Round counter (if speed play)
                if (currentGame.speedPlayEnabled)
                  _buildRoundCounter(currentGame.currentRound, currentGame.roundLimit),

                // Game content
                Expanded(
                  child: Row(
                    children: [
                      // Active player panel (left, 200px)
                      if (currentPlayer != null)
                        SizedBox(
                          width: 200,
                          child: _buildActivePlayerPanel(currentGame, currentPlayer, reefProvider),
                        ),

                      // Coral tracker (center)
                      Expanded(
                        child: _buildCoralTracker(currentGame, reefProvider, allPlayers),
                      ),
                    ],
                  ),
                ),

                // Opponent summary bar
                _buildOpponentBar(currentGame, reefProvider, allPlayers),
              ],
            ),
          ),

          // Cursed Tide badge
          if (currentGame.gameMode == ReefRoyaleGameMode.cursedTide)
            Positioned(
              top: 8,
              right: 120,
              child: Container(
                key: ReefRoyaleGameKeys.cursedBadge,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _coralPink.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Text(
                  'CURSED',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Hint overlay (if enabled)
          if (currentGame.showHints)
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                key: ReefRoyaleGameKeys.hintOverlay,
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: _deepReefBlue.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _seafoamGreen.withOpacity(0.5)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_fixed, color: _seafoamGreen, size: 32),
                      const SizedBox(height: 4),
                      Text(
                        'Targets',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _pearlWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentGame.activeTargets
                            .map((t) => t == 25 ? 'Bull' : '$t')
                            .join(', '),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: _seafoamGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Remove darts modal
          if (shouldPromptTakeout && !dartboardProvider.isConnected)
            RemoveDartsModal(
              config: RemoveDartsModalConfig.reefRoyale(),
              playerName: currentPlayer?.name ?? 'Player',
              editScoreButtonKey: ReefRoyaleGameKeys.editScoreButton,
              onEditScore: () {
                if (currentPlayer == null) return;
                showEditScoreDialog(
                  context: context,
                  playerName: currentPlayer.name,
                  initialSegments: reefProvider.getCurrentTurnDarts(currentPlayer.id),
                  onSubmit: (newSegments) =>
                      reefProvider.updateAllDartScores(currentPlayer.id, newSegments),
                  config: EditScoreDialogConfig.reefRoyale(),
                  dartBorderColors: _computeDartBorderColors(currentPlayer.id, reefProvider),
                );
              },
            ),

          // Dartboard emulator
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DartboardEmulatorSection(
              controller: _dartboardEmulatorController,
              isConnected: dartboardProvider.isConnected,
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
              config: DartboardSectionConfig.reefRoyale(),
            ),
          ),
        ],
      ),
      floatingActionButton: DartboardEmulatorFAB(
        controller: _dartboardEmulatorController,
        isConnected: dartboardProvider.isConnected,
        config: DartboardFABConfig.reefRoyale(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBuffBanner(ReefBuff buff) {
    return Container(
      key: ReefRoyaleGameKeys.buffBanner,
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _biolumPurple.withOpacity(0.8),
            _deepReefBlue.withOpacity(0.8),
            _biolumPurple.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '${ReefRoyaleGame.getBuffDisplayName(buff)} — ${ReefRoyaleGame.getBuffDescription(buff)}',
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _sandyGold,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundCounter(int currentRound, int roundLimit) {
    return Container(
      key: ReefRoyaleGameKeys.roundCounter,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        'Round $currentRound/$roundLimit',
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _pearlWhite,
        ),
      ),
    );
  }

  Widget _buildActivePlayerPanel(ReefRoyaleGame game, Player player, ReefRoyaleProvider provider) {
    final playerId = player.id;
    final pearls = provider.getPlayerPearls(playerId);
    final claimedCount = provider.getPlayerClaimedCount(playerId);
    final imagePath = provider.getCreatureImagePath(playerId);
    final dartSegments = provider.getCurrentTurnDarts(playerId);
    final dartsThrown = provider.getCurrentPlayerDartsThrown();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _deepReefBlue.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _seafoamGreen.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Player avatar
          if (player.photoPath != null)
            CircleAvatar(
              key: ReefRoyaleGameKeys.playerAvatar,
              radius: 30,
              backgroundImage: player.photoPath!.startsWith('data:')
                  ? MemoryImage(base64Decode(player.photoPath!.split(',')[1]))
                  : NetworkImage(player.photoPath!) as ImageProvider,
            )
          else
            CircleAvatar(
              key: ReefRoyaleGameKeys.playerAvatar,
              radius: 30,
              backgroundColor: _seafoamGreen.withOpacity(0.3),
              child: const Icon(Icons.person, size: 30, color: _pearlWhite),
            ),
          const SizedBox(height: 4),

          // Player name
          Text(
            player.name,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _pearlWhite,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Creature image
          if (imagePath != null)
            Image.asset(imagePath, width: 80, height: 80, fit: BoxFit.contain),
          const SizedBox(height: 8),

          // Pearls count
          Row(
            key: ReefRoyaleGameKeys.pearlCounter,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 16, color: _sandyGold),
              const SizedBox(width: 4),
              Text(
                '$pearls',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: game.gameMode == ReefRoyaleGameMode.cursedTide
                      ? _coralPink
                      : _sandyGold,
                ),
              ),
              Text(
                ' pearls',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: _pearlWhite.withOpacity(0.7),
                ),
              ),
            ],
          ),

          // Corals count
          Row(
            key: ReefRoyaleGameKeys.coralCounter,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.park, size: 16, color: _seafoamGreen),
              const SizedBox(width: 4),
              Text(
                '$claimedCount/7',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _seafoamGreen,
                ),
              ),
              Text(
                ' corals',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: _pearlWhite.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dart indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final hasThrown = i < dartsThrown;
              final segment = i < dartSegments.length ? dartSegments[i] : null;
              final isNeighborList = provider.getDartThrowIsNeighbor(playerId);
              final isNeighbor = i < isNeighborList.length && isNeighborList[i];
              final claimedList = provider.getDartThrowClaimedCoral(playerId);
              final justClaimed = i < claimedList.length && claimedList[i];
              final pearlsList = provider.getDartThrowPearlsScored(playerId);
              final scoredPearls = i < pearlsList.length && pearlsList[i] > 0;
              final marksAddedList = provider.getDartThrowMarksAdded(playerId);
              final addedMarks = i < marksAddedList.length && marksAddedList[i] > 0;

              Color borderColor;
              if (!hasThrown) {
                borderColor = _pearlWhite.withOpacity(0.3);
              } else if (justClaimed) {
                borderColor = _sandyGold;
              } else if (scoredPearls) {
                borderColor = _sandyGold.withOpacity(0.7);
              } else if (isNeighbor) {
                borderColor = _sunlitAqua;
              } else if (addedMarks) {
                borderColor = _seafoamGreen;
              } else {
                borderColor = _coralPink.withOpacity(0.5);
              }

              return Container(
                key: ReefRoyaleGameKeys.dartIndicator(i),
                width: 50,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: hasThrown ? borderColor.withOpacity(0.25) : _deepReefBlue.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: justClaimed ? 2.5 : 1.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        segment ?? '-',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: hasThrown ? _pearlWhite : _pearlWhite.withOpacity(0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isNeighbor)
                        Text(
                          '(neighbor)',
                          style: GoogleFonts.nunito(
                            fontSize: 8,
                            color: _sunlitAqua.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const Spacer(),

          // Skip Turn button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: ReefRoyaleGameKeys.skipTurnButton,
              onPressed: () {
                final reefProvider = context.read<ReefRoyaleProvider>();
                reefProvider.skipTurn();
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _mockApi?.simulateTakeoutStarted();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _coralPink,
                foregroundColor: _pearlWhite,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Skip Turn',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoralTracker(ReefRoyaleGame game, ReefRoyaleProvider provider, List<Player> allPlayers) {
    final targets = game.activeTargets;
    // 2 rows: 4 top, 3 bottom
    final topRow = targets.length > 4 ? targets.sublist(0, 4) : targets;
    final bottomRow = targets.length > 4 ? targets.sublist(4) : <int>[];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Top row
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: topRow.map((target) => Expanded(
                child: _buildCoralCard(game, provider, target, allPlayers),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Bottom row
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: bottomRow.map((target) => Expanded(
                child: _buildCoralCard(game, provider, target, allPlayers),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoralCard(ReefRoyaleGame game, ReefRoyaleProvider provider, int target, List<Player> allPlayers) {
    final isLocked = provider.isTargetLocked(target);
    final currentPlayerId = provider.getCurrentPlayerId()!;
    final playerClaimed = provider.hasPlayerClaimed(currentPlayerId, target);
    final playerMarks = provider.getPlayerMarks(currentPlayerId, target);
    final markThreshold = game.markThreshold;
    final coralImagePath = game.getCoralImagePath(target, playerClaimed);
    final coralName = game.getCoralDisplayName(target);

    return Container(
      key: ReefRoyaleGameKeys.coralCard(target),
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withOpacity(0.3)
            : playerClaimed
                ? _seafoamGreen.withOpacity(0.15)
                : _deepReefBlue.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLocked
              ? Colors.grey
              : playerClaimed
                  ? _seafoamGreen
                  : _pearlWhite.withOpacity(0.3),
          width: playerClaimed ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Target number
          Text(
            game.getTargetDisplayName(target),
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey : _pearlWhite,
            ),
          ),

          // Coral image (fills available space)
          if (coralImagePath.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Image.asset(
                  coralImagePath,
                  fit: BoxFit.contain,
                  opacity: AlwaysStoppedAnimation(isLocked ? 0.4 : 1.0),
                ),
              ),
            ),

          // Marks display
          if (!isLocked && !playerClaimed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(markThreshold, (i) {
                return Icon(
                  i < playerMarks ? Icons.circle : Icons.circle_outlined,
                  size: 14,
                  color: i < playerMarks ? _seafoamGreen : _pearlWhite.withOpacity(0.4),
                );
              }),
            ),

          // Status
          if (isLocked)
            Text(
              'LOCKED',
              style: GoogleFonts.fredoka(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            )
          else if (playerClaimed)
            Text(
              'CLAIMED',
              style: GoogleFonts.fredoka(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _seafoamGreen,
              ),
            ),

          // Coral name
          Text(
            coralName,
            style: GoogleFonts.nunito(
              fontSize: 9,
              color: _pearlWhite.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),

          // Player marks summary (who has claimed)
          if (!game.bonusBuffsEnabled || game.activeBuff != ReefBuff.inkCloud)
            _buildPlayerMarksSummary(game, provider, target, allPlayers),
        ],
      ),
    );
  }

  Widget _buildPlayerMarksSummary(ReefRoyaleGame game, ReefRoyaleProvider provider, int target, List<Player> allPlayers) {
    return Wrap(
      spacing: 2,
      children: game.playerIds.map((pid) {
        final marks = provider.getPlayerMarks(pid, target);
        final claimed = provider.hasPlayerClaimed(pid, target);
        if (marks == 0 && !claimed) return const SizedBox.shrink();
        final creature = game.creatureAssignments[pid];
        final initial = creature != null
            ? ReefRoyaleGame.getCreatureFileName(creature)[0]
            : '?';
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: claimed ? _seafoamGreen.withOpacity(0.5) : _deepReefBlue,
            shape: BoxShape.circle,
            border: Border.all(color: claimed ? _seafoamGreen : _pearlWhite.withOpacity(0.3), width: 1),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(fontSize: 8, color: _pearlWhite, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Color?> _computeDartBorderColors(String playerId, ReefRoyaleProvider provider) {
    final claimedList = provider.getDartThrowClaimedCoral(playerId);
    final pearlsList = provider.getDartThrowPearlsScored(playerId);
    final isNeighborList = provider.getDartThrowIsNeighbor(playerId);
    final marksAddedList = provider.getDartThrowMarksAdded(playerId);

    return List.generate(3, (i) {
      if (i >= claimedList.length) return null;
      if (claimedList[i]) return _sandyGold; // Coral claimed
      if (pearlsList[i] > 0) return _sandyGold.withOpacity(0.7); // Scored pearls
      if (isNeighborList[i]) return _sunlitAqua; // Neighbor hit
      if (i < marksAddedList.length && marksAddedList[i] > 0) return _seafoamGreen; // Valid target hit
      return _coralPink.withOpacity(0.5); // Miss / non-target
    });
  }

  Widget _buildOpponentBar(ReefRoyaleGame game, ReefRoyaleProvider provider, List<Player> allPlayers) {
    final currentPlayerId = provider.getCurrentPlayerId()!;
    final opponents = game.playerIds.where((pid) => pid != currentPlayerId).toList();

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _deepReefBlue.withOpacity(0.9),
        border: Border(top: BorderSide(color: _seafoamGreen.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((opponentId) {
          final player = allPlayers.firstWhere(
            (p) => p.id == opponentId,
            orElse: () => Player(id: opponentId, name: 'Player', createdAt: DateTime.now()),
          );
          final pearls = provider.getPlayerPearls(opponentId);
          final claimedCount = provider.getPlayerClaimedCount(opponentId);
          final imagePath = provider.getCreatureImagePath(opponentId);
          final showInfo = !game.bonusBuffsEnabled || game.activeBuff != ReefBuff.inkCloud;

          return Expanded(
            child: Container(
              key: ReefRoyaleGameKeys.playerTile(opponentId),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _deepReefBlue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _seafoamGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Creature avatar
                  if (imagePath != null)
                    Image.asset(imagePath, width: 40, height: 40, fit: BoxFit.contain)
                  else
                    const Icon(Icons.person, size: 40, color: _pearlWhite),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _pearlWhite,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showInfo) ...[
                          Text(
                            '${game.gameMode == ReefRoyaleGameMode.cursedTide ? '' : ''}$pearls pearls',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: game.gameMode == ReefRoyaleGameMode.cursedTide
                                  ? _coralPink
                                  : _sandyGold,
                            ),
                          ),
                          Text(
                            '$claimedCount/7 corals',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: _seafoamGreen,
                            ),
                          ),
                        ] else
                          Text(
                            '???',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              color: _biolumPurple,
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
      ),
    );
  }
}
