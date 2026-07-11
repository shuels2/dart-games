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

  // Responsive scale factor — every "large" size on this screen (champion
  // title, winner avatars, button text, rank-row image) is multiplied by
  // _scale so the layout fills a wide desktop/tablet screen but tightens
  // gracefully on smaller windows without overflowing.
  // 1.0 at 1440 px+, floor at 0.5 (≈720 px width).
  double get _scale =>
      (MediaQuery.of(context).size.width / 1440).clamp(0.5, 1.0);

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
                fontSize: 36,
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
                  padding: EdgeInsets.all(24 * _scale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Champion title — large hero text.
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          'CHAMPION OF THE ARENA!',
                          style: GoogleFonts.cinzel(
                            fontSize: 60 * _scale,
                            fontWeight: FontWeight.bold,
                            color: _kGladiatorGold,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: _kGladiatorGold.withOpacity(0.6),
                                blurRadius: 24,
                              ),
                              const Shadow(
                                  color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 32 * _scale),
                      // Winner row: character image + player photo
                      // Bumped from 200×200 → 340×340 so the hero pair
                      // dominates the screen.
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Winner character image (no glow halo —
                            // the silhouette stands on its own).
                            SizedBox(
                              key: GladiatorArenaResultsKeys
                                  .winnerCharacterImage,
                              width: 340 * _scale,
                              height: 340 * _scale,
                              child: winnerCharPath != null
                                  ? Image.asset(
                                      winnerCharPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                          Icons.emoji_events,
                                          color: _kGladiatorGold,
                                          size: 220 * _scale),
                                    )
                                  : Icon(Icons.emoji_events,
                                      color: _kGladiatorGold,
                                      size: 220 * _scale),
                            ),
                            SizedBox(width: 32 * _scale),
                            // Player photo / initials avatar — gold ring
                            // border only, no glow halo.
                            Container(
                              key: GladiatorArenaResultsKeys
                                  .winnerPlayerPhoto,
                              width: 340 * _scale,
                              height: 340 * _scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _kGladiatorGold, width: 4),
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
                                              fontSize: 140 * _scale,
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
                      SizedBox(height: 20 * _scale),
                      Text(
                        winner.name,
                        key: GladiatorArenaResultsKeys.winnerName,
                        style: GoogleFonts.cinzel(
                          fontSize: 44 * _scale,
                          fontWeight: FontWeight.bold,
                          color: _kGladiatorGold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 28 * _scale),
                      // Rankings card
                      _buildRankings(game, sortedPlayers, winnerId),
                      SizedBox(height: 20 * _scale),
                      // Knockoff stats (conditional)
                      if (anyKnockoffs) _buildKnockoffStats(game, allPlayers),
                      if (anyKnockoffs) SizedBox(height: 20 * _scale),
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
    final scale = _scale;
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
      final charPath = game.playerCharacterPaths[p.id] as String?;

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
        margin: EdgeInsets.only(bottom: 4 * scale),
        padding: EdgeInsets.symmetric(
            horizontal: 16 * scale, vertical: 10 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF4A3520).withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          border: isWinner
              ? Border.all(color: _kGladiatorGold, width: 2)
              : Border.all(color: _kBronze.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: GoogleFonts.cinzel(
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
            SizedBox(width: 10 * scale),
            // Character image — matches the podium silhouette so each
            // ranked player is immediately identifiable next to their
            // initials avatar.
            SizedBox(
              width: 56 * scale,
              height: 56 * scale,
              child: charPath != null
                  ? Image.asset(
                      charPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(width: 8 * scale),
            CircleAvatar(
              radius: 28 * scale,
              backgroundColor: rankColor.withOpacity(0.7),
              child: Text(
                initial,
                style: GoogleFonts.cinzel(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.bold,
                  color: _kMarbleWhite,
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                p.name,
                style: GoogleFonts.lato(
                  fontSize: 22 * scale,
                  // Top 3 bold (podium finishers), everyone else regular.
                  fontWeight:
                      rank <= 3 ? FontWeight.w700 : FontWeight.w400,
                  color: _kMarbleWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$score pts',
              style: GoogleFonts.cinzel(
                fontSize: 18 * scale,
                color: rankColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // No container around the rankings list — rows sit directly against
    // the screen background. Width is still capped so a wide-screen layout
    // doesn't stretch rows uncomfortably. Caps bumped 25% (1100→1375,
    // 720→900) to make the tiles fill more of the screen.
    final maxWidth = (isMultiCol ? 1375.0 : 900.0) * scale;

    return ConstrainedBox(
      key: GladiatorArenaResultsKeys.rankingsList,
      constraints: BoxConstraints(maxWidth: maxWidth),
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
                SizedBox(width: 16 * scale),
                Expanded(
                  child: Column(
                    children: col2
                        .asMap()
                        .entries
                        .map((e) =>
                            buildRankRow(e.value, col1.length + e.key + 1))
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

    final scale = _scale;
    return Container(
      key: GladiatorArenaResultsKeys.knockoffStats,
      constraints: BoxConstraints(maxWidth: 720 * scale),
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3520).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBloodRed.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text('Total Knockoffs',
                  style: GoogleFonts.lato(
                      fontSize: 16 * scale,
                      color: _kMarbleWhite.withOpacity(0.7))),
              Text('$totalKnockoffs',
                  style: GoogleFonts.cinzel(
                      fontSize: 34 * scale,
                      fontWeight: FontWeight.bold,
                      color: _kBloodRed)),
            ],
          ),
          Container(width: 1, height: 56 * scale, color: _kColosseumGray),
          Column(
            children: [
              Text('Top Knocker',
                  style: GoogleFonts.lato(
                      fontSize: 16 * scale,
                      color: _kMarbleWhite.withOpacity(0.7))),
              Text(
                topDealer.isNotEmpty ? '$topDealer ($topDealerCount)' : '—',
                style: GoogleFonts.cinzel(
                    fontSize: 26 * scale,
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
    final scale = _scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(
          key: GladiatorArenaResultsKeys.playAgainButton,
          label: 'FIGHT AGAIN',
          color: _kBronze,
          onTap: _fightAgain,
        ),
        SizedBox(width: 20 * scale),
        _buildButton(
          key: GladiatorArenaResultsKeys.changeSettingsButton,
          label: 'CHANGE RULES',
          color: _kImperialPurple,
          onTap: _changeRules,
        ),
        SizedBox(width: 20 * scale),
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
    final scale = _scale;
    // Sized at 75% of the doubled baseline:
    //   padding  vertical 21 / horizontal 30   (was 28 / 40)
    //   font     24 pt                          (was 32 pt)
    return ElevatedButton(
      key: key,
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: _kMarbleWhite,
        padding: EdgeInsets.symmetric(
            vertical: 21 * scale, horizontal: 30 * scale),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.cinzel(
          fontSize: 24 * scale,
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
