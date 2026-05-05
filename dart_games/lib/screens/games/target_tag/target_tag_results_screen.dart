import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/target_tag_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../services/victory_music_service.dart';
import '../../../widgets/target_tag/tech_neon_background.dart';
import '../../../constants/test_keys.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../providers/dartboard_provider.dart';
import 'target_tag_menu_screen.dart';
import 'target_tag_game_screen.dart';

class TargetTagResultsScreen extends StatefulWidget {
  const TargetTagResultsScreen({super.key});

  @override
  State<TargetTagResultsScreen> createState() => _TargetTagResultsScreenState();
}

class _TargetTagResultsScreenState extends State<TargetTagResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _statsUpdated = false; // Prevent duplicate stats updates

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Setup pulse animation for trophy and winner text
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

    // Update stats, celebrate, and play music
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deleteResumedSavedGame();
      _updatePlayerStats();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _confettiController.play();
        }
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _playVictoryMusic();
        }
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
      // Prevent duplicate stats updates
      if (_statsUpdated) return;
      _statsUpdated = true;

      final targetTagProvider = context.read<TargetTagProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final currentGame = targetTagProvider.currentGame;

      if (currentGame == null) return;

      // Calculate game duration
      final gameDuration = DateTime.now().difference(currentGame.startedAt);

      // Get winners
      final winners = targetTagProvider.getWinners(playerProvider.allPlayers);
      final winnerIds = winners.map((p) => p.id).toSet();

      // Get player count
      final playerCount = currentGame.getPlayerCount();

      // Update stats for all players (both winners and losers get duration)
      for (final playerId in currentGame.playerIds) {
        if (!mounted) return;
        final isWinner = winnerIds.contains(playerId);
        final dartThrows = currentGame.getTotalDartsThrown(playerId);
        final turns = currentGame.getTotalTurns(playerId);

        await playerProvider.updatePlayerStats(
          playerId,
          won: isWinner,
          gameName: 'Target Tag',
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
      final targetTagProvider = context.read<TargetTagProvider>();
      final savedGameId = targetTagProvider.resumedSavedGameId;
      if (savedGameId != null) {
        await SaveGameService().deleteSavedGame('target_tag', savedGameId);
        if (!mounted) return;
        targetTagProvider.clearResumedSavedGameId();
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
          // Web: data URL
          await _audioPlayer.play(UrlSource(customMusicSource)).timeout(
                const Duration(seconds: 5),
                onTimeout: () => debugPrint('Audio playback timed out'),
              );
        } else {
          // Native: file path
          await _audioPlayer.play(DeviceFileSource(customMusicSource)).timeout(
                const Duration(seconds: 5),
                onTimeout: () => debugPrint('Audio playback timed out'),
              );
        }
      } else {
        // Fallback
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
    final targetTagProvider = context.watch<TargetTagProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    final currentGame = targetTagProvider.currentGame;
    if (currentGame == null) {
      return const Scaffold(
        body: Center(child: Text('No game data')),
      );
    }

    final winners = targetTagProvider.getWinners(playerProvider.allPlayers);
    if (winners.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No winner found')),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            title: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Target Tag Game Over',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 36,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            backgroundColor: const Color(0xFFFF007A), // Hot pink
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.targetTag(),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Tech/Neon background
              const Positioned.fill(
                child: TechNeonBackground(),
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
                    Color(0xFFFF007A),
                    Color(0xFF00FFA3),
                    Colors.yellow,
                    Colors.blue,
                    Colors.purple,
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
                    Color(0xFFFF007A),
                    Color(0xFF00FFA3),
                    Colors.yellow,
                    Colors.blue,
                    Colors.purple,
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
                    Color(0xFFFF007A),
                    Color(0xFF00FFA3),
                    Colors.yellow,
                    Colors.blue,
                    Colors.purple,
                  ],
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trophy icon - gold and pulsing
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: const Icon(
                            Icons.emoji_events,
                            size: 120,
                            color: Color(0xFFFFD700), // Arcade gold
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Winner announcement - larger and pulsing
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Text(
                            winners.length == 1 ? 'WINNER!' : 'WINNERS!',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 64, // Increased from 48
                              color: const Color(0xFFFFD700), // Arcade gold
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Winner images and names
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            // Player images side by side in team mode, single image in solo mode
                            if (winners.length > 1) ...[
                              // Team mode: Show both player images side by side
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: winners
                                    .map((winner) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: winner.photoPath != null
                                              ? CircleAvatar(
                                                  radius: 60,
                                                  backgroundImage: winner
                                                          .photoPath!
                                                          .startsWith('data:')
                                                      ? MemoryImage(Uri.parse(
                                                              winner.photoPath!)
                                                          .data!
                                                          .contentAsBytes())
                                                      : NetworkImage(
                                                              winner.photoPath!)
                                                          as ImageProvider,
                                                )
                                              : CircleAvatar(
                                                  radius: 60,
                                                  backgroundColor:
                                                      const Color(0xFFFF007A),
                                                  child: Text(
                                                    winner.name[0]
                                                        .toUpperCase(),
                                                    style: GoogleFonts.fredoka(
                                                      fontSize: 48,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              // Player names below images
                              ...winners.map((winner) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      winner.name,
                                      style: GoogleFonts.luckiestGuy(
                                        fontSize: 36,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                            ] else ...[
                              // Solo mode: Show single player image and name
                              if (winners.isNotEmpty) ...[
                                if (winners.first.photoPath != null)
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundImage: winners.first.photoPath!
                                            .startsWith('data:')
                                        ? MemoryImage(
                                            Uri.parse(winners.first.photoPath!)
                                                .data!
                                                .contentAsBytes())
                                        : NetworkImage(winners.first.photoPath!)
                                            as ImageProvider,
                                  )
                                else
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: const Color(0xFFFF007A),
                                    child: Text(
                                      winners.first.name[0].toUpperCase(),
                                      style: GoogleFonts.fredoka(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  winners.first.name,
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 36,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Action buttons
                      _buildActionButton(
                        'Play Again',
                        Icons.refresh,
                        const Color(0xFF00FFA3),
                        _playAgain,
                        key: TargetTagResultsKeys.playAgainButton,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        'Change Settings',
                        Icons.settings,
                        const Color(0xFFFF007A),
                        _changeSettings,
                        key: TargetTagResultsKeys.changeSettingsButton,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        'Select Different Game',
                        Icons.home,
                        const Color(0xFF2A2A3E),
                        _goHome,
                        key: TargetTagResultsKeys.backToMenuButton,
                      ),
                    ],
                  ),
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
            config: DartboardPausedModalConfig.targetTag(),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    Key? key,
  }) {
    return SizedBox(
      width: 300,
      height: 60,
      child: ElevatedButton.icon(
        key: key,
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _playAgain() {
    final targetTagProvider = context.read<TargetTagProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentGame = targetTagProvider.currentGame!;

    // Get players from current game
    final players = currentGame.playerIds
        .map((id) => playerProvider.getPlayerById(id))
        .whereType<Player>()
        .toList();

    // Restart game with same settings
    if (currentGame.mode.toString().contains('team')) {
      targetTagProvider.startTeamGame(
        currentGame.teamPlayers!,
        currentGame.shieldMax,
        currentGame.soloHeroBonus,
      );
    } else {
      targetTagProvider.startSoloGame(
          players, currentGame.shieldMax, currentGame.soloHeroBonus);
    }

    // Navigate to game screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const TargetTagGameScreen(),
      ),
    );
  }

  void _changeSettings() {
    final targetTagProvider = context.read<TargetTagProvider>();
    final currentGame = targetTagProvider.currentGame!;

    // Navigate to menu with preselected values
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => TargetTagMenuScreen(
          preselectedPlayerIds: currentGame.playerIds,
          initialShieldMax: currentGame.shieldMax,
          initialIsTeamMode: currentGame.mode.toString().contains('team'),
          initialSoloHeroBonus: currentGame.soloHeroBonus,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _goHome() {
    final targetTagProvider = context.read<TargetTagProvider>();
    targetTagProvider.clearGame();

    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
