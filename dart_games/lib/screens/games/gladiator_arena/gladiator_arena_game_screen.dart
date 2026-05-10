import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/test_keys.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/gladiator_arena_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/gladiator_arena_announcement_helper.dart';
import '../../../services/play_to_complete/gladiator_arena_strategy.dart';
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
import 'gladiator_arena_results_screen.dart';

// ─── Color constants ──────────────────────────────────────────────────────────

const _kMarbleWhite = Color(0xFFF5F0E8);
const _kGladiatorGold = Color(0xFFDAA520);
const _kArenaSand = Color(0xFFD2B48C);
const _kImperialPurple = Color(0xFF7B2D8E);
const _kBloodRed = Color(0xFFC0392B);
const _kColosseumGray = Color(0xFF8B8682);
const _kLaurelGreen = Color(0xFF4A7C59);

class GladiatorArenaGameScreen extends StatefulWidget {
  const GladiatorArenaGameScreen({super.key});

  @override
  State<GladiatorArenaGameScreen> createState() =>
      _GladiatorArenaGameScreenState();
}

class _GladiatorArenaGameScreenState extends State<GladiatorArenaGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  GladiatorArenaAnnouncementHelper? _audioQueue;
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();

  PlayToCompleteRunner? _playToCompleteRunner;
  bool _gameCompleted = false;
  bool _showSaveModal = false;

  // Speed Play timer
  Timer? _speedPlayTimer;
  int _speedPlaySecondsRemaining = 25;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGame());
  }

  Future<void> _initializeGame() async {
    final dartboardProvider = context.read<DartboardProvider>();
    _mockApi = dartboardProvider.apiService;
    if (mounted) setState(() {});

    // Initialize announcement helper
    final queueService = GameAnnouncementQueueService();
    await queueService.loadSettings();
    _audioQueue = GladiatorArenaAnnouncementHelper(queueService: queueService);

    // Announce game start
    final provider = context.read<GladiatorArenaProvider>();
    final targetScore = provider.currentGame?.targetScore ?? 200;
    _audioQueue?.announceGameStart(targetScore);

    // Subscribe to dartboard events
    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen(_handleDartboardEvent);
    }

    // Announce first player turn after brief delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _startSpeedPlayTimerIfNeeded();
        final p = context.read<GladiatorArenaProvider>();
        final game = p.currentGame;
        if (game != null) {
          final playerProvider = context.read<PlayerProvider>();
          final firstPlayer = playerProvider.allPlayers
              .where((pl) => pl.id == game.currentPlayerId)
              .firstOrNull;
          if (firstPlayer != null) {
            _audioQueue?.announcePlayerTurn(firstPlayer.name);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _playToCompleteRunner?.dispose();
    _dartboardSubscription?.cancel();
    _speedPlayTimer?.cancel();
    _dartboardEmulatorController.dispose();
    _audioQueue?.dispose();
    super.dispose();
  }

  void _onPlayToComplete() {
    if (_mockApi == null) return;
    _dartboardEmulatorController.setAutoPlaying(true);
    _dartboardEmulatorController.hide();

    _playToCompleteRunner = PlayToCompleteRunner(
      strategy: GladiatorArenaStrategy(),
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
    final provider = context.read<GladiatorArenaProvider>();
    if (!mounted || !provider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;
    final parsed = _parseSector(sector);

    // Snapshot state BEFORE the throw for bust/knockoff detection
    final game = provider.currentGame!;
    final playerId = game.currentPlayerId;
    final preTurnScore = game.scores[playerId] ?? 0;
    final dfOn = game.doubleFinishEnabled;
    final targetScore = game.targetScore;
    final preOpponentScores = <String, int>{};
    for (final id in game.playerIds) {
      if (id != playerId) preOpponentScores[id] = game.scores[id] ?? 0;
    }
    final isShieldRound = game.isShieldRound;

    // Determine dart parameters
    final int dartScore;
    final String dartMultiplier;
    final String dartSector;
    if (parsed == null) {
      dartScore = 0;
      dartMultiplier = 'miss';
      dartSector = 'Miss';
      provider.processDartThrow(score: 0, multiplier: 'miss', sector: 'Miss');
    } else {
      dartScore = parsed['score'] as int;
      dartMultiplier = parsed['multiplier'] as String;
      dartSector = sector;
      provider.processDartThrow(
        score: dartScore,
        multiplier: dartMultiplier,
        sector: dartSector,
      );
    }

    // Compute dart value
    final dartValue = _computeDartValue(score: dartScore, multiplier: dartMultiplier);

    // Detect bust conditions AFTER the throw
    final postScore = game.scores[playerId] ?? 0;
    final prospective = preTurnScore +
        (game.currentTurnDartValues[playerId] ?? [])
            .fold<int>(0, (sum, v) => sum + v);
    final wasBustOvershoot = dfOn && prospective > targetScore;
    final segments = game.currentTurnDartSegments[playerId] ?? [];
    final lastSeg = segments.isNotEmpty ? segments.last : '';
    final wasBustNoDouble =
        dfOn && prospective == targetScore && !lastSeg.startsWith('D');

    // Detect knockoff: opponent went from their score to 0, and that score == postScore
    String? knockoffVictimName;
    String? shieldBlockedName;
    if (!provider.hasWinner) {
      final playerProvider = context.read<PlayerProvider>();
      for (final entry in preOpponentScores.entries) {
        final preScore = entry.value;
        final postOpScore = game.scores[entry.key] ?? 0;
        if (preScore > 0 && postOpScore == 0 && postScore == preScore) {
          // This opponent was knocked off
          final victim = playerProvider.allPlayers
              .where((p) => p.id == entry.key)
              .firstOrNull;
          knockoffVictimName = victim?.name ?? entry.key;
          break;
        }
        // Shield block: would-be knockoff blocked by isShieldRound
        if (isShieldRound &&
            preScore > 0 &&
            postOpScore == preScore &&
            postScore == preScore) {
          final victim = playerProvider.allPlayers
              .where((p) => p.id == entry.key)
              .firstOrNull;
          shieldBlockedName = victim?.name ?? entry.key;
        }
      }
    }

    // Fire ONE moment announcement (not during auto-play)
    if (!_dartboardEmulatorController.isAutoPlaying) {
      final playerProvider = context.read<PlayerProvider>();
      final currentPlayer = playerProvider.allPlayers
          .where((p) => p.id == playerId)
          .firstOrNull;
      final currentPlayerName = currentPlayer?.name ?? 'Player';

      _audioQueue?.pickAndAnnounceMoment(
        playerName: currentPlayerName,
        dartValue: dartValue,
        multiplier: dartMultiplier,
        sector: dartSector,
        hasWinner: provider.hasWinner,
        knockoffVictimName: knockoffVictimName,
        shieldBlockedName: shieldBlockedName,
        wasBustOvershoot: wasBustOvershoot,
        wasBustNoDouble: wasBustNoDouble,
      );
    }

    // After throw: check if turn is complete → unconditionally announce remove darts
    if (!_dartboardEmulatorController.isAutoPlaying) {
      final dartsThrown = provider.getCurrentPlayerDartsThrown();
      final shouldPrompt = dartsThrown >= 3 || provider.hasWinner;
      if (shouldPrompt) {
        // Cancel speed play timer when turn ends
        _speedPlayTimer?.cancel();
        _speedPlayTimer = null;

        // UNCONDITIONAL remove-darts announcement — NOT inside the precedence chain
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _audioQueue?.announceRemoveDarts();
        });
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (mounted) _mockApi?.simulateTakeoutStarted();
        });
      }
    }

    setState(() {});
  }

  /// Computes the point value for a dart throw (mirrors provider logic).
  int _computeDartValue({required int score, required String multiplier}) {
    switch (multiplier) {
      case 'miss':
        return 0;
      case 'bull':
        return 50;
      case 'double':
        return score * 2;
      case 'triple':
        return score * 3;
      default:
        return score;
    }
  }

  Map<String, dynamic>? _parseSector(String sector) {
    if (sector == 'None') return null;
    if (sector == 'Bull') return {'score': 50, 'multiplier': 'bull'};
    if (sector == '25') return {'score': 25, 'multiplier': 'single'};

    final match = RegExp(r'([SDTsdt])(\d+)').firstMatch(sector);
    if (match == null) return null;

    final prefix = match.group(1)!.toUpperCase();
    final number = int.parse(match.group(2)!);
    String multiplier = 'single';
    if (prefix == 'D') multiplier = 'double';
    if (prefix == 'T') multiplier = 'triple';

    return {'score': number, 'multiplier': multiplier};
  }

  void _handleTakeoutFinished() {
    final provider = context.read<GladiatorArenaProvider>();
    if (!mounted) return;

    if (provider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!provider.isGameActive) return;

    provider.handleTakeoutFinished();

    // Announce next player's turn after takeout (500ms delay)
    if (!_dartboardEmulatorController.isAutoPlaying) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final p = context.read<GladiatorArenaProvider>();
          final game = p.currentGame;
          if (game != null) {
            final playerProvider = context.read<PlayerProvider>();
            final nextPlayer = playerProvider.allPlayers
                .where((pl) => pl.id == game.currentPlayerId)
                .firstOrNull;
            if (nextPlayer != null) {
              _audioQueue?.announcePlayerTurn(nextPlayer.name);
            }
          }
        }
      });
      _startSpeedPlayTimerIfNeeded();
    }

    setState(() {});
  }

  void _startSpeedPlayTimerIfNeeded() {
    final provider = context.read<GladiatorArenaProvider>();
    final game = provider.currentGame;
    if (game == null || !game.speedPlayEnabled) return;

    _speedPlayTimer?.cancel();
    _speedPlaySecondsRemaining = game.speedPlayTimeRemaining ?? 25;

    _speedPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final p = context.read<GladiatorArenaProvider>();
      if (p.shouldPromptTakeout) {
        timer.cancel();
        return;
      }
      setState(() {
        _speedPlaySecondsRemaining--;
      });
      p.setSpeedPlayTimeRemaining(_speedPlaySecondsRemaining);

      if (_speedPlaySecondsRemaining <= 0) {
        timer.cancel();
        p.onSpeedPlayTimerExpired();
        _audioQueue?.announceSpeedTimerExpired();
        // UNCONDITIONAL remove-darts announcement when timer expires
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _audioQueue?.announceRemoveDarts();
        });
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (mounted) _mockApi?.simulateTakeoutStarted();
        });
        setState(() {});
      }
    });
  }

  void _handleGameWon() {
    if (_gameCompleted) return;
    _gameCompleted = true;

    void navigateToResults() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GladiatorArenaResultsScreen()),
      );
    }

    if (_dartboardEmulatorController.isAutoPlaying) {
      navigateToResults();
    } else {
      // Victory announcement fires when the winning dart is detected (via
      // pickAndAnnounceMoment in _handleDartThrow). Navigate after delay.
      Future.delayed(const Duration(milliseconds: 3000), navigateToResults);
    }
  }

  /// Builds the initial segment list for the Edit Score dialog.
  /// Maps 'Miss'/'Skip' to 'Miss' so dialog Save button stays enabled.
  List<String> _buildInitialSegments(String playerId) {
    final provider = context.read<GladiatorArenaProvider>();
    final segments = provider.getCurrentTurnDartSegments(playerId);
    return segments.map((s) {
      if (s == 'Skip' || s == 'X') return 'Miss';
      return s;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GladiatorArenaProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final dartboardProvider = context.watch<DartboardProvider>();

    final game = provider.currentGame;
    if (game == null) {
      return const Scaffold(
        body: Center(child: Text('No game in progress')),
      );
    }

    final allPlayers = playerProvider.allPlayers;
    final currentPlayerId = provider.currentPlayerId ?? '';
    final dartValues = game.currentTurnDartValues[currentPlayerId] ?? [];
    final dartSegments = game.currentTurnDartSegments[currentPlayerId] ?? [];
    final shouldPromptTakeout = provider.shouldPromptTakeout;
    final hasDartsThrown = game.totalDartsThrown.values.any((c) => c > 0);

    // Current player name
    final currentPlayer = allPlayers.where((p) => p.id == currentPlayerId).firstOrNull;
    final currentPlayerName = currentPlayer?.name ?? 'Player';

    return PopScope(
      canPop: !hasDartsThrown || _showSaveModal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF2A1500),
            appBar: AppBar(
              leading: IconButton(
                key: GladiatorArenaGameKeys.backButton,
                icon: const Icon(Icons.arrow_back, color: _kMarbleWhite, size: 32),
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
                'GLADIATOR ARENA',
                style: GoogleFonts.cinzel(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _kMarbleWhite,
                  letterSpacing: 1.5,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 4,
                        offset: Offset(1, 1)),
                  ],
                ),
              ),
              backgroundColor: const Color(0xFF4A3520),
              foregroundColor: _kMarbleWhite,
              actions: [
                // Skip Turn button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    key: GladiatorArenaGameKeys.skipTurnButton,
                    onPressed: shouldPromptTakeout
                        ? null
                        : () {
                            final p = context.read<GladiatorArenaProvider>();
                            final dartsThrown = p.getCurrentPlayerDartsThrown();
                            p.skipTurn();
                            _speedPlayTimer?.cancel();
                            _speedPlayTimer = null;
                            if (dartsThrown > 0) {
                              // UNCONDITIONAL remove-darts announcement on skip
                              Future.delayed(const Duration(milliseconds: 1500), () {
                                if (mounted) _audioQueue?.announceRemoveDarts();
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kImperialPurple,
                      foregroundColor: _kMarbleWhite,
                      disabledBackgroundColor:
                          _kImperialPurple.withOpacity(0.4),
                      disabledForegroundColor: _kMarbleWhite.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      elevation: 2,
                    ),
                    child: Text(
                      'SKIP TURN',
                      style: GoogleFonts.cinzel(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // D1, D2, D3 dart indicators (Pattern A: show calculated point values)
                ...List.generate(3, (i) {
                  final hasValue = i < dartValues.length;
                  final value = hasValue ? dartValues[i] : null;
                  final segment = hasValue && i < dartSegments.length
                      ? dartSegments[i]
                      : null;

                  // Determine slot state
                  Color slotBg;
                  Color slotBorder;
                  String label;
                  Color labelColor;

                  if (!hasValue) {
                    // Empty slot — Marble White on a faint sand tint reads
                    // clearly against the dark brown app bar.
                    slotBg = _kArenaSand.withOpacity(0.12);
                    slotBorder = _kMarbleWhite.withOpacity(0.85);
                    label = '—';
                    labelColor = _kMarbleWhite;
                  } else if (segment == 'Skip' || segment == 'X') {
                    // Skipped dart
                    slotBg = _kColosseumGray.withOpacity(0.15);
                    slotBorder = _kColosseumGray.withOpacity(0.5);
                    label = '0';
                    labelColor = _kColosseumGray.withOpacity(0.5);
                  } else if (segment != null &&
                      game.doubleFinishEnabled &&
                      segment.startsWith('D')) {
                    // Double hit with DF ON → Laurel Green
                    slotBg = _kLaurelGreen.withOpacity(0.25);
                    slotBorder = _kLaurelGreen;
                    label = '${value ?? 0}';
                    labelColor = _kLaurelGreen;
                  } else {
                    // Normal hit → Gladiator Gold
                    slotBg = _kGladiatorGold.withOpacity(0.2);
                    slotBorder = _kGladiatorGold;
                    label = '${value ?? 0}';
                    labelColor = _kGladiatorGold;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
                    child: Container(
                      key: GladiatorArenaGameKeys.dartIndicator(i),
                      width: 40,
                      decoration: BoxDecoration(
                        color: slotBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: slotBorder, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: labelColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 24),
                DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.gladiatorArena(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/games/gladiator_arena/images/GladiatorArena-Background.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF2A1500)),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.45)),
                ),
                // Main game content
                Column(
                  children: [
                    // Shield Banner (conditional)
                    if (game.isShieldRound)
                      Container(
                        key: GladiatorArenaGameKeys.shieldBanner,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_kLaurelGreen, _kArenaSand],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield, color: _kMarbleWhite, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Shield Round — No Knockoffs!',
                              style: GoogleFonts.cinzel(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _kMarbleWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Goal / Double Finish badge / Round row — centered
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Goal: ${game.targetScore}',
                              key: GladiatorArenaGameKeys.goalDisplay,
                              style: GoogleFonts.cinzel(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: _kGladiatorGold,
                              ),
                            ),
                            if (game.doubleFinishEnabled) ...[
                              const SizedBox(width: 12),
                              Container(
                                key: GladiatorArenaGameKeys.doubleBadge,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kGladiatorGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _kGladiatorGold, width: 1),
                                ),
                                child: Text(
                                  'Double Finish',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: _kGladiatorGold,
                                  ),
                                ),
                              ),
                            ],
                            if (game.speedPlayEnabled) ...[
                              const SizedBox(width: 12),
                              Text(
                                'Round ${game.round}',
                                style: GoogleFonts.cinzel(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: _kMarbleWhite,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Arena Podium Display
                    Expanded(
                      child: _buildArenaPodiums(
                          game, currentPlayerId, allPlayers),
                    ),
                    // Elimination Zone
                    _buildEliminationZone(game, allPlayers),
                    // Bottom padding for emulator overlay (halved per design)
                    const SizedBox(height: 60),
                  ],
                ),
              ],
            ),
          ),
          // RemoveDartsModal — behind emulator layer
          if (shouldPromptTakeout)
            RemoveDartsModal(
              config: RemoveDartsModalConfig.gladiatorArena(),
              playerName: currentPlayerName,
              editScoreButtonKey: GladiatorArenaGameKeys.editScoreButton,
              onEditScore: () {
                final initialSegments = _buildInitialSegments(currentPlayerId);
                showEditScoreDialog(
                  context: context,
                  playerName: currentPlayerName,
                  initialSegments: initialSegments,
                  onSubmit: (newSegments) {
                    context
                        .read<GladiatorArenaProvider>()
                        .editPlayerScore(currentPlayerId, newSegments);
                  },
                  config: EditScoreDialogConfig.gladiatorArena(),
                );
              },
            ),
          // Dartboard emulator section
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
              config: DartboardSectionConfig.gladiatorArena(),
              onPlayToComplete: _mockApi != null ? _onPlayToComplete : null,
              playToCompleteConfig: _mockApi != null
                  ? PlayToCompleteButtonConfig.gladiatorArena()
                  : null,
            ),
          ),
          // FAB
          Positioned(
            right: 16,
            bottom: 16,
            child: DartboardEmulatorFAB(
              controller: _dartboardEmulatorController,
              isConnected: !dartboardProvider.isEmulator,
              config: DartboardFABConfig.gladiatorArena(),
              onCancelAutoPlay: _onCancelAutoPlay,
            ),
          ),
          // Save Game Modal
          if (_showSaveModal)
            SaveGameModal(
              config: SaveGameModalConfig.gladiatorArena(),
              onSave: () async {
                await provider.saveGame(allPlayers);
                if (mounted) Navigator.of(context).pop();
              },
              onDontSave: () => Navigator.of(context).pop(),
            ),
          // Dartboard Paused Modal — last child
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status != DartboardConnectionStatus.connected &&
              dartboardProvider.status != DartboardConnectionStatus.emulator)
            DartboardPausedModal(
              config: DartboardPausedModalConfig.gladiatorArena(),
            ),
        ],
      ),
    );
  }

  Widget _buildArenaPodiums(dynamic game, String currentPlayerId,
      List<dynamic> allPlayers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final playerCount = game.playerIds.length;
        // Character HEIGHT (target render height — all characters fill this
        // same height regardless of source aspect ratio, via BoxFit.fitHeight).
        final charSize = _charSizeForCount(playerCount, constraints.maxWidth);
        // Character BOX WIDTH — sized for the widest expected source aspect
        // (~1.3:1 for AquilaEagle with wings spread). With fitHeight inside
        // this box, narrower characters center horizontally; the widest fills
        // the box.
        final charBoxWidth = charSize * 1.3;
        // Podium / column width — just a little wider than the widest
        // character box.
        final barWidth = charBoxWidth + 16;

        // Reserve vertical space above the bar for the column's other
        // children — sized for the worst case (active player with Speed Play
        // ON and Double Range visible) so the bar never pushes content past
        // the available height.
        //   Name pill           ~28  (font 18 + 4 pad + line gap)
        //   Speed-timer pill    ~34  (font 16 + 6 pad + 2 border + 6 outer)
        //   Double-range label  ~20  (font 12 + 4 bottom pad)
        //   Score text          ~20  (font 14 + line gap)
        //   Gap before bar       ~4
        //   Buffer               ~4
        const reservedAbove = 28.0 + 34.0 + 20.0 + 20.0 + 4.0 + 4.0;
        final barMaxHeight =
            (constraints.maxHeight - charSize - reservedAbove)
                .clamp(120.0, 500.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: game.playerIds.map<Widget>((id) {
              return _buildPodium(
                game: game,
                playerId: id as String,
                currentPlayerId: currentPlayerId,
                allPlayers: allPlayers,
                charSize: charSize,
                charBoxWidth: charBoxWidth,
                barWidth: barWidth,
                barMaxHeight: barMaxHeight,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  double _charSizeForCount(int count, double availableWidth) {
    // Per-count clamp ceilings + per-column multipliers, anchored on:
    //   • 2-player head-to-head feel (ceiling 280)
    //   • 4-player target (ceiling 254, +15% over the previous tweak)
    // Counts 3 and 5–8 are calibrated so the total podium row at the clamp
    // ceiling fills a consistent ~96% of a wide tablet/desktop screen
    // (≈1385 px row at 1440 px width). Pillar width tracks automatically via
    // charBoxWidth = charSize × 1.3 and barWidth = charBoxWidth + 16.
    if (count <= 2) return (availableWidth / count * 0.42).clamp(140.0, 280.0);
    if (count == 3) return (availableWidth / count * 0.70).clamp(135.0, 267.0);
    if (count == 4) return (availableWidth / count * 1.00).clamp(125.0, 254.0);
    if (count == 5) return (availableWidth / count * 0.85).clamp(105.0, 200.0);
    if (count == 6) return (availableWidth / count * 0.85).clamp(85.0, 165.0);
    if (count == 7) return (availableWidth / count * 0.85).clamp(70.0, 140.0);
    return (availableWidth / count * 0.85).clamp(60.0, 121.0); // 8 players
  }

  /// Computes the active player's displayed score, factoring in darts thrown
  /// during the current turn. With Double Finish enabled, a prospective bust
  /// (overshoot, or reaching target without a double) reverts to the pre-turn
  /// base so the podium snaps back visually.
  ///
  /// Once the turn has ended (3 darts thrown), `game.scores` already reflects
  /// the final outcome — including a no-update on bust — so we read it
  /// directly to avoid double-counting the dart values still held in
  /// `currentTurnDartValues` until takeout finishes.
  int _liveActiveScore(dynamic game, String playerId, int base, int target) {
    final dartsThrown = (game.dartsThrown[playerId] as int?) ?? 0;
    if (dartsThrown >= 3) return base;

    final values = (game.currentTurnDartValues[playerId] as List?) ?? const [];
    if (values.isEmpty) return base;
    final segments =
        (game.currentTurnDartSegments[playerId] as List?) ?? const [];
    final sum = values.fold<int>(0, (s, v) => s + (v as int));
    final prospective = base + sum;

    if (game.doubleFinishEnabled == true) {
      if (prospective > target) return base;
      if (prospective == target) {
        final last = segments.isNotEmpty ? segments.last as String : '';
        return last.startsWith('D') ? target : base;
      }
      return prospective;
    }
    return prospective.clamp(0, target);
  }

  Widget _buildPodium({
    required dynamic game,
    required String playerId,
    required String currentPlayerId,
    required List<dynamic> allPlayers,
    required double charSize,
    required double charBoxWidth,
    required double barWidth,
    required double barMaxHeight,
  }) {
    final isActive = playerId == currentPlayerId;
    final score = game.scores[playerId] as int? ?? 0;
    final target = game.targetScore as int;

    // Live podium height: for the active player, grow with each dart thrown
    // this turn. If Double Finish is on and the in-progress total would bust
    // (overshoot, or hits target on a non-double), snap back to the pre-turn
    // score so the bar visibly resets.
    final liveScore = isActive
        ? _liveActiveScore(game, playerId, score, target)
        : score;
    final progress = (liveScore / target).clamp(0.0, 1.0);
    // Bumped min from 12 → 24 so empty bars are clearly visible at game start.
    final barHeight = (progress * barMaxHeight).clamp(24.0, barMaxHeight);

    final player = allPlayers.where((p) => p.id == playerId).firstOrNull;
    final playerName = player?.name ?? '';

    // Character image path from game model
    final characterPath = game.playerCharacterPaths[playerId] as String?;

    // Double range indicator: active player only, DF ON, within range
    final showDoubleRange = isActive &&
        game.doubleFinishEnabled == true &&
        score > 0 &&
        (target - score) >= 2 &&
        (target - score) <= 40 &&
        (target - score) % 2 == 0;

    // Shape-conformal glow on the active player's character silhouette.
    // ImageFiltered (blur) + ColorFiltered(BlendMode.srcIn) applied to a copy
    // of the same Image.asset means the glow follows the alpha mask of the
    // character art — NOT a rectangular box around the bounding rect.
    //
    // BoxFit.fitHeight ensures every character renders at the same visual
    // height (charSize) regardless of source aspect ratio. The enclosing
    // SizedBox is wider than tall to accommodate the widest expected
    // character (~1.3:1 aspect for AquilaEagle); narrower characters center
    // horizontally inside the box.
    Widget buildCharacterImage() {
      final fallbackIcon = Icon(
        Icons.person,
        color: isActive ? _kGladiatorGold : _kMarbleWhite,
        size: charSize * 0.7,
      );
      if (characterPath == null) {
        return SizedBox(
          width: charBoxWidth,
          height: charSize,
          child: Center(child: fallbackIcon),
        );
      }

      final foreground = Image.asset(
        characterPath,
        fit: BoxFit.fitHeight,
        errorBuilder: (_, __, ___) => fallbackIcon,
      );

      if (!isActive) {
        return SizedBox(
          width: charBoxWidth,
          height: charSize,
          child: foreground,
        );
      }

      // Active: render a blurred Imperial Purple silhouette behind the
      // foreground at slightly larger bounds so the glow extends outward.
      final glowPad = charSize * 0.10;
      return SizedBox(
        width: charBoxWidth,
        height: charSize,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -glowPad,
              right: -glowPad,
              top: -glowPad,
              bottom: -glowPad,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                    sigmaX: charSize * 0.07, sigmaY: charSize * 0.07),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                      _kImperialPurple.withOpacity(0.85), BlendMode.srcIn),
                  child: Image.asset(
                    characterPath,
                    fit: BoxFit.fitHeight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            foreground,
          ],
        ),
      );
    }

    return SizedBox(
      width: barWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Player name label — ABOVE the character for ALL players (active +
          // inactive). Active player's name renders in Imperial Purple to
          // mirror the active glow; inactive players use Marble White. Wrapped
          // in a Container with horizontal padding + ellipsis truncation so
          // names fit cleanly within the podium column (lunar-lander pattern).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              playerName,
              key: isActive
                  ? GladiatorArenaGameKeys.activePlayerNameLabel
                  : null,
              style: GoogleFonts.cinzel(
                fontSize: isActive ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: _kMarbleWhite,
                shadows: const [
                  Shadow(
                      color: Color(0xCC000000),
                      offset: Offset(1, 1),
                      blurRadius: 2),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Speed Play timer (active player only, when Speed Play is enabled).
          if (isActive && game.speedPlayEnabled == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 2),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _speedPlaySecondsRemaining <= 5
                      ? _kBloodRed.withOpacity(0.25)
                      : _kImperialPurple.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _speedPlaySecondsRemaining <= 5
                        ? _kBloodRed
                        : _kImperialPurple,
                    width: 1,
                  ),
                ),
                child: Text(
                  '$_speedPlaySecondsRemaining',
                  key: GladiatorArenaGameKeys.timerDisplay,
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _speedPlaySecondsRemaining <= 5
                        ? _kBloodRed
                        : _kMarbleWhite,
                  ),
                ),
              ),
            ),
          // Double range indicator (active only, between name and character)
          if (showDoubleRange)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Double Range!',
                key: GladiatorArenaGameKeys.doubleRangeIndicator,
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _kGladiatorGold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // Character image — shape-conformal glow when active
          SizedBox(
            key: GladiatorArenaGameKeys.podium(playerId),
            child: buildCharacterImage(),
          ),
          // Score (active player shows the live in-turn total to match bar)
          Text(
            '$liveScore',
            style: GoogleFonts.cinzel(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _kGladiatorGold,
            ),
          ),
          const SizedBox(height: 2),
          // Podium bar — active uses Imperial Purple to match the active
          // player's silhouette glow; inactive uses Colosseum Gray for a
          // uniform colosseum-stone look.
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: barWidth - 8,
            height: barHeight,
            decoration: BoxDecoration(
              color: isActive ? _kImperialPurple : _kColosseumGray,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEliminationZone(dynamic game, List<dynamic> allPlayers) {
    final victimId = game.lastKnockoffVictimId as String?;
    final attackerId = game.lastKnockoffAttackerId as String?;
    final lastAt = game.lastKnockoffAt as DateTime?;

    final showKnockoff = victimId != null &&
        attackerId != null &&
        lastAt != null &&
        DateTime.now().difference(lastAt).inSeconds <= 5;

    String knockoffText = '';
    if (showKnockoff) {
      final victim = allPlayers.where((p) => p.id == victimId).firstOrNull;
      final attacker = allPlayers.where((p) => p.id == attackerId).firstOrNull;
      knockoffText =
          '${victim?.name ?? 'Player'} was knocked off by ${attacker?.name ?? 'Player'}!';
    }

    return Container(
      key: GladiatorArenaGameKeys.eliminationZone,
      height: 30,
      width: double.infinity,
      child: Center(
        child: showKnockoff
            ? Text(
                knockoffText,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: _kBloodRed,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
