import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/player.dart';
import '../../../models/reef_royale_game.dart';
import '../../../providers/player_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../providers/reef_royale_provider.dart';
import '../../../services/victory_music_service.dart';
import '../../../constants/test_keys.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../providers/dartboard_provider.dart';
import 'reef_royale_menu_screen.dart';
import 'reef_royale_game_screen.dart';

class ReefRoyaleResultsScreen extends StatefulWidget {
  const ReefRoyaleResultsScreen({super.key});

  @override
  State<ReefRoyaleResultsScreen> createState() =>
      _ReefRoyaleResultsScreenState();
}

class _ReefRoyaleResultsScreenState extends State<ReefRoyaleResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _statsUpdated = false;

  // Reef Royale color palette
  static const _deepReefBlue = Color(0xFF0B3D91);
  static const _seafoamGreen = Color(0xFF48D1CC);
  static const _sunlitAqua = Color(0xFF00CED1);
  static const _pearlWhite = Color(0xFFFFF8F0);
  static const _sandyGold = Color(0xFFF4D03F);
  static const _coralPink = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(hours: 1),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deleteResumedSavedGame();
      _updatePlayerStats();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _confettiController.play();
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _playVictoryMusic();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updatePlayerStats() async {
    try {
      if (_statsUpdated) return;
      _statsUpdated = true;

      final reefProvider = context.read<ReefRoyaleProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final currentGame = reefProvider.currentGame;

      if (currentGame == null) return;

      final gameDuration = DateTime.now().difference(currentGame.startedAt);
      final winnerIds = currentGame.winnerIds ?? [];
      final playerCount = currentGame.getPlayerCount();

      for (final playerId in currentGame.playerIds) {
        if (!mounted) return;
        final isWinner = winnerIds.contains(playerId);
        final dartThrows = currentGame.totalDartsThrown[playerId] ?? 0;
        final turns = currentGame.totalTurns[playerId] ?? 0;

        await playerProvider.updatePlayerStats(
          playerId,
          won: isWinner,
          gameName: 'Reef Royale',
          gameDuration: gameDuration,
          dartThrows: dartThrows,
          turns: turns,
          playerCount: playerCount,
        );
      }
    } catch (e) {
      debugPrint('Error updating player stats: $e');
    }
  }

  void _deleteResumedSavedGame() async {
    try {
      final reefProvider = context.read<ReefRoyaleProvider>();
      final savedGameId = reefProvider.resumedSavedGameId;
      if (savedGameId != null) {
        await SaveGameService().deleteSavedGame('reef_royale', savedGameId);
        if (!mounted) return;
        reefProvider.clearResumedSavedGameId();
      }
    } catch (e) {
      debugPrint('Error deleting resumed saved game: $e');
    }
  }

  void _playVictoryMusic() async {
    try {
      final musicService = VictoryMusicService();
      final customMusicSource = await musicService.getRandomMusicSource();

      await _audioPlayer.setVolume(0.7);

      if (customMusicSource != null && customMusicSource.isNotEmpty) {
        if (customMusicSource.startsWith('data:')) {
          await _audioPlayer.play(UrlSource(customMusicSource)).timeout(
                const Duration(seconds: 5),
                onTimeout: () => debugPrint('Audio playback timed out'),
              );
        } else {
          await _audioPlayer.play(DeviceFileSource(customMusicSource)).timeout(
                const Duration(seconds: 5),
                onTimeout: () => debugPrint('Audio playback timed out'),
              );
        }
      } else {
        await _audioPlayer
            .play(UrlSource(
                'https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'))
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => debugPrint('Audio playback timed out'),
            );
      }
    } catch (e) {
      debugPrint('Error playing victory music: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final reefProvider = context.read<ReefRoyaleProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final currentGame = reefProvider.currentGame;
    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    final allPlayers = playerProvider.allPlayers;
    if (allPlayers.isEmpty) {
      return const Scaffold(body: Center(child: Text('No player data')));
    }
    final rankedIds = currentGame.getRankedPlayerIds();
    final winnerIds = currentGame.winnerIds ?? [];
    final winners = winnerIds.isEmpty
        ? [allPlayers.first]
        : winnerIds
            .map((id) => allPlayers.firstWhere((p) => p.id == id,
                orElse: () => allPlayers.first))
            .toList();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _deepReefBlue,
          appBar: AppBar(
            title: Transform.translate(
              offset: const Offset(0, -3),
              child: Text(
                'Reef Royale — Game Over',
                style: GoogleFonts.fredoka(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _pearlWhite,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                        color: _seafoamGreen.withOpacity(0.6), blurRadius: 12),
                    const Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(2, 2)),
                  ],
                ),
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
            automaticallyImplyLeading: false,
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
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),

              // Confetti
              Align(
                alignment: Alignment.topLeft,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 4,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.1,
                  colors: const [
                    _seafoamGreen,
                    _sandyGold,
                    _coralPink,
                    _sunlitAqua,
                    _pearlWhite
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.1,
                  colors: const [
                    _seafoamGreen,
                    _sandyGold,
                    _coralPink,
                    _sunlitAqua,
                    _pearlWhite
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 3 * pi / 4,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.1,
                  colors: const [
                    _seafoamGreen,
                    _sandyGold,
                    _coralPink,
                    _sunlitAqua,
                    _pearlWhite
                  ],
                ),
              ),

              // Main content
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Scale creature size to fit everything on screen without scrolling
                    final availableHeight = constraints.maxHeight;
                    final creatureMaxHeight =
                        (availableHeight * 0.30).clamp(100.0, 280.0);

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Winner creature image(s)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: ScaleTransition(
                              scale: _pulseAnimation,
                              child: _buildWinnerCreatures(
                                  winners, currentGame, reefProvider,
                                  maxSize: creatureMaxHeight),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Winner text
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: ScaleTransition(
                              scale: _pulseAnimation,
                              child: Text(
                                winners.length == 1
                                    ? 'CROWN OF THE REEF!'
                                    : 'TIED!',
                                style: GoogleFonts.fredoka(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: _sandyGold,
                                  shadows: [
                                    Shadow(
                                        color: _sandyGold.withOpacity(0.5),
                                        blurRadius: 20),
                                    const Shadow(
                                        color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Winner name(s) with avatar(s)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildWinnerNamesAndAvatars(winners),
                          ),

                          const SizedBox(height: 8),

                          // Winner stats (only show if single winner)
                          if (winners.length == 1)
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildStatChip(
                                    '${currentGame.getPlayerPearls(winners[0].id)}',
                                    'Pearls',
                                    _sandyGold,
                                    ReefRoyaleResultsKeys.pearlCount,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatChip(
                                    '${currentGame.getPlayerClaimedCount(winners[0].id)}/7',
                                    'Corals',
                                    _seafoamGreen,
                                    ReefRoyaleResultsKeys.coralCount,
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Rankings
                          Flexible(
                              child: SingleChildScrollView(
                                  child: _buildRankings(
                                      rankedIds, allPlayers, currentGame))),

                          const SizedBox(height: 16),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                'DIVE AGAIN',
                                Icons.refresh,
                                _seafoamGreen,
                                _deepReefBlue,
                                _playAgain,
                                key: ReefRoyaleResultsKeys.playAgainButton,
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                'CHANGE REEFS',
                                Icons.settings,
                                _sunlitAqua,
                                _deepReefBlue,
                                _changeSettings,
                                key: ReefRoyaleResultsKeys.changeSettingsButton,
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                'SWIM HOME',
                                Icons.home,
                                _coralPink,
                                _pearlWhite,
                                _goHome,
                                key: ReefRoyaleResultsKeys.backToMenuButton,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Dartboard paused modal — covers entire screen incl. AppBar when disconnected.
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status != DartboardConnectionStatus.connected &&
            dartboardProvider.status != DartboardConnectionStatus.emulator)
          DartboardPausedModal(
            config: DartboardPausedModalConfig.reefRoyale(),
          ),
      ],
    );
  }

  Widget _buildWinnerCreatures(
      List<Player> winners, ReefRoyaleGame game, ReefRoyaleProvider provider,
      {double? maxSize}) {
    // Scale creature size based on number of winners and available space
    double creatureSize;
    double horizontalPadding;
    if (winners.length <= 2) {
      creatureSize = 320;
      horizontalPadding = 20;
    } else if (winners.length <= 4) {
      creatureSize = 260;
      horizontalPadding = 16;
    } else if (winners.length <= 6) {
      creatureSize = 210;
      horizontalPadding = 12;
    } else {
      creatureSize = 180;
      horizontalPadding = 8;
    }

    // Clamp to maxSize if provided (responsive layout)
    if (maxSize != null && creatureSize > maxSize) {
      creatureSize = maxSize;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: winners.map((winner) {
        final imagePath = provider.getCreatureImagePath(winner.id);
        if (imagePath == null) return const SizedBox();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Image.asset(
            imagePath,
            width: creatureSize,
            height: creatureSize,
            fit: BoxFit.contain,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWinnerNamesAndAvatars(List<Player> winners) {
    // Match sizes and spacing to character sizes above for proper alignment
    double fontSize;
    double avatarRadius;
    double horizontalPadding;
    double iconSize;
    double maxWidth;

    if (winners.length <= 2) {
      fontSize = 40;
      avatarRadius = 60;
      horizontalPadding = 20; // Matches creature padding
      iconSize = 60;
      maxWidth = 320; // Matches creature width
    } else if (winners.length <= 4) {
      fontSize = 36;
      avatarRadius = 50;
      horizontalPadding = 16; // Matches creature padding
      iconSize = 50;
      maxWidth = 260; // Matches creature width
    } else if (winners.length <= 6) {
      fontSize = 32;
      avatarRadius = 45;
      horizontalPadding = 12; // Matches creature padding
      iconSize = 45;
      maxWidth = 210; // Matches creature width
    } else {
      fontSize = 30;
      avatarRadius = 42;
      horizontalPadding = 8; // Matches creature padding
      iconSize = 42;
      maxWidth = 180; // Matches creature width
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: winners.map((winner) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            width: maxWidth,
            child: Column(
              children: [
                Text(
                  key: ReefRoyaleResultsKeys.winnerName,
                  winner.name,
                  style: GoogleFonts.fredoka(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: _pearlWhite,
                    shadows: [
                      Shadow(
                          color: _seafoamGreen.withOpacity(0.7),
                          blurRadius: 16),
                      const Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (winner.photoPath != null)
                  CircleAvatar(
                    key: ReefRoyaleResultsKeys.winnerPhoto,
                    radius: avatarRadius,
                    backgroundImage: winner.photoPath!.startsWith('data:')
                        ? MemoryImage(
                            base64Decode(winner.photoPath!.split(',')[1]))
                        : NetworkImage(winner.photoPath!) as ImageProvider,
                  )
                else
                  CircleAvatar(
                    key: ReefRoyaleResultsKeys.winnerPhoto,
                    radius: avatarRadius,
                    backgroundColor: _seafoamGreen.withOpacity(0.3),
                    child:
                        Icon(Icons.person, size: iconSize, color: _pearlWhite),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatChip(String value, String label, Color color, Key? key) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _deepReefBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: _pearlWhite.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankings(
      List<String> rankedIds, List<Player> allPlayers, ReefRoyaleGame game) {
    // If more than 4 players, split into two columns
    if (rankedIds.length > 4) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Places 1-4
          Expanded(
            child: _buildRankingColumn(
                rankedIds.take(4).toList(), allPlayers, game, 0),
          ),
          const SizedBox(width: 16),
          // Right column: Places 5-8
          Expanded(
            child: _buildRankingColumn(
                rankedIds.skip(4).toList(), allPlayers, game, 4),
          ),
        ],
      );
    }

    // 4 or fewer players: single column
    return _buildRankingColumn(rankedIds, allPlayers, game, 0);
  }

  Widget _buildRankingColumn(List<String> rankedIds, List<Player> allPlayers,
      ReefRoyaleGame game, int startIndex) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _deepReefBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _seafoamGreen.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rankedIds.length, (index) {
          final playerId = rankedIds[index];
          final player = allPlayers.firstWhere(
            (p) => p.id == playerId,
            orElse: () =>
                Player(id: playerId, name: 'Player', createdAt: DateTime.now()),
          );
          final pearls = game.getPlayerPearls(playerId);
          final corals = game.getPlayerClaimedCount(playerId);
          final isWinner = playerId == game.winnerId;
          final globalIndex = startIndex + index;

          return Container(
            key: ReefRoyaleResultsKeys.playerRanking(globalIndex),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isWinner
                  ? _seafoamGreen.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isWinner
                  ? Border.all(color: _seafoamGreen.withOpacity(0.5))
                  : null,
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 30,
                  child: Text(
                    '#${globalIndex + 1}',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: globalIndex == 0
                          ? _sandyGold
                          : _pearlWhite.withOpacity(0.7),
                    ),
                  ),
                ),
                // Player avatar
                if (player.photoPath != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: player.photoPath!.startsWith('data:')
                        ? MemoryImage(
                            base64Decode(player.photoPath!.split(',')[1]))
                        : NetworkImage(player.photoPath!) as ImageProvider,
                  )
                else
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _seafoamGreen.withOpacity(0.3),
                    child:
                        const Icon(Icons.person, size: 16, color: _pearlWhite),
                  ),
                const SizedBox(width: 8),
                // Name
                Expanded(
                  child: Text(
                    player.name,
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _pearlWhite,
                    ),
                  ),
                ),
                // Stats
                Text(
                  '$corals/7 corals  |  $pearls pearls',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: _pearlWhite.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color bgColor,
    Color fgColor,
    VoidCallback onTap, {
    Key? key,
  }) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton.icon(
        key: key,
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _playAgain() {
    final reefProvider = context.read<ReefRoyaleProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentGame = reefProvider.currentGame!;

    final players = currentGame.playerIds
        .map((id) => playerProvider.getPlayerById(id))
        .whereType<Player>()
        .toList();

    reefProvider.startGame(
      players,
      currentGame.gameMode,
      currentGame.easyClaim,
      currentGame.neighborNumbers,
      currentGame.randomReefs,
      currentGame.bonusBuffsEnabled,
      currentGame.showHints,
      currentGame.speedPlayEnabled,
      currentGame.roundLimit,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ReefRoyaleGameScreen()),
    );
  }

  void _changeSettings() {
    final reefProvider = context.read<ReefRoyaleProvider>();
    final currentGame = reefProvider.currentGame!;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ReefRoyaleMenuScreen(
          preselectedPlayerIds: currentGame.playerIds,
          initialGameMode: currentGame.gameMode,
          initialEasyClaim: currentGame.easyClaim,
          initialNeighborNumbers: currentGame.neighborNumbers,
          initialRandomReefs: currentGame.randomReefs,
          initialBonusBuffs: currentGame.bonusBuffsEnabled,
          initialShowHints: currentGame.showHints,
          initialSpeedPlay: currentGame.speedPlayEnabled,
          initialRoundLimit: currentGame.roundLimit,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _goHome() {
    final reefProvider = context.read<ReefRoyaleProvider>();
    reefProvider.clearGame();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
