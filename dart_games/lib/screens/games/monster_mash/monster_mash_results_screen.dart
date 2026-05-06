import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/player.dart';
import '../../../models/monster_mash_game.dart';
import '../../../providers/player_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../providers/monster_mash_provider.dart';
import '../../../services/victory_music_service.dart';
import '../../../constants/test_keys.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../providers/dartboard_provider.dart';
import 'monster_mash_menu_screen.dart';
import 'monster_mash_game_screen.dart';

class MonsterMashResultsScreen extends StatefulWidget {
  const MonsterMashResultsScreen({super.key});

  @override
  State<MonsterMashResultsScreen> createState() =>
      _MonsterMashResultsScreenState();
}

class _MonsterMashResultsScreenState extends State<MonsterMashResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;
  AnimationController? _glowController1;
  AnimationController? _glowController2;
  AnimationController? _glowController3;
  late AnimationController _lightningController;
  Animation<double>? _glowAnimation1;
  Animation<double>? _glowAnimation2;
  Animation<double>? _glowAnimation3;
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

    // Glow pulse controllers at different rates
    _glowController1 = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation1 = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController1!, curve: Curves.easeInOut),
    );

    _glowController2 = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation2 = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController2!, curve: Curves.easeInOut),
    );

    _glowController3 = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation3 = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController3!, curve: Curves.easeInOut),
    );

    _lightningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

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
    _glowController1?.dispose();
    _glowController2?.dispose();
    _glowController3?.dispose();
    _lightningController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updatePlayerStats() async {
    try {
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

      await playerProvider.batchUpdatePlayerStats([
        for (final playerId in currentGame.playerIds)
          PlayerStatsUpdate(
            playerId: playerId,
            won: winnerIds.contains(playerId),
            gameName: 'Monster Mash',
            gameDuration: gameDuration,
            dartThrows: currentGame.getTotalDartsThrown(playerId),
            turns: currentGame.getTotalTurns(playerId),
            playerCount: playerCount,
          ),
      ]);
    } catch (e) {
      debugPrint('Error updating player stats: $e');
    }
  }

  void _deleteResumedSavedGame() async {
    try {
      final monsterMashProvider = context.read<MonsterMashProvider>();
      final savedGameId = monsterMashProvider.resumedSavedGameId;
      if (savedGameId != null) {
        await SaveGameService().deleteSavedGame('monster_mash', savedGameId);
        if (!mounted) return;
        monsterMashProvider.clearResumedSavedGameId();
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
    final monsterMashProvider = context.watch<MonsterMashProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    final currentGame = monsterMashProvider.currentGame;
    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    final winners = monsterMashProvider.getWinners(playerProvider.allPlayers);
    if (winners.isEmpty) {
      return const Scaffold(body: Center(child: Text('No winner found')));
    }

    return Stack(
      children: [
        Scaffold(
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.monsterMash(),
                ),
              ),
            ],
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
                          child: _buildWinnerMonsters(
                              winners, currentGame, monsterMashProvider),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Winner text
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Stroke outline
                              Text(
                                winners.length == 1
                                    ? 'LAST MONSTER STANDING!'
                                    : 'TIED!',
                                style: GoogleFonts.creepster(
                                  fontSize: 60,
                                  letterSpacing: 2,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 5
                                    ..color = Colors.black,
                                ),
                              ),
                              // Fill with glow
                              Text(
                                winners.length == 1
                                    ? 'LAST MONSTER STANDING!'
                                    : 'TIED!',
                                style: GoogleFonts.creepster(
                                  fontSize: 60,
                                  color: const Color(0xFF7FFF00),
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                        color: const Color(0xFF7FFF00)
                                            .withOpacity(0.8),
                                        blurRadius: 20),
                                    Shadow(
                                        color: const Color(0xFF7FFF00)
                                            .withOpacity(0.5),
                                        blurRadius: 40),
                                    const Shadow(
                                        color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Winner name(s) with player avatar
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: winners.map((winner) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Stroke outline
                                      Text(
                                        winner.name,
                                        style: GoogleFonts.creepster(
                                          fontSize: 36,
                                          foreground: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeWidth = 4
                                            ..color = Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      // Fill with glow
                                      Text(
                                        key: MonsterMashResultsKeys.winnerName,
                                        winner.name,
                                        style: GoogleFonts.creepster(
                                          fontSize: 36,
                                          color: const Color(0xFFF5F5DC),
                                          shadows: [
                                            Shadow(
                                                color: const Color(0xFFFF8C00)
                                                    .withOpacity(0.7),
                                                blurRadius: 16),
                                            Shadow(
                                                color: const Color(0xFFFF8C00)
                                                    .withOpacity(0.4),
                                                blurRadius: 30),
                                            const Shadow(
                                                color: Colors.black,
                                                blurRadius: 4),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (winner.photoPath != null)
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundImage: winner.photoPath!
                                              .startsWith('data:')
                                          ? MemoryImage(base64Decode(
                                              winner.photoPath!.split(',')[1]))
                                          : NetworkImage(winner.photoPath!)
                                              as ImageProvider,
                                    )
                                  else
                                    const CircleAvatar(
                                      radius: 60,
                                      child: Icon(Icons.person, size: 60),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Action buttons (horizontal)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            'Play Again',
                            Icons.refresh,
                            const Color(0xFF7FFF00),
                            _playAgain,
                            glowAnimation: _glowAnimation1,
                            lightningColor: const Color(0xFF7FFF00),
                            lightningPhaseOffset: 0.0,
                            lightningSeedOffset: 0,
                            key: MonsterMashResultsKeys.playAgainButton,
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            'Change Settings',
                            Icons.settings,
                            const Color(0xFFFF8C00),
                            _changeSettings,
                            glowAnimation: _glowAnimation2,
                            lightningColor: const Color(0xFFFF8C00),
                            lightningPhaseOffset: 0.33,
                            lightningSeedOffset: 100,
                            key: MonsterMashResultsKeys.changeSettingsButton,
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            'Play Another Game',
                            Icons.home,
                            const Color(0xFF4B0082),
                            _goHome,
                            glowAnimation: _glowAnimation3,
                            lightningColor: const Color(0xFF4B0082),
                            lightningPhaseOffset: 0.67,
                            lightningSeedOffset: 200,
                            key: MonsterMashResultsKeys.backToMenuButton,
                          ),
                        ],
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
            config: DartboardPausedModalConfig.monsterMash(),
          ),
      ],
    );
  }

  Widget _buildWinnerMonsters(List<Player> winners, MonsterMashGame currentGame,
      MonsterMashProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: winners.map((winner) {
        final monsterType = provider.getMonsterType(winner.id);
        if (monsterType == null) return const SizedBox();

        final monsterName = MonsterMashGame.getMonsterFileName(monsterType);
        final imagePath =
            'assets/games/monster_mash/characters/$monsterName-FullHealth.png';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Image.asset(
            imagePath,
            width: 340,
            height: 340,
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
    Animation<double>? glowAnimation,
    Color? lightningColor,
    double lightningPhaseOffset = 0.0,
    int lightningSeedOffset = 0,
  }) {
    // Use a fixed seed based on the label so edges are consistent across rebuilds
    final jaggedClipper = _JaggedEdgeClipper(seed: label.hashCode);

    final buttonContent = SizedBox(
      width: 300,
      height: 60,
      child: CustomPaint(
        painter: _StoneTabletPainter(jaggedClipper: jaggedClipper),
        child: ClipPath(
          clipper: jaggedClipper,
          child: Stack(
            children: [
              // Stone gradient fill
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.4, -0.4),
                      radius: 1.2,
                      colors: [
                        Color(0xFFa8a8a8),
                        Color(0xFF888888),
                        Color(0xFF707070),
                      ],
                    ),
                  ),
                ),
              ),
              // Inner bevel: top/left highlight edge
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.15, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
              // Inner bevel: left/right edges
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                      ],
                      stops: const [0.0, 0.08, 0.92, 1.0],
                    ),
                  ),
                ),
              ),
              // Cracked stone texture overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 1.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage(
                            'assets/games/monster_mash/images/stone-texture.png'),
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                ),
              ),
              // Lightning effect overlay
              if (lightningColor != null)
                Positioned.fill(
                  child: RepaintBoundary(child: AnimatedBuilder(
                    animation: _lightningController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _LightningPainter(
                          animationValue: (_lightningController.value +
                                  lightningPhaseOffset) %
                              1.0,
                          lightningColor: lightningColor,
                          seedOffset: lightningSeedOffset,
                        ),
                      );
                    },
                  )),
                ),
              // Button content - chiseled text effect
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: const Color(0xFF1A1A1A),
                      size: 28,
                      shadows: [
                        Shadow(
                            color: Colors.white.withOpacity(0.5),
                            offset: const Offset(1, 1),
                            blurRadius: 0),
                        const Shadow(
                            color: Colors.black,
                            offset: Offset(-1, -1),
                            blurRadius: 0),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.pirataOne(
                        fontSize: 26,
                        color: const Color(0xFF1A1A1A),
                        shadows: [
                          Shadow(
                              color: Colors.white.withOpacity(0.5),
                              offset: const Offset(1, 1),
                              blurRadius: 0),
                          const Shadow(
                              color: Colors.black,
                              offset: Offset(-1, -1),
                              blurRadius: 0),
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
    );

    if (glowAnimation == null) {
      return GestureDetector(key: key, onTap: onTap, child: buttonContent);
    }

    return RepaintBoundary(child: AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        final glowOpacity = glowAnimation.value;
        return GestureDetector(
          key: key,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(glowOpacity),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: color.withOpacity(glowOpacity * 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: buttonContent,
          ),
        );
      },
    ));
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

/// Clips a rectangle with jagged/chipped stone edges
class _JaggedEdgeClipper extends CustomClipper<Path> {
  final int seed;
  final double jagAmount;
  final int segmentsPerSide;

  _JaggedEdgeClipper({
    this.seed = 0,
    this.jagAmount = 3.5,
    this.segmentsPerSide = 20,
  });

  @override
  Path getClip(Size size) {
    final rng = Random(seed);
    final path = Path();

    final w = size.width;
    final h = size.height;

    // Start at top-left with a small inset
    path.moveTo(jagAmount, jagAmount);

    // Top edge: left to right
    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = (w - jagAmount * 2) * i / segmentsPerSide + jagAmount;
      final y = (rng.nextDouble() - 0.5) * jagAmount * 2;
      path.lineTo(x, y.clamp(0, jagAmount * 2));
    }

    // Right edge: top to bottom
    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = w - (rng.nextDouble() - 0.5) * jagAmount * 2;
      final y = (h - jagAmount * 2) * i / segmentsPerSide + jagAmount;
      path.lineTo(x.clamp(w - jagAmount * 2, w), y);
    }

    // Bottom edge: right to left
    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = w - (w - jagAmount * 2) * i / segmentsPerSide - jagAmount;
      final y = h - (rng.nextDouble() - 0.5) * jagAmount * 2;
      path.lineTo(x, y.clamp(h - jagAmount * 2, h));
    }

    // Left edge: bottom to top
    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = (rng.nextDouble() - 0.5) * jagAmount * 2;
      final y = h - (h - jagAmount * 2) * i / segmentsPerSide - jagAmount;
      path.lineTo(x.clamp(0, jagAmount * 2), y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Paints the stone border and shadow following the jagged path
class _StoneTabletPainter extends CustomPainter {
  final _JaggedEdgeClipper jaggedClipper;

  _StoneTabletPainter({required this.jaggedClipper});

  @override
  void paint(Canvas canvas, Size size) {
    final path = jaggedClipper.getClip(size);

    // Floor shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.save();
    canvas.translate(5, 5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Stone border
    final borderPaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LightningPainter extends CustomPainter {
  final double animationValue;
  final Color lightningColor;
  final int seedOffset;

  _LightningPainter(
      {required this.animationValue,
      required this.lightningColor,
      this.seedOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    _maybeDrawBolt(canvas, size,
        phase: 0.0, duration: 0.08, seed: 42 + seedOffset);
    _maybeDrawBolt(canvas, size,
        phase: 0.05, duration: 0.04, seed: 43 + seedOffset);
    _maybeDrawBolt(canvas, size,
        phase: 0.45, duration: 0.06, seed: 77 + seedOffset);
    _maybeDrawBolt(canvas, size,
        phase: 0.50, duration: 0.03, seed: 78 + seedOffset);

    final flashOpacity = _getFlashOpacity();
    if (flashOpacity > 0) {
      final flashPaint = Paint()
        ..color = lightningColor.withOpacity(flashOpacity * 0.15);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }
  }

  double _getFlashOpacity() {
    for (final window in [
      (0.0, 0.08),
      (0.05, 0.04),
      (0.45, 0.06),
      (0.50, 0.03)
    ]) {
      final start = window.$1;
      final dur = window.$2;
      if (animationValue >= start && animationValue <= start + dur) {
        final t = (animationValue - start) / dur;
        return 1.0 - (2.0 * (t - 0.5)).abs();
      }
    }
    return 0.0;
  }

  void _maybeDrawBolt(
    Canvas canvas,
    Size size, {
    required double phase,
    required double duration,
    required int seed,
  }) {
    if (animationValue < phase || animationValue > phase + duration) return;

    final t = (animationValue - phase) / duration;
    final opacity = t < 0.3 ? t / 0.3 : 1.0 - ((t - 0.3) / 0.7);

    final rng = Random(seed);
    final startX = size.width * (0.15 + rng.nextDouble() * 0.7);
    final segments = 5 + rng.nextInt(4);

    final path = Path();
    path.moveTo(startX, 0);

    double x = startX;
    double y = 0;
    final segHeight = size.height / segments;

    for (int i = 0; i < segments; i++) {
      x += (rng.nextDouble() - 0.5) * size.width * 0.3;
      x = x.clamp(4.0, size.width - 4.0);
      y += segHeight;
      path.lineTo(x, y);
    }

    final corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, corePaint);

    final glowPaint = Paint()
      ..color = lightningColor.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    final ambientPaint = Paint()
      ..color = lightningColor.withOpacity(opacity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, ambientPaint);
  }

  @override
  bool shouldRepaint(covariant _LightningPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
