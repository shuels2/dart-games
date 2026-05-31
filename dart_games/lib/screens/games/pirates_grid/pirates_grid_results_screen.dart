import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/pirates_grid_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../services/victory_music_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import 'pirates_grid_menu_screen.dart';
import 'pirates_grid_game_screen.dart';

class PiratesGridResultsScreen extends StatefulWidget {
  const PiratesGridResultsScreen({super.key});

  @override
  State<PiratesGridResultsScreen> createState() =>
      _PiratesGridResultsScreenState();
}

class _PiratesGridResultsScreenState extends State<PiratesGridResultsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _statsUpdated = false;

  // Palette
  static const Color _oceanNavy = Color(0xFF1B2838);
  static const Color _bloodRed = Color(0xFF8B0000);
  static const Color _treasureGold = Color(0xFFDAA520);
  static const Color _compassBronze = Color(0xFFCD7F32);
  static const Color _seaFoamTeal = Color(0xFF2E8B8B);
  static const Color _parchmentTan = Color(0xFFF5E6C8);
  static const Color _inkBlack = Color(0xFF1A1A1A);


  // P1 / P2 flag colors
  static const Color _p1FlagColor = Color(0xFF8B0000);
  static const Color _p2FlagColor = Color(0xFF2E8B8B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePlayerStats();
      _playVictoryMusic();
      _deleteResumedSavedGame(); // INDEPENDENT — not awaited inline
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updatePlayerStats() async {
    try {
      if (_statsUpdated) return;
      _statsUpdated = true;

      final provider = context.read<PiratesGridProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final game = provider.currentGame;
      if (game == null) return;

      final winnerId = game.matchWinnerId;
      final isMatchDraw = game.isMatchDraw;
      final duration =
          (game.gameEndTime ?? DateTime.now()).difference(game.startedAt);

      await playerProvider.batchUpdatePlayerStats([
        for (final id in game.playerIds)
          PlayerStatsUpdate(
            playerId: id,
            won: !isMatchDraw && id == winnerId,
            gameName: "Pirate's Grid",
            gameDuration: duration,
          ),
      ]);
    } catch (e) {
      debugPrint('Error updating player stats: $e');
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

  void _deleteResumedSavedGame() {
    try {
      final provider = context.read<PiratesGridProvider>();
      final savedGameId = provider.resumedSavedGameId;
      if (savedGameId != null) {
        SaveGameService().deleteSavedGame('pirates_grid', savedGameId);
        provider.clearResumedSavedGameId();
      }
    } catch (e) {
      debugPrint('Error deleting resumed saved game: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final provider = context.watch<PiratesGridProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    final game = provider.currentGame;
    if (game == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    final players = game.playerIds
        .map((id) => playerProvider.allPlayers.where((p) => p.id == id).firstOrNull)
        .whereType<Player>()
        .toList();

    final winnerId = game.matchWinnerId;
    final isMatchDraw = game.isMatchDraw;
    final isSingleRound = game.bestOf == 1;

    // Determine headline
    String headline;
    if (isMatchDraw) {
      headline = 'STALEMATE!';
    } else if (isSingleRound) {
      headline = 'TREASURE FOUND!';
    } else {
      headline = 'CAPTAIN OF THE SEAS!';
    }

    final headlineColor = isMatchDraw ? _compassBronze : _treasureGold;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _oceanNavy,
          appBar: AppBar(
            automaticallyImplyLeading: false, // NO back arrow per spec
            backgroundColor: Colors.transparent,
            // Ocean Navy → Sea Foam Teal → Blood Red 3-stop gradient.
            // Navy holds solid for the first quarter, eases into teal through
            // the middle, then warms into blood red on the far right. Shared
            // with the menu and game AppBars.
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_oceanNavy, _seaFoamTeal, _bloodRed],
                  stops: [0.25, 0.525, 1.0], // navy 0–25%, teal 25–52.5%, red 52.5–100% (red +10% of bar width)
                ),
              ),
            ),
            title: Text(
              "PIRATE'S GRID RESULTS",
              style: GoogleFonts.pirataOne(
                fontSize: 35,
                color: _treasureGold,
                letterSpacing: 1.5,
              ),
            ),
            actions: [
              DartboardConnectionInfo(
                config: DartboardConnectionInfoConfig.piratesGrid(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/games/pirates_grid/images/PiratesGrid-Background.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Ocean Navy 0.65 overlay
              Positioned.fill(
                child: Container(color: const Color(0xA61B2838)),
              ),
              // Main content
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 2, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Headline
                      Text(
                        headline,
                        key: PiratesGridResultsKeys.headlineText,
                        style: GoogleFonts.pirataOne(
                          fontSize: 56,
                          color: headlineColor,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: headlineColor.withOpacity(0.5),
                              blurRadius: 16,
                            ),
                            const Shadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Winner content
                      isMatchDraw
                          ? _buildDrawContent(game, players)
                          : winnerId != null
                              ? _buildWinnerContent(game, players, winnerId)
                              : const SizedBox.shrink(),
                      const SizedBox(height: 16),
                      // Rankings card
                      _buildRankingsCard(game, players, winnerId, isMatchDraw),
                      const SizedBox(height: 16),
                      // Action buttons
                      _buildActionButtons(game),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Dartboard paused modal — covers entire screen incl. AppBar when disconnected
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status != DartboardConnectionStatus.connected &&
            dartboardProvider.status != DartboardConnectionStatus.emulator)
          DartboardPausedModal(
            config: DartboardPausedModalConfig.piratesGrid(),
          ),
      ],
    );
  }

  Widget _buildWinnerContent(
    dynamic game,
    List<Player> players,
    String winnerId,
  ) {
    // Find winner player
    final winner = players.where((p) => p.id == winnerId).firstOrNull;
    if (winner == null) return const SizedBox.shrink();

    // Determine character (fixed by player index)
    final winnerIndex = game.playerIds.indexOf(winnerId);
    final characterPath = winnerIndex == 0
        ? 'assets/games/pirates_grid/characters/CaptainCrossbones.png'
        : 'assets/games/pirates_grid/characters/CaptainRedbeard.png';
    final winnerFlagColor = winnerIndex == 0 ? _p1FlagColor : _p2FlagColor;

    final flagsPlanted = game.getFlagsPlanted(winnerId);
    final roundsWon = game.roundsWon[winnerId] ?? 0;
    final totalRounds = game.currentRound;

    // Responsive character + name sizing — scale with available width so the
    // winner section adapts to portrait phones, landscape tablets, and large
    // browsers. LayoutBuilder gives us the parent's actual content width;
    // characterSize takes ~32% of it (capped at 460px so it doesn't dominate
    // huge desktops), and nameFontSize scales linearly with characterSize.
    return LayoutBuilder(builder: (context, constraints) {
      final availW = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width;
      final availH = MediaQuery.of(context).size.height;
      final widthBased = availW * 0.32;
      final heightBased = (availH - 350) * 0.66;
      final characterSize = math.min(widthBased, heightBased).clamp(120.0, 500.0);
      final nameFontSize = (characterSize * 0.115).clamp(28.0, 56.0);

      return Column(
      children: [
        // Winner character
        SizedBox(
          key: PiratesGridResultsKeys.winnerAvatar,
          width: characterSize,
          height: characterSize,
          child: Image.asset(
            characterPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.person,
              color: winnerFlagColor,
              size: characterSize * 0.72,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Winner name
        Text(
          winner.name,
          key: PiratesGridResultsKeys.winnerName,
          style: GoogleFonts.pirataOne(
            fontSize: nameFontSize,
            color: _parchmentTan,
            shadows: const [
              Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
              Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
              Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
              Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Stats
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag,
              color: winnerFlagColor,
              size: 22,
              shadows: const [
                Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
                Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
                Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
                Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
              ],
            ),
            if (game.bestOf > 1) ...[
              Text(
                ' Flags: ${(game.flagsPlantedPerRound[winnerId] ?? []).join(' / ')}',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  color: _parchmentTan,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '⚓ Rounds won: $roundsWon/$totalRounds',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  color: _parchmentTan,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
                  ],
                ),
              ),
            ] else ...[
              Text(
                ' Flags planted: $flagsPlanted',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  color: _parchmentTan,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
    });
  }

  Widget _buildDrawContent(dynamic game, List<Player> players) {
    if (players.length < 2) return const SizedBox.shrink();

    final availW = MediaQuery.of(context).size.width;
    final availH = MediaQuery.of(context).size.height;
    final heightBased = (availH - 350) * 0.66;
    final drawCharSize = heightBased.clamp(120.0, 500.0);
    final nameFontSize = (drawCharSize * 0.115).clamp(28.0, 56.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(width: 60),
          Column(
            children: [
              SizedBox(
                width: drawCharSize,
                height: drawCharSize,
                child: Image.asset(
                  i == 0
                      ? 'assets/games/pirates_grid/characters/CaptainCrossbones.png'
                      : 'assets/games/pirates_grid/characters/CaptainRedbeard.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    color: i == 0 ? _p1FlagColor : _p2FlagColor,
                    size: drawCharSize * 0.72,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                players[i].name,
                style: GoogleFonts.pirataOne(
                  fontSize: nameFontSize,
                  color: _parchmentTan,
                  shadows: const [
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
                    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRankingsCard(
    dynamic game,
    List<Player> players,
    String? winnerId,
    bool isMatchDraw,
  ) {
    return Container(
      key: PiratesGridResultsKeys.rankingsList,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _oceanNavy.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _compassBronze, width: 2),
      ),
      child: Column(
        children: players.asMap().entries.map((entry) {
          final i = entry.key;
          final player = entry.value;
          final isWinner = !isMatchDraw && player.id == winnerId;
          final flagsPlanted = game.getFlagsPlanted(player.id) as int;
          final roundsWon = (game.roundsWon[player.id] ?? 0) as int;
          final playerFlagColor = i == 0 ? _p1FlagColor : _p2FlagColor;
          final initial =
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isWinner
                  ? _treasureGold.withOpacity(0.15)
                  : _oceanNavy.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: isWinner
                  ? Border.all(color: _treasureGold, width: 2)
                  : Border.all(
                      color: _compassBronze.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                // Generic colored-circle initials avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: playerFlagColor.withOpacity(0.7),
                  child: Text(
                    initial,
                    style: GoogleFonts.pirataOne(
                      fontSize: 16,
                      color: _parchmentTan,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    player.name,
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _parchmentTan,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Stats
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag,
                      color: playerFlagColor,
                      size: 16,
                      shadows: const [
                        Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1, -1), blurRadius: 0),
                        Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1, -1), blurRadius: 0),
                        Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1,  1), blurRadius: 0),
                        Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1,  1), blurRadius: 0),
                      ],
                    ),
                    Text(
                      game.bestOf > 1
                          ? ' ${(game.flagsPlantedPerRound[player.id] ?? []).join('/')}'
                          : ' $flagsPlanted',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: _parchmentTan,
                      ),
                    ),
                  ],
                ),
                if (game.bestOf > 1) ...[
                  const SizedBox(width: 16),
                  Text(
                    '⚓ $roundsWon',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: _parchmentTan.withOpacity(0.8),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // WIN / DRAW / LOSS badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMatchDraw
                        ? _compassBronze
                        : isWinner
                            ? _treasureGold
                            : _bloodRed.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: (!isMatchDraw && !isWinner)
                        ? Border.all(color: _bloodRed.withOpacity(0.6), width: 1)
                        : null,
                  ),
                  child: Text(
                    isMatchDraw ? 'DRAW' : (isWinner ? 'WIN' : 'LOSS'),
                    style: GoogleFonts.pirataOne(
                      fontSize: 13,
                      color: isMatchDraw
                          ? _parchmentTan
                          : isWinner
                              ? _inkBlack
                              : _parchmentTan,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(dynamic game) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        // SET SAIL AGAIN — Play Again
        ElevatedButton(
          key: PiratesGridResultsKeys.playAgainButton,
          onPressed: _playAgain,
          style: ElevatedButton.styleFrom(
            backgroundColor: _compassBronze,
            foregroundColor: _parchmentTan,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'SET SAIL AGAIN',
            style: GoogleFonts.pirataOne(
              fontSize: 25,
              color: _parchmentTan,
              letterSpacing: 1.0,
            ),
          ),
        ),
        // NEW VOYAGE — Change Settings
        ElevatedButton(
          key: PiratesGridResultsKeys.changeSettingsButton,
          onPressed: _changeSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: _treasureGold,
            foregroundColor: _inkBlack,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'NEW VOYAGE',
            style: GoogleFonts.pirataOne(
              fontSize: 25,
              color: _inkBlack,
              letterSpacing: 1.0,
            ),
          ),
        ),
        // PORT HOME — Back to Home
        ElevatedButton(
          key: PiratesGridResultsKeys.backToMenuButton,
          onPressed: _goHome,
          style: ElevatedButton.styleFrom(
            backgroundColor: _bloodRed,
            foregroundColor: _parchmentTan,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'HOME PORT',
            style: GoogleFonts.pirataOne(
              fontSize: 25,
              color: _parchmentTan,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  void _playAgain() {
    final provider = context.read<PiratesGridProvider>();
    final game = provider.currentGame!;

    provider.startGame(
      game.playerIds,
      game.targetDifficulty,
      game.bestOf,
      game.stealMode,
      game.speedPlay,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PiratesGridGameScreen()),
    );
  }

  void _changeSettings() {
    final game = context.read<PiratesGridProvider>().currentGame;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PiratesGridMenuScreen(
          initialDifficulty: game?.targetDifficulty,
          initialBestOf: game?.bestOf,
          initialStealMode: game?.stealMode,
          initialSpeedPlay: game?.speedPlay,
          initialSelectedPlayerIds: game?.playerIds,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _goHome() {
    final provider = context.read<PiratesGridProvider>();
    provider.clearGame();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
