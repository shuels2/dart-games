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

    _audioQueue!.announceGameStart();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _announceCurrentPlayerTurn();
      }
    });
  }

  // Grid layout for opponents: determines rows/cols based on count
  static Map<String, int> _getGridLayout(int count) {
    if (count <= 2) return {'cols': 2, 'rows': 1};
    if (count <= 4) return {'cols': 3, 'rows': 2};
    if (count <= 6) return {'cols': 3, 'rows': 2};
    return {'cols': 3, 'rows': 3};
  }

  // Get specific cell assignments: bottom-heavy layout (more on bottom, fewer on top)
  static List<Map<String, int>> _getCellAssignments(int count, int cols, int rows) {
    if (rows == 1) {
      // Single row: just spread across columns
      return List.generate(count, (i) => {'row': 0, 'col': i % cols});
    }
    if (rows == 2) {
      // Bottom-heavy: put most on bottom row, remainder on top-right
      final bottomCount = (count * 3 / 4).ceil().clamp(1, cols);
      final topCount = count - bottomCount;
      final assignments = <Map<String, int>>[];
      // Top row: place from right side
      for (int i = 0; i < topCount; i++) {
        assignments.add({'row': 0, 'col': cols - 1 - i});
      }
      // Bottom row: spread across
      for (int i = 0; i < bottomCount; i++) {
        assignments.add({'row': 1, 'col': i});
      }
      return assignments;
    }
    // 3 rows: distribute bottom-heavy
    final assignments = <Map<String, int>>[];
    final bottomCount = (count / 3.0).ceil().clamp(1, cols);
    final midCount = ((count - bottomCount) / 2.0).ceil().clamp(0, cols);
    final topCount = count - bottomCount - midCount;
    for (int i = 0; i < topCount; i++) {
      assignments.add({'row': 0, 'col': cols - 1 - i});
    }
    for (int i = 0; i < midCount; i++) {
      assignments.add({'row': 1, 'col': i});
    }
    for (int i = 0; i < bottomCount; i++) {
      assignments.add({'row': 2, 'col': i});
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

    // 1. Hit announcement
    if (!isMiss && parsed != null) {
      _audioQueue!.announceHit(parsed['number'] as int, parsed['multiplier'] as String);
    } else {
      _audioQueue!.announceHit(0, 'single', isMiss: true);
    }

    // 2. Healing announcements
    final healthAfter = monsterMashProvider.getHealth(currentPlayerId);
    final healthBefore = allHealthBefore[currentPlayerId]!;
    if (healthAfter > healthBefore) {
      final healAmount = healthAfter - healthBefore;
      final multiplierStr = parsed?['multiplier'] as String? ?? 'single';
      _audioQueue!.announceHealing(multiplierStr, healAmount);

      // Clutch heal check
      if (healthBefore < 10 && healthBefore > 0) {
        _audioQueue!.announceClutchHeal(currentPlayer.name);
      }
    }

    // 3. Attack announcements
    final dartThrowTargetPlayerIds = monsterMashProvider.getDartThrowTargetPlayerId(currentPlayerId);
    final dartThrowDamageDealt = monsterMashProvider.getDartThrowDamageDealt(currentPlayerId);
    final dartIndex = dartThrowTargetPlayerIds.length - 1;

    if (dartIndex >= 0 && dartThrowTargetPlayerIds[dartIndex] != null) {
      final targetId = dartThrowTargetPlayerIds[dartIndex]!;
      final damage = dartThrowDamageDealt[dartIndex];
      final targetPlayer = allPlayers.firstWhere((p) => p.id == targetId);
      final multiplierStr = parsed?['multiplier'] as String? ?? 'single';
      _audioQueue!.announceAttack(targetPlayer.name, multiplierStr, damage);

      // Health warning for damaged opponent
      final opponentHealthAfter = monsterMashProvider.getHealth(targetId);
      final healthMax = currentGame.healthMax;
      final pct = opponentHealthAfter / healthMax;
      _audioQueue!.announceHealthWarning(targetPlayer.name, pct);
    }

    // 4. Elimination announcements
    final eliminatedAfter = currentGame.playerIds.where((id) => monsterMashProvider.isEliminated(id)).toSet();
    final newlyEliminated = eliminatedAfter.difference(eliminatedBefore);
    for (final eliminatedId in newlyEliminated) {
      final eliminatedPlayer = allPlayers.firstWhere((p) => p.id == eliminatedId);
      _audioQueue!.announceElimination(eliminatedPlayer.name);
    }

    // 5. Hat trick check (all 3 darts hit same opponent)
    if (dartThrowTargetPlayerIds.length == 3) {
      final targets = dartThrowTargetPlayerIds.where((t) => t != null).toList();
      if (targets.length == 3 && targets.every((t) => t == targets.first)) {
        final targetPlayer = allPlayers.firstWhere((p) => p.id == targets.first);
        _audioQueue!.announceHatTrick(targetPlayer.name);
      }
    }

    // Check if turn is over
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
        actions: [
          // Round indicator and buff display
          if (currentGame.speedPlayEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4F4F).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF8C00), width: 2),
                  ),
                  child: Text(
                    'Round ${currentGame.currentRound}/${currentGame.roundLimit}',
                    style: GoogleFonts.pirataOne(
                      fontSize: 16,
                      color: const Color(0xFFF5F5DC),
                    ),
                  ),
                ),
              ),
            ),
          if (currentGame.bonusBuffsEnabled && currentGame.activeBuff != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B0082).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7FFF00), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF7FFF00), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        MonsterMashGame.getBuffDisplayName(currentGame.activeBuff!),
                        style: GoogleFonts.pirataOne(
                          fontSize: 14,
                          color: const Color(0xFF7FFF00),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
                fontSize: 28,
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

    // Opponent area spans from 30% to 104% of screen width
    final rightAreaStart = screenWidth * 0.30;
    final rightAreaEnd = screenWidth * 1.04;
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
      final imageSize = screenWidth * 0.11 * perspectiveScale;
      final shieldSize = (70.0 * perspectiveScale).clamp(35.0, 90.0);
      final shieldFontSize = (55.0 * perspectiveScale).clamp(26.0, 70.0);
      final strokeWidth = (4.0 * perspectiveScale).clamp(2.0, 5.0);
      final nameFontSize = (12.0 * perspectiveScale).clamp(8.0, 16.0);
      final healthBarHeight = (14.0 * perspectiveScale).clamp(8.0, 18.0);
      final widgetWidth = imageSize + 50;
      final totalWidgetHeight = shieldSize + 4 + healthBarHeight + imageSize + nameFontSize + 8;

      // Center each opponent in its grid cell, offset odd rows by half a cell width
      final rowOffset = (row % 2 == 1) ? cellWidth * 0.5 : 0.0;
      final cellLeft = rightAreaStart + (col * cellWidth) + rowOffset;
      // Push top row down by 30% of cell height to bring it closer to other rows
      final topRowNudge = (row == 0 && rows > 1) ? cellHeight * 0.30 : 0.0;
      final cellTop = topBand + (row * cellHeight) + topRowNudge;
      final left = (cellLeft + (cellWidth - widgetWidth) / 2).clamp(0.0, screenWidth - widgetWidth);
      final top = (cellTop + (cellHeight - totalWidgetHeight) / 2).clamp(0.0, screenHeight - totalWidgetHeight);

      opponentWidgets.add(MapEntry(row, Positioned(
        left: left,
        top: top,
        child: Opacity(
          opacity: isEliminated ? 0.4 : 1.0,
          child: SizedBox(
            width: widgetWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shield + number
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
                const SizedBox(height: 4),
                // Health bar
                SizedBox(
                  width: imageSize,
                  child: _buildHealthBar(currentHealth, currentGame.healthMax, healthPercent, compact: true, compactHeight: healthBarHeight),
                ),
                const SizedBox(height: 8),
                // Monster image (faces left - default) with ground shadow
                SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: Stack(
                    alignment: Alignment.center,
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
                      ),
                    ],
                  ),
                ),
                // Player name
                Text(
                  player.name,
                  style: GoogleFonts.montserrat(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.bold,
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

  Widget _buildHealthBar(int currentHealth, int maxHealth, double healthPercent, {bool compact = false, double? compactHeight}) {
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
      child: Stack(
        children: [
          // Gradient fill
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: hp,
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
          // HP text centered inside bar
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
      ),
    );
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
