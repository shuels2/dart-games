import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../providers/clockwork_quest_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal_config.dart';
import '../../../widgets/edit_score/edit_score_dialog.dart';
import '../../../widgets/edit_score/edit_score_dialog_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal_config.dart';
import '../../../widgets/interactive_dartboard.dart';

class ClockworkQuestGameScreen extends StatefulWidget {
  const ClockworkQuestGameScreen({super.key});

  @override
  State<ClockworkQuestGameScreen> createState() =>
      _ClockworkQuestGameScreenState();
}

class _ClockworkQuestGameScreenState extends State<ClockworkQuestGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  MockScoliaApiService? _mockApi;
  final DartboardEmulatorController _dartboardEmulatorController =
      DartboardEmulatorController();
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

    // Subscribe to dartboard events
    final eventStream = dartboardProvider.dartboardEventStream;
    if (eventStream != null) {
      _dartboardSubscription = eventStream.listen((event) {
        _handleDartboardEvent(event);
      });
    }
  }

  @override
  void dispose() {
    _dartboardSubscription?.cancel();
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
    final clockworkProvider = context.read<ClockworkQuestProvider>();
    if (!mounted || !clockworkProvider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;

    clockworkProvider.processDartThrow(sector);
    setState(() {});
  }

  void _handleTakeoutFinished() {
    final clockworkProvider = context.read<ClockworkQuestProvider>();
    if (!mounted) return;

    clockworkProvider.confirmDartsRemoved();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final clockworkProvider = Provider.of<ClockworkQuestProvider>(context);
    final dartboardProvider = Provider.of<DartboardProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context);

    final game = clockworkProvider.currentGame;
    if (game == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const SizedBox();
    }

    final currentPlayerId = clockworkProvider.getCurrentPlayerId();
    final currentPlayer = currentPlayerId != null
        ? playerProvider.getPlayerById(currentPlayerId)
        : null;

    final shouldPromptTakeout = clockworkProvider.shouldPromptTakeout;
    final hasDartsThrown =
        game.totalDartsThrown.values.any((c) => c > 0);

    // Check for winner
    if (clockworkProvider.hasWinner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/clockwork_quest_results');
      });
    }

    return PopScope(
      canPop: !hasDartsThrown,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _showSaveModal) return;
        setState(() => _showSaveModal = true);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF2C2C34), // Dark Iron
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C34),
        leading: IconButton(
          key: ClockworkQuestGameKeys.backButton,
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF5F0E8), size: 32),
          onPressed: () {
            if (hasDartsThrown) {
              setState(() => _showSaveModal = true);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'CLOCKWORK QUEST',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF5F0E8),
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DartboardConnectionInfo(
              config: DartboardConnectionInfoConfig.clockworkQuest(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image with dark overlay
          Positioned.fill(
            child: Image.asset(
              'assets/games/clockwork_quest/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF2C2C34).withOpacity(0.75),
            ),
          ),

          // Main game content — Positioned.fill so emulator overlay doesn't resize it
          Positioned.fill(
            child: Builder(builder: (context) {
              // Compute opponents in turn order (who plays next)
              final playerIds = game.playerIds as List<String>;
              final currentIdx = game.currentPlayerIndex;
              final opponents = <String>[];
              for (int i = 1; i < playerIds.length; i++) {
                opponents.add(playerIds[(currentIdx + i) % playerIds.length]);
              }
              final leftOpponents = opponents.take(4).toList();
              final rightOpponents = opponents.skip(4).take(3).toList();

              return Column(
                children: [
                  // Lap counter (if multiple laps)
                  if (game.numberOfLaps > 1)
                    _buildLapCounter(clockworkProvider, currentPlayerId),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left column — always reserve width so clock stays centered
                        SizedBox(
                          width: 263,
                          child: leftOpponents.isNotEmpty
                              ? _buildOpponentColumn(
                                  leftOpponents, clockworkProvider, playerProvider, game)
                              : const SizedBox(),
                        ),

                        // Center — clock face
                        Expanded(
                          child: _buildClockFace(clockworkProvider, playerProvider,
                              currentPlayer, currentPlayerId, game),
                        ),

                        // Right column — always reserve width so clock stays centered
                        SizedBox(
                          width: 263,
                          child: rightOpponents.isNotEmpty
                              ? _buildOpponentColumn(
                                  rightOpponents, clockworkProvider, playerProvider, game)
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),

          // Remove Darts Modal
          if (shouldPromptTakeout && currentPlayer != null)
            RemoveDartsModal(
              key: ClockworkQuestGameKeys.removeDartsModal,
              playerName: currentPlayer.name,
              config: RemoveDartsModalConfig.clockworkQuest(),
              editScoreButtonKey: ClockworkQuestGameKeys.editScoreButton,
              onEditScore: () => _showEditScoreDialog(context),
            ),

          // Dartboard Emulator — rendered after modal so its buttons stay on top
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DartboardEmulatorSection(
              key: ClockworkQuestGameKeys.dartboardSection,
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
              config: DartboardSectionConfig.clockworkQuest(),
            ),
          ),

          // Dartboard Paused Modal
          if (!dartboardProvider.isEmulator &&
              dartboardProvider.status != DartboardConnectionStatus.connected &&
              dartboardProvider.status != DartboardConnectionStatus.emulator)
            DartboardPausedModal(
              config: DartboardPausedModalConfig.clockworkQuest(),
            ),

          // Save Game Modal
          if (_showSaveModal)
            SaveGameModal(
              config: SaveGameModalConfig.clockworkQuest(),
              onSave: () async {
                await clockworkProvider.saveGame(playerProvider.allPlayers);
                if (mounted) Navigator.of(context).pop();
              },
              onDontSave: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      floatingActionButton: DartboardEmulatorFAB(
        controller: _dartboardEmulatorController,
        isConnected: !dartboardProvider.isEmulator,
        config: DartboardFABConfig.clockworkQuest(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildLapCounter(
      ClockworkQuestProvider provider, String? currentPlayerId) {
    if (currentPlayerId == null) return const SizedBox();
    final currentLap = provider.getPlayerLapsCompleted(currentPlayerId) + 1;
    final totalLaps = provider.currentGame!.numberOfLaps;

    return Container(
      key: ClockworkQuestGameKeys.currentLapText,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC5A54E).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC5A54E), width: 2),
      ),
      child: Text(
        'Lap $currentLap/$totalLaps',
        style: GoogleFonts.cinzelDecorative(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFBF00),
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Clock-face layout: player at center, gears in a circle around them
  Widget _buildClockFace(
    ClockworkQuestProvider provider,
    PlayerProvider playerProvider,
    dynamic currentPlayer,
    String? currentPlayerId,
    dynamic game,
  ) {
    if (currentPlayerId == null || currentPlayer == null) {
      return const SizedBox();
    }

    final currentTarget = provider.getPlayerCurrentTarget(currentPlayerId);
    final totalGears = game.maxTarget as int;
    final completedTargets = provider.getPlayerCompletedTargets(currentPlayerId);
    final isSpeedMode = game.speedMode as bool;

    // Standard dartboard segment order, clockwise from 12 o'clock
    const dartboardOrder = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5];

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final size = min(w, h);
              final cx = w / 2;
              final cy = h / 2;
              final gearRadius = size * 0.43;
              final gearSize = (size * 0.157).clamp(78.0, 123.0);
              final currentGearSize = gearSize * 1.25;

              return Stack(
                key: ClockworkQuestGameKeys.gearTracker,
                children: [
                  // Gears in dartboard order (clockwise from 12 o'clock)
                  for (int i = 0; i < 20; i++)
                    _positionedGearOnClock(
                      i, dartboardOrder[i], currentTarget,
                      cx, cy, gearRadius, gearSize, currentGearSize, totalGears,
                      completedTargets: completedTargets, isSpeedMode: isSpeedMode,
                    ),
                  if (game.includeBullseye)
                    _positionedGearOnClock(
                      20, 21, currentTarget,
                      cx, cy, gearRadius, gearSize, currentGearSize, totalGears,
                      isBull: true,
                      completedTargets: completedTargets, isSpeedMode: isSpeedMode,
                    ),

                  // Active player at the center
                  Align(
                    alignment: const Alignment(0, -0.28),
                    child: _buildClockCenterPanel(
                        provider, currentPlayer, currentPlayerId,
                        currentTarget, game),
                  ),
                ],
              );
            },
          ),
        ),

      ],
    );
  }

  Widget _positionedGearOnClock(
    int positionIndex, // clock position 0-indexed (0 = 12 o'clock)
    int number,        // gear number (1-20 or 21 for bull)
    int currentTarget,
    double cx,
    double cy,
    double gearRadius,
    double gearSize,
    double currentGearSize,
    int totalGears, {
    bool isBull = false,
    List<int> completedTargets = const [],
    bool isSpeedMode = false,
  }) {
    final bool isActive = isSpeedMode
        ? completedTargets.contains(number)
        : number < currentTarget;
    final bool isCurrent = isSpeedMode ? false : number == currentTarget;
    // Position by clock index, starting at 12 o'clock, going clockwise
    final double angle = positionIndex / totalGears * 2 * pi - pi / 2;
    final double size = isCurrent ? currentGearSize : gearSize;
    final double left = cx + gearRadius * cos(angle) - size / 2;
    final double top = cy + gearRadius * sin(angle) - size / 2;

    final String gearName =
        isBull ? 'GearBull' : 'Gear${number.toString().padLeft(2, '0')}';
    final String stateSuffix = isActive ? 'Active' : 'Inactive';
    final String imagePath =
        'assets/games/clockwork_quest/images/gears/$gearName-$stateSuffix.png';

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Container(
        key: isActive
            ? ClockworkQuestGameKeys.gearActive(number)
            : ClockworkQuestGameKeys.gear(number),
        decoration: isCurrent
            ? const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFFBF00),
                    blurRadius: 14,
                    spreadRadius: 5,
                  ),
                ],
              )
            : null,
        child: Image.asset(imagePath, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildClockCenterPanel(
    ClockworkQuestProvider provider,
    dynamic currentPlayer,
    String? currentPlayerId,
    int currentTarget,
    dynamic game,
  ) {
    final inventorPath = provider.getInventorImagePath(currentPlayerId!);
    final maxTarget = game.maxTarget as int;

    return Container(
      key: ClockworkQuestGameKeys.activePlayerPanel,
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inventor character image (separate from avatar)
          if (inventorPath != null)
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.70,
                child: Image.asset(inventorPath, width: 620, height: 620,
                    fit: BoxFit.contain),
              ),
            )
          // Player photo avatar (fallback when no inventor)
          else if (currentPlayer.photoPath != null)
            CircleAvatar(
              key: ClockworkQuestGameKeys.playerAvatar,
              radius: 100,
              backgroundImage: currentPlayer.photoPath!.startsWith('data:')
                  ? MemoryImage(
                      base64Decode(currentPlayer.photoPath!.split(',')[1]))
                  : NetworkImage(currentPlayer.photoPath!) as ImageProvider,
            )
          else
            CircleAvatar(
              key: ClockworkQuestGameKeys.playerAvatar,
              radius: 100,
              backgroundColor: const Color(0xFFC5A54E),
              child: Text(
                currentPlayer.name[0].toUpperCase(),
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C2C34),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // Player name
          Text(
            currentPlayer.name,
            key: ClockworkQuestGameKeys.activePlayerName,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF5F0E8),
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // Target label + number
          if (game.speedMode as bool) ...[
            Text(
              'Activate Any Gear!',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: const Color(0xFFF5F0E8).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${currentTarget - 1}/$maxTarget',
              key: ClockworkQuestGameKeys.currentTargetText,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFBF00),
              ),
            ),
            Text(
              'gears activated',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: const Color(0xFFF5F0E8).withOpacity(0.5),
              ),
            ),
          ] else ...[
            Text(
              'Target',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: const Color(0xFFF5F0E8).withOpacity(0.6),
              ),
            ),
            Text(
              currentTarget == 21 ? 'BULL' : '$currentTarget',
              key: ClockworkQuestGameKeys.currentTargetText,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFBF00),
              ),
            ),
            Text(
              '$currentTarget/$maxTarget',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: const Color(0xFFF5F0E8).withOpacity(0.5),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Dart indicators
          _buildDartIndicators(provider, currentPlayerId),

          const SizedBox(height: 10),

          // Skip Turn button
          SizedBox(
            width: 200,
            child: ElevatedButton(
              key: ClockworkQuestGameKeys.skipTurnButton,
              onPressed: provider.shouldPromptTakeout
                  ? null
                  : () => provider.skipTurn(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB87333),
                disabledBackgroundColor: const Color(0xFF4A4A52),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Skip Turn',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF5F0E8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDartIndicators(
      ClockworkQuestProvider provider, String? currentPlayerId) {
    if (currentPlayerId == null) return const SizedBox();
    final hitList = provider.getDartThrowHitTarget(currentPlayerId);
    final maxDarts = provider.currentGame!.maxDartsPerTurn;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < maxDarts; i++)
          Container(
            key: ClockworkQuestGameKeys.dartIndicator(i),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < hitList.length
                  ? (hitList[i]
                      ? const Color(0xFFFFBF00) // Amber Glow = hit
                      : const Color(0xFF8A8D93)) // Rivet Silver = miss
                  : Colors.transparent,
              border: i < hitList.length
                  ? null
                  : Border.all(
                      color: const Color(0xFF43B3AE), // Verdigris = empty
                      width: 2,
                    ),
            ),
            child: i < hitList.length
                ? Icon(
                    hitList[i] ? Icons.settings : Icons.air,
                    size: 14,
                    color: const Color(0xFF2C2C34),
                  )
                : null,
          ),
      ],
    );
  }

  Widget _buildOpponentColumn(
    List<String> opponentIds,
    ClockworkQuestProvider provider,
    PlayerProvider playerProvider,
    dynamic game,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final opponentId in opponentIds)
          _buildOpponentTile(opponentId, provider, playerProvider, game),
      ],
    );
  }

  Widget _buildOpponentTile(
    String opponentId,
    ClockworkQuestProvider provider,
    PlayerProvider playerProvider,
    dynamic game,
  ) {
    final opponent = playerProvider.getPlayerById(opponentId);
    if (opponent == null) return const SizedBox();

    final target = provider.getPlayerCurrentTarget(opponentId);
    final laps = provider.getPlayerLapsCompleted(opponentId);
    final maxTarget = game.maxTarget as int;
    final gearsActivated = laps * maxTarget + (target - 1);
    final inventorPath = provider.getInventorImagePath(opponentId);

    return Container(
      key: ClockworkQuestGameKeys.playerTile(opponentId),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C34).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFB87333).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inventor character image at fixed size
          if (inventorPath != null)
            Image.asset(inventorPath, width: 220, height: 220,
                fit: BoxFit.contain)
          else
            CircleAvatar(
              radius: 80,
              backgroundColor: const Color(0xFFB87333),
              child: Text(
                opponent.name[0].toUpperCase(),
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C2C34),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            opponent.name,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: const Color(0xFFF5F0E8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '$gearsActivated/$maxTarget',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFFFFBF00),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEditScoreDialog(BuildContext context) {
    final clockworkProvider =
        Provider.of<ClockworkQuestProvider>(context, listen: false);
    final playerProvider =
        Provider.of<PlayerProvider>(context, listen: false);

    final currentPlayerId = clockworkProvider.getCurrentPlayerId();
    if (currentPlayerId == null) return;

    final currentPlayer = playerProvider.getPlayerById(currentPlayerId);
    if (currentPlayer == null) return;

    showEditScoreDialog(
      context: context,
      playerName: currentPlayer.name,
      initialSegments:
          clockworkProvider.getCurrentTurnDarts(currentPlayerId),
      config: EditScoreDialogConfig.clockworkQuest(),
      onSubmit: (newSegments) {
        clockworkProvider.editScore(
          newSegments.map((s) => {'sector': s}).toList(),
        );
      },
    );
  }

}

