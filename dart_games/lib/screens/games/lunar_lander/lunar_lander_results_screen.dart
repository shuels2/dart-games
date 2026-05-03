import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../models/lunar_lander_game.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/lunar_lander_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../services/victory_music_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import 'lunar_lander_menu_screen.dart';
import 'lunar_lander_game_screen.dart';

class LunarLanderResultsScreen extends StatefulWidget {
  const LunarLanderResultsScreen({super.key});

  @override
  State<LunarLanderResultsScreen> createState() =>
      _LunarLanderResultsScreenState();
}

class _LunarLanderResultsScreenState extends State<LunarLanderResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _statsUpdated = false;

  // Color constants
  static const Color _spaceBlack = Color(0xFF0D1B2A);
  static const Color _rocketFlame = Color(0xFFF26430);
  static const Color _earthBlue = Color(0xFF1B4965);
  static const Color _starWhite = Color(0xFFFAFDF6);
  static const Color _thrusterRed = Color(0xFFE63946);
  static const Color _missionGreen = Color(0xFF52B788);

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
    _confettiController =
        ConfettiController(duration: const Duration(hours: 1));
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
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updatePlayerStats() async {
    try {
      if (_statsUpdated) return;
      _statsUpdated = true;

      final provider = context.read<LunarLanderProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final game = provider.currentGame;
      if (game == null) return;

      final gameDuration = provider.gameDuration ?? Duration.zero;
      final winnerId = game.winnerId;

      for (final playerId in game.playerIds) {
        if (!mounted) return;
        final isWinner = playerId == winnerId;
        await playerProvider.updatePlayerStats(
          playerId,
          won: isWinner,
          gameName: 'Lunar Lander',
          gameDuration: gameDuration,
        );
      }
    } catch (e) {
      debugPrint('Error updating player stats: $e');
    }
  }

  void _deleteResumedSavedGame() async {
    try {
      final provider = context.read<LunarLanderProvider>();
      final savedGameId = provider.resumedSavedGameId;
      if (savedGameId != null) {
        await SaveGameService().deleteSavedGame('lunar_lander', savedGameId);
        if (!mounted) return;
        provider.clearResumedSavedGameId();
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
          await _audioPlayer
              .play(UrlSource(customMusicSource))
              .timeout(const Duration(seconds: 5),
                  onTimeout: () =>
                      debugPrint('Audio playback timed out'));
        } else {
          await _audioPlayer
              .play(DeviceFileSource(customMusicSource))
              .timeout(const Duration(seconds: 5),
                  onTimeout: () =>
                      debugPrint('Audio playback timed out'));
        }
      } else {
        await _audioPlayer
            .play(UrlSource(
                'https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'))
            .timeout(const Duration(seconds: 5),
                onTimeout: () =>
                    debugPrint('Audio playback timed out'));
      }
    } catch (e) {
      debugPrint('Error playing victory music: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LunarLanderProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final game = provider.currentGame;
    if (game == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    final allPlayers = playerProvider.allPlayers;
    final winnerId = game.winnerId;
    if (winnerId == null) {
      return const Scaffold(body: Center(child: Text('No winner found')));
    }
    final winner =
        allPlayers.where((p) => p.id == winnerId).firstOrNull;
    if (winner == null) {
      return const Scaffold(body: Center(child: Text('Winner not found')));
    }

    final winnerCharacter = game.getCharacter(winnerId);
    final winnerTurns = game.totalTurns[winnerId] ?? 0;

    // Sort players for rankings: ascending altitude (closest to 0), tiebreaker fewer turns
    final sortedPlayers = List<Player>.from(
        allPlayers.where((p) => game.playerIds.contains(p.id)));
    sortedPlayers.sort((a, b) {
      final altA = game.getCurrentAltitude(a.id);
      final altB = game.getCurrentAltitude(b.id);
      final absDiff = altA.abs().compareTo(altB.abs());
      if (absDiff != 0) return absDiff;
      final turnsA = game.totalTurns[a.id] ?? 0;
      final turnsB = game.totalTurns[b.id] ?? 0;
      return turnsA.compareTo(turnsB);
    });

    return Scaffold(
      backgroundColor: _spaceBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _starWhite, size: 32),
          onPressed: () => Navigator.of(context).pop(),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        title: Text(
          'LUNAR LANDER RESULTS',
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _starWhite,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: _earthBlue,
        foregroundColor: _starWhite,
        automaticallyImplyLeading: false,
        actions: [
          DartboardConnectionInfo(
            config: DartboardConnectionInfoConfig.lunarLander(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/games/lunar_lander/images/LunarLander-Background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 4,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.1,
              colors: const [
                _rocketFlame,
                _missionGreen,
                Colors.yellow,
                _starWhite,
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.1,
              colors: const [
                _rocketFlame,
                _missionGreen,
                Colors.yellow,
                _starWhite,
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3 * pi / 4,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.1,
              colors: const [
                _rocketFlame,
                _missionGreen,
                Colors.yellow,
                _starWhite,
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
                  // Title
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      'MISSION ACCOMPLISHED!',
                      style: GoogleFonts.orbitron(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _rocketFlame,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Winner card
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        // Character + player avatar side by side
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Winner character image
                            Container(
                              key: LunarLanderResultsKeys.winnerPhoto,
                              width: 270,
                              height: 270,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: _rocketFlame.withOpacity(0.6),
                                    blurRadius: 24,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: winnerCharacter != null
                                  ? Image.asset(
                                      winnerCharacter.assetPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.rocket,
                                        color: _rocketFlame,
                                        size: 180,
                                      ),
                                    )
                                  : const Icon(Icons.rocket,
                                      color: _rocketFlame, size: 180),
                            ),
                            const SizedBox(width: 24),
                            // Player avatar matching character height
                            SizedBox(
                              width: 270,
                              height: 270,
                              child: ClipOval(
                                child: winner.photoPath != null
                                    ? Image(
                                        image: winner.photoPath!.startsWith('data:')
                                            ? MemoryImage(Uri.parse(winner.photoPath!).data!.contentAsBytes())
                                            : NetworkImage(winner.photoPath!) as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: _earthBlue,
                                        child: Center(
                                          child: Text(
                                            winner.name.isNotEmpty
                                                ? winner.name[0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.orbitron(
                                              fontSize: 100,
                                              fontWeight: FontWeight.bold,
                                              color: _starWhite,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Flag
                        const Text('🚩',
                            style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        // Winner name
                        Text(
                          winner.name,
                          key: LunarLanderResultsKeys.winnerName,
                          style: GoogleFonts.orbitron(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _starWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Turn count
                        Text(
                          'Landed in $winnerTurns turns',
                          key: LunarLanderResultsKeys.turnCount,
                          style: GoogleFonts.orbitron(
                            fontSize: 20,
                            color: _rocketFlame,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Rankings
                  _buildRankings(game, sortedPlayers, allPlayers, winnerId),
                  const SizedBox(height: 32),
                  // Action buttons
                  _buildActionButtons(game, allPlayers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankings(LunarLanderGame game, List<Player> sortedPlayers,
      List<Player> allPlayers, String winnerId) {
    final cols =
        sortedPlayers.length > 4 ? 2 : 1;
    final col1 = cols == 2
        ? sortedPlayers.sublist(0, 4)
        : sortedPlayers;
    final col2 =
        cols == 2 ? sortedPlayers.sublist(4) : <Player>[];

    Widget buildRankRow(Player p, int rank) {
      final isWinner = p.id == winnerId;
      final alt = game.getCurrentAltitude(p.id);
      // Generic avatar (initials)
      final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';

      return Container(
        key: LunarLanderResultsKeys.playerRanking(rank - 1),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: rank % 2 == 1
              ? _earthBlue.withOpacity(0.6)
              : _spaceBlack.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: isWinner
              ? Border.all(color: _rocketFlame, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isWinner ? _rocketFlame : _starWhite.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            // Generic avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: _rocketFlame.withOpacity(0.7),
              child: Text(
                initial,
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _starWhite,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                p.name,
                style: GoogleFonts.exo2(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _starWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Alt: $alt',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                color:
                    isWinner ? _missionGreen : _starWhite.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (cols == 1) {
      return Column(
        children: sortedPlayers
            .asMap()
            .entries
            .map((e) => buildRankRow(e.value, e.key + 1))
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: col1
                .asMap()
                .entries
                .map((e) => buildRankRow(e.value, e.key + 1))
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: col2
                .asMap()
                .entries
                .map((e) => buildRankRow(e.value, col1.length + e.key + 1))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(LunarLanderGame game, List<Player> allPlayers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(
          key: LunarLanderResultsKeys.playAgainButton,
          label: 'RELAUNCH',
          color: _missionGreen,
          onTap: _playAgain,
        ),
        const SizedBox(width: 12),
        _buildButton(
          key: LunarLanderResultsKeys.changeSettingsButton,
          label: 'CHANGE MISSION',
          color: _earthBlue,
          onTap: _changeSettings,
        ),
        const SizedBox(width: 12),
        _buildButton(
          key: LunarLanderResultsKeys.backToMenuButton,
          label: 'MISSION CONTROL',
          color: _thrusterRed,
          onTap: _goHome,
        ),
      ],
    );
  }

  Widget _buildButton({
    required Key key,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      key: key,
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: _starWhite,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _starWhite,
        ),
      ),
    );
  }

  void _playAgain() {
    final provider = context.read<LunarLanderProvider>();
    final game = provider.currentGame!;

    provider.startGame(
      playerIds: game.playerIds,
      startingAltitude: game.startingAltitude,
      hardLandingEnabled: game.hardLandingEnabled,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LunarLanderGameScreen()),
    );
  }

  void _changeSettings() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LunarLanderMenuScreen(),
      ),
      (route) => route.isFirst,
    );
  }

  void _goHome() {
    final provider = context.read<LunarLanderProvider>();
    provider.clearGame();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
