import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/lunar_lander_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../models/lunar_lander_game.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/lunar_lander_announcement_helper.dart';
import '../../../services/play_to_complete/lunar_lander_strategy.dart';
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
import 'lunar_lander_results_screen.dart';

class LunarLanderGameScreen extends StatefulWidget {
  const LunarLanderGameScreen({super.key});

  @override
  State<LunarLanderGameScreen> createState() => _LunarLanderGameScreenState();
}

class _LunarLanderGameScreenState extends State<LunarLanderGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  LunarLanderAnnouncementHelper? _audioQueue;
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();

  PlayToCompleteRunner? _playToCompleteRunner;
  bool _gameCompleted = false;
  bool _showSaveModal = false;

  // Color constants
  static const Color _spaceBlack = Color(0xFF0D1B2A);
  static const Color _rocketFlame = Color(0xFFF26430);
  static const Color _moonDustGray = Color(0xFFD4C5A9);
  static const Color _earthBlue = Color(0xFF1B4965);
  static const Color _starWhite = Color(0xFFFAFDF6);
  static const Color _thrusterRed = Color(0xFFE63946);
  static const Color _missionGreen = Color(0xFF52B788);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGame());
  }

  Future<void> _initializeGame() async {
    final dartboardProvider = context.read<DartboardProvider>();
    _mockApi = dartboardProvider.apiService;
    if (mounted) setState(() {});

    // Initialize announcement queue
    final globalQueue = GameAnnouncementQueueService();
    await globalQueue.loadSettings();
    _audioQueue = LunarLanderAnnouncementHelper(globalQueue);

    // Subscribe to dartboard events
    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen(_handleDartboardEvent);
    }

    // Announce game start
    final provider = context.read<LunarLanderProvider>();
    final game = provider.currentGame;
    if (game != null) {
      _audioQueue!.announceGameStart(startingAltitude: game.startingAltitude);
    }

    // Announce first player turn after brief delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _announceCurrentPlayerTurn();
    });
  }

  @override
  void dispose() {
    _playToCompleteRunner?.dispose();
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
      strategy: LunarLanderStrategy(),
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
    final provider = context.read<LunarLanderProvider>();
    if (!mounted || !provider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;

    // Parse the sector string into score + multiplier
    final parsed = _parseSector(sector);

    // Gather facts BEFORE processing the dart (previous altitude)
    final currentPlayerId = provider.getCurrentPlayerId();
    final previousAltitude = currentPlayerId != null
        ? provider.getCurrentAltitude(currentPlayerId)
        : 0;
    final hardLandingEnabled =
        provider.currentGame?.hardLandingEnabled ?? false;

    if (parsed == null) {
      // Miss — score 0
      provider.processDartThrow(score: 0, multiplier: 1);
    } else {
      provider.processDartThrow(
        score: parsed['score'] as int,
        multiplier: parsed['multiplier'] as int,
      );
    }

    // Handle announcements (not during auto-play)
    if (!_dartboardEmulatorController.isAutoPlaying) {
      if (currentPlayerId != null) {
        final playerProvider = context.read<PlayerProvider>();
        final player = playerProvider.allPlayers
            .where((p) => p.id == currentPlayerId)
            .firstOrNull;
        if (player != null) {
          // Gather facts AFTER processing the dart
          final dartScore = parsed != null
              ? (parsed['score'] as int) * (parsed['multiplier'] as int)
              : 0;
          final newAltitude = provider.getCurrentAltitude(currentPlayerId);
          final dartBusts = provider.getDartThrowWasBust(currentPlayerId);
          final wasBust = dartBusts.isNotEmpty && dartBusts.last;
          final hasWinner = provider.hasWinner;

          // Fire exactly ONE moment announcement via precedence chain
          _audioQueue!.announceMomentForDart(
            playerName: player.name,
            dartScore: dartScore,
            previousAltitude: previousAltitude,
            newAltitude: newAltitude,
            wasBust: wasBust,
            hasWinner: hasWinner,
            hardLandingEnabled: hardLandingEnabled,
          );
        }
      }

      // After 3 darts or win — prompt remove darts UNCONDITIONALLY
      final dartsThrown = provider.getCurrentPlayerDartsThrown();
      if (dartsThrown >= 3 || provider.hasWinner) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _audioQueue!.announceRemoveDarts(); // UNCONDITIONAL
          }
        });
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (mounted) {
            _mockApi?.simulateTakeoutStarted();
          }
        });
      }
    }

    setState(() {});
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
    final provider = context.read<LunarLanderProvider>();
    if (!mounted) return;

    if (provider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!provider.isGameActive) return;

    provider.advanceTurn();

    if (!_dartboardEmulatorController.isAutoPlaying) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _announceCurrentPlayerTurn();
      });
    }

    setState(() {});
  }

  void _announceCurrentPlayerTurn() {
    final provider = context.read<LunarLanderProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentPlayerId = provider.getCurrentPlayerId();
    if (currentPlayerId == null) return;
    final player = playerProvider.allPlayers
        .where((p) => p.id == currentPlayerId)
        .firstOrNull;
    if (player != null) {
      _audioQueue!.announcePlayerTurn(playerName: player.name);
    }
  }

  void _handleGameWon() {
    if (_gameCompleted) return;
    _gameCompleted = true;

    void navigateToResults() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LunarLanderResultsScreen()),
      );
    }

    if (_dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
    } else {
      final provider = context.read<LunarLanderProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final winnerId = provider.currentGame?.winnerId;
      if (winnerId != null) {
        final winner = playerProvider.allPlayers.firstWhere(
          (p) => p.id == winnerId,
          orElse: () => playerProvider.allPlayers.first,
        );
        _audioQueue?.announceWinner(winner.name);
      }
      Future.delayed(const Duration(milliseconds: 3000), navigateToResults);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LunarLanderProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final dartboardProvider = context.watch<DartboardProvider>();

    final game = provider.currentGame;
    if (game == null) {
      return const Scaffold(
        body: Center(child: Text('No game in progress')),
      );
    }

    final allPlayers = playerProvider.allPlayers;
    final currentPlayerId = provider.getCurrentPlayerId() ?? '';
    final dartScores = game.getCurrentTurnDartScores(currentPlayerId);
    final dartBusts = game.getDartThrowWasBust(currentPlayerId);
    final shouldPromptTakeout = provider.shouldPromptTakeout;

    final hasDartsThrown = game.totalDartsThrown.values.any((c) => c > 0);

    return PopScope(
      canPop: !hasDartsThrown || _showSaveModal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: _spaceBlack,
            appBar: AppBar(
              leading: IconButton(
                key: LunarLanderGameKeys.backButton,
                icon: const Icon(Icons.arrow_back, color: _starWhite, size: 32),
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
                'LUNAR LANDER',
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _starWhite,
                  letterSpacing: 1.5,
                ),
              ),
              flexibleSpace: game.hardLandingEnabled
                  ? SafeArea(
                      child: Center(
                        child: Container(
                          key: LunarLanderGameKeys.hardLandingBadge,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 6),
                          decoration: BoxDecoration(
                            color: _thrusterRed,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'HARD LANDING',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _starWhite,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              backgroundColor: _earthBlue,
              foregroundColor: _starWhite,
              actions: [
                // Skip turn button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton(
                    key: LunarLanderGameKeys.skipTurnButton,
                    onPressed: () {
                      final p = context.read<LunarLanderProvider>();
                      p.skipTurn();
                      if (p.shouldPromptTakeout) {
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (mounted) _audioQueue!.announceRemoveDarts();
                        });
                        Future.delayed(const Duration(milliseconds: 3500), () {
                          if (mounted) _mockApi?.simulateTakeoutStarted();
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _rocketFlame, width: 1.5),
                      foregroundColor: _rocketFlame,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      'SKIP TURN',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // D1, D2, D3 dart indicators
                ...List.generate(3, (i) {
                  final hasScore = i < dartScores.length;
                  final score = hasScore ? dartScores[i] : null;
                  final isBust =
                      hasScore && i < dartBusts.length && dartBusts[i];
                  final isSkip = hasScore && score == 0 && !isBust;

                  Color slotColor;
                  String scoreLabel;
                  if (!hasScore) {
                    slotColor = _rocketFlame.withOpacity(0.5);
                    scoreLabel = '—';
                  } else if (isBust) {
                    slotColor = _thrusterRed;
                    scoreLabel = 'X';
                  } else if (isSkip) {
                    slotColor = _moonDustGray.withOpacity(0.5);
                    scoreLabel = '—';
                  } else {
                    slotColor = _missionGreen;
                    scoreLabel = '$score';
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Container(
                      key: LunarLanderGameKeys.dartIndicator(i),
                      width: 44,
                      decoration: BoxDecoration(
                        color: hasScore
                            ? slotColor.withOpacity(0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasScore
                              ? slotColor
                              : _rocketFlame.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          scoreLabel,
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasScore
                                ? slotColor
                                : _rocketFlame.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.lunarLander(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // Background image with dark overlay
                Positioned.fill(
                  child: Image.asset(
                    'assets/games/lunar_lander/images/LunarLander-Background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Main content
                Column(
                  children: [
                    // Game area: full-width descent tracks
                    Expanded(
                      child:
                          _buildDescentArea(game, currentPlayerId, allPlayers),
                    ),
                  ],
                ),
              ],
            ),
            floatingActionButton: DartboardEmulatorFAB(
              controller: _dartboardEmulatorController,
              isConnected: !dartboardProvider.isEmulator,
              config: DartboardFABConfig.lunarLander(),
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
              config: RemoveDartsModalConfig.lunarLander(),
              playerName: allPlayers
                      .where((p) => p.id == currentPlayerId)
                      .firstOrNull
                      ?.name ??
                  'Player',
              editScoreButtonKey: LunarLanderGameKeys.editScoreButton,
              onEditScore: () {
                final currentPlayer = allPlayers
                    .where((p) => p.id == currentPlayerId)
                    .firstOrNull;
                if (currentPlayer == null) return;
                final dartScores =
                    provider.getCurrentTurnDartScores(currentPlayerId);
                // Build segment strings from dart scores for edit dialog.
                // EditScoreDialog distinguishes between '-' (not yet thrown,
                // ring=null → invalidates the Save button) and 'Miss' (thrown
                // as a miss, ring='Miss' → valid). Mapping a thrown miss to
                // '-' would wrongly disable Save; map it to 'Miss' instead.
                final segments = dartScores
                    .map((score) => score == 0 ? 'Miss' : 'S$score')
                    .toList();
                showEditScoreDialog(
                  context: context,
                  playerName: currentPlayer.name,
                  initialSegments: segments,
                  onSubmit: (newSegments) {
                    // Apply each dart's new value via editPlayerScore.
                    // Segments arrive from the dialog as one of:
                    //   'S20' / 's20' / 'D20' / 'T20' — single/double/triple
                    //   'Bull' (50) / '25' (outer bull)
                    //   'Miss' — a thrown miss (score 0)
                    //   '-' or empty — dart not thrown (skip; should not
                    //   occur because Save is disabled when ring is null)
                    for (int i = 0; i < newSegments.length && i < 3; i++) {
                      final seg = newSegments[i];
                      if (seg.isEmpty || seg == '-') continue;
                      int score = 0;
                      int mult = 1;
                      if (seg == 'Miss') {
                        score = 0;
                        mult = 1;
                      } else if (seg == 'Bull') {
                        score = 50;
                        mult = 1;
                      } else if (seg == '25') {
                        score = 25;
                        mult = 1;
                      } else {
                        final m = RegExp(r'([SDTsdt])(\d+)').firstMatch(seg);
                        if (m != null) {
                          score = int.tryParse(m.group(2)!) ?? 0;
                          final p = m.group(1)!.toUpperCase();
                          if (p == 'D') mult = 2;
                          if (p == 'T') mult = 3;
                        }
                      }
                      if (i < dartScores.length) {
                        provider.editPlayerScore(
                          playerId: currentPlayerId,
                          dartIndex: i,
                          newScore: score,
                          newMultiplier: mult,
                        );
                      }
                    }
                  },
                  config: EditScoreDialogConfig.lunarLander(),
                );
              },
            ),
          // Emulator above RemoveDartsModal; below SaveGameModal so the save modal's
          // Don't Save button isn't intercepted by the emulator.
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
              config: DartboardSectionConfig.lunarLander(),
              onPlayToComplete: _mockApi != null ? _onPlayToComplete : null,
              playToCompleteConfig: _mockApi != null
                  ? PlayToCompleteButtonConfig.lunarLander()
                  : null,
            ),
          ),
          // Save Game Modal
          if (_showSaveModal)
            SaveGameModal(
              config: SaveGameModalConfig.lunarLander(),
              onSave: () async {
                await provider.saveGame(allPlayers);
                if (mounted) Navigator.of(context).pop();
              },
              onDontSave: () => Navigator.of(context).pop(),
            ),
          // Dartboard Paused Modal — last child, paints on top.
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status != DartboardConnectionStatus.connected &&
              dartboardProvider.status != DartboardConnectionStatus.emulator)
            DartboardPausedModal(
              config: DartboardPausedModalConfig.lunarLander(),
            ),
        ],
      ),
    );
  }

  Widget _buildDescentArea(
      LunarLanderGame game, String currentPlayerId, List<dynamic> allPlayers) {
    final playerCount = game.playerIds.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fill 85% of each equal column width, clamped to a sensible range.
        // This adapts automatically to any screen size or player count.
        final charSize =
            (constraints.maxWidth / playerCount * 0.85).clamp(120.0, 300.0);

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 112),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              // Descent columns
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: game.playerIds.map((playerId) {
                    return _buildPlayerDescentColumn(
                      game: game,
                      playerId: playerId,
                      currentPlayerId: currentPlayerId,
                      allPlayers: allPlayers,
                      charSize: charSize,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerDescentColumn({
    required LunarLanderGame game,
    required String playerId,
    required String currentPlayerId,
    required List<dynamic> allPlayers,
    required double charSize,
  }) {
    final isActive = playerId == currentPlayerId;
    final character = game.getCharacter(playerId);
    final currentAlt = game.getCurrentAltitude(playerId);
    final startingAlt = game.startingAltitude;

    // Clamp progress ratio (0 = at orbit, 1 = landed)
    final progress = ((startingAlt - currentAlt) / startingAlt).clamp(0.0, 1.0);

    final player = allPlayers.where((p) => p.id == playerId).firstOrNull;
    final playerName = player?.name ?? 'Player';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Descent column with character (name moves with character)
            Expanded(
              child: Column(
                key: LunarLanderGameKeys.descentTrack(playerId),
                children: [
                  // Spacer proportional to descent (character moves down)
                  Expanded(
                    flex: (progress * 100).toInt(),
                    child: Container(),
                  ),
                  // Player name travels with the character
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _rocketFlame.withOpacity(0.9)
                          : const Color(0xFF4A9EC4).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      playerName,
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _starWhite,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Character image — fixed charSize box, top-aligned so all
                  // character tops sit at the same position relative to the
                  // name pill. Letterbox variation is pushed to the bottom.
                  Container(
                    key: isActive
                        ? LunarLanderGameKeys.playerAvatar
                        : LunarLanderGameKeys.characterOnTrack(playerId),
                    width: charSize,
                    height: charSize,
                    child: character != null
                        ? Image.asset(
                            character.assetPath,
                            width: charSize,
                            height: charSize,
                            fit: BoxFit.contain,
                            alignment: Alignment.topCenter,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.rocket,
                              color: isActive ? _rocketFlame : _starWhite,
                              size: charSize * 0.7,
                            ),
                          )
                        : Icon(
                            Icons.rocket,
                            color: isActive ? _rocketFlame : _starWhite,
                            size: charSize * 0.7,
                          ),
                  ),
                  // Altitude label below character
                  Container(
                    key: isActive ? LunarLanderGameKeys.altitudeReadout : null,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentAlt < 0
                          ? _thrusterRed.withOpacity(0.9)
                          : isActive
                              ? _rocketFlame.withOpacity(0.9)
                              : const Color(0xFF4A9EC4).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$currentAlt',
                      style: GoogleFonts.orbitron(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _starWhite,
                      ),
                    ),
                  ),
                  // Descent line below character
                  Expanded(
                    flex: ((1.0 - progress) * 100).toInt().clamp(1, 100),
                    child: Center(
                      child: Container(
                        width: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isActive
                                ? [_rocketFlame, _rocketFlame.withOpacity(0.15)]
                                : [
                                    const Color(0xFF4A9EC4),
                                    const Color(0xFF4A9EC4).withOpacity(0.15)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
