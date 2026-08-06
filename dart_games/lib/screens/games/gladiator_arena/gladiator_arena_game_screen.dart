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
import '../../../services/gladiator_arena_sound_effects.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/dartboard_emulator/buff_toggle_column.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator_config.dart';
import '../../../widgets/dartboard_emulator/play_to_complete_runner.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/edit_score/edit_score.dart';
import '../../../widgets/edit_score/edit_score_dialog_config.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/auto_save_on_pause.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal_config.dart';
import '../../../widgets/interactive_dartboard.dart';
import 'gladiator_arena_results_screen.dart';
import '../../../utils/dart_sector.dart';

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

  // Milestone-announcement state-transition tracking (per playerId). Each
  // milestone fires at most once per *crossing* from out-of-zone → in-zone.
  // If the player gets knocked off (score drops out of zone) the flag flips
  // back to false automatically and the milestone can re-fire on the next
  // crossing.
  //   • _wasInDoubleRange  — DF ON AND (target - score) in [2..40] AND even
  //   • _wasInNearVictory  — (target - score) in [1..20]
  final Map<String, bool> _wasInDoubleRange = {};
  final Map<String, bool> _wasInNearVictory = {};

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
    await queueService.loadSettings(preloadEffects: GladiatorArenaSoundEffects.all);
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
          (_audioQueue?.whenIdle() ?? Future<void>.value())
          .timeout(const Duration(seconds: 10), onTimeout: () {})
          .then((_) {
            if (mounted) _startSpeedPlayTimerIfNeeded();
          });
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

      // Milestone announcements — fire on the dart that *crosses* the active
      // player into the double-range or near-victory zone. Matches the
      // Reef Royale / Clockwork Quest precedent: gated by a state-transition
      // flag so each crossing fires at most once. Near victory takes
      // precedence when both apply (it's the more urgent milestone). Skip
      // on victory (already handled by announceVictory).
      //
      // After firing, tracking flags are re-synced for ALL players (not just
      // the active one) so a knockoff victim's drop to 0 is reflected — when
      // they climb back into the zone later, the milestone re-fires.
      if (!provider.hasWinner) {
        final newScore = game.scores[playerId] ?? 0;
        final remaining = targetScore - newScore;
        final inDoubleRange = dfOn &&
            remaining >= 2 &&
            remaining <= 40 &&
            remaining.isEven;
        final inNearVictory = remaining >= 1 && remaining <= 20;
        final wasInDR = _wasInDoubleRange[playerId] ?? false;
        final wasInNV = _wasInNearVictory[playerId] ?? false;

        if (newScore > 0) {
          if (inNearVictory && !wasInNV) {
            _audioQueue?.announceNearVictory(currentPlayerName);
          } else if (inDoubleRange && !wasInDR) {
            _audioQueue?.announceDoubleRange(currentPlayerName);
          }
        }
        // Sync flags for EVERY player, not just the active one. A knockoff
        // victim went from in-zone → 0, so their flags must clear to allow
        // re-firing when they come back. A player at score 0 has both flags
        // false regardless of the (target - 0) arithmetic.
        for (final id in game.playerIds) {
          final s = game.scores[id] ?? 0;
          final r = targetScore - s;
          _wasInDoubleRange[id] =
              dfOn && s > 0 && r >= 2 && r <= 40 && r.isEven;
          _wasInNearVictory[id] = s > 0 && r >= 1 && r <= 20;
        }
      }
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

  /// Parses a board sector string into this game's legacy map shape.
  ///
  /// `score` is the FACE value; the bull reports multiplier 'bull'.
  /// Delegates to [DartSector].
  Map<String, dynamic>? _parseSector(String sector) {
    final dart = DartSector.parse(sector);
    if (dart.isMiss) return null;
    if (dart.isInnerBull) return {'score': 50, 'multiplier': 'bull'};
    if (dart.isOuterBull) return {'score': 25, 'multiplier': 'single'};
    return {'score': dart.face, 'multiplier': dart.multiplierName};
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

    // Reset timer display immediately so new player sees full time
    final game = provider.currentGame;
    if (game != null && game.speedPlayEnabled) {
      _speedPlayTimer?.cancel();
      setState(() => _speedPlaySecondsRemaining = 25);
    }

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
          (_audioQueue?.whenIdle() ?? Future<void>.value())
          .timeout(const Duration(seconds: 10), onTimeout: () {})
          .then((_) {
            if (mounted) _startSpeedPlayTimerIfNeeded();
          });
        }
      });
    } else {
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
      final provider = context.read<GladiatorArenaProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final winnerId = provider.currentGame?.winnerId;
      if (winnerId != null) {
        final winner = playerProvider.getPlayerById(winnerId);
        if (winner != null) {
          _audioQueue?.announceVictory(winner.name);
        }
      }
      (_audioQueue?.whenIdle() ?? Future<void>.value())
          .timeout(const Duration(seconds: 10), onTimeout: () {})
          .then((_) {
        Future.delayed(const Duration(milliseconds: 250), navigateToResults);
      });
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

    return AutoSaveOnPause(
      onPaused: () {
        if (!hasDartsThrown) return;
        provider.saveGame(allPlayers, isAutoSave: true);
      },
      child: PopScope(
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
              title: Transform.translate(
                // Cinzel's ascender pushes the visual baseline high in
                // the AppBar strip; nudge down 2 px so caps sit centered.
                offset: const Offset(0, 2),
                child: Text(
                  'GLADIATOR ARENA',
                  style: GoogleFonts.cinzel(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _kMarbleWhite,
                    letterSpacing: 1.5,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4,
                          offset: Offset(1, 1)),
                    ],
                  ),
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
                    // Bottom padding for emulator overlay (halved per design).
                    // Was 60 — trimmed by 45 to absorb the elimination-zone's
                    // height growth (30 → 75) for the larger 2-line knockoff
                    // label so the podium row above doesn't shift.
                    const SizedBox(height: 15),
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
              buffToggles: _mockApi != null
                  ? [
                      BuffToggleSpec<Object>(
                        buff: 'shieldRound',
                        label: 'Shield\nRound',
                        isActive: game.isShieldRound,
                        isEnabled: game.shieldRoundEnabled,
                        buttonKey: DartboardEmulatorKeys.buffToggleButton('shieldRound'),
                        config: BuffToggleButtonConfig.gladiatorArena(),
                      ),
                    ]
                  : null,
              onBuffToggle: _mockApi != null
                  ? (_) {
                      context.read<GladiatorArenaProvider>().toggleShieldRoundOverride();
                    }
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
      ),
    );
  }

  Widget _buildArenaPodiums(dynamic game, String currentPlayerId,
      List<dynamic> allPlayers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final playerCount = game.playerIds.length;
        // Character HEIGHT (target render height — all characters fill this
        // same height via BoxFit.fitHeight, so silhouettes line up).
        final charSize = _charSizeForCount(playerCount, constraints.maxWidth);
        // Character BOX WIDTH = charSize × 1.3 — sized for the widest source
        // aspect (AquilaEagle ~1.3:1 with wings spread). Without this, the
        // eagle's wings render beyond the SizedBox via fitHeight overflow and
        // get painted over by the neighbor's character (z-order in the row),
        // looking like the wings are clipped. The high-count charSize
        // ceilings are tuned so charBoxWidth ≤ slot at 1440 px so the eagle
        // never extends into its neighbor's slot.
        final charBoxWidth = charSize * 1.3;

        // Reserve vertical space above the bar for the column's other
        // children — sized for the worst case (active player with Speed Play
        // ON and Double Range visible) so the bar never pushes content past
        // the available height.
        //   Name pill           ~28  (font 18 + 4 pad + line gap)
        //   Speed-timer pill    ~34  (font 16 + 6 pad + 2 border + 6 outer)
        //   Double-range label  ~20  (font 12 + 4 bottom pad)
        //   Score text          ~26  (font 18 + line gap)
        //   Gap before bar       ~4
        //   Buffer               ~4
        const reservedAbove = 28.0 + 34.0 + 20.0 + 26.0 + 4.0 + 4.0;
        final barMaxHeight =
            (constraints.maxHeight - charSize - reservedAbove)
                .clamp(120.0, 500.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            // Each player gets an Expanded slot (= row_width / N), like
            // Lunar Lander. Leftover space stays inside the slot rather than
            // being distributed as gaps between podiums, so adjacent
            // characters sit much closer at higher player counts.
            children: game.playerIds.map<Widget>((id) {
              return Expanded(
                child: _buildPodium(
                  game: game,
                  playerId: id as String,
                  currentPlayerId: currentPlayerId,
                  allPlayers: allPlayers,
                  charSize: charSize,
                  charBoxWidth: charBoxWidth,
                  barMaxHeight: barMaxHeight,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  double _charSizeForCount(int count, double availableWidth) {
    // Per-count clamp ceilings + per-column multipliers.
    //   • 2-player: head-to-head feel (ceiling 280)
    //   • 3- and 4-player: large characters (ceilings 267 / 254)
    //   • 5–8 player: ceilings = floor(slot_width / 1.3) at 1440 px so the
    //     eagle's 1.3:1 wings always fit inside their own Expanded slot
    //     (otherwise the neighbor's character paints over the wing tips).
    if (count <= 2) return (availableWidth / count * 0.42).clamp(140.0, 280.0);
    if (count == 3) return (availableWidth / count * 0.70).clamp(135.0, 267.0);
    if (count == 4) return (availableWidth / count * 1.00).clamp(125.0, 254.0);
    if (count == 5) return (availableWidth / count * 0.85).clamp(105.0, 220.0);
    if (count == 6) return (availableWidth / count * 0.85).clamp(85.0, 184.0);
    if (count == 7) return (availableWidth / count * 0.85).clamp(70.0, 158.0);
    return (availableWidth / count * 0.85).clamp(60.0, 138.0); // 8 players
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
    // Foreground character only (no inline glow). The active player's glow is
    // now rendered as a separate background layer in the Stack below so it can
    // bleed up behind the name and score.
    Widget buildCharacterForeground() {
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
      return SizedBox(
        width: charBoxWidth,
        height: charSize,
        child: Image.asset(
          characterPath,
          fit: BoxFit.fitHeight,
          errorBuilder: (_, __, ___) => fallbackIcon,
        ),
      );
    }

    // Top zone — name, timer/double-range, score, character — wrapped in a
    // Stack so the active player's Imperial Purple glow can render BEHIND
    // every element above the bar. The glow is the character silhouette
    // bottom-anchored inside a tall blur layer; with sigma ~charSize*0.20 the
    // haze bleeds upward behind the score and name without distorting the
    // character's shape-conformal halo at the bottom.
    final glowPad = charSize * 0.10;
    final topZone = Stack(
      clipBehavior: Clip.none,
      children: [
        if (isActive && characterPath != null)
          Positioned(
            left: -glowPad,
            right: -glowPad,
            top: 0,
            bottom: -glowPad,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                    sigmaX: charSize * 0.20, sigmaY: charSize * 0.20),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: charBoxWidth + glowPad * 2,
                    height: charSize + glowPad * 2,
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
              ),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name label
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
            // Speed Play timer (active only)
            if (isActive && game.speedPlayEnabled == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
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
            // Double range indicator (active only)
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
            // Score — sits between name and character. Color matches the name
            // (Marble White) for visual unity; active player shows the live
            // in-turn total to match the bar.
            Text(
              '$liveScore',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kMarbleWhite,
                shadows: const [
                  Shadow(
                      color: Color(0xCC000000),
                      offset: Offset(1, 1),
                      blurRadius: 2),
                ],
              ),
            ),
            // Character (foreground only — glow is the Stack's first child)
            SizedBox(
              key: GladiatorArenaGameKeys.podium(playerId),
              child: buildCharacterForeground(),
            ),
          ],
        ),
      ],
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        topZone,
        const SizedBox(height: 2),
        // Podium bar — rendered as a marble Roman column with vertical
        // fluting and cylindrical shading. Active players get an Imperial
        // Purple wash over the marble; inactive players a subtle Colosseum
        // Gray wash. Pillar width is anchored to charSize × 0.992 so the
        // column reads as a slightly-narrower plinth under the character.
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: charSize * 0.992,
          height: barHeight,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
            child: CustomPaint(
              size: Size.infinite,
              painter: _RomanColumnPainter(
                tint: isActive ? _kImperialPurple : _kColosseumGray,
                isActive: isActive,
              ),
            ),
          ),
        ),
      ],
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
          'Devastating blow! ${victim?.name ?? 'Player'} was knocked off '
          'their pedestal by ${attacker?.name ?? 'Player'}!';
    }

    return Container(
      key: GladiatorArenaGameKeys.eliminationZone,
      height: 75,
      width: double.infinity,
      child: Center(
        child: showKnockoff
            ? Text(
                knockoffText,
                style: GoogleFonts.lato(
                  fontSize: 30,
                  color: _kBloodRed,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  shadows: const [
                    // Black outline — stacked 0-blur shadows at 4 offsets
                    Shadow(color: Colors.black, offset: Offset(-1.5, 0), blurRadius: 0),
                    Shadow(color: Colors.black, offset: Offset(1.5, 0), blurRadius: 0),
                    Shadow(color: Colors.black, offset: Offset(0, -1.5), blurRadius: 0),
                    Shadow(color: Colors.black, offset: Offset(0, 1.5), blurRadius: 0),
                    // Soft drop shadow for depth
                    Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 5),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ─── Roman column painter ────────────────────────────────────────────────────
// Renders a fluted marble Roman column. Layers, bottom-up:
//   1. Warm-cream marble base gradient (top→bottom, slight darkening).
//   2. Soft marble veining (a few subtle wavy strokes).
//   3. Vertical flutes — concave grooves rendered as horizontal
//      light→dark→light gradients across each flute strip, separated by thin
//      bright fillets at the seams to read as raised ridges.
//   4. Cylindrical shading — left/right edges darken to suggest the column's
//      curvature.
//   5. Player tint wash (Imperial Purple for active, Colosseum Gray for
//      inactive) at low opacity so the marble character is preserved.
class _RomanColumnPainter extends CustomPainter {
  const _RomanColumnPainter({required this.tint, required this.isActive});

  final Color tint;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Offset.zero & size;

    // 1. Marble base — warm cream, slightly cooler at the bottom.
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF7F2E6), // top — bright cream
          Color(0xFFE6DCC8), // bottom — warmer shadowed marble
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Marble veining — a few faint wavy strokes. Deterministic (seeded by
    // size.width.toInt()) so the same-width column is stable across rebuilds.
    final veinPaint = Paint()
      ..color = const Color(0x33857058)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final seed = size.width.toInt();
    for (int i = 0; i < 3; i++) {
      final t = ((seed + i * 37) % 100) / 100.0;
      final yStart = size.height * (0.15 + 0.25 * t);
      final yEnd = size.height * (0.55 + 0.35 * ((seed + i * 19) % 100) / 100);
      final p = Path()
        ..moveTo(-2, yStart)
        ..cubicTo(
          size.width * 0.30, yStart + size.height * 0.05,
          size.width * 0.65, yStart + size.height * 0.18,
          size.width + 2, yEnd,
        );
      canvas.drawPath(p, veinPaint);
    }

    // 3. Vertical fluting. Number of flutes scales with width so each flute
    // stays at least ~10 px wide; clamped to a sensible range.
    final fluteCount = (size.width / 18).round().clamp(5, 9);
    final fluteWidth = size.width / fluteCount;
    for (int i = 0; i < fluteCount; i++) {
      final x = i * fluteWidth;
      final fluteRect = Rect.fromLTWH(x, 0, fluteWidth, size.height);
      // Concave groove: shadowed across the whole flute, deepest in the
      // center, falling off toward the rim. Edges stay dark so the bright
      // fillet line at the seam reads as a raised ridge against carved sides.
      final groovePaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x14000000), // rim-side shadow (just inside the fillet)
            Color(0x33000000), // descending into groove
            Color(0x4D000000), // deepest groove shadow (center)
            Color(0x33000000), // rising back up
            Color(0x14000000), // rim-side shadow
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(fluteRect);
      canvas.drawRect(fluteRect, groovePaint);
    }

    // Fillet ridges between flutes — drawn AFTER all flute shadows so they
    // sit cleanly on top. Each ridge is a bright highlight line flanked by
    // thin dark "carved-edge" lines on either side, which is what makes the
    // groove read as concave rather than just darkened.
    final filletHighlight = Paint()
      ..color = const Color(0xCCFFF8E8)
      ..strokeWidth = 1.2;
    final carvedEdge = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.0;
    for (int i = 1; i < fluteCount; i++) {
      final x = i * fluteWidth;
      // Dark carved edge on the left side of the ridge…
      canvas.drawLine(
          Offset(x - 1, 0), Offset(x - 1, size.height), carvedEdge);
      // …bright highlight at the ridge crest…
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), filletHighlight);
      // …dark carved edge on the right side of the ridge.
      canvas.drawLine(
          Offset(x + 1, 0), Offset(x + 1, size.height), carvedEdge);
    }

    // 4. Cylindrical body shading — strong vignette on the left edge, softer
    // on the right (light from upper-right convention).
    final cylPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x66000000),
          Color(0x00000000),
          Color(0x00000000),
          Color(0x33000000),
        ],
        stops: [0.0, 0.20, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, cylPaint);

    // 5. Player tint wash — preserves marble while signalling active state.
    final tintPaint = Paint()
      ..color = tint.withOpacity(isActive ? 0.32 : 0.18)
      ..blendMode = BlendMode.multiply;
    canvas.drawRect(rect, tintPaint);

    // 6. Subtle top edge highlight — sells the rounded-top capital.
    final capPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 6));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 6), capPaint);
  }

  @override
  bool shouldRepaint(covariant _RomanColumnPainter old) =>
      old.tint != tint || old.isActive != isActive;
}
