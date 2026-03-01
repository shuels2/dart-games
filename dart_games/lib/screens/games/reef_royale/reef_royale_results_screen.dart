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
import '../../../providers/reef_royale_provider.dart';
import '../../../services/victory_music_service.dart';
import '../../../constants/test_keys.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import 'reef_royale_menu_screen.dart';
import 'reef_royale_game_screen.dart';

class ReefRoyaleResultsScreen extends StatefulWidget {
  const ReefRoyaleResultsScreen({super.key});

  @override
  State<ReefRoyaleResultsScreen> createState() => _ReefRoyaleResultsScreenState();
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
    if (_statsUpdated) return;
    _statsUpdated = true;

    final reefProvider = context.read<ReefRoyaleProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentGame = reefProvider.currentGame;

    if (currentGame == null) return;

    final gameDuration = DateTime.now().difference(currentGame.startedAt);
    final winnerId = currentGame.winnerId;
    final playerCount = currentGame.getPlayerCount();

    for (final playerId in currentGame.playerIds) {
      final isWinner = playerId == winnerId;
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
  }

  void _playVictoryMusic() async {
    try {
      final musicService = VictoryMusicService();
      final customMusicSource = await musicService.getRandomMusicSource();

      await _audioPlayer.setVolume(0.7);

      if (customMusicSource != null && customMusicSource.isNotEmpty) {
        if (customMusicSource.startsWith('data:')) {
          await _audioPlayer.play(UrlSource(customMusicSource));
        } else {
          await _audioPlayer.play(DeviceFileSource(customMusicSource));
        }
      } else {
        await _audioPlayer.play(UrlSource(
            'https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'));
      }
    } catch (e) {
      debugPrint('Error playing victory music: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reefProvider = context.read<ReefRoyaleProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final currentGame = reefProvider.currentGame;
    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    final allPlayers = playerProvider.allPlayers;
    final rankedIds = currentGame.getRankedPlayerIds();
    final winnerId = currentGame.winnerId;
    final winner = winnerId != null
        ? allPlayers.firstWhere((p) => p.id == winnerId, orElse: () => allPlayers.first)
        : allPlayers.first;

    return Scaffold(
      backgroundColor: _deepReefBlue,
      appBar: AppBar(
        title: Text(
          'Reef Royale — Game Over',
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
              colors: const [_seafoamGreen, _sandyGold, _coralPink, _sunlitAqua, _pearlWhite],
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
              colors: const [_seafoamGreen, _sandyGold, _coralPink, _sunlitAqua, _pearlWhite],
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
              colors: const [_seafoamGreen, _sandyGold, _coralPink, _sunlitAqua, _pearlWhite],
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Winner creature image
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: _buildWinnerCreature(winner, currentGame, reefProvider),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Winner text
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Text(
                        'CROWN OF THE REEF!',
                        style: GoogleFonts.fredoka(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _sandyGold,
                          shadows: [
                            Shadow(color: _sandyGold.withOpacity(0.5), blurRadius: 20),
                            const Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Winner name with avatar
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Text(
                          key: ReefRoyaleResultsKeys.winnerName,
                          winner.name,
                          style: GoogleFonts.fredoka(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _pearlWhite,
                            shadows: [
                              Shadow(color: _seafoamGreen.withOpacity(0.7), blurRadius: 16),
                              const Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (winner.photoPath != null)
                          CircleAvatar(
                            key: ReefRoyaleResultsKeys.winnerPhoto,
                            radius: 50,
                            backgroundImage: winner.photoPath!.startsWith('data:')
                                ? MemoryImage(base64Decode(winner.photoPath!.split(',')[1]))
                                : NetworkImage(winner.photoPath!) as ImageProvider,
                          )
                        else
                          CircleAvatar(
                            key: ReefRoyaleResultsKeys.winnerPhoto,
                            radius: 50,
                            backgroundColor: _seafoamGreen.withOpacity(0.3),
                            child: const Icon(Icons.person, size: 50, color: _pearlWhite),
                          ),
                        const SizedBox(height: 8),

                        // Winner stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatChip(
                              '${currentGame.getPlayerPearls(winnerId ?? '')}',
                              'Pearls',
                              _sandyGold,
                              ReefRoyaleResultsKeys.pearlCount,
                            ),
                            const SizedBox(width: 16),
                            _buildStatChip(
                              '${currentGame.getPlayerClaimedCount(winnerId ?? '')}/7',
                              'Corals',
                              _seafoamGreen,
                              ReefRoyaleResultsKeys.coralCount,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Rankings
                  _buildRankings(rankedIds, allPlayers, currentGame),

                  const SizedBox(height: 32),

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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerCreature(Player winner, ReefRoyaleGame game, ReefRoyaleProvider provider) {
    final imagePath = provider.getCreatureImagePath(winner.id);
    if (imagePath == null) return const SizedBox();

    return Image.asset(
      imagePath,
      width: 280,
      height: 280,
      fit: BoxFit.contain,
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

  Widget _buildRankings(List<String> rankedIds, List<Player> allPlayers, ReefRoyaleGame game) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _deepReefBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _seafoamGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: List.generate(rankedIds.length, (index) {
          final playerId = rankedIds[index];
          final player = allPlayers.firstWhere(
            (p) => p.id == playerId,
            orElse: () => Player(id: playerId, name: 'Player', createdAt: DateTime.now()),
          );
          final pearls = game.getPlayerPearls(playerId);
          final corals = game.getPlayerClaimedCount(playerId);
          final isWinner = playerId == game.winnerId;

          return Container(
            key: ReefRoyaleResultsKeys.playerRanking(index),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isWinner ? _seafoamGreen.withOpacity(0.15) : Colors.transparent,
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
                    '#${index + 1}',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? _sandyGold : _pearlWhite.withOpacity(0.7),
                    ),
                  ),
                ),
                // Player avatar
                if (player.photoPath != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: player.photoPath!.startsWith('data:')
                        ? MemoryImage(base64Decode(player.photoPath!.split(',')[1]))
                        : NetworkImage(player.photoPath!) as ImageProvider,
                  )
                else
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _seafoamGreen.withOpacity(0.3),
                    child: const Icon(Icons.person, size: 16, color: _pearlWhite),
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
