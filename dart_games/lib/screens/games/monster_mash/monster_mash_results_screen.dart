import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/player.dart';
import '../../../models/monster_mash_game.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/monster_mash_provider.dart';
import '../../../services/victory_music_service.dart';
import '../../../constants/test_keys.dart';
import 'monster_mash_menu_screen.dart';
import 'monster_mash_game_screen.dart';

class MonsterMashResultsScreen extends StatefulWidget {
  const MonsterMashResultsScreen({super.key});

  @override
  State<MonsterMashResultsScreen> createState() => _MonsterMashResultsScreenState();
}

class _MonsterMashResultsScreenState extends State<MonsterMashResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _statsUpdated = false;

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

    final monsterMashProvider = context.read<MonsterMashProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentGame = monsterMashProvider.currentGame;

    if (currentGame == null) return;

    final gameDuration = DateTime.now().difference(currentGame.startedAt);
    final winners = monsterMashProvider.getWinners(playerProvider.allPlayers);
    final winnerIds = winners.map((p) => p.id).toSet();
    final playerCount = currentGame.getPlayerCount();

    for (final playerId in currentGame.playerIds) {
      final isWinner = winnerIds.contains(playerId);
      final dartThrows = currentGame.getTotalDartsThrown(playerId);
      final turns = currentGame.getTotalTurns(playerId);

      await playerProvider.updatePlayerStats(
        playerId,
        won: isWinner,
        gameName: 'Monster Mash',
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
    final monsterMashProvider = context.read<MonsterMashProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final currentGame = monsterMashProvider.currentGame;
    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    final winners = monsterMashProvider.getWinners(playerProvider.allPlayers);
    if (winners.isEmpty) {
      return const Scaffold(body: Center(child: Text('No winner found')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Text(
            'Monster Mash Game Over',
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
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/games/monster_mash/images/MonsterMash-Background.png',
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
                Color(0xFF4B0082),
                Color(0xFF7FFF00),
                Color(0xFFFF8C00),
                Color(0xFFF5F5DC),
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
                Color(0xFF4B0082),
                Color(0xFF7FFF00),
                Color(0xFFFF8C00),
                Color(0xFFF5F5DC),
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
                Color(0xFF4B0082),
                Color(0xFF7FFF00),
                Color(0xFFFF8C00),
                Color(0xFFF5F5DC),
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
                  // Winner monster image(s)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: _buildWinnerMonsters(winners, currentGame, monsterMashProvider),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Winner text
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Text(
                        winners.length == 1 ? 'LAST MONSTER STANDING!' : 'TIED!',
                        style: GoogleFonts.creepster(
                          fontSize: 48,
                          color: const Color(0xFF7FFF00),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Winner name(s)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: winners.map((winner) {
                        final monsterType = monsterMashProvider.getMonsterType(winner.id);
                        final monsterName = monsterType != null
                            ? MonsterMashGame.getMonsterDisplayName(monsterType)
                            : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Text(
                                key: MonsterMashResultsKeys.winnerName,
                                winner.name,
                                style: GoogleFonts.creepster(
                                  fontSize: 36,
                                  color: const Color(0xFFF5F5DC),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                monsterName,
                                style: GoogleFonts.pirataOne(
                                  fontSize: 20,
                                  color: const Color(0xFFFF8C00),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Action buttons
                  _buildActionButton(
                    'Play Again',
                    Icons.refresh,
                    const Color(0xFF7FFF00),
                    _playAgain,
                    key: MonsterMashResultsKeys.playAgainButton,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    'Change Settings',
                    Icons.settings,
                    const Color(0xFFFF8C00),
                    _changeSettings,
                    key: MonsterMashResultsKeys.changeSettingsButton,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    'Play Another Game',
                    Icons.home,
                    const Color(0xFF2F4F4F),
                    _goHome,
                    key: MonsterMashResultsKeys.backToMenuButton,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerMonsters(List<Player> winners, MonsterMashGame currentGame, MonsterMashProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: winners.map((winner) {
        final monsterType = provider.getMonsterType(winner.id);
        if (monsterType == null) return const SizedBox();

        final monsterName = MonsterMashGame.getMonsterFileName(monsterType);
        final imagePath = 'assets/games/monster_mash/characters/$monsterName-FullHealth.png';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Image.asset(
            imagePath,
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        );
      }).toList(),
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
        icon: Icon(icon, color: const Color(0xFFF5F5DC)),
        label: Text(
          label,
          style: GoogleFonts.pirataOne(
            fontSize: 22,
            color: const Color(0xFFF5F5DC),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }

  void _playAgain() {
    final monsterMashProvider = context.read<MonsterMashProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentGame = monsterMashProvider.currentGame!;

    final players = currentGame.playerIds
        .map((id) => playerProvider.getPlayerById(id))
        .whereType<Player>()
        .toList();

    monsterMashProvider.startGame(
      players,
      currentGame.healthMax,
      currentGame.bonusBuffsEnabled,
      currentGame.speedPlayEnabled,
      currentGame.roundLimit,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MonsterMashGameScreen()),
    );
  }

  void _changeSettings() {
    final monsterMashProvider = context.read<MonsterMashProvider>();
    final currentGame = monsterMashProvider.currentGame!;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MonsterMashMenuScreen(
          preselectedPlayerIds: currentGame.playerIds,
          initialHealthMax: currentGame.healthMax,
          initialBonusBuffs: currentGame.bonusBuffsEnabled,
          initialSpeedPlay: currentGame.speedPlayEnabled,
          initialRoundLimit: currentGame.roundLimit,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _goHome() {
    final monsterMashProvider = context.read<MonsterMashProvider>();
    monsterMashProvider.clearGame();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
