import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../models/monster_mash_game.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/monster_mash_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/monster_mash_announcement_helper.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/edit_score/edit_score.dart';
import 'monster_mash_results_screen.dart';

class MonsterMashGameScreen extends StatefulWidget {
  const MonsterMashGameScreen({super.key});

  @override
  State<MonsterMashGameScreen> createState() => _MonsterMashGameScreenState();
}

class _MonsterMashGameScreenState extends State<MonsterMashGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  MonsterMashAnnouncementHelper? _audioQueue;
  final DartboardEmulatorController _dartboardEmulatorController = DartboardEmulatorController();
  bool _gameCompleted = false;

  // Track health tiers for announcement threshold-crossing detection
  // 0=healthy(>70%), 1=weakening(<=70%), 2=critical(<=30%), 3=barely(<=10%)
  final Map<String, int> _playerHealthTier = {};

  static int _getHealthTier(double pct) {
    if (pct <= 0.10) return 3;
    if (pct <= 0.30) return 2;
    if (pct <= 0.70) return 1;
    return 0;
  }

  // Shuffled opponent order for grid placement (generated once)
  List<int>? _shuffledOpponentOrder;

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

    final globalQueue = GameAnnouncementQueueService();
    await globalQueue.loadSettings();
    _audioQueue = MonsterMashAnnouncementHelper(globalQueue);

    if (_mockApi != null) {
      _dartboardSubscription = _mockApi!.eventStream.listen((event) {
        _handleDartboardEvent(event);
      });
    }

    // Generate shuffled order for grid cell assignment
    final monsterMashProvider = context.read<MonsterMashProvider>();
    final opponentCount = (monsterMashProvider.currentGame?.playerIds.length ?? 2) - 1;
    _shuffledOpponentOrder = List.generate(opponentCount, (i) => i)..shuffle(Random());

    // Initialize health tiers based on starting health
    final monsterMashProviderInit = context.read<MonsterMashProvider>();
    final currentGameInit = monsterMashProviderInit.currentGame;
    if (currentGameInit != null) {
      for (final playerId in currentGameInit.playerIds) {
        final pct = monsterMashProviderInit.getHealth(playerId) / currentGameInit.healthMax;
        _playerHealthTier[playerId] = _getHealthTier(pct);
      }
    }

    _audioQueue!.announceGameStart();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _announceCurrentPlayerTurn();
      }
    });
  }

  // Grid layout for opponents: determines rows/cols based on count
  static Map<String, int> _getGridLayout(int count) {
    if (count <= 1) return {'cols': 1, 'rows': 1};
    if (count <= 3) return {'cols': 3, 'rows': 2};
    if (count <= 5) return {'cols': 3, 'rows': 2};
    return {'cols': 3, 'rows': 3};
  }

  // Size multiplier based on opponent count (fewer opponents = larger characters)
  static double _getSizeMultiplier(int count) {
    if (count <= 1) return 2.2;
    if (count <= 3) return 1.4;
    if (count <= 5) return 1.35;
    return 1.0;
  }

  // Get specific cell assignments: bottom-heavy layout (more on bottom, fewer on top)
  static List<Map<String, int>> _getCellAssignments(int count, int cols, int rows) {
    // 1 opponent: single centered cell
    if (count <= 1) {
      return [{'row': 0, 'col': 0}];
    }
    // 2-3 opponents: 2 rows, skip bottom-left cell (closest to current player)
    if (count <= 3) {
      final assignments = <Map<String, int>>[];
      if (count == 2) {
        // 1 top-middle, 1 bottom-right
        assignments.add({'row': 0, 'col': 1});
        assignments.add({'row': 1, 'col': 2});
      } else {
        // 3 opponents: 1 top-middle, 2 on bottom (middle and right, skip col 0)
        assignments.add({'row': 0, 'col': 1});
        assignments.add({'row': 1, 'col': 1});
        assignments.add({'row': 1, 'col': 2});
      }
      return assignments;
    }
    // 4-5 opponents: 2 rows, bottom-heavy
    // Top row offset by half cell, so col 0+0.5 and col 1+0.5 stagger between bottom cols
    if (count <= 5) {
      final assignments = <Map<String, int>>[];
      if (count == 4) {
        // 1 top (centered between bottom cols 1-2), 3 bottom
        assignments.add({'row': 0, 'col': 1});
        assignments.add({'row': 1, 'col': 0});
        assignments.add({'row': 1, 'col': 1});
        assignments.add({'row': 1, 'col': 2});
      } else {
        // 5 opponents: 2 top staggered, 3 bottom
        assignments.add({'row': 0, 'col': 0});
        assignments.add({'row': 0, 'col': 1});
        assignments.add({'row': 1, 'col': 0});
        assignments.add({'row': 1, 'col': 1});
        assignments.add({'row': 1, 'col': 2});
      }
      return assignments;
    }
    // 6-7 opponents: 3 rows — 1 top, 2 middle, 3 bottom
    final assignments = <Map<String, int>>[];
    if (count == 6) {
      // 1 top-middle, 2 middle, 3 bottom
      assignments.add({'row': 0, 'col': 1});
      assignments.add({'row': 1, 'col': 0});
      assignments.add({'row': 1, 'col': 1});
      assignments.add({'row': 2, 'col': 0});
      assignments.add({'row': 2, 'col': 1});
      assignments.add({'row': 2, 'col': 2});
    } else {
      // 7 opponents: 2 top, 2 middle, 3 bottom
      assignments.add({'row': 0, 'col': 1});
      assignments.add({'row': 0, 'col': 2});
      assignments.add({'row': 1, 'col': 0});
      assignments.add({'row': 1, 'col': 1});
      assignments.add({'row': 2, 'col': 0});
      assignments.add({'row': 2, 'col': 1});
      assignments.add({'row': 2, 'col': 2});
    }
    return assignments;
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
    final monsterMashProvider = context.read<MonsterMashProvider>();
    if (!mounted || !monsterMashProvider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;

    final playerProvider = context.read<PlayerProvider>();
    final allPlayers = playerProvider.allPlayers;
    final currentPlayer = monsterMashProvider.getCurrentPlayer(allPlayers);
    if (currentPlayer == null) return;

    final currentGame = monsterMashProvider.currentGame!;
    final currentPlayerId = monsterMashProvider.getCurrentPlayerId()!;

    // Track health before processing for announcements
    final allHealthBefore = <String, int>{};
    for (final playerId in currentGame.playerIds) {
      allHealthBefore[playerId] = monsterMashProvider.getHealth(playerId);
    }
    final eliminatedBefore = currentGame.playerIds.where((id) => monsterMashProvider.isEliminated(id)).toSet();

    // Process the dart throw
    monsterMashProvider.processDartThrow(sector);

    // Parse sector for announcements
    final parsed = _parseSector(sector);
    final isMiss = sector == 'None' || parsed == null;

    // --- Gather facts ---

    // Healing
    final healthAfter = monsterMashProvider.getHealth(currentPlayerId);
    final healthBefore = allHealthBefore[currentPlayerId]!;
    final hasHealing = healthAfter > healthBefore;
    final healAmount = hasHealing ? healthAfter - healthBefore : 0;
    final hasClutchHeal = hasHealing && healthBefore < 10 && healthBefore > 0;

    // Attack
    final dartThrowTargetPlayerIds = monsterMashProvider.getDartThrowTargetPlayerId(currentPlayerId);
    final dartThrowDamageDealt = monsterMashProvider.getDartThrowDamageDealt(currentPlayerId);
    final dartIndex = dartThrowTargetPlayerIds.length - 1;

    String? attackTargetId;
    String? attackTargetName;
    final attackMultiplier = parsed?['multiplier'] as String? ?? 'single';
    int attackDamage = 0;
    bool hasAttack = false;

    if (dartIndex >= 0 && dartThrowTargetPlayerIds[dartIndex] != null) {
      attackTargetId = dartThrowTargetPlayerIds[dartIndex]!;
      attackDamage = dartThrowDamageDealt[dartIndex];
      attackTargetName = allPlayers.firstWhere((p) => p.id == attackTargetId).name;
      hasAttack = true;
    }

    // Eliminations
    final eliminatedAfter = currentGame.playerIds.where((id) => monsterMashProvider.isEliminated(id)).toSet();
    final newlyEliminated = eliminatedAfter.difference(eliminatedBefore);
    final hasElimination = newlyEliminated.isNotEmpty;

    // Hat trick
    bool hasHatTrick = false;
    String? hatTrickTargetId;
    String? hatTrickTargetName;
    if (dartThrowTargetPlayerIds.length == 3) {
      final targets = dartThrowTargetPlayerIds.where((t) => t != null).toList();
      if (targets.length == 3 && targets.every((t) => t == targets.first)) {
        hasHatTrick = true;
        hatTrickTargetId = targets.first;
        hatTrickTargetName = allPlayers.firstWhere((p) => p.id == hatTrickTargetId).name;
      }
    }

    // Health warning tier crossing (only for direct attack target)
    bool hasHealthWarningCrossing = false;
    double? warningPct;
    if (hasAttack && attackTargetId != null) {
      final opponentPct = monsterMashProvider.getHealth(attackTargetId) / currentGame.healthMax;
      final newTier = _getHealthTier(opponentPct);
      final oldTier = _playerHealthTier[attackTargetId] ?? 0;
      if (newTier > oldTier) {
        hasHealthWarningCrossing = true;
        warningPct = opponentPct;
      }
    }

    // Update tiers for all players whose health changed
    for (final playerId in currentGame.playerIds) {
      final pct = monsterMashProvider.getHealth(playerId) / currentGame.healthMax;
      _playerHealthTier[playerId] = _getHealthTier(pct);
    }

    // --- Apply precedence rules ---
    final hasSecondary = hasHealing || hasClutchHeal || hasAttack || hasElimination || hasHatTrick;

    // Rule 1: Hit only fires when no secondary effect exists
    if (!hasSecondary) {
      if (!isMiss && parsed != null) {
        _audioQueue!.announceHit(parsed['number'] as int, parsed['multiplier'] as String);
      } else {
        _audioQueue!.announceHit(0, 'single', isMiss: true);
      }
    }

    // Determine which moment announcement fires (highest priority wins)
    if (hasHatTrick && hasElimination && newlyEliminated.contains(hatTrickTargetId)) {
      // Rule 8: Merged hat trick + elimination
      _audioQueue!.announceHatTrickElimination(hatTrickTargetName!);
      // Handle any OTHER eliminations not covered by the hat trick (e.g. Lab Spark)
      final otherEliminated = newlyEliminated.where((id) => id != hatTrickTargetId).toList();
      if (otherEliminated.isNotEmpty) {
        final names = otherEliminated.map((id) => allPlayers.firstWhere((p) => p.id == id).name).toList();
        if (names.length > 1) {
          _audioQueue!.announceCombinedElimination(names);
        } else {
          _audioQueue!.announceElimination(names.first);
        }
      }
    } else if (hasElimination) {
      // Rules 2,3,4,9: Elimination supersedes attack, health warning, heal
      final eliminatedNames = newlyEliminated.map((id) => allPlayers.firstWhere((p) => p.id == id).name).toList();
      if (eliminatedNames.length > 1) {
        _audioQueue!.announceCombinedElimination(eliminatedNames);
      } else {
        _audioQueue!.announceElimination(eliminatedNames.first);
      }
    } else if (hasHatTrick) {
      // Rule 7: Hat trick supersedes attack and health warning
      _audioQueue!.announceHatTrick(hatTrickTargetName!);
    } else if (hasClutchHeal) {
      // Rule 5: Clutch heal supersedes healing amount
      _audioQueue!.announceClutchHeal(currentPlayer.name);
    } else if (hasAttack) {
      // Attack fires (hit already suppressed by rule 1)
      _audioQueue!.announceAttack(attackTargetName!, attackMultiplier, attackDamage);
      // Rule 6: Health warning only on tier crossing
      if (hasHealthWarningCrossing) {
        _audioQueue!.announceHealthWarning(attackTargetName!, warningPct!);
      }
    } else if (hasHealing) {
      // Healing fires (hit already suppressed by rule 1)
      final multiplierStr = parsed?['multiplier'] as String? ?? 'single';
      _audioQueue!.announceHealing(multiplierStr, healAmount);
    }

    // Remove darts (always fires on 3rd dart or winner)
    final dartsThrown = monsterMashProvider.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3 || monsterMashProvider.hasWinner) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _audioQueue!.announceRemoveDarts();
      });
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) _mockApi?.simulateTakeoutStarted();
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
    final monsterMashProvider = context.read<MonsterMashProvider>();
    if (!mounted) return;

    if (monsterMashProvider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!monsterMashProvider.isGameActive) return;

    // Get the buff before advancing (advance may change it)
    final buffBefore = monsterMashProvider.getActiveBuff();

    monsterMashProvider.handleTakeoutFinished();

    // Check if buff changed (new round started)
    final buffAfter = monsterMashProvider.getActiveBuff();
    if (buffAfter != null && buffAfter != buffBefore) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _audioQueue!.announceBuff(buffAfter);
      });
    }

    // Check for game end after advancing (round limit)
    if (monsterMashProvider.hasWinner) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _handleGameWon();
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _announceCurrentPlayerTurn();
    });

    setState(() {});
  }

  void _announceCurrentPlayerTurn() {
    final monsterMashProvider = context.read<MonsterMashProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentPlayer = monsterMashProvider.getCurrentPlayer(playerProvider.allPlayers);
    if (currentPlayer != null) {
      _audioQueue!.announceTurn(currentPlayer.name);
    }
  }

  void _handleGameWon() {
    if (_gameCompleted) return;
    _gameCompleted = true;

    final playerProvider = context.read<PlayerProvider>();
    final monsterMashProvider = context.read<MonsterMashProvider>();
    final winners = monsterMashProvider.getWinners(playerProvider.allPlayers);

    if (winners.isNotEmpty) {
      _audioQueue!.announceWinners(winners.map((p) => p.name).toList());
    }

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MonsterMashResultsScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final monsterMashProvider = context.watch<MonsterMashProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final dartboardProvider = context.watch<DartboardProvider>();

    final currentGame = monsterMashProvider.currentGame;
    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No game in progress')));
    }

    final allPlayers = playerProvider.allPlayers;
    final currentPlayer = monsterMashProvider.getCurrentPlayer(allPlayers);
    final shouldPromptTakeout = monsterMashProvider.shouldPromptTakeout;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFFF5F5DC),
            size: 32,
            shadows: [
              Shadow(
                color: const Color(0xFF7FFF00),
                blurRadius: 20,
              ),
              Shadow(
                color: const Color(0xFF7FFF00).withOpacity(0.8),
                blurRadius: 40,
              ),
            ],
          ),
          onPressed: () => Navigator.of(context).pop(),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Text(
            'It\'s Monster Mashin\' Time!',
            style: GoogleFonts.creepster(
              fontSize: 39,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: const Color(0xFF7FFF00).withOpacity(0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF1A1A2E),
                Color(0xFF7FFF00),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF5F5DC),
        actions: const [],
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/games/monster_mash/images/MonsterMash-Background.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              color: Colors.black.withOpacity(0.3),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // Main game area (fills entire body)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gameAreaWidth = constraints.maxWidth;
                final gameAreaHeight = constraints.maxHeight;
                return Stack(
                  children: [
                    // Opponents (right side, scattered)
                    ..._buildOpponents(currentGame, allPlayers, monsterMashProvider, gameAreaWidth, gameAreaHeight),

                    // Active player (left side)
                    if (currentPlayer != null)
                      _buildActivePlayer(currentGame, currentPlayer, monsterMashProvider),

                    // Remove darts modal
                    if (shouldPromptTakeout && !dartboardProvider.isConnected)
                      _buildRemoveDartsModal(currentPlayer, monsterMashProvider),

                    // Round progress bar (top-center)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildRoundProgressBar(currentGame.currentRound, currentGame.roundLimit, currentGame.activeBuff, currentGame.speedPlayEnabled),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Dartboard emulator (overlay, in front of everything)
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
              config: DartboardSectionConfig.monsterMash(),
            ),
          ),
        ],
      ),
      floatingActionButton: DartboardEmulatorFAB(
        controller: _dartboardEmulatorController,
        isConnected: dartboardProvider.isConnected,
        config: DartboardFABConfig.monsterMash(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // DEBUG: Buff test button (remove later)
  Widget _buildActivePlayer(MonsterMashGame currentGame, Player currentPlayer, MonsterMashProvider provider) {
    final playerId = currentPlayer.id;
    final healthPercent = provider.getHealthPercentage(playerId);
    final currentHealth = provider.getHealth(playerId);
    final targetNumber = provider.getTargetNumber(playerId) ?? 0;
    final imagePath = provider.getMonsterImagePath(playerId)!;
    final dartSegments = provider.getCurrentTurnDarts(playerId);
    final dartsThrown = provider.getCurrentPlayerDartsThrown();

    return Positioned(
      left: 20,
      top: 20,
      bottom: 20,
      width: MediaQuery.of(context).size.width * 0.28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Player name
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              currentPlayer.name,
              style: GoogleFonts.creepster(
                fontSize: 30,
                color: const Color(0xFFF5F5DC),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),

          // Target number with shield
          SizedBox(
            width: 144,
            height: 144,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/games/monster_mash/icons/Shield-Health.png',
                  width: 144,
                  height: 144,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Black outline for readability
                    Text(
                      '$targetNumber',
                      style: GoogleFonts.creepster(
                        fontSize: 96,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 5
                          ..color = Colors.black,
                      ),
                    ),
                    // Main text
                    Text(
                      '$targetNumber',
                      style: GoogleFonts.creepster(
                        fontSize: 96,
                        color: const Color(0xFF7FFF00),
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Health bar
          _buildHealthBar(currentHealth, currentGame.healthMax, healthPercent),
          const SizedBox(height: 8),

          // Monster image (flipped to face right) with ground shadow
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shadow at bottom
                Positioned(
                  bottom: 0,
                  child: _buildGroundShadow(width: 140, height: 16),
                ),
                // Monster image
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Darts thrown display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final segment = i < dartSegments.length ? dartSegments[i] : '';
              return Container(
                width: 60,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F4F4F).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getDartBorderColor(playerId, i, provider),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    segment.isEmpty ? '-' : segment,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF5F5DC),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Skip turn button
          SizedBox(
            width: 160,
            child: ElevatedButton(
              key: MonsterMashGameKeys.skipTurnButton,
              onPressed: dartsThrown < 3 && !provider.shouldPromptTakeout
                  ? () {
                      provider.skipTurn();
                      if (dartsThrown > 0) {
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (mounted) _audioQueue!.announceRemoveDarts();
                        });
                        Future.delayed(const Duration(milliseconds: 3500), () {
                          if (mounted) _mockApi?.simulateTakeoutStarted();
                        });
                      } else {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) _mockApi?.simulateTakeoutFinished();
                        });
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B0082).withOpacity(0.8),
                foregroundColor: const Color(0xFFF5F5DC),
                side: const BorderSide(color: Color(0xFFFF8C00), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Skip Turn',
                style: GoogleFonts.pirataOne(fontSize: 16, color: const Color(0xFFF5F5DC)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDartBorderColor(String playerId, int dartIndex, MonsterMashProvider provider) {
    final healAmounts = provider.getDartThrowHealAmount(playerId);
    final damageDealt = provider.getDartThrowDamageDealt(playerId);
    final dartSegments = provider.getCurrentTurnDarts(playerId);

    if (dartIndex >= dartSegments.length || dartSegments[dartIndex].isEmpty) {
      return const Color(0xFF2F4F4F);
    }

    final segment = dartSegments[dartIndex];
    if (segment == 'Miss' || segment == 'Skip') {
      return const Color(0xFFF5F5DC).withOpacity(0.3);
    }

    if (dartIndex < healAmounts.length && healAmounts[dartIndex] > 0) {
      return const Color(0xFF7FFF00); // Green for healing
    }
    if (dartIndex < damageDealt.length && damageDealt[dartIndex] > 0) {
      return const Color(0xFFFF4444); // Red for damage
    }

    return const Color(0xFFF5F5DC).withOpacity(0.3);
  }

  List<Widget> _buildOpponents(
    MonsterMashGame currentGame,
    List<Player> allPlayers,
    MonsterMashProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    final currentPlayerId = provider.getCurrentPlayerId();
    final opponents = currentGame.playerIds.where((id) => id != currentPlayerId).toList();
    final n = opponents.length;

    // Grid layout based on opponent count
    final grid = _getGridLayout(n);
    final cols = grid['cols']!;
    final rows = grid['rows']!;

    // Opponent area: adjust based on opponent count
    final rightAreaStart = n <= 1 ? screenWidth * 0.40 : screenWidth * 0.30;
    final rightAreaEnd = n <= 1 ? screenWidth * 0.90 : screenWidth * 1.04;
    final rightAreaWidth = rightAreaEnd - rightAreaStart;

    // Vertical: use 15% to 85% of game area height
    final topBand = screenHeight * 0.15;
    final bottomBand = screenHeight * 0.85;
    final bandHeight = bottomBand - topBand;

    // Cell dimensions
    final cellWidth = rightAreaWidth / cols;
    final cellHeight = bandHeight / rows;

    // Get bottom-heavy cell assignments
    final cellAssignments = _getCellAssignments(n, cols, rows);

    // Build widgets sorted by row (top first for painter's order)
    final opponentWidgets = <MapEntry<int, Widget>>[];

    for (int i = 0; i < n; i++) {
      final assignment = cellAssignments[i];
      final row = assignment['row']!;
      final col = assignment['col']!;

      final opponentId = opponents[i];
      final player = allPlayers.firstWhere((p) => p.id == opponentId);
      final isEliminated = provider.isEliminated(opponentId);
      final healthPercent = provider.getHealthPercentage(opponentId);
      final currentHealth = provider.getHealth(opponentId);
      final targetNumber = provider.getTargetNumber(opponentId) ?? 0;
      final imagePath = provider.getMonsterImagePath(opponentId)!;

      // Perspective: 50% difference, row 0 = 0.75x, last row = 1.25x
      final rowFraction = rows > 1 ? row / (rows - 1) : 0.5;
      final perspectiveScale = 0.75 + (rowFraction * 0.50);
      final sizeMultiplier = _getSizeMultiplier(n);
      final scaledPerspective = perspectiveScale * sizeMultiplier;
      final imageSize = screenWidth * 0.11 * scaledPerspective;
      final shieldSize = (70.0 * scaledPerspective).clamp(35.0, 160.0);
      final shieldFontSize = (55.0 * scaledPerspective).clamp(26.0, 120.0);
      final strokeWidth = (4.0 * scaledPerspective).clamp(2.0, 7.0);
      final nameFontSize = (14.0 * scaledPerspective).clamp(10.0, 26.0);
      final healthBarHeight = (14.0 * scaledPerspective).clamp(8.0, 24.0);
      final shieldsRowWidth = shieldSize * 2;
      final widgetWidth = (shieldsRowWidth > imageSize + 50) ? shieldsRowWidth + 10 : imageSize + 50;
      final totalWidgetHeight = shieldSize + 4 + healthBarHeight + imageSize + nameFontSize + 8;

      // Center each opponent in its grid cell, stagger alternating rows
      // For 2-row grids: offset top row so bottom row stays evenly spread
      // For 3-row grids: offset middle row (odd rows)
      final bool shouldOffset = rows <= 2 ? (row == 0) : (row % 2 == 1);
      final rowOffset = shouldOffset ? cellWidth * 0.5 : 0.0;
      final topRowLeftNudge = (row == 0 && rows > 1) ? 20.0 : 0.0;
      final topRowLeftmostRightNudge = (row == 0 && n == 5 && col == 0) ? 20.0 : 0.0;
      final cellLeft = rightAreaStart + (col * cellWidth) + rowOffset - topRowLeftNudge + topRowLeftmostRightNudge;
      // Push top row down for 3-row grids; pull up for 2-row grids to avoid overlap
      final topRowNudge = (row == 0 && rows > 1) ? cellHeight * (rows <= 2 ? -0.10 : 0.30) : 0.0;
      final cellTop = topBand + (row * cellHeight) + topRowNudge;
      final left = (cellLeft + (cellWidth - widgetWidth) / 2).clamp(0.0, screenWidth - widgetWidth);
      final top = (cellTop + (cellHeight - totalWidgetHeight) / 2).clamp(0.0, screenHeight - totalWidgetHeight);
      // When eliminated, shield + health bar + spacing are hidden, so push down to keep image at same position
      final eliminatedOffset = isEliminated ? (shieldSize + 4 + healthBarHeight + 8) : 0.0;

      opponentWidgets.add(MapEntry(row, Positioned(
        left: left,
        top: top + eliminatedOffset,
        child: Opacity(
          opacity: isEliminated ? 0.4 : 1.0,
          child: SizedBox(
            width: widgetWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shields row: Target Number + Health (hidden when eliminated)
                if (!isEliminated)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Target number shield
                      SizedBox(
                        width: shieldSize,
                        height: shieldSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/games/monster_mash/icons/Shield-HitPoint.png',
                              width: shieldSize,
                              height: shieldSize,
                            ),
                            Transform.translate(
                              offset: const Offset(0, -4),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '$targetNumber',
                                    style: GoogleFonts.creepster(
                                      fontSize: shieldFontSize,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = strokeWidth
                                        ..color = Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '$targetNumber',
                                    style: GoogleFonts.creepster(
                                      fontSize: shieldFontSize,
                                      color: const Color(0xFFFF4444),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Health shield
                      SizedBox(
                        width: shieldSize,
                        height: shieldSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/games/monster_mash/icons/Shield-Health.png',
                              width: shieldSize,
                              height: shieldSize,
                            ),
                            Transform.translate(
                              offset: const Offset(0, -4),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '$currentHealth',
                                    style: GoogleFonts.creepster(
                                      fontSize: shieldFontSize,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = strokeWidth
                                        ..color = Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '$currentHealth',
                                    style: GoogleFonts.creepster(
                                      fontSize: shieldFontSize,
                                      color: _getHealthColor(healthPercent),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (!isEliminated) const SizedBox(height: 4),
                // Health bar (hidden when eliminated, no HP text)
                if (!isEliminated)
                  SizedBox(
                    width: imageSize,
                    child: _buildHealthBar(currentHealth, currentGame.healthMax, healthPercent, compact: true, compactHeight: healthBarHeight, showHPText: false),
                  ),
                if (!isEliminated) const SizedBox(height: 8),
                // Monster image (faces left - default) with ground shadow
                SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: Stack(
                    alignment: isEliminated ? Alignment.bottomCenter : Alignment.center,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: _buildGroundShadow(width: imageSize * 0.8, height: imageSize * 0.12),
                      ),
                      Image.asset(
                        imagePath,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                        alignment: isEliminated ? Alignment.bottomCenter : Alignment.center,
                      ),
                    ],
                  ),
                ),
                // Player name
                Text(
                  player.name,
                  style: GoogleFonts.creepster(
                    fontSize: nameFontSize,
                    color: isEliminated ? Colors.grey : const Color(0xFFF5F5DC),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      )));
    }

    // Sort by row for painter's order (back rows render first)
    opponentWidgets.sort((a, b) => a.key.compareTo(b.key));
    return opponentWidgets.map((e) => e.value).toList();
  }

  Widget _buildRoundProgressBar(int currentRound, int maxRounds, BonusBuff? activeBuff, bool speedPlayEnabled) {
    final progress = speedPlayEnabled ? (currentRound / maxRounds).clamp(0.0, 1.0) : 0.0;
    const barWidth = 408.0;
    const barHeight = 36.0;
    const shieldSize = 56.0;
    const shieldFontSize = 35.0;
    const healShieldFontSize = 39.0;

    // Determine buff display based on active buff
    final bool showHealShield = activeBuff == BonusBuff.ancientBandages;
    final bool showDamageShield = activeBuff == BonusBuff.bloodMoon ||
        activeBuff == BonusBuff.shadowWalk ||
        activeBuff == BonusBuff.laboratorySpark;

    String? healShieldText;
    String? damageShieldText;
    String? buffLabel;

    switch (activeBuff) {
      case BonusBuff.ancientBandages:
        healShieldText = '5';
        buffLabel = 'Hit your target number for +5 HP!';
        break;
      case BonusBuff.bloodMoon:
        damageShieldText = '2x';
        buffLabel = 'Double damage to any opponent!';
        break;
      case BonusBuff.shadowWalk:
        damageShieldText = '0';
        buffLabel = 'You cannot attack opponents this turn!';
        break;
      case BonusBuff.laboratorySpark:
        damageShieldText = '10';
        buffLabel = 'Hit the bullseye and ALL opponents lose 10 HP!';
        break;
      case null:
        break;
    }

    // Total height: bar + gap + label line(s)
    const totalHeight = barHeight + 2 + 28;

    return SizedBox(
      width: barWidth + shieldSize * 2 + 16, // enough room for shields on both sides
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Progress bar (always centered)
          Positioned(
            top: 0,
            left: (shieldSize + 8),
            child: Opacity(
              opacity: speedPlayEnabled ? 1.0 : 0.5,
              child: Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  border: Border.all(color: const Color(0xFFFF8C00).withOpacity(speedPlayEnabled ? 0.6 : 0.3), width: 1.5),
                ),
                child: Stack(
                  children: [
                    if (speedPlayEnabled)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(barHeight / 2),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF6600),
                                  Color(0xFFFF8C00),
                                  Color(0xFFFFAA33),
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Text(
                        speedPlayEnabled ? 'Round $currentRound / $maxRounds' : 'Unlimited Rounds',
                        style: GoogleFonts.pirataOne(
                          fontSize: 18,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 4),
                            Shadow(color: Colors.black, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Left: healing buff shield (positioned to the left of progress bar)
          if (showHealShield)
            Positioned(
              key: MonsterMashGameKeys.buffHealShield,
              top: (barHeight - shieldSize) / 2,
              left: 0,
              child: SizedBox(
                width: shieldSize,
                height: shieldSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/games/monster_mash/icons/Shield-Health.png',
                      width: shieldSize,
                      height: shieldSize,
                    ),
                    Transform.translate(
                      offset: Offset.zero,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            healShieldText!,
                            style: GoogleFonts.creepster(
                              fontSize: healShieldFontSize,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 4
                                ..color = Colors.black,
                            ),
                          ),
                          Text(
                            healShieldText,
                            style: GoogleFonts.creepster(
                              fontSize: healShieldFontSize,
                              color: const Color(0xFF7FFF00),
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Right: damage buff shield (positioned to the right of progress bar)
          if (showDamageShield)
            Positioned(
              key: MonsterMashGameKeys.buffDamageShield,
              top: (barHeight - shieldSize) / 2,
              right: 0,
              child: SizedBox(
                width: shieldSize,
                height: shieldSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/games/monster_mash/icons/Shield-HitPoint.png',
                      width: shieldSize,
                      height: shieldSize,
                    ),
                    Transform.translate(
                      offset: Offset.zero,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            damageShieldText!,
                            style: GoogleFonts.creepster(
                              fontSize: shieldFontSize,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 4
                                ..color = Colors.black,
                            ),
                          ),
                          Text(
                            damageShieldText,
                            style: GoogleFonts.creepster(
                              fontSize: shieldFontSize,
                              color: const Color(0xFFFF4444),
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Buff description label (centered under progress bar)
          if (buffLabel != null)
            Positioned(
              top: barHeight + 2,
              left: shieldSize + 8,
              child: SizedBox(
                width: barWidth,
                child: Text(
                  key: MonsterMashGameKeys.buffLabel,
                  buffLabel,
                  style: GoogleFonts.pirataOne(
                    fontSize: 22,
                    color: const Color(0xFFF5F5DC),
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                      Shadow(color: Colors.black, blurRadius: 8),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroundShadow({double width = 120, double height = 20}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(width / 2, height / 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(int currentHealth, int maxHealth, double healthPercent, {bool compact = false, double? compactHeight, bool showHPText = true}) {
    const redColor = Color(0xFFFF4444);
    const yellowColor = Color(0xFFFFCC00);
    const greenColor = Color(0xFF00CC00);

    final height = compact ? (compactHeight ?? 14.0) : 22.0;
    final fontSize = compact ? (height * 0.7).clamp(7.0, 12.0) : 14.0;
    final hp = healthPercent.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          return Stack(
            children: [
              // Gradient fill - fixed gradient clipped to health percentage
              ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: hp,
                    child: SizedBox(
                      width: barWidth,
                      height: height,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              redColor,
                              Color(0xFFFF6622),
                              yellowColor,
                              Color(0xFF88DD00),
                              greenColor,
                            ],
                            stops: [0.0, 0.25, 0.45, 0.70, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          // HP text centered inside bar (optional)
              // HP text centered inside bar (optional)
              if (showHPText)
                Center(
                  child: Text(
                    '$currentHealth/$maxHealth HP',
                    style: GoogleFonts.montserrat(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                        Shadow(color: Colors.black, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static Color _getHealthColor(double healthPercent) {
    if (healthPercent > 0.70) return const Color(0xFF00CC00);
    if (healthPercent > 0.30) return const Color(0xFFFFCC00);
    return const Color(0xFFFF4444);
  }

  Widget _buildRemoveDartsModal(Player? currentPlayer, MonsterMashProvider provider) {
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
              color: const Color(0xFF2F4F4F).withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7FFF00), width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7FFF00).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pan_tool, color: Color(0xFFF5F5DC), size: 48),
                const SizedBox(height: 16),
                Text(
                  playerName,
                  style: GoogleFonts.creepster(
                    color: const Color(0xFF7FFF00),
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Remove Your Darts',
                  style: GoogleFonts.pirataOne(
                    color: const Color(0xFFF5F5DC),
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: MonsterMashGameKeys.editScoreButton,
                  onPressed: () {
                    if (currentPlayer == null) return;
                    showEditScoreDialog(
                      context: context,
                      playerName: currentPlayer.name,
                      initialSegments: provider.getCurrentTurnDarts(currentPlayer.id),
                      onSubmit: (newSegments) =>
                          provider.updateAllDartScores(currentPlayer.id, newSegments),
                      config: EditScoreDialogConfig.monsterMash(),
                      dartBorderColors: _computeDartBorderColors(currentPlayer.id, provider),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B0082).withOpacity(0.85),
                    foregroundColor: const Color(0xFFF5F5DC),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    side: const BorderSide(color: Color(0xFFFF8C00), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Edit Player Score',
                    style: GoogleFonts.pirataOne(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color?> _computeDartBorderColors(String playerId, MonsterMashProvider provider) {
    final dartSegments = provider.getCurrentTurnDarts(playerId);
    final healAmounts = provider.getDartThrowHealAmount(playerId);
    final damageDealt = provider.getDartThrowDamageDealt(playerId);

    return List.generate(3, (dartIndex) {
      if (dartIndex >= dartSegments.length) return null;
      final segment = dartSegments[dartIndex];
      if (segment.isEmpty || segment == 'Skip') return null;
      if (segment == 'Miss') return const Color(0xFFF5F5DC).withOpacity(0.3);

      if (dartIndex < healAmounts.length && healAmounts[dartIndex] > 0) {
        return const Color(0xFF7FFF00); // Green for heal
      }
      if (dartIndex < damageDealt.length && damageDealt[dartIndex] > 0) {
        return const Color(0xFFFF4444); // Red for damage
      }

      return const Color(0xFFF5F5DC).withOpacity(0.3);
    });
  }
}
