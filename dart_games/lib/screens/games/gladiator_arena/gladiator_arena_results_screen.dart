import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/gladiator_arena_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../services/victory_music_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import 'gladiator_arena_menu_screen.dart';
import 'gladiator_arena_game_screen.dart';

// ─── Color constants ──────────────────────────────────────────────────────────

const _kMarbleWhite = Color(0xFFF5F0E8);
const _kGladiatorGold = Color(0xFFDAA520);
const _kArenaSand = Color(0xFFD2B48C);
const _kImperialPurple = Color(0xFF7B2D8E);
const _kBloodRed = Color(0xFFC0392B);
const _kBronze = Color(0xFFCD7F32);
const _kColosseumGray = Color(0xFF8B8682);

class GladiatorArenaResultsScreen extends StatefulWidget {
  const GladiatorArenaResultsScreen({super.key});

  @override
  State<GladiatorArenaResultsScreen> createState() =>
      _GladiatorArenaResultsScreenState();
}

class _GladiatorArenaResultsScreenState
    extends State<GladiatorArenaResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
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
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deleteResumedSavedGame();
      _updatePlayerStats();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _playVictoryMusic();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updatePlayerStats() async {
    try {
      if (_statsUpdated) return;
      _statsUpdated = true;

      final provider = context.read<GladiatorArenaProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final game = provider.currentGame;
      if (game == null || game.endedAt == null) return;

      final duration = game.endedAt!.difference(game.startedAt);
      final winnerId = game.winnerId;

      await playerProvider.batchUpdatePlayerStats([
        for (final playerId in game.playerIds)
          PlayerStatsUpdate(
            playerId: playerId,
            won: playerId == winnerId,
            gameName: 'Gladiator Arena',
            gameDuration: duration,
            dartThrows: game.totalDartsThrown[playerId] ?? 0,
            turns: game.totalTurns[playerId] ?? 0,
            playerCount: game.playerIds.length,
          ),
      ]);
    } catch (e) {
      debugPrint('Error updating player stats: $e');
    }
  }

  Future<void> _deleteResumedSavedGame() async {
    try {
      final provider = context.read<GladiatorArenaProvider>();
      final savedGameId = provider.resumedSavedGameId;
      if (savedGameId != null) {
        await SaveGameService().deleteSavedGame('gladiator_arena', savedGameId);
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
          await _audioPlayer.play(UrlSource(customMusicSource)).timeout(
              const Duration(seconds: 5),
              onTimeout: () => debugPrint('Audio playback timed out'));
        } else {
          await _audioPlayer.play(DeviceFileSource(customMusicSource)).timeout(
              const Duration(seconds: 5),
              onTimeout: () => debugPrint('Audio playback timed out'));
        }
      } else {
        await _audioPlayer
            .play(UrlSource(
                'https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'))
            .timeout(const Duration(seconds: 5),
                onTimeout: () => debugPrint('Audio playback timed out'));
      }
    } catch (e) {
      debugPrint('Error playing victory music: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final provider = context.watch<GladiatorArenaProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    final game = provider.currentGame;
    if (game == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    final allPlayers = playerProvider.allPlayers;
    final winnerId = game.winnerId;
    if (winnerId == null) {
      return const Scaffold(body: Center(child: Text('No winner found')));
    }

    final winner = allPlayers.where((p) => p.id == winnerId).firstOrNull;
    if (winner == null) {
      return const Scaffold(body: Center(child: Text('Winner not found')));
    }

    final winnerScore = game.scores[winnerId] ?? game.targetScore;
    final winnerCharPath = game.playerCharacterPaths[winnerId];

    // Sort players: by score descending (winner first, then by score)
    final sortedPlayers = List<Player>.from(
        allPlayers.where((p) => game.playerIds.contains(p.id)));
    sortedPlayers.sort((a, b) {
      final scoreA = game.scores[a.id] ?? 0;
      final scoreB = game.scores[b.id] ?? 0;
      return scoreB.compareTo(scoreA);
    });

    // Knockoff stats
    final anyKnockoffs =
        game.knockoffsDealt.values.any((c) => c > 0);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF2A1500),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'GLADIATOR ARENA RESULTS',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kMarbleWhite,
                letterSpacing: 1.5,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4,
                      offset: Offset(1, 1)),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF4A3520),
            foregroundColor: _kMarbleWhite,
            actions: [
              DartboardConnectionInfo(
                config: DartboardConnectionInfoConfig.gladiatorArena(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Image.asset(
                  'assets/games/gladiator_arena/images/GladiatorArena-Background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF2A1500)),
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Champion title
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          'CHAMPION OF THE ARENA!',
                          style: GoogleFonts.cinzel(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _kGladiatorGold,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: _kGladiatorGold.withOpacity(0.6),
                                blurRadius: 20,
                              ),
                              const Shadow(
                                  color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Winner row: character image + player photo
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Winner character image
                            Container(
                              key: GladiatorArenaResultsKeys.winnerCharacterImage,
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: _kGladiatorGold.withOpacity(0.6),
                                    blurRadius: 24,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: winnerCharPath != null
                                  ? Image.asset(
                                      winnerCharPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.emoji_events,
                                          color: _kGladiatorGold,
                                          size: 140),
                                    )
                                  : const Icon(Icons.emoji_events,
                                      color: _kGladiatorGold, size: 140),
                            ),
                            const SizedBox(width: 24),
                            // Player photo / initials avatar
                            Container(
                              key: GladiatorArenaResultsKeys.winnerPlayerPhoto,
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _kGladiatorGold, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kGladiatorGold.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: winner.photoPath != null
                                    ? Image(
                                        image: winner.photoPath!
                                                .startsWith('data:')
                                            ? MemoryImage(
                                                Uri.parse(winner.photoPath!)
                                                    .data!
                                                    .contentAsBytes())
                                            : NetworkImage(winner.photoPath!)
                                                as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: const Color(0xFF4A3520),
                                        child: Center(
                                          child: Text(
                                            winner.name.isNotEmpty
                                                ? winner.name[0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.cinzel(
                                              fontSize: 84,
                                              fontWeight: FontWeight.bold,
                                              color: _kGladiatorGold,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        winner.name,
                        key: GladiatorArenaResultsKeys.winnerName,
                        style: GoogleFonts.cinzel(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _kGladiatorGold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Final Score: $winnerScore',
                        key: GladiatorArenaResultsKeys.winnerScore,
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          color: _kMarbleWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Rankings card
                      _buildRankings(game, sortedPlayers, winnerId),
                      const SizedBox(height: 16),
                      // Knockoff stats (conditional)
                      if (anyKnockoffs) _buildKnockoffStats(game, allPlayers),
                      if (anyKnockoffs) const SizedBox(height: 16),
                      // Action buttons
                      _buildActionButtons(game),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Dartboard paused modal
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status != DartboardConnectionStatus.connected &&
            dartboardProvider.status != DartboardConnectionStatus.emulator)
          DartboardPausedModal(
            config: DartboardPausedModalConfig.gladiatorArena(),
          ),
      ],
    );
  }

  Widget _buildRankings(dynamic game, List<Player> sortedPlayers,
      String winnerId) {
    final isMultiCol = sortedPlayers.length > 4;
    final col1 = isMultiCol
        ? sortedPlayers.sublist(0, min(4, sortedPlayers.length))
        : sortedPlayers;
    final col2 = isMultiCol && sortedPlayers.length > 4
        ? sortedPlayers.sublist(4)
        : <Player>[];

    Widget buildRankRow(Player p, int rank) {
      final score = game.scores[p.id] as int? ?? 0;
      final isWinner = p.id == winnerId;
      final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';

      Color rankColor;
      if (rank == 1) {
        rankColor = _kGladiatorGold;
      } else if (rank == 2) {
        rankColor = _kMarbleWhite;
      } else if (rank == 3) {
        rankColor = _kBronze;
      } else {
        rankColor = _kColosseumGray;
      }

      return Container(
        key: GladiatorArenaResultsKeys.rankRow(rank - 1),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4A3520).withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: isWinner
              ? Border.all(color: _kGladiatorGold, width: 2)
              : Border.all(color: _kBronze.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: rankColor.withOpacity(0.7),
              child: Text(
                initial,
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _kMarbleWhite,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                p.name,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kMarbleWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$score pts',
              style: GoogleFonts.cinzel(
                fontSize: 13,
                color: rankColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final cardWidth = isMultiCol ? 900.0 : 600.0;

    return Container(
      key: GladiatorArenaResultsKeys.rankingsList,
      constraints: BoxConstraints(maxWidth: cardWidth),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kArenaSand.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBronze, width: 2),
      ),
      child: isMultiCol
          ? Row(
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
            )
          : Column(
              children: sortedPlayers
                  .asMap()
                  .entries
                  .map((e) => buildRankRow(e.value, e.key + 1))
                  .toList(),
            ),
    );
  }

  Widget _buildKnockoffStats(dynamic game, List<dynamic> allPlayers) {
    // Find top knockoff dealer and total knockoffs received
    String topDealer = '';
    int topDealerCount = 0;
    int totalKnockoffs = 0;

    for (final id in game.playerIds as List<String>) {
      final dealt = game.knockoffsDealt[id] as int? ?? 0;
      totalKnockoffs += dealt;
      if (dealt > topDealerCount) {
        topDealerCount = dealt;
        final player = (allPlayers as List).where((p) => p.id == id).firstOrNull;
        topDealer = player?.name ?? 'Player';
      }
    }

    return Container(
      key: GladiatorArenaResultsKeys.knockoffStats,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3520).withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBloodRed.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text('Total Knockoffs',
                  style: GoogleFonts.lato(
                      fontSize: 12, color: _kMarbleWhite.withOpacity(0.7))),
              Text('$totalKnockoffs',
                  style: GoogleFonts.cinzel(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _kBloodRed)),
            ],
          ),
          Container(width: 1, height: 40, color: _kColosseumGray),
          Column(
            children: [
              Text('Top Knocker',
                  style: GoogleFonts.lato(
                      fontSize: 12, color: _kMarbleWhite.withOpacity(0.7))),
              Text(
                topDealer.isNotEmpty ? '$topDealer ($topDealerCount)' : '—',
                style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kBloodRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(
          key: GladiatorArenaResultsKeys.playAgainButton,
          label: 'FIGHT AGAIN',
          color: _kBronze,
          onTap: _fightAgain,
        ),
        const SizedBox(width: 12),
        _buildButton(
          key: GladiatorArenaResultsKeys.changeSettingsButton,
          label: 'CHANGE RULES',
          color: _kImperialPurple,
          onTap: _changeRules,
        ),
        const SizedBox(width: 12),
        _buildButton(
          key: GladiatorArenaResultsKeys.backToMenuButton,
          label: 'LEAVE ARENA',
          color: _kBloodRed,
          onTap: _leaveArena,
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
        foregroundColor: _kMarbleWhite,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.cinzel(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _kMarbleWhite,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _fightAgain() {
    final provider = context.read<GladiatorArenaProvider>();
    final game = provider.currentGame!;

    provider.startGame(
      playerIds: game.playerIds,
      targetScore: game.targetScore,
      doubleFinishEnabled: game.doubleFinishEnabled,
      shieldRoundEnabled: game.shieldRoundEnabled,
      speedPlayEnabled: game.speedPlayEnabled,
      playerCharacterPaths: game.playerCharacterPaths,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GladiatorArenaGameScreen()),
    );
  }

  void _changeRules() {
    final game = context.read<GladiatorArenaProvider>().currentGame;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => GladiatorArenaMenuScreen(
          initialTargetScore: game?.targetScore,
          initialDoubleFinishEnabled: game?.doubleFinishEnabled,
          initialShieldRoundEnabled: game?.shieldRoundEnabled,
          initialSpeedPlayEnabled: game?.speedPlayEnabled,
          initialSelectedPlayerIds: game?.playerIds,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _leaveArena() {
    context.read<GladiatorArenaProvider>().clearGame();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
