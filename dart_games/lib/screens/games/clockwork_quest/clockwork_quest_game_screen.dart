import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../providers/clockwork_quest_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';
import '../../../widgets/edit_score/edit_score_dialog.dart';
import '../../../widgets/edit_score/edit_score_dialog_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/save_game_modal/save_game_modal.dart';
import '../../../widgets/remove_darts_modal/remove_darts_modal.dart';
import '../../../services/play_to_complete/clockwork_quest_strategy.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../services/clockwork_quest_announcement_helper.dart';
import '../../../services/clockwork_quest_sound_effects.dart';
import '../shared/game_screen_controller.dart';
import '../shared/game_screen_shell.dart';
import 'clockwork_quest_results_screen.dart';
import '../../../widgets/game_background.dart';

class ClockworkQuestGameScreen extends StatefulWidget {
  const ClockworkQuestGameScreen({super.key});

  @override
  State<ClockworkQuestGameScreen> createState() =>
      _ClockworkQuestGameScreenState();
}

class _ClockworkQuestGameScreenState extends State<ClockworkQuestGameScreen>
    with GameScreenController<ClockworkQuestGameScreen> {
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();
  ClockworkQuestAnnouncementHelper? _audioQueue;
  final Set<String> _bullseyeTargetAnnouncedFor = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initGameScreen(
        preloadEffects: ClockworkQuestSoundEffects.all,
        buildAudio: (queue) =>
            _audioQueue = ClockworkQuestAnnouncementHelper(queue),
        onReady: () => _audioQueue?.announceGameStart(),
        firstTurnDelay: const Duration(milliseconds: 2000),
        announceFirstTurn: _announceCurrentPlayerTurn,
      );
    });
  }

  @override
  void dispose() {
    disposeGameScreen();
    _audioQueue?.dispose();
    super.dispose();
  }

  // ─── GameScreenController contract ───────────────────────────────────────────

  @override
  PlayToCompleteStrategy get playToCompleteStrategy =>
      ClockworkQuestStrategy();

  @override
  Future<void> whenAnnouncementsIdle() =>
      _audioQueue?.whenIdle() ?? Future<void>.value();

  void _announceCurrentPlayerTurn() {
    final clockworkProvider = context.read<ClockworkQuestProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentPlayerId = clockworkProvider.getCurrentPlayerId();
    if (currentPlayerId == null) return;
    final player = playerProvider.getPlayerById(currentPlayerId);
    if (player != null) {
      _audioQueue?.announcePlayerTurn(player);
    }
  }

  @override
  void onDartThrowEvent(Map<String, dynamic> event) {
    final clockworkProvider = context.read<ClockworkQuestProvider>();
    if (!mounted || !clockworkProvider.isGameActive) return;

    final throwData = event['data']['payload'];
    final sector = throwData['sector'] as String;

    final currentPlayerId = clockworkProvider.getCurrentPlayerId();

    clockworkProvider.processDartThrow(sector);

    if (!isAutoPlaying && currentPlayerId != null) {
      _announceDartResult(clockworkProvider, currentPlayerId);
    }

    final dartsThrown = clockworkProvider.getCurrentPlayerDartsThrown();
    if (!isAutoPlaying &&
        (dartsThrown >= 3 || clockworkProvider.hasWinner)) {
      final playerProvider = context.read<PlayerProvider>();
      final player = currentPlayerId != null
          ? playerProvider.getPlayerById(currentPlayerId)
          : null;
      scheduleTakeoutSequence(
        dartsOnBoard: true,
        announceRemoveDarts: () {
          if (player != null) _audioQueue?.announceRemoveDarts(player);
        },
      );
    }
  }

  void _announceDartResult(ClockworkQuestProvider provider, String playerId) {
    final playerProvider = context.read<PlayerProvider>();
    final player = playerProvider.getPlayerById(playerId);
    if (player == null) return;

    final hitTargetList = provider.getDartThrowHitTarget(playerId);
    final multiplierList = provider.getDartThrowMultiplier(playerId);
    final advancedList = provider.getDartThrowAdvanced(playerId);
    final completedLapList = provider.getDartThrowCompletedLap(playerId);
    final targetNumberList = provider.getDartThrowTargetNumber(playerId);
    if (hitTargetList.isEmpty) return;

    final hitTarget = hitTargetList.last;
    final multiplier = multiplierList.last;
    final advanced = advancedList.last;
    final completedLap = completedLapList.last;
    final dartTargetNumber = targetNumberList.last;
    final newTarget = provider.getPlayerCurrentTarget(playerId);
    final completedTargets = provider.getPlayerCompletedTargets(playerId);

    // Slot 1: moment announcement (highest priority wins)
    if (completedLap && !provider.hasWinner) {
      _audioQueue?.announceLapComplete();
      _bullseyeTargetAnnouncedFor.remove(playerId);
    } else if (hitTarget && advanced && (newTarget == 21 || dartTargetNumber == 21)) {
      _audioQueue?.announceBullseyeHit();
    } else if (hitTarget && advanced) {
      _audioQueue?.announceGearActivated(dartTargetNumber);
    } else if (!hitTarget && !provider.hasWinner) {
      _audioQueue?.announceMiss();
    }

    if (provider.hasWinner) return;

    // Slot 2: milestone announcement
    if (newTarget == 21 && !completedLap && _bullseyeTargetAnnouncedFor.add(playerId)) {
      _audioQueue?.announceBullseyeTarget();
    } else if (completedTargets.length == 10) {
      _audioQueue?.announceHalfway(player);
    } else if (completedTargets.length >= 18) {
      final gearsLeft = 20 - completedTargets.length;
      _audioQueue?.announceNearVictory(player, gearsLeft);
    }
  }

  @override
  void onTakeoutFinished() {
    final clockworkProvider = context.read<ClockworkQuestProvider>();
    if (!mounted) return;

    cancelTakeoutSequence();

    if (clockworkProvider.hasWinner) {
      _handleGameWon();
      return;
    }

    if (!clockworkProvider.isGameActive) return;

    clockworkProvider.confirmDartsRemoved();

    if (!isAutoPlaying) {
      runAfter(const Duration(milliseconds: 500), _announceCurrentPlayerTurn);
    }
  }

  void _handleGameWon() {
    handleGameWon(
      announceWinner: () {
        final clockworkProvider = context.read<ClockworkQuestProvider>();
        final playerProvider = context.read<PlayerProvider>();
        final winnerId = clockworkProvider.currentGame?.winnerId;
        if (winnerId != null) {
          final winner = playerProvider.allPlayers.firstWhere(
            (p) => p.id == winnerId,
            orElse: () => playerProvider.allPlayers.first,
          );
          _audioQueue?.announceVictory(winner);
        }
      },
      resultsBuilder: (_) => const ClockworkQuestResultsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clockworkProvider = Provider.of<ClockworkQuestProvider>(context);
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
    final hasDartsThrown = game.totalDartsThrown.values.any((c) => c > 0);

    return GameScreenShell(
      hasDartsThrown: hasDartsThrown,
      showSaveModal: showSaveModal,
      onRequestSaveModal: openSaveModal,
      onAutoSave: () => clockworkProvider.saveGame(playerProvider.allPlayers,
          isAutoSave: true),
      onSave: () async {
        await clockworkProvider.saveGame(playerProvider.allPlayers);
        if (mounted) Navigator.of(context).pop();
      },
      onDontSave: () => Navigator.of(context).pop(),
      saveGameModalConfig: SaveGameModalConfig.clockworkQuest(),
      shouldPromptTakeout: shouldPromptTakeout,
      // Clockwork additionally gates the modal on a resolvable player.
      showRemoveDartsModal: shouldPromptTakeout && currentPlayer != null,
      removeDartsModalKey: ClockworkQuestGameKeys.removeDartsModal,
      removeDartsConfig: RemoveDartsModalConfig.clockworkQuest(),
      removeDartsPlayerName: currentPlayer?.name ?? 'Player',
      editScoreButtonKey: ClockworkQuestGameKeys.editScoreButton,
      onEditScore: () => _showEditScoreDialog(context),
      emulatorSectionKey: ClockworkQuestGameKeys.dartboardSection,
      emulatorController: dartboardEmulatorController,
      mockApi: mockApi,
      dartboardKey: _dartboardKey,
      emulatorSectionConfig: DartboardSectionConfig.clockworkQuest(),
      fabConfig: DartboardFABConfig.clockworkQuest(),
      onCancelAutoPlay: cancelAutoPlay,
      onPlayToComplete: mockApi != null ? startPlayToComplete : null,
      playToCompleteConfig: mockApi != null
          ? PlayToCompleteButtonConfig.clockworkQuest()
          : null,
      pausedModalConfig: DartboardPausedModalConfig.clockworkQuest(),
      backgroundColor: const Color(0xFF2C2C34), // Dark Iron
      appBar: AppBar(
              backgroundColor: const Color(0xFF2C2C34),
              leading: IconButton(
                key: ClockworkQuestGameKeys.backButton,
                icon: const Icon(Icons.arrow_back,
                    color: Color(0xFFF5F0E8), size: 32),
                onPressed: () {
                  if (hasDartsThrown) {
                    openSaveModal();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
              ),
              title: Text(
                'CLOCKWORK QUEST',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF5F0E8),
                  letterSpacing: 1.5,
                ),
              ),
              flexibleSpace: game.numberOfLaps > 1 && currentPlayerId != null
                  ? SafeArea(
                      child: Center(
                        child: Text(
                          'Lap ${clockworkProvider.getPlayerLapsCompleted(currentPlayerId!) + 1} / ${game.numberOfLaps}',
                          key: ClockworkQuestGameKeys.currentLapText,
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFBF00),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    )
                  : null,
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
                // Background image with dark overlay. GameBackground caps
                // the decoded raster; this screen rebuilds on every dart.
                const GameBackground(
                  asset: 'assets/games/clockwork_quest/images/background.png',
                  fallbackColor: Color(0xFF2C2C34),
                  overlayColor: Color(0xFF2C2C34),
                  overlayOpacity: 0.75,
                ),

                // Main game content — Positioned.fill so emulator overlay doesn't resize it
                Positioned.fill(
                  child: Builder(builder: (context) {
                    // Compute opponents in turn order (who plays next)
                    final playerIds = game.playerIds as List<String>;
                    final currentIdx = game.currentPlayerIndex;
                    final opponents = <String>[];
                    for (int i = 1; i < playerIds.length; i++) {
                      opponents
                          .add(playerIds[(currentIdx + i) % playerIds.length]);
                    }
                    final leftOpponents = opponents.take(4).toList();
                    final rightOpponents = opponents.skip(4).take(3).toList();

                    return Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left column — always reserve width so clock stays centered
                              SizedBox(
                                width: 263,
                                child: leftOpponents.isNotEmpty
                                    ? _buildOpponentColumn(leftOpponents,
                                        clockworkProvider, playerProvider, game)
                                    : const SizedBox(),
                              ),

                              // Center — clock face
                              Expanded(
                                child: _buildClockFace(
                                    clockworkProvider,
                                    playerProvider,
                                    currentPlayer,
                                    currentPlayerId,
                                    game),
                              ),

                              // Right column — always reserve width so clock stays centered
                              SizedBox(
                                width: 263,
                                child: rightOpponents.isNotEmpty
                                    ? _buildOpponentColumn(rightOpponents,
                                        clockworkProvider, playerProvider, game)
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
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
    final completedTargets =
        provider.getPlayerCompletedTargets(currentPlayerId);
    final isSpeedMode = game.speedMode as bool;

    // Standard dartboard segment order, clockwise from 12 o'clock
    const dartboardOrder = [
      20,
      1,
      18,
      4,
      13,
      6,
      10,
      15,
      2,
      17,
      3,
      19,
      7,
      16,
      8,
      11,
      14,
      9,
      12,
      5
    ];

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
              // Max arc spacing between 20 gear centres = size * 0.135.
              // Keep gear width comfortably below that so they never touch.
              final gearSize = (size * 0.1645).clamp(40.0, 132.0);
              final currentGearSize = gearSize * 1.20;

              return Stack(
                key: ClockworkQuestGameKeys.gearTracker,
                children: [
                  // Gears in dartboard order (clockwise from 12 o'clock)
                  for (int i = 0; i < 20; i++)
                    _positionedGearOnClock(
                      i,
                      dartboardOrder[i],
                      currentTarget,
                      cx,
                      cy,
                      gearRadius,
                      gearSize,
                      currentGearSize,
                      totalGears,
                      completedTargets: completedTargets,
                      isSpeedMode: isSpeedMode,
                      hasWinner: provider.hasWinner,
                    ),
                  if (game.includeBullseye)
                    _positionedGearOnClock(
                      20,
                      21,
                      currentTarget,
                      cx,
                      cy,
                      gearRadius,
                      gearSize,
                      currentGearSize,
                      totalGears,
                      isBull: true,
                      completedTargets: completedTargets,
                      isSpeedMode: isSpeedMode,
                      hasWinner: provider.hasWinner,
                    ),

                  // Active player at the center
                  Align(
                    alignment: const Alignment(0, 0.0),
                    child: _buildClockCenterPanel(provider, currentPlayer,
                        currentPlayerId, currentTarget, game, size),
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
    int number, // gear number (1-20 or 21 for bull)
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
    bool hasWinner = false,
  }) {
    final bool isActive = hasWinner
        ? true
        : isSpeedMode
            ? completedTargets.contains(number)
            : number < currentTarget;
    final bool isCurrent = hasWinner ? false : isSpeedMode ? false : number == currentTarget;
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
    double clockSize,
  ) {
    final inventorPath = provider.getInventorImagePath(currentPlayerId!);
    final maxTarget = game.maxTarget as int;

    // All sizes derived from clockSize so the panel always fits inside the gear ring.
    final characterSize = (clockSize * 0.462).clamp(93.0, 401.0);
    final panelMaxWidth = (clockSize * 0.56).clamp(130.0, 460.0);
    final nameFontSize = (clockSize * 0.032).clamp(11.0, 24.0);
    final targetFontSize = (clockSize * 0.065).clamp(22.0, 52.0);
    final labelFontSize = (clockSize * 0.026).clamp(10.0, 18.0);
    final avatarRadius = (characterSize / 2).clamp(30.0, 100.0);

    return Container(
      key: ClockworkQuestGameKeys.activePlayerPanel,
      constraints: BoxConstraints(maxWidth: panelMaxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inventor character image (separate from avatar)
          if (inventorPath != null)
            Image.asset(inventorPath,
                height: characterSize, fit: BoxFit.contain)
          // Player photo avatar (fallback when no inventor)
          else if (currentPlayer.photoPath != null)
            CircleAvatar(
              key: ClockworkQuestGameKeys.playerAvatar,
              radius: avatarRadius,
              backgroundImage: currentPlayer.photoPath!.startsWith('data:')
                  ? MemoryImage(
                      base64Decode(currentPlayer.photoPath!.split(',')[1]))
                  : NetworkImage(currentPlayer.photoPath!) as ImageProvider,
            )
          else
            CircleAvatar(
              key: ClockworkQuestGameKeys.playerAvatar,
              radius: avatarRadius,
              backgroundColor: const Color(0xFFC5A54E),
              child: Text(
                currentPlayer.name[0].toUpperCase(),
                style: GoogleFonts.cinzelDecorative(
                  fontSize: avatarRadius * 0.8,
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
              fontSize: nameFontSize,
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
                fontSize: labelFontSize,
                color: const Color(0xFFF5F0E8).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${currentTarget - 1}/$maxTarget',
              key: ClockworkQuestGameKeys.currentTargetText,
              style: GoogleFonts.cinzelDecorative(
                fontSize: targetFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFBF00),
              ),
            ),
            Text(
              'gears activated',
              style: GoogleFonts.lato(
                fontSize: labelFontSize,
                color: const Color(0xFFF5F0E8).withOpacity(0.5),
              ),
            ),
          ] else ...[
            Text(
              'Target',
              style: GoogleFonts.lato(
                fontSize: labelFontSize,
                color: const Color(0xFFF5F0E8).withOpacity(0.6),
              ),
            ),
            Text(
              currentTarget == 21 ? 'BULL' : '$currentTarget',
              key: ClockworkQuestGameKeys.currentTargetText,
              style: GoogleFonts.cinzelDecorative(
                fontSize: targetFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFBF00),
              ),
            ),
            Text(
              '${currentTarget - 1}/$maxTarget',
              style: GoogleFonts.lato(
                fontSize: labelFontSize,
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
                  : () {
                      final dartsThrown =
                          provider.getCurrentPlayerDartsThrown();
                      provider.skipTurn();
                      // Darts on board → wait for DARTS REMOVED (Clockwork's
                      // skip has never announced); 0 darts → 500ms
                      // auto-advance with no modal.
                      scheduleTakeoutSequence(dartsOnBoard: dartsThrown > 0);
                    },
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
    // 3+ tiles: stretch to fill height so nothing clips
    if (opponentIds.length >= 3) {
      return Column(
        children: [
          for (final opponentId in opponentIds)
            Expanded(
              child: _buildOpponentTile(
                  opponentId, provider, playerProvider, game),
            ),
        ],
      );
    }
    // Fewer tiles: natural sizing, centered vertically
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
    final gearsActivated = target - 1;
    final inventorPath = provider.getInventorImagePath(opponentId);
    final showLaps = (game.numberOfLaps as int) > 1;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // When inside Expanded (finite height), scale image to fit;
          // otherwise use default 220px
          final imgSize = constraints.maxHeight.isFinite
              ? (constraints.maxHeight - 50).clamp(40.0, 220.0)
              : 220.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Inventor character image
              if (inventorPath != null)
                Image.asset(inventorPath,
                    width: imgSize, height: imgSize, fit: BoxFit.contain)
              else
                CircleAvatar(
                  radius: imgSize / 2,
                  backgroundColor: const Color(0xFFB87333),
                  child: Text(
                    opponent.name[0].toUpperCase(),
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: imgSize * 0.325,
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
              if (showLaps)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lap ${laps + 1}/${game.numberOfLaps}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: const Color(0xFFF5F0E8).withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$gearsActivated/$maxTarget',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: const Color(0xFFFFBF00),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '$gearsActivated/$maxTarget',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFFFFBF00),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          );
        },
      ),
    );
  }

  void _showEditScoreDialog(BuildContext context) {
    final clockworkProvider =
        Provider.of<ClockworkQuestProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    final currentPlayerId = clockworkProvider.getCurrentPlayerId();
    if (currentPlayerId == null) return;

    final currentPlayer = playerProvider.getPlayerById(currentPlayerId);
    if (currentPlayer == null) return;

    showEditScoreDialog(
      context: context,
      playerName: currentPlayer.name,
      initialSegments: clockworkProvider.getCurrentTurnDarts(currentPlayerId),
      config: EditScoreDialogConfig.clockworkQuest(),
      onSubmit: (newSegments) {
        clockworkProvider.editScore(
          newSegments.map((s) => {'sector': s}).toList(),
        );
      },
    );
  }
}
