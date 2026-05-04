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
import '../../../services/play_to_complete/reef_royale_strategy.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/edit_score/edit_score.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import '../../../utils/dartboard_layout.dart';
import 'reef_royale_results_screen.dart';

class ReefRoyaleGameScreen extends StatefulWidget {
  const ReefRoyaleGameScreen({super.key});

  @override
  State<ReefRoyaleGameScreen> createState() => _ReefRoyaleGameScreenState();
}

class _ReefRoyaleGameScreenState extends State<ReefRoyaleGameScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  ReefRoyaleAnnouncementHelper? _audioQueue;
  final DartboardEmulatorController _dartboardEmulatorController = DartboardEmulatorController();
  PlayToCompleteRunner? _playToCompleteRunner;
  bool _gameCompleted = false;
  bool _showSaveModal = false;
  late final AnimationController _pulseController;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    final dartboardProvider = context.read<DartboardProvider>();
    _mockApi = dartboardProvider.apiService;
    if (mounted) setState(() {});

    // Initialize audio
    final globalQueue = GameAnnouncementQueueService();
    await globalQueue.loadSettings();
    _audioQueue = ReefRoyaleAnnouncementHelper(globalQueue);

    // Subscribe to dartboard events (works for both WebSocket and emulator)
    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen((event) {
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
    _playToCompleteRunner?.dispose();
    _pulseController.dispose();
    _dartboardSubscription?.cancel();
    _audioQueue?.dispose();
    _dartboardEmulatorController.dispose();
    super.dispose();
  }

  void _onPlayToComplete() {
    if (_mockApi == null) return;
    _dartboardEmulatorController.setAutoPlaying(true);
    _dartboardEmulatorController.hide();

    _playToCompleteRunner = PlayToCompleteRunner(
      strategy: ReefRoyaleStrategy(),
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
    final reefProvider = context.read<ReefRoyaleProvider>();
    if (!mounted || !reefProvider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;

    // Capture player ID before processing
    final playerId = reefProvider.getCurrentPlayerId()!;

    reefProvider.processDartThrow(sector);

    // Announce dart result
    if (!_dartboardEmulatorController.isAutoPlaying) {
      _announceDartResult(reefProvider, playerId, sector);
    }

    final dartsThrown = reefProvider.getCurrentPlayerDartsThrown();
    if (!_dartboardEmulatorController.isAutoPlaying && (dartsThrown >= 3 || reefProvider.hasWinner)) {
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
    if (!_dartboardEmulatorController.isAutoPlaying && buffAfter != null && buffAfter != buffBefore) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _audioQueue?.announceBuff(buffAfter);
      });
    }

    if (reefProvider.hasWinner) {
      if (!_dartboardEmulatorController.isAutoPlaying) {
        _audioQueue?.announceSpeedPlayEnd();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _handleGameWon();
        });
      }
      return;
    }

    // Announce next player's turn
    if (!_dartboardEmulatorController.isAutoPlaying) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _announceCurrentPlayerTurn();
      });
    }

    setState(() {});
  }

  void _handleGameWon() {
    if (_gameCompleted) return;
    _gameCompleted = true;

    void navigateToResults() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReefRoyaleResultsScreen()),
      );
    }

    if (_dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
    } else {
      final reefProvider = context.read<ReefRoyaleProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final winnerId = reefProvider.currentGame?.winnerId;
      if (winnerId != null) {
        final winner = playerProvider.allPlayers.firstWhere((p) => p.id == winnerId);
        _audioQueue?.announceVictory(winner.name);
      }
      Future.delayed(const Duration(milliseconds: 3000), navigateToResults);
    }
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

    if (playerProvider.allPlayers.isEmpty) return;
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
    final currentPlayer = currentPlayerId != null && allPlayers.isNotEmpty
        ? allPlayers.firstWhere((p) => p.id == currentPlayerId, orElse: () => allPlayers.first)
        : null;
    final shouldPromptTakeout = reefProvider.shouldPromptTakeout;

    final hasDartsThrown = currentGame.totalDartsThrown.values.any((c) => c > 0);

    return PopScope(
      canPop: !hasDartsThrown || _showSaveModal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Scaffold(
      backgroundColor: _deepReefBlue,
      appBar: AppBar(
        leading: IconButton(
          key: ReefRoyaleGameKeys.backButton,
          icon: const Icon(Icons.arrow_back, color: _pearlWhite, size: 32),
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
        title: Transform.translate(
          offset: const Offset(0, -3),
          child: Text(
            'Reef Royale',
            style: GoogleFonts.fredoka(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _pearlWhite,
              letterSpacing: 2,
              shadows: [
                Shadow(color: _seafoamGreen.withOpacity(0.6), blurRadius: 12),
                const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
              ],
            ),
          ),
        ),
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_deepReefBlue, _deepReefBlue, _seafoamGreen],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Center(
              child: _buildRoundProgressBar(currentGame),
            ),
            if (currentGame.gameMode == ReefRoyaleGameMode.cursedTide || currentGame.bonusBuffsEnabled || currentGame.neighborNumbers)
              Positioned(
                left: MediaQuery.of(context).size.width * 0.60,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (currentGame.gameMode == ReefRoyaleGameMode.cursedTide)
                      Container(
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
                    if (currentGame.gameMode == ReefRoyaleGameMode.cursedTide && (currentGame.neighborNumbers || currentGame.bonusBuffsEnabled))
                      const SizedBox(width: 6),
                    if (currentGame.neighborNumbers)
                      Container(
                        key: ReefRoyaleGameKeys.neighborsBadge,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _sandyGold.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Text(
                          'NEIGHBORS',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _deepReefBlue,
                          ),
                        ),
                      ),
                    if (currentGame.neighborNumbers && currentGame.bonusBuffsEnabled)
                      const SizedBox(width: 6),
                    if (currentGame.bonusBuffsEnabled)
                      Container(
                        key: ReefRoyaleGameKeys.buffsBadge,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _seafoamGreen.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Text(
                          'BUFFS',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _deepReefBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
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

                // Game content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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

          // RemoveDartsModal (conditional) — sits BEHIND the emulator so the emulator's DARTS REMOVED button stays visible/tappable on top of the takeout overlay.
          if (shouldPromptTakeout)
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

          // DartboardEmulatorSection — sits ABOVE RemoveDartsModal so DARTS REMOVED is on top, BELOW SaveGameModal so Save's Don't Save button isn't intercepted.
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
              config: DartboardSectionConfig.reefRoyale(),
              onPlayToComplete: _mockApi != null ? _onPlayToComplete : null,
              playToCompleteConfig: _mockApi != null ? PlayToCompleteButtonConfig.reefRoyale() : null,
            ),
          ),

          // Save game modal
          if (_showSaveModal)
            SaveGameModal(
              config: SaveGameModalConfig.reefRoyale(),
              onSave: () async {
                await reefProvider.saveGame(allPlayers);
                if (mounted) Navigator.of(context).pop();
              },
              onDontSave: () => Navigator.of(context).pop(),
            ),

          // Dartboard connection lost modal
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status != DartboardConnectionStatus.connected &&
              dartboardProvider.status != DartboardConnectionStatus.emulator)
            DartboardPausedModal(
              config: DartboardPausedModalConfig.reefRoyale(),
            ),
        ],
      ),
      floatingActionButton: DartboardEmulatorFAB(
        controller: _dartboardEmulatorController,
        isConnected: !dartboardProvider.isEmulator,
        config: DartboardFABConfig.reefRoyale(),
        onCancelAutoPlay: _onCancelAutoPlay,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _sandyGold,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundProgressBar(ReefRoyaleGame game) {
    final isSpeedPlay = game.speedPlayEnabled;
    final progress = isSpeedPlay
        ? (game.currentRound / game.roundLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      key: ReefRoyaleGameKeys.roundCounter,
      width: 330,
      height: 28,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _seafoamGreen.withOpacity(0.5), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Progress fill
            if (isSpeedPlay)
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_seafoamGreen, _sunlitAqua, _seafoamGreen],
                    ),
                  ),
                ),
              ),
            // Text
            Center(
              child: Text(
                isSpeedPlay
                    ? 'Round ${game.currentRound} / ${game.roundLimit}'
                    : 'Unlimited Rounds',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _pearlWhite,
                  shadows: [
                    const Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
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
      margin: const EdgeInsets.fromLTRB(8, 12, 0, 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _deepReefBlue.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _seafoamGreen.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Creature image
          if (imagePath != null)
            Image.asset(imagePath, width: 138, height: 138, fit: BoxFit.contain),
          const SizedBox(height: 8),

          // Pearls count
          Text(
            key: ReefRoyaleGameKeys.pearlCounter,
            '$pearls pearls',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: game.gameMode == ReefRoyaleGameMode.cursedTide
                  ? _coralPink
                  : _sandyGold,
            ),
          ),

          // Corals count
          Text(
            key: ReefRoyaleGameKeys.coralCounter,
            '$claimedCount/7 corals',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _seafoamGreen,
            ),
          ),
          const SizedBox(height: 8),

          // Dart indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final segment = i < dartSegments.length ? dartSegments[i] : null;
              final hasThrown = i < dartsThrown || segment == 'Skip';
              final isNeighborList = provider.getDartThrowIsNeighbor(playerId);
              final isNeighbor = i < isNeighborList.length && isNeighborList[i];
              final claimedList = provider.getDartThrowClaimedCoral(playerId);
              final justClaimed = i < claimedList.length && claimedList[i];
              final pearlsList = provider.getDartThrowPearlsScored(playerId);
              final scoredPearls = i < pearlsList.length && pearlsList[i] > 0;
              final marksAddedList = provider.getDartThrowMarksAdded(playerId);
              final addedMarks = i < marksAddedList.length && marksAddedList[i] > 0;
              final targetCountList = provider.getDartThrowTargetCount(playerId);
              final isMultiTarget = i < targetCountList.length && targetCountList[i] > 1;

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

              final indicator = Container(
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

              if (!isMultiTarget) return indicator;

              // Pulsing glow for shared neighbor multi-target hits
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _sunlitAqua.withOpacity(0.3 + 0.4 * _pulseController.value),
                          blurRadius: 6 + 6 * _pulseController.value,
                          spreadRadius: 1 + 2 * _pulseController.value,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  key: ReefRoyaleGameKeys.dartIndicator(i),
                  width: 50,
                  height: 40,
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
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Skip Turn button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: ReefRoyaleGameKeys.skipTurnButton,
              onPressed: () {
                final reefProvider = context.read<ReefRoyaleProvider>();
                final dartsThrown = reefProvider.getCurrentPlayerDartsThrown();
                reefProvider.skipTurn();
                if (dartsThrown > 0) {
                  // Darts in board — wait for physical takeout or emulator button
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) _mockApi?.simulateTakeoutStarted();
                  });
                } else {
                  // No darts thrown, advance directly
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

          const Spacer(),

          // Hints (if enabled)
          if (game.showHints) ...[
            Builder(builder: (_) {
              return Transform.translate(
                offset: const Offset(0, -5),
                child: Container(
                key: ReefRoyaleGameKeys.hintOverlay,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _deepReefBlue.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _seafoamGreen.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.gps_fixed, color: _seafoamGreen, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'Targets',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _pearlWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...game.activeTargets.map((t) {
                      final label = t == 25 ? 'Bull' : '$t';
                      if (game.neighborNumbers && t >= 1 && t <= 20) {
                        final neighbors = DartboardLayout.getNeighbors(t)
                            .where((n) => !game.activeTargets.contains(n))
                            .toList();
                        if (neighbors.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: label,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _seafoamGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' (${neighbors.join(", ")})',
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      color: _sunlitAqua.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          label,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _seafoamGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              );
            }),
          ],
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
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
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
              fontSize: 26,
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

          // Marks display with player hit markers on sides
          if (!isLocked && !playerClaimed)
            Row(
              children: [
                // Left player markers (Expanded to balance with right)
                Expanded(
                  child: (!game.bonusBuffsEnabled || game.activeBuff != ReefBuff.inkCloud)
                      ? _buildSidePlayerMarkers(game, provider, target, allPlayers, isLeft: true)
                      : const SizedBox.shrink(),
                ),
                // Mark circles (always centered)
                ...List.generate(markThreshold, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < playerMarks ? Icons.circle : Icons.circle_outlined,
                      size: 28,
                      color: i < playerMarks ? _seafoamGreen : _pearlWhite.withOpacity(0.4),
                    ),
                  );
                }),
                // Right player markers (Expanded to balance with left)
                Expanded(
                  child: (!game.bonusBuffsEnabled || game.activeBuff != ReefBuff.inkCloud)
                      ? _buildSidePlayerMarkers(game, provider, target, allPlayers, isLeft: false)
                      : const SizedBox.shrink(),
                ),
              ],
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

          // Player marks summary for locked/claimed state
          if ((isLocked || playerClaimed) && (!game.bonusBuffsEnabled || game.activeBuff != ReefBuff.inkCloud))
            _buildPlayerMarksSummary(game, provider, target, allPlayers),
        ],
      ),
    );
  }

  Widget _buildSidePlayerMarkers(ReefRoyaleGame game, ReefRoyaleProvider provider, int target, List<Player> allPlayers, {required bool isLeft}) {
    final markers = <Widget>[];
    for (final pid in game.playerIds) {
      final marks = provider.getPlayerMarks(pid, target);
      final claimed = provider.hasPlayerClaimed(pid, target);
      if (marks == 0 && !claimed) continue;
      final player = allPlayers.firstWhere(
        (p) => p.id == pid,
        orElse: () => Player(id: pid, name: '?', createdAt: DateTime.now()),
      );
      final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';
      markers.add(Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: claimed ? _seafoamGreen.withOpacity(0.5) : _deepReefBlue,
          shape: BoxShape.circle,
          border: Border.all(color: claimed ? _seafoamGreen : _pearlWhite.withOpacity(0.3), width: 1),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(fontSize: 12, color: _pearlWhite, fontWeight: FontWeight.bold),
          ),
        ),
      ));
    }
    if (markers.isEmpty) return const SizedBox.shrink();
    final leftCount = (markers.length + 1) ~/ 2;
    final side = isLeft ? markers.sublist(0, leftCount) : markers.sublist(leftCount);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isLeft ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: side,
    );
  }

  Widget _buildPlayerMarksSummary(ReefRoyaleGame game, ReefRoyaleProvider provider, int target, List<Player> allPlayers) {
    return Wrap(
      spacing: 2,
      children: game.playerIds.map((pid) {
        final marks = provider.getPlayerMarks(pid, target);
        final claimed = provider.hasPlayerClaimed(pid, target);
        if (marks == 0 && !claimed) return const SizedBox.shrink();
        final player = allPlayers.firstWhere(
          (p) => p.id == pid,
          orElse: () => Player(id: pid, name: '?', createdAt: DateTime.now()),
        );
        final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: claimed ? _seafoamGreen.withOpacity(0.5) : _deepReefBlue,
            shape: BoxShape.circle,
            border: Border.all(color: claimed ? _seafoamGreen : _pearlWhite.withOpacity(0.3), width: 1),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(fontSize: 12, color: _pearlWhite, fontWeight: FontWeight.bold),
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
    // Order opponents by turn order: next player first, wrapping around
    final opponents = List.generate(
      game.playerIds.length - 1,
      (i) => game.playerIds[(game.currentPlayerIndex + i + 1) % game.playerIds.length],
    );
    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: opponents.map((opponentId) {
          final player = allPlayers.firstWhere(
            (p) => p.id == opponentId,
            orElse: () => Player(id: opponentId, name: 'Player', createdAt: DateTime.now()),
          );
          final pearls = provider.getPlayerPearls(opponentId);
          final claimedCount = provider.getPlayerClaimedCount(opponentId);
          final imagePath = provider.getCreatureImagePath(opponentId);
          final showInfo = !game.bonusBuffsEnabled || game.activeBuff != ReefBuff.inkCloud;

          return Flexible(
            child: Container(
              key: ReefRoyaleGameKeys.playerTile(opponentId),
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _deepReefBlue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _seafoamGreen.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Creature avatar
                  if (imagePath != null)
                    Image.asset(imagePath, width: 64, height: 64, fit: BoxFit.contain)
                  else
                    const Icon(Icons.person, size: 64, color: _pearlWhite),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _pearlWhite,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showInfo) ...[
                          Text(
                            '$pearls pearls',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: game.gameMode == ReefRoyaleGameMode.cursedTide
                                  ? _coralPink
                                  : _sandyGold,
                            ),
                          ),
                          Text(
                            '$claimedCount/7 corals',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: _seafoamGreen,
                            ),
                          ),
                        ] else
                          Text(
                            '???',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
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
