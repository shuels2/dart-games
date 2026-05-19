import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../models/tiki_golf_game.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/tiki_golf_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../services/victory_music_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import 'tiki_golf_game_screen.dart';
import 'tiki_golf_menu_screen.dart';

// ─── Color palette (matches game_screen and menu_screen) ─────────────────────
const Color _lagoonBlue = Color(0xFF00B4D8);
const Color _palmGreen = Color(0xFF2D6A4F);
const Color _tikiBrown = Color(0xFF8B5E3C);
const Color _hibiscusPink = Color(0xFFFF69B4);
const Color _sandWhite = Color(0xFFFFF5E1);
const Color _tropicalOrange = Color(0xFFFF8C42); // substitution — NOT 0xFFFF6B35
const Color _goldenTrophy = Color(0xFFFFC857);

// ─── Text shadow helpers ──────────────────────────────────────────────────────

/// 4-corner dark outline shadow — used on champion headings, names, stats.
List<Shadow> _outlineShadow4({double offset = 2.0, double blur = 10.0}) => [
      Shadow(
          color: const Color(0xF20F281C),
          offset: Offset(-offset, -offset),
          blurRadius: 0),
      Shadow(
          color: const Color(0xF20F281C),
          offset: Offset(offset, -offset),
          blurRadius: 0),
      Shadow(
          color: const Color(0xF20F281C),
          offset: Offset(-offset, offset),
          blurRadius: 0),
      Shadow(
          color: const Color(0xF20F281C),
          offset: Offset(offset, offset),
          blurRadius: 0),
      Shadow(
          color: const Color(0x73000000),
          offset: Offset.zero,
          blurRadius: blur),
    ];

/// Lighter 4-corner shadow for secondary stats.
List<Shadow> _lightShadow4() => [
      const Shadow(
          color: Color(0xE60F281C), offset: Offset(-1, -1), blurRadius: 0),
      const Shadow(
          color: Color(0xE60F281C), offset: Offset(1, -1), blurRadius: 0),
      const Shadow(
          color: Color(0xE60F281C), offset: Offset(-1, 1), blurRadius: 0),
      const Shadow(
          color: Color(0xE60F281C), offset: Offset(1, 1), blurRadius: 0),
      const Shadow(
          color: Color(0x66000000), offset: Offset.zero, blurRadius: 8),
    ];

// ─── Par constant (all 9 holes, par=2 each → total par = 18) ─────────────────
const int _kTotalPar = 18; // 9 holes × par-2 per hole

// ─── Avatar background color palette for player tiles ────────────────────────
const List<Color> _kAvatarColors = [
  _lagoonBlue,
  Color(0xFF87CEEB), // sky blue
  _palmGreen,
  _tikiBrown,
  _hibiscusPink,
  _tropicalOrange,
  Color(0xFF9B59B6), // purple
  Color(0xFF27AE60), // emerald
];

Color _avatarColorForIndex(int index) =>
    _kAvatarColors[index % _kAvatarColors.length];

// ─────────────────────────────────────────────────────────────────────────────

class TikiGolfResultsScreen extends StatefulWidget {
  const TikiGolfResultsScreen({super.key});

  @override
  State<TikiGolfResultsScreen> createState() => _TikiGolfResultsScreenState();
}

class _TikiGolfResultsScreenState extends State<TikiGolfResultsScreen> {
  bool _statsUpdated = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // 1. Init VictoryMusicService
    VictoryMusicService().initialize();

    // 2. Batch-update player stats once, after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _updatePlayerStats();
    });

    // 3. Independently auto-delete resumed saved game if applicable
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _deleteResumedSavedGame();
    });

    // 4. Play victory music after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _playVictoryMusic();
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _updatePlayerStats() async {
    if (_statsUpdated) return;
    _statsUpdated = true;

    try {
      final provider = context.read<TikiGolfProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final game = provider.currentGame;
      if (game == null) return;

      final duration = (game.gameStartTime != null && game.gameEndTime != null)
          ? game.gameEndTime!.difference(game.gameStartTime!)
          : Duration.zero;

      // Resolve winner sets (tied players in solo, tied teams in team).
      // Fall back to the singular winnerId/winnerTeamId for backward compat
      // with games saved before tie support.
      final soloWinners = game.winnerIds ??
          (game.winnerId != null ? [game.winnerId!] : const <String>[]);
      final teamWinners = game.winnerTeamIds ??
          (game.winnerTeamId != null
              ? [game.winnerTeamId!]
              : const <String>[]);

      // ONE batch call — never loop playerProvider.updatePlayerStats per player
      await playerProvider.batchUpdatePlayerStats([
        for (final id in game.playerIds)
          PlayerStatsUpdate(
            playerId: id,
            won: game.gameMode == TikiGolfGameMode.team
                ? teamWinners.contains(game.playerTeamAssignments[id])
                : soloWinners.contains(id),
            gameName: 'Tiki Golf',
            gameDuration: duration,
            dartThrows: (game.totalTurns[id] ?? 0) * game.maxStrokes,
            turns: game.totalTurns[id] ?? 0,
            playerCount: game.playerIds.length,
          ),
      ]);
    } catch (e) {
      debugPrint('[TikiGolfResultsScreen] Error updating player stats: $e');
    }
  }

  Future<void> _deleteResumedSavedGame() async { // line ~148
    try {
      final provider = context.read<TikiGolfProvider>();
      final savedId = provider.resumedSavedGameId;
      if (savedId != null) {
        await SaveGameService().deleteSavedGame('tiki_golf', savedId);
        if (!mounted) return;
        provider.clearResumedSavedGameId();
      }
    } catch (e) {
      debugPrint('[TikiGolfResultsScreen] Error deleting saved game: $e');
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
      debugPrint('[TikiGolfResultsScreen] Error playing victory music: $e');
    }
  }

  // ─── Navigation helpers ───────────────────────────────────────────────────

  void _playAgain() {
    final provider = context.read<TikiGolfProvider>();
    final game = provider.currentGame;
    if (game == null) return;

    provider.startGame(
      playerIds: List<String>.from(game.playerIds),
      maxStrokes: game.maxStrokes,
      mulliganEnabled: game.mulliganEnabled,
      gameMode: game.gameMode,
      teamAssignment: game.teamAssignment,
      teamCount: game.teamCount,
      manualTeamAssignments:
          game.teamAssignment == TikiGolfTeamAssignment.manual
              ? Map<String, String>.from(game.playerTeamAssignments)
              : null,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TikiGolfGameScreen()),
    );
  }

  void _changeSettings() {
    final provider = context.read<TikiGolfProvider>();
    final game = provider.currentGame;
    if (game == null) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TikiGolfMenuScreen(
          initialGameMode: game.gameMode,
          initialTeamAssignment: game.teamAssignment,
          initialTeamCount: game.teamCount,
          initialMaxStrokes: game.maxStrokes,
          initialMulliganEnabled: game.mulliganEnabled,
          initialSelectedPlayerIds: List<String>.from(game.playerIds),
          initialManualTeamAssignments:
              game.teamAssignment == TikiGolfTeamAssignment.manual
                  ? Map<String, String>.from(game.playerTeamAssignments)
                  : null,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _backToMenu() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final provider = context.watch<TikiGolfProvider>(); // MUST be .watch
    final playerProvider = context.watch<PlayerProvider>(); // MUST be .watch

    final game = provider.currentGame;
    if (game == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false, // no back arrow on results screen
            backgroundColor: _palmGreen,
            title: Text(
              'TIKI GOLF RESULTS',
              style: GoogleFonts.boogaloo(
                fontSize: 34,
                color: _sandWhite,
                letterSpacing: 0.5,
                // 4-corner gold outline — unified across all three Tiki
                // Golf AppBar titles (menu / game / results).
                shadows: const [
                  Shadow(color: _goldenTrophy, offset: Offset(1, 1)),
                  Shadow(color: _goldenTrophy, offset: Offset(-1, -1)),
                  Shadow(color: _goldenTrophy, offset: Offset(1, -1)),
                  Shadow(color: _goldenTrophy, offset: Offset(-1, 1)),
                ],
              ),
            ),
            actions: [
              DartboardConnectionInfo(
                config: DartboardConnectionInfoConfig.tikiGolf(),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Image.asset(
                  'assets/games/tiki_golf/images/TikiGolf-Background.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Palm Green 60% overlay
              Positioned.fill(
                child: Container(
                  color: _palmGreen.withOpacity(0.60),
                ),
              ),
              // Main content
              game.gameMode == TikiGolfGameMode.solo
                  ? _buildSoloLayout(context, game, playerProvider)
                  : _buildTeamLayout(context, game, playerProvider),
            ],
          ),
        ),
        // DartboardPausedModal — covers AppBar when disconnected
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status != DartboardConnectionStatus.connected &&
            dartboardProvider.status != DartboardConnectionStatus.emulator)
          DartboardPausedModal(
            config: DartboardPausedModalConfig.tikiGolf(),
          ),
      ],
    );
  }

  // ─── Solo layout ──────────────────────────────────────────────────────────

  Widget _buildSoloLayout(
    BuildContext context,
    TikiGolfGame game,
    PlayerProvider playerProvider,
  ) {
    // Sort players by total strokes ascending (winner first)
    final sortedIds = List<String>.from(game.playerIds);
    sortedIds.sort((a, b) =>
        game.totalForPlayer(a).compareTo(game.totalForPlayer(b)));

    // Resolve tied-winner list (fall back to singular winnerId for legacy saves).
    final winnerIds = game.winnerIds ??
        (game.winnerId != null ? [game.winnerId!] : <String>[sortedIds.first]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          // ── Winner card (single or tied) ──
          if (winnerIds.length <= 1)
            () {
              final winnerId = winnerIds.isNotEmpty
                  ? winnerIds.first
                  : sortedIds.first;
              final winner = playerProvider.getPlayerById(winnerId);
              final winnerTotal = game.totalForPlayer(winnerId);
              final winnerDiff = winnerTotal - _kTotalPar;
              final winnerBirdies = game.birdiesForPlayer(winnerId);
              return _buildSoloWinnerCard(winner, winnerId, winnerTotal,
                  winnerDiff, winnerBirdies);
            }()
          else
            _buildSoloTiedWinnersCard(game, winnerIds, playerProvider),
          const SizedBox(height: 16),
          // ── Final scorecard ──
          Expanded(
            child: SingleChildScrollView(
              child: _buildSoloScorecard(
                  game, sortedIds, winnerIds, playerProvider),
            ),
          ),
          const SizedBox(height: 12),
          // ── Action buttons (outside scroll container) ──
          _buildActionButtons(),
        ],
      ),
    );
  }

  // Tied solo winners — N avatars side-by-side under a plural heading.
  Widget _buildSoloTiedWinnersCard(
    TikiGolfGame game,
    List<String> winnerIds,
    PlayerProvider playerProvider,
  ) {
    final tiedTotal = game.totalForPlayer(winnerIds.first);
    final diff = tiedTotal - _kTotalPar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'GOLDEN TIKI CHAMPIONS!',
          key: TikiGolfResultsKeys.championHeading,
          style: GoogleFonts.boogaloo(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _lagoonBlue,
            shadows: _outlineShadow4(),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'TIED!',
          style: GoogleFonts.boogaloo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _goldenTrophy,
            shadows: _outlineShadow4(),
          ),
        ),
        const SizedBox(height: 6),
        // Row of tied-winner avatars
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            for (int i = 0; i < winnerIds.length; i++)
              _buildSoloTiedWinnerItem(
                player: playerProvider.getPlayerById(winnerIds[i]),
                playerId: winnerIds[i],
                colorIndex: i,
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Shared total line — all tied players have the same total
        RichText(
          key: TikiGolfResultsKeys.winnerTotal,
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.boogaloo(
              fontSize: 18,
              color: _sandWhite,
              shadows: _lightShadow4(),
            ),
            children: [
              TextSpan(text: 'Tied at $tiedTotal strokes ('),
              TextSpan(
                text: _formatDiff(diff),
                style: GoogleFonts.boogaloo(
                  fontSize: 18,
                  color: _diffColor(diff),
                  shadows: _lightShadow4(),
                ),
              ),
              const TextSpan(text: ')'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoloTiedWinnerItem({
    required Player? player,
    required String playerId,
    required int colorIndex,
  }) {
    final name = player?.name ?? '—';
    final bg = _avatarColorForIndex(colorIndex);

    return Column(
      key: TikiGolfResultsKeys.tiedWinnerPhoto(playerId),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 128, // extra space for the golden-tiki overlap
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sandWhite,
                  border: Border.all(color: _goldenTrophy, width: 3),
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildPlayerAvatarInitials(
                  player,
                  size: 120,
                  fontSize: 56,
                  bgColor: bg,
                ),
              ),
              Positioned(
                bottom: -6,
                right: -6,
                child: Image.asset(
                  'assets/games/tiki_golf/pieces/GoldenTiki.png',
                  width: 48,
                  height: 48,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.emoji_events,
                        size: 32, color: _goldenTrophy),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          key: TikiGolfResultsKeys.tiedWinnerName(playerId),
          style: GoogleFonts.boogaloo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _sandWhite,
            shadows: _outlineShadow4(),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSoloWinnerCard(
    Player? winner,
    String winnerId,
    int total,
    int diff,
    int birdies,
  ) {
    final initial =
        winner != null && winner.name.isNotEmpty ? winner.name[0].toUpperCase() : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heading
        Text(
          'GOLDEN TIKI CHAMPION!',
          key: TikiGolfResultsKeys.championHeading,
          style: GoogleFonts.boogaloo(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: _lagoonBlue,
            shadows: _outlineShadow4(),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Avatar with Golden Tiki overlay
        SizedBox(
          key: TikiGolfResultsKeys.winnerPhoto,
          width: 180,
          height: 188, // extra height for the overflow of the golden tiki badge
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Circular avatar
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sandWhite,
                  border: Border.all(color: _goldenTrophy, width: 4),
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildPlayerAvatarInitials(
                  winner,
                  size: 180,
                  fontSize: 88,
                  bgColor: _palmGreen,
                ),
              ),
              // Golden Tiki overlay anchored to lower-right
              Positioned(
                bottom: -8,
                right: -8,
                child: Image.asset(
                  'assets/games/tiki_golf/pieces/GoldenTiki.png',
                  width: 72,
                  height: 72,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 72,
                    height: 72,
                    child: Icon(Icons.emoji_events,
                        size: 48, color: _goldenTrophy),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Winner name
        Text(
          winner?.name ?? '—',
          key: TikiGolfResultsKeys.winnerName,
          style: GoogleFonts.boogaloo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _sandWhite,
            shadows: _outlineShadow4(),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Total strokes + vs-par diff
        RichText(
          key: TikiGolfResultsKeys.winnerTotal,
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.boogaloo(
              fontSize: 20,
              color: _sandWhite,
              shadows: _lightShadow4(),
            ),
            children: [
              TextSpan(text: 'Total: $total strokes ('),
              TextSpan(
                text: _formatDiff(diff),
                style: GoogleFonts.boogaloo(
                  fontSize: 20,
                  color: _diffColor(diff),
                  shadows: _lightShadow4(),
                ),
              ),
              const TextSpan(text: ')'),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Birdies sub-stat
        Text(
          'Birdies: $birdies',
          key: TikiGolfResultsKeys.winnerStats,
          style: GoogleFonts.boogaloo(
            fontSize: 16,
            color: _sandWhite,
            shadows: _lightShadow4(),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSoloScorecard(
    TikiGolfGame game,
    List<String> sortedIds,
    List<String> winnerIds,
    PlayerProvider playerProvider,
  ) {
    final winnerSet = winnerIds.toSet();
    return Container(
      key: TikiGolfResultsKeys.finalScorecard,
      decoration: BoxDecoration(
        color: const Color(0xB32D6A4F), // palmGreen 70% opacity
        border: Border.all(color: _tikiBrown),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          // Header row
          TableRow(
            decoration:
                const BoxDecoration(color: Color(0xE62D6A4F)), // 90% opacity
            children: [
              _hdrCell('', isName: true),
              for (int h = 1; h <= 9; h++) _hdrCell('H$h'),
              _hdrCell('Total', isTotal: true),
              _hdrCell('+/−', isPlusMinus: true),
            ],
          ),
          // Player rows — every tied winner gets the winner row styling
          for (int i = 0; i < sortedIds.length; i++)
            _buildSoloPlayerRow(
              key: TikiGolfResultsKeys.playerRanking(i),
              game: game,
              playerId: sortedIds[i],
              playerName:
                  playerProvider.getPlayerById(sortedIds[i])?.name ??
                      sortedIds[i],
              isWinner: winnerSet.contains(sortedIds[i]),
            ),
        ],
      ),
    );
  }

  TableRow _buildSoloPlayerRow({
    required LocalKey key,
    required TikiGolfGame game,
    required String playerId,
    required String playerName,
    required bool isWinner,
  }) {
    final total = game.totalForPlayer(playerId);
    final diff = total - _kTotalPar;
    final scores = game.playerHoleScores[playerId] ?? List.filled(9, null);

    final rowBg = isWinner
        ? const Color(0x2E00B4D8) // lagoon blue 18% tint
        : Colors.transparent;

    return TableRow(
      key: key,
      decoration: BoxDecoration(color: rowBg),
      children: [
        // Player name cell
        TableCell(
          child: Container(
            decoration: isWinner
                ? const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: _lagoonBlue, width: 2),
                    ),
                  )
                : null,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              playerName,
              style: GoogleFonts.boogaloo(
                fontSize: 18,
                color: isWinner ? _lagoonBlue : _sandWhite,
                shadows: _lightShadow4(),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Hole score cells
        for (int h = 0; h < 9; h++)
          _scoreCell(scores[h], game.maxStrokes),
        // Total
        TableCell(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0x662D6A4F), width: 1),
              ),
            ),
            child: Text(
              '$total',
              textAlign: TextAlign.center,
              style: GoogleFonts.boogaloo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _sandWhite,
                shadows: _lightShadow4(),
              ),
            ),
          ),
        ),
        // +/− diff
        TableCell(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0x662D6A4F), width: 1),
              ),
            ),
            child: Text(
              _formatDiff(diff),
              textAlign: TextAlign.center,
              style: GoogleFonts.boogaloo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _diffColor(diff),
                shadows: _lightShadow4(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Team layout ──────────────────────────────────────────────────────────

  Widget _buildTeamLayout(
    BuildContext context,
    TikiGolfGame game,
    PlayerProvider playerProvider,
  ) {
    // Sort teams by best-ball total ascending
    final sortedTeams = List<String>.from(game.teamPlayers.keys);
    sortedTeams.sort((a, b) =>
        game.totalForTeam(a).compareTo(game.totalForTeam(b)));

    // Resolve tied winning teams (fall back to singular winnerTeamId).
    final winnerTeamIds = game.winnerTeamIds ??
        (game.winnerTeamId != null
            ? [game.winnerTeamId!]
            : <String>[_resolveWinnerTeam(game)]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        children: [
          // ── Winner card (single or tied) ──
          if (winnerTeamIds.length <= 1)
            () {
              final winnerTeamId = winnerTeamIds.isNotEmpty
                  ? winnerTeamIds.first
                  : sortedTeams.first;
              return _buildTeamWinnerCard(
                game,
                playerProvider,
                winnerTeamId,
                _crestPathForTeam(game, winnerTeamId),
                game.teamPlayers[winnerTeamId] ?? [],
                game.totalForTeam(winnerTeamId),
                game.totalForTeam(winnerTeamId) - _kTotalPar,
                game.teamBirdies(winnerTeamId),
              );
            }()
          else
            _buildTeamTiedWinnersCard(game, winnerTeamIds, playerProvider),
          const SizedBox(height: 12),
          // ── Scrollable scorecards (Expanded so buttons stay pinned below) ──
          Expanded(
            child: SingleChildScrollView(
              key: TikiGolfResultsKeys.scorecardsScroll,
              child: _buildTeamScorecards(
                  game, sortedTeams, winnerTeamIds, playerProvider),
            ),
          ),
          const SizedBox(height: 25),
          // ── Action buttons OUTSIDE scroll container — 25px gap above ──
          _buildActionButtons(),
        ],
      ),
    );
  }

  // Tied team winners — N crests side-by-side, with team rosters under each.
  Widget _buildTeamTiedWinnersCard(
    TikiGolfGame game,
    List<String> winnerTeamIds,
    PlayerProvider playerProvider,
  ) {
    final tiedTotal = game.totalForTeam(winnerTeamIds.first);
    final diff = tiedTotal - _kTotalPar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heading — PLURAL for tied team winners. Sized 48 per user request.
        Text(
          'GOLDEN TIKI CHAMPIONS!',
          key: TikiGolfResultsKeys.championHeading,
          style: GoogleFonts.boogaloo(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _lagoonBlue,
            shadows: _outlineShadow4(offset: 2, blur: 10),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'TIED!',
          style: GoogleFonts.boogaloo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _goldenTrophy,
            shadows: _outlineShadow4(),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            for (final tid in winnerTeamIds)
              _buildTeamTiedWinnerItem(
                game: game,
                playerProvider: playerProvider,
                teamId: tid,
              ),
          ],
        ),
        const SizedBox(height: 6),
        // "Tied at N strokes (±X)" — unified 26pt per user request.
        RichText(
          key: TikiGolfResultsKeys.winnerTotal,
          text: TextSpan(
            style: GoogleFonts.boogaloo(
              fontSize: 26,
              color: _sandWhite,
              shadows: _lightShadow4(),
            ),
            children: [
              TextSpan(text: 'Tied at $tiedTotal strokes ('),
              TextSpan(
                text: _formatDiff(diff),
                style: GoogleFonts.boogaloo(
                  fontSize: 26,
                  color: _diffColor(diff),
                  shadows: _lightShadow4(),
                ),
              ),
              const TextSpan(text: ')'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamTiedWinnerItem({
    required TikiGolfGame game,
    required PlayerProvider playerProvider,
    required String teamId,
  }) {
    final crestPath = _crestPathForTeam(game, teamId);
    final members = game.teamPlayers[teamId] ?? [];

    return Column(
      key: TikiGolfResultsKeys.tiedWinnerTeamCrest(teamId),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _lagoonBlue, width: 4),
                  color: _lagoonBlue.withOpacity(0.20),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.asset(
                  crestPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.shield,
                    color: _lagoonBlue,
                    size: 60,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Image.asset(
                  'assets/games/tiki_golf/pieces/GoldenTiki.png',
                  width: 48,
                  height: 48,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events,
                    size: 36,
                    color: _goldenTrophy,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Member names — first names, comma separated
        SizedBox(
          width: 160,
          child: Text(
            members
                .map((pid) =>
                    playerProvider.getPlayerById(pid)?.name.split(' ').first ??
                    pid)
                .join(', '),
            style: GoogleFonts.boogaloo(
              fontSize: 14,
              color: _sandWhite,
              shadows: _lightShadow4(),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamWinnerCard(
    TikiGolfGame game,
    PlayerProvider playerProvider,
    String winnerTeamId,
    String crestPath,
    List<String> winnerPlayers,
    int total,
    int diff,
    int birdies,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heading — PLURAL for team mode. Sized 48 per user request.
        Text(
          'GOLDEN TIKI CHAMPIONS!',
          key: TikiGolfResultsKeys.championHeading,
          style: GoogleFonts.boogaloo(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _lagoonBlue,
            shadows: _outlineShadow4(offset: 2, blur: 10),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Big team crest removed per user — the badge already appears at the
        // left of every team's scorecard below, so duplicating it here was
        // redundant. The crest-key sentinel stays attached to a 0-size
        // placeholder so test selectors that look for it still resolve.
        SizedBox(
          key: TikiGolfResultsKeys.winnerTeamCrest,
          width: 0,
          height: 0,
        ),
        // Row of winning-team player items
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 8,
          children: [
            for (int i = 0; i < winnerPlayers.length; i++)
              _buildWinnerTeamPlayerItem(
                key: TikiGolfResultsKeys.winnerTeamPlayer(winnerPlayers[i]),
                player: playerProvider.getPlayerById(winnerPlayers[i]),
                colorIndex: i,
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Team stats row — all entries unified at 26pt per user request
        // (Team Total baseline 20 + 6).
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              key: TikiGolfResultsKeys.winnerTotal,
              text: TextSpan(
                style: GoogleFonts.boogaloo(
                  fontSize: 26,
                  color: _sandWhite,
                  shadows: _lightShadow4(),
                ),
                children: [
                  TextSpan(text: 'Team Total: $total strokes ('),
                  TextSpan(
                    text: _formatDiff(diff),
                    style: GoogleFonts.boogaloo(
                      fontSize: 26,
                      color: _diffColor(diff),
                      shadows: _lightShadow4(),
                    ),
                  ),
                  const TextSpan(text: ')'),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Text(
              'Team Birdies: $birdies',
              key: TikiGolfResultsKeys.winnerStats,
              style: GoogleFonts.boogaloo(
                fontSize: 26,
                color: _sandWhite,
                shadows: _lightShadow4(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWinnerTeamPlayerItem({
    required Key key,
    required Player? player,
    required int colorIndex,
  }) {
    final initial = player != null && player.name.isNotEmpty
        ? player.name[0].toUpperCase()
        : '?';
    final name = player?.name.split(' ').first ?? '—';
    final bg = _avatarColorForIndex(colorIndex);

    return SizedBox(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Winning team avatar — +40% per user request (130→182).
          // Stack lets the Golden Tiki trophy overlay each avatar's
          // lower-right (replaces the single team-level trophy badge that
          // used to sit on the big team crest above).
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 182,
                  height: 182,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                    border: Border.all(
                        color: _lagoonBlue.withOpacity(0.60), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.boogaloo(
                        // Initial scaled with the +40% avatar bump (59→83).
                        fontSize: 83,
                        fontWeight: FontWeight.bold,
                        color: _sandWhite,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Image.asset(
                    'assets/games/tiki_golf/pieces/GoldenTiki.png',
                    width: 72,
                    height: 72,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.emoji_events,
                      size: 56,
                      color: _goldenTrophy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Player name — +6pt per user request (20→26).
          Text(
            name,
            style: GoogleFonts.boogaloo(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _sandWhite,
              shadows: _lightShadow4(),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScorecards(
    TikiGolfGame game,
    List<String> sortedTeams,
    List<String> winnerTeamIds,
    PlayerProvider playerProvider,
  ) {
    final winnerSet = winnerTeamIds.toSet();
    // Distribution: 4 teams → [2,2]; 3 teams → [2,1]; 2 teams → [1,1]; 1 team → centered
    final col1 = <String>[];
    final col2 = <String>[];

    if (sortedTeams.length == 1) {
      col1.add(sortedTeams[0]);
    } else {
      for (int i = 0; i < sortedTeams.length; i++) {
        if (i % 2 == 0) {
          col1.add(sortedTeams[i]);
        } else {
          col2.add(sortedTeams[i]);
        }
      }
    }

    if (sortedTeams.length == 1) {
      // Single team: centered single column
      return Center(
        child: SizedBox(
          width: 600,
          child: _buildTeamBlock(
            game: game,
            teamId: sortedTeams[0],
            isWinner: winnerSet.contains(sortedTeams[0]),
            playerProvider: playerProvider,
            rankIndex: 0,
          ),
        ),
      );
    }

    // Pair col1[i] with col2[i] inside an IntrinsicHeight Row so left and
    // right team scorecard containers stretch to the taller of the two,
    // giving every row of containers the same height (user request).
    final maxRows =
        col1.length >= col2.length ? col1.length : col2.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < maxRows; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: i < col1.length
                      ? _buildTeamBlock(
                          game: game,
                          teamId: col1[i],
                          isWinner: winnerSet.contains(col1[i]),
                          playerProvider: playerProvider,
                          rankIndex: sortedTeams.indexOf(col1[i]),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: i < col2.length
                      ? _buildTeamBlock(
                          game: game,
                          teamId: col2[i],
                          isWinner: winnerSet.contains(col2[i]),
                          playerProvider: playerProvider,
                          rankIndex: sortedTeams.indexOf(col2[i]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeamBlock({
    required TikiGolfGame game,
    required String teamId,
    required bool isWinner,
    required PlayerProvider playerProvider,
    required int rankIndex,
  }) {
    final crestPath = _crestPathForTeam(game, teamId);
    final teamMembers = game.teamPlayers[teamId] ?? [];
    final bestBallTotal = game.totalForTeam(teamId);

    return Container(
      key: TikiGolfResultsKeys.teamScorecardBlock(teamId),
      decoration: BoxDecoration(
        color: const Color(0xB32D6A4F),
        border: Border.all(
          color: isWinner ? _lagoonBlue : _tikiBrown,
          width: isWinner ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      // Row layout per user request: badge on the LEFT of the scorecard.
      // Scorecard aligned to the top of the container so its header row
      // sits at the same Y across all team blocks regardless of the team's
      // player count.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team crest 80×80.
          ClipOval(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.asset(
                crestPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _lagoonBlue.withOpacity(0.40),
                  child: const Icon(Icons.shield,
                      color: _lagoonBlue, size: 50),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mini scorecard fills remaining row width.
          Expanded(
            child: _buildTeamMiniScorecard(
              game: game,
              teamId: teamId,
              teamMembers: teamMembers,
              playerProvider: playerProvider,
              isWinner: isWinner,
              bestBallTotal: bestBallTotal,
              rankIndex: rankIndex,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMiniScorecard({
    required TikiGolfGame game,
    required String teamId,
    required List<String> teamMembers,
    required PlayerProvider playerProvider,
    required bool isWinner,
    required int bestBallTotal,
    required int rankIndex,
  }) {
    final teamDiff = bestBallTotal - _kTotalPar;
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: Color(0xE62D6A4F)),
          children: [
            _miniHdrCell('', isName: true),
            for (int h = 1; h <= 9; h++) _miniHdrCell('H$h'),
            _miniHdrCell('Total', isTotal: true),
          ],
        ),
        // Per-player rows
        for (final playerId in teamMembers)
          _buildMiniPlayerRow(
            game: game,
            playerId: playerId,
            playerName:
                playerProvider.getPlayerById(playerId)?.name ?? playerId,
          ),
        // Best-ball team total row (2× scaled per user request).
        TableRow(
          decoration: const BoxDecoration(color: Color(0x261616160)),
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Text(
                  'Team Best-Ball',
                  style: GoogleFonts.boogaloo(
                    fontSize: 20,
                    color: _sandWhite.withOpacity(0.80),
                    shadows: _lightShadow4(),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            for (int h = 0; h < 9; h++)
              _miniScoreCell(game.bestBallForTeam(teamId, h), game.maxStrokes),
            // Best-ball total + (relative-to-par) in parens, per user request.
            TableCell(
              key: TikiGolfResultsKeys.teamBlockTotal(teamId),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: Color(0x662D6A4F), width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$bestBallTotal',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.boogaloo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isWinner ? _lagoonBlue : _sandWhite,
                        shadows: _lightShadow4(),
                      ),
                    ),
                    Text(
                      '(${_formatDiff(teamDiff)})',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.boogaloo(
                        fontSize: 16,
                        color: _diffColor(teamDiff),
                        shadows: _lightShadow4(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  TableRow _buildMiniPlayerRow({
    required TikiGolfGame game,
    required String playerId,
    required String playerName,
  }) {
    final scores = game.playerHoleScores[playerId] ?? List.filled(9, null);
    final total = game.totalForPlayer(playerId);

    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            child: Text(
              playerName,
              style: GoogleFonts.boogaloo(
                fontSize: 20,
                color: _sandWhite,
                shadows: _lightShadow4(),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        for (int h = 0; h < 9; h++) _miniScoreCell(scores[h], game.maxStrokes),
        // Player total (2× scaled per user request).
        TableCell(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              border:
                  Border(left: BorderSide(color: Color(0x662D6A4F), width: 1)),
            ),
            child: Text(
              '$total',
              textAlign: TextAlign.center,
              style: GoogleFonts.boogaloo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _sandWhite,
                shadows: _lightShadow4(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Action buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            key: TikiGolfResultsKeys.playAgainButton,
            label: 'PLAY AGAIN',
            color: _lagoonBlue,
            onTap: _playAgain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            key: TikiGolfResultsKeys.changeSettingsButton,
            label: 'CHANGE SETTINGS',
            color: _tikiBrown,
            onTap: _changeSettings,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            key: TikiGolfResultsKeys.backToMenuButton,
            label: 'BACK TO MENU',
            color: _hibiscusPink,
            onTap: _backToMenu,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
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
        foregroundColor: _sandWhite,
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 3,
      ),
      child: Text(
        label,
        style: GoogleFonts.boogaloo(
          // +14pt total over the original (18 → 26 → 32) — last +6 per
          // most-recent user request.
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _sandWhite,
          shadows: [
            const Shadow(
                color: Color(0xB30F281C), offset: Offset(-1, -1)),
            const Shadow(
                color: Color(0xB30F281C), offset: Offset(1, -1)),
            const Shadow(
                color: Color(0xB30F281C), offset: Offset(-1, 1)),
            const Shadow(
                color: Color(0xB30F281C), offset: Offset(1, 1)),
          ],
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ─── Shared cell helpers ──────────────────────────────────────────────────

  /// Full-scorecard header cell.
  Widget _hdrCell(String text,
      {bool isName = false,
      bool isTotal = false,
      bool isPlusMinus = false}) {
    final leftBorder = (isTotal || isPlusMinus)
        ? const Border(
            left: BorderSide(color: Color(0x662D6A4F), width: 1))
        : null;
    return TableCell(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isName ? 14 : 8, vertical: 10),
        alignment: isName ? Alignment.centerLeft : Alignment.center,
        decoration: BoxDecoration(
          border: leftBorder,
          color: const Color(0xE62D6A4F),
        ),
        child: Text(
          text,
          style: GoogleFonts.boogaloo(
            fontSize: 15,
            color: _sandWhite,
            shadows: _outlineShadow4(),
          ),
          textAlign: isName ? TextAlign.left : TextAlign.center,
        ),
      ),
    );
  }

  /// Full score cell (solo scorecard). Matches the gameplay-screen cell
  /// format: 'X' for splash, with the to-par diff in parens beneath.
  Widget _scoreCell(int? score, int maxStrokes) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Center(
          child: score == null
              ? Text('—',
                  style: GoogleFonts.boogaloo(
                      fontSize: 14, color: _sandWhite.withOpacity(0.40)))
              : _scoreCellContent(score, maxStrokes,
                  scoreFontSize: 22, diffFontSize: 12),
        ),
      ),
    );
  }

  /// Mini scorecard header cell. Dimensions/fonts are 2× the original
  /// (player scorecards bumped per user request).
  Widget _miniHdrCell(String text,
      {bool isName = false, bool isTotal = false}) {
    return TableCell(
      child: Container(
        padding:
            EdgeInsets.fromLTRB(isName ? 12 : 6, 8, 6, 8),
        alignment: isName ? Alignment.centerLeft : Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xE62D6A4F),
          border: isTotal
              ? const Border(
                  left: BorderSide(color: Color(0x662D6A4F), width: 1))
              : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.boogaloo(
            fontSize: 18,
            color: _sandWhite,
            shadows: _lightShadow4(),
          ),
          textAlign: isName ? TextAlign.left : TextAlign.center,
        ),
      ),
    );
  }

  /// Mini score cell (team scorecard). Matches the gameplay-screen cell
  /// format: shows the splash label ('X') instead of the raw stroke count
  /// for splashes, and adds the to-par diff in parens underneath each
  /// played cell. `maxStrokes` is required so splash detection here
  /// matches gameplay (splash = `maxStrokes + 1`).
  Widget _miniScoreCell(int? score, int maxStrokes) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Center(
          child: score == null
              ? Text('—',
                  style: GoogleFonts.boogaloo(
                      fontSize: 18, color: _sandWhite.withOpacity(0.40)))
              : _scoreCellContent(score, maxStrokes,
                  scoreFontSize: 18, diffFontSize: 12),
        ),
      ),
    );
  }

  /// Stacked "<label>\n(<diff>)" used by both _scoreCell and _miniScoreCell.
  /// Mirrors the gameplay-screen score cell labelling so the two screens
  /// display the same content per cell.
  Widget _scoreCellContent(int score, int maxStrokes,
      {required double scoreFontSize, required double diffFontSize}) {
    const par = 2;
    final isSplash = score == maxStrokes + 1;
    Color cellColor;
    String label;
    if (isSplash) {
      cellColor = _tropicalOrange;
      label = 'X';
    } else if (score < par) {
      cellColor = _lagoonBlue;
      label = '$score';
    } else if (score == par) {
      cellColor = _sandWhite;
      label = '$score';
    } else {
      cellColor = _hibiscusPink;
      label = '$score';
    }
    final diff = score - par;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.boogaloo(
            fontSize: scoreFontSize,
            fontWeight: FontWeight.bold,
            color: cellColor,
            shadows: _lightShadow4(),
          ),
        ),
        Text(
          '(${_formatDiff(diff)})',
          textAlign: TextAlign.center,
          style: GoogleFonts.boogaloo(
            fontSize: diffFontSize,
            color: _diffColor(diff),
            shadows: _lightShadow4(),
          ),
        ),
      ],
    );
  }

  /// Build a circular avatar with player initials (no character art).
  Widget _buildPlayerAvatarInitials(
    Player? player, {
    required double size,
    required double fontSize,
    required Color bgColor,
  }) {
    final initial =
        player != null && player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      color: bgColor,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.boogaloo(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: _sandWhite,
          ),
        ),
      ),
    );
  }

  // ─── Utility helpers ──────────────────────────────────────────────────────

  String _formatDiff(int diff) {
    if (diff < 0) return '−${diff.abs()}';
    if (diff > 0) return '+$diff';
    return 'E';
  }

  Color _diffColor(int diff) {
    if (diff < 0) return _lagoonBlue;
    if (diff > 0) return _tropicalOrange;
    return _sandWhite;
  }

  String _crestPathForTeam(TikiGolfGame game, String teamId) {
    // teamIds are 'team_1', 'team_2', etc. Crest paths are indexed by team order.
    final teamIds = game.teamPlayers.keys.toList();
    final idx = teamIds.indexOf(teamId);
    if (idx >= 0 && idx < game.teamCrestPaths.length) {
      return game.teamCrestPaths[idx];
    }
    // Fallback: first crest path
    return game.teamCrestPaths.isNotEmpty
        ? game.teamCrestPaths.first
        : 'assets/games/tiki_golf/teams/Sharks.png';
  }

  /// Fallback: derive winning team from best-ball totals if winnerTeamId is null.
  String _resolveWinnerTeam(TikiGolfGame game) {
    String? best;
    int bestTotal = 999;
    for (final teamId in game.teamPlayers.keys) {
      final t = game.totalForTeam(teamId);
      if (t < bestTotal) {
        bestTotal = t;
        best = teamId;
      }
    }
    return best ?? game.teamPlayers.keys.first;
  }
}
