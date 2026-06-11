import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/treasure_divide_game.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/treasure_divide_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../services/victory_music_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/treasure_divide/pirate_avatar_widget.dart';
import 'treasure_divide_menu_screen.dart';

// ─── Color palette ────────────────────────────────────────────────────────────
const Color _treasureGold = Color(0xFFFFD700);
const Color _oceanTeal = Color(0xFF008B8B);
const Color _plankBrown = Color(0xFF8B6914);
const Color _sailWhite = Color(0xFFFFF8E7);
const Color _bloodRed = Color(0xFFC41E3A);
const Color _islandGreen = Color(0xFF228B22);

class TreasureDivideResultsScreen extends StatefulWidget {
  const TreasureDivideResultsScreen({Key? key}) : super(key: key);

  @override
  State<TreasureDivideResultsScreen> createState() =>
      _TreasureDivideResultsScreenState();
}

class _TreasureDivideResultsScreenState
    extends State<TreasureDivideResultsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _musicPlayed = false;
  bool _statsUpdated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await VictoryMusicService().initialize();
      _playVictoryMusic();
      await _updatePlayerStats();
      _deleteResumedSavedGame();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playVictoryMusic() async {
    if (_musicPlayed) return;
    _musicPlayed = true;
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

  Future<void> _updatePlayerStats() async {
    if (_statsUpdated) return;
    _statsUpdated = true;
    if (!mounted) return;

    final provider = context.read<TreasureDivideProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final game = provider.currentGame;
    if (game == null) return;

    final winners = game.winnerIds.toSet();
    final gameDuration = game.gameEndTime
            ?.difference(game.gameStartTime ?? DateTime.now())
            .inSeconds ??
        0;

    try {
      await playerProvider.batchUpdatePlayerStats([
        for (final id in game.playerIds)
          PlayerStatsUpdate(
            playerId: id,
            won: winners.contains(id),
            gameName: 'Treasure Divide',
            gameDuration: Duration(seconds: gameDuration),
            dartThrows: game.totalDartsThrown[id] ?? 0,
            turns: game.totalTurns[id] ?? 0,
            playerCount: game.playerIds.length,
          ),
      ]);
    } catch (e) {
      // Auto-logged by PlayerProvider
    }
  }

  void _deleteResumedSavedGame() {
    final provider = context.read<TreasureDivideProvider>();
    final savedId = provider.resumedSavedGameId;
    if (savedId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SaveGameService().deleteSavedGame('treasure_divide', savedId);
      provider.clearResumedSavedGameId();
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final provider = context.watch<TreasureDivideProvider>();
    final playerProvider = context.watch<PlayerProvider>();

    final game = provider.currentGame;
    if (game == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.pop(context);
        }
      });
      return const SizedBox();
    }

    return Stack(
      children: [
        // ─── Scaffold ──────────────────────────────────────────────────────
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'TREASURE DIVIDE RESULTS',
              style: GoogleFonts.pirataOne(fontSize: 34, color: _treasureGold),
            ),
            centerTitle: false,
            backgroundColor: _oceanTeal,
            actions: [
              DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.treasureDivide()),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/games/treasure_divide/images/TreasureDivide-Background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: _oceanTeal),
                ),
              ),
              Positioned.fill(
                child: Container(color: _oceanTeal.withOpacity(0.65)),
              ),
              SingleChildScrollView(
                child:
                    _buildResultsBody(context, provider, playerProvider, game),
              ),
            ],
          ),
        ),

        // ─── DartboardPausedModal (last child) ─────────────────────────────
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status != DartboardConnectionStatus.connected &&
            dartboardProvider.status != DartboardConnectionStatus.emulator)
          DartboardPausedModal(
              config: DartboardPausedModalConfig.treasureDivide()),
      ],
    );
  }

  Widget _buildResultsBody(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Winner section
          _buildWinnerSection(context, provider, playerProvider, game),
          const SizedBox(height: 24),

          // Rankings
          _buildRankings(context, provider, playerProvider, game),
          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(context, provider, playerProvider, game),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Winner section ───────────────────────────────────────────────────────────

  Widget _buildWinnerSection(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    final isTeam = game.gameMode == TreasureDivideGameMode.team;
    final isTeamTie = isTeam && game.winnerTeamIds.length > 1;
    final isSoloTie = !isTeam && game.winnerIds.length > 1;

    if (isTeam) {
      return isTeamTie
          ? _buildTeamTieWinner(context, provider, playerProvider, game)
          : _buildTeamSingleWinner(context, provider, playerProvider, game);
    } else {
      return isSoloTie
          ? _buildSoloTieWinner(context, provider, playerProvider, game)
          : _buildSoloSingleWinner(context, provider, playerProvider, game);
    }
  }

  Widget _buildSoloSingleWinner(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    final winnerId =
        game.winnerIds.isNotEmpty ? game.winnerIds.first : '';
    final winner = playerProvider.getPlayerById(winnerId);
    final treasure = game.totalForPlayer(winnerId);
    final timesHalved = game.timesHalvedPerPlayer[winnerId] ?? 0;
    final halvedLabel =
        game.quarterItEnabled ? 'Times Quartered' : 'Times Halved';

    return Column(
      children: [
        // Title with Plank Brown outline effect
        _buildTitleWithOutline('PIRATE CAPTAIN!'),
        const SizedBox(height: 12),

        // Winner avatar with pirate theme overlay
        if (winner != null)
          PirateAvatarWidget(
            player: winner,
            themeIndex: game.playerPirateThemes[winner.id] ?? 0,
            size: 120,
            isActive: true,
          ),
        const SizedBox(height: 10),

        // Winner name
        Text(
          winner?.name ?? '',
          key: TreasureDivideResultsKeys.winnerName,
          style: GoogleFonts.pirataOne(fontSize: 28, color: _sailWhite),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Stats line
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Treasure: ',
              key: TreasureDivideResultsKeys.treasureScore,
              style: GoogleFonts.merriweather(
                  fontSize: 16, color: _treasureGold),
            ),
            Text(
              '$treasure gold',
              style: GoogleFonts.merriweather(
                  fontSize: 16,
                  color: _treasureGold,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '($halvedLabel: ',
              key: TreasureDivideResultsKeys.timesHalved,
              style: GoogleFonts.merriweather(
                  fontSize: 14, color: _sailWhite.withOpacity(0.7)),
            ),
            Text(
              '$timesHalved)',
              style: GoogleFonts.merriweather(
                  fontSize: 14, color: _sailWhite.withOpacity(0.7)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSoloTieWinner(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    final winnerIds = game.winnerIds;
    final treasure =
        winnerIds.isNotEmpty ? game.totalForPlayer(winnerIds.first) : 0;
    final timesHalved = winnerIds.isNotEmpty
        ? (game.timesHalvedPerPlayer[winnerIds.first] ?? 0)
        : 0;
    final halvedLabel =
        game.quarterItEnabled ? 'Times Quartered' : 'Times Halved';
    final names = winnerIds
        .map((id) => playerProvider.getPlayerById(id)?.name ?? id)
        .toList();
    final nameStr = names.join(' & ');

    return Column(
      children: [
        _buildTitleWithOutline('DIVIDED TREASURE!'),
        const SizedBox(height: 6),
        Text(
          'A TIE BETWEEN CAPTAINS',
          style: GoogleFonts.pirataOne(fontSize: 18, color: _sailWhite),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Row of tied-player avatars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final id in winnerIds) ...[
              Builder(builder: (context) {
                final tiedPlayer = playerProvider.getPlayerById(id);
                if (tiedPlayer == null) {
                  return _buildAvatarCircle(id, size: 80);
                }
                return PirateAvatarWidget(
                  player: tiedPlayer,
                  themeIndex: game.playerPirateThemes[id] ?? 0,
                  size: 80,
                  isActive: true,
                );
              }),
              const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 8),

        Text(
          nameStr,
          key: TreasureDivideResultsKeys.winnerName,
          style: GoogleFonts.pirataOne(fontSize: 22, color: _sailWhite),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        Text(
          'Treasure: $treasure gold each ($halvedLabel: $timesHalved each)',
          key: TreasureDivideResultsKeys.treasureScore,
          style: GoogleFonts.merriweather(fontSize: 14, color: _treasureGold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTeamSingleWinner(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    final winnerTeamId =
        game.winnerTeamIds.isNotEmpty ? game.winnerTeamIds.first : '';
    final teamIds = game.teamPlayers.keys.toList();
    final crestIdx = teamIds.indexOf(winnerTeamId);
    final crestPath = (crestIdx >= 0 && crestIdx < game.teamCrestPaths.length)
        ? game.teamCrestPaths[crestIdx]
        : null;
    final treasure = game.totalForTeam(winnerTeamId);
    final timesHalved = game.timesHalvedPerTeam[winnerTeamId] ?? 0;
    final halvedLabel =
        game.quarterItEnabled ? 'Times Quartered' : 'Times Halved';
    final members = game.teamPlayers[winnerTeamId] ?? [];

    return Column(
      children: [
        _buildTitleWithOutline("CAPTAIN'S CREW!"),
        const SizedBox(height: 12),

        // Winning crew crest
        Container(
          key: TreasureDivideResultsKeys.winnerCrewCrest,
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _treasureGold, width: 3),
            color: _oceanTeal.withOpacity(0.4),
          ),
          child: crestPath != null
              ? ClipOval(
                  child: Image.asset(
                    crestPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.shield, color: _treasureGold, size: 64),
                  ),
                )
              : Icon(Icons.shield, color: _treasureGold, size: 64),
        ),
        const SizedBox(height: 10),

        // Row of winning crew members
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            for (final pid in members)
              Container(
                key: TreasureDivideResultsKeys.winnerCrewPlayer(pid),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final memberPlayer = playerProvider.getPlayerById(pid);
                      if (memberPlayer == null) {
                        return _buildAvatarCircle(pid, size: 48);
                      }
                      return PirateAvatarWidget(
                        player: memberPlayer,
                        themeIndex: game.playerPirateThemes[pid] ?? 0,
                        size: 48,
                        isActive: true,
                      );
                    }),
                    const SizedBox(height: 4),
                    Text(
                      playerProvider.getPlayerById(pid)?.name ?? pid,
                      style: GoogleFonts.merriweather(
                          fontSize: 12, color: _sailWhite),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Stats
        Text(
          'Crew Treasure: $treasure gold ($halvedLabel: $timesHalved)',
          key: TreasureDivideResultsKeys.treasureScore,
          style: GoogleFonts.merriweather(
              fontSize: 16, color: _treasureGold, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTeamTieWinner(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    final winnerTeamIds = game.winnerTeamIds;
    final teamIds = game.teamPlayers.keys.toList();
    final treasure =
        winnerTeamIds.isNotEmpty ? game.totalForTeam(winnerTeamIds.first) : 0;
    final timesHalved = winnerTeamIds.isNotEmpty
        ? (game.timesHalvedPerTeam[winnerTeamIds.first] ?? 0)
        : 0;
    final halvedLabel =
        game.quarterItEnabled ? 'Times Quartered' : 'Times Halved';

    return Column(
      children: [
        _buildTitleWithOutline('DIVIDED TREASURE!'),
        const SizedBox(height: 6),
        Text(
          'A TIE BETWEEN CREWS',
          style: GoogleFonts.pirataOne(fontSize: 18, color: _sailWhite),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Side-by-side tied crew crests + members. Two-way ties get a
        // decorative "&" between the crests (matches the wireframe's
        // `.crew-tie-ampersand`). Three-plus-way ties skip the
        // ampersand and fall back to a comma-style separation, since
        // an "&" between every pair gets visually noisy.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < winnerTeamIds.length; i++) ...[
              _buildTiedCrewColumn(
                  game, playerProvider, winnerTeamIds[i], teamIds),
              if (i < winnerTeamIds.length - 1) ...[
                const SizedBox(width: 16),
                if (winnerTeamIds.length == 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      '&',
                      style: GoogleFonts.pirataOne(
                        fontSize: 48,
                        color: _treasureGold,
                        shadows: const [
                          Shadow(
                              color: Color(0xFF8B6914),
                              offset: Offset(-1.5, -1.5)),
                          Shadow(
                              color: Color(0xFF8B6914),
                              offset: Offset(1.5, -1.5)),
                          Shadow(
                              color: Color(0xFF8B6914),
                              offset: Offset(-1.5, 1.5)),
                          Shadow(
                              color: Color(0xFF8B6914),
                              offset: Offset(1.5, 1.5)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
              ],
            ],
          ],
        ),
        const SizedBox(height: 8),

        Text(
          'Crew Treasure: $treasure gold each ($halvedLabel: $timesHalved each)',
          key: TreasureDivideResultsKeys.treasureScore,
          style: GoogleFonts.merriweather(
              fontSize: 14, color: _treasureGold, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTiedCrewColumn(
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    String teamId,
    List<String> teamIdList,
  ) {
    final crestIdx = teamIdList.indexOf(teamId);
    final crestPath = (crestIdx >= 0 && crestIdx < game.teamCrestPaths.length)
        ? game.teamCrestPaths[crestIdx]
        : null;
    final members = game.teamPlayers[teamId] ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crest
        Container(
          key: TreasureDivideResultsKeys.winnerCrewCrest,
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _treasureGold, width: 2),
            color: _oceanTeal.withOpacity(0.4),
          ),
          child: crestPath != null
              ? ClipOval(
                  child: Image.asset(
                    crestPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.shield, color: _treasureGold, size: 40),
                  ),
                )
              : Icon(Icons.shield, color: _treasureGold, size: 40),
        ),
        const SizedBox(height: 8),
        // Members
        for (final pid in members)
          Text(
            playerProvider.getPlayerById(pid)?.name ?? pid,
            style: GoogleFonts.merriweather(
                fontSize: 12, color: _sailWhite),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  // ─── Rankings ─────────────────────────────────────────────────────────────────

  Widget _buildRankings(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    final isTeam = game.gameMode == TreasureDivideGameMode.team;

    if (isTeam) {
      return _buildTeamRankings(context, provider, playerProvider, game);
    } else {
      return _buildSoloRankings(context, provider, playerProvider, game);
    }
  }

  Widget _buildSoloRankings(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    final ranked = _getRankedSoloPlayers(game);

    if (ranked.length > 4) {
      // Two-column layout for 5+ players
      final half = (ranked.length / 2).ceil();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildSoloRankingColumn(
                ranked.sublist(0, half), playerProvider, game, 0),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSoloRankingColumn(
                ranked.sublist(half), playerProvider, game, half),
          ),
        ],
      );
    }

    return _buildSoloRankingColumn(ranked, playerProvider, game, 0);
  }

  Widget _buildSoloRankingColumn(
    List<String> playerIds,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
    int startIndex,
  ) {
    final halvedLabel =
        game.quarterItEnabled ? 'Times Quartered' : 'Times Halved';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _plankBrown.withOpacity(0.4), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(playerIds.length, (index) {
          final playerId = playerIds[index];
          final player = playerProvider.getPlayerById(playerId);
          if (player == null) return const SizedBox();

          final globalIndex = startIndex + index;
          final treasure = game.totalForPlayer(playerId);
          final timesHalved = game.timesHalvedPerPlayer[playerId] ?? 0;
          final isWinner = game.winnerIds.contains(playerId);

          return Container(
            key: TreasureDivideResultsKeys.playerRanking(globalIndex),
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: globalIndex % 2 == 0
                  ? _oceanTeal.withOpacity(0.2)
                  : _oceanTeal.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
              border: isWinner
                  ? Border.all(color: _treasureGold, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 36,
                  child: Text(
                    '${globalIndex + 1}.',
                    style: GoogleFonts.pirataOne(
                        fontSize: 18, color: _treasureGold),
                  ),
                ),
                // Avatar with pirate theme
                PirateAvatarWidget(
                  player: player,
                  themeIndex: game.playerPirateThemes[playerId] ?? 0,
                  size: 40,
                  isActive: false,
                ),
                const SizedBox(width: 10),
                // Name
                Expanded(
                  child: Text(
                    player.name,
                    style: GoogleFonts.merriweather(
                        fontSize: 14,
                        color: _sailWhite,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$treasure gold',
                      style: GoogleFonts.merriweather(
                          fontSize: 13,
                          color: _treasureGold,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$halvedLabel: $timesHalved',
                      style: GoogleFonts.merriweather(
                          fontSize: 11,
                          color: _sailWhite.withOpacity(0.6)),
                    ),
                  ],
                ),
                if (isWinner) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _islandGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'WIN',
                      style: GoogleFonts.pirataOne(
                          fontSize: 10, color: _sailWhite),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTeamRankings(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    final ranked = _getRankedTeams(game);
    final halvedLabel =
        game.quarterItEnabled ? 'Times Quartered' : 'Times Halved';
    final teamIdList = game.teamPlayers.keys.toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _plankBrown.withOpacity(0.4), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(ranked.length, (index) {
          final teamId = ranked[index];
          final treasure = game.totalForTeam(teamId);
          final timesHalved = game.timesHalvedPerTeam[teamId] ?? 0;
          final isWinner = game.winnerTeamIds.contains(teamId);
          final crestIdx = teamIdList.indexOf(teamId);
          final crestPath =
              (crestIdx >= 0 && crestIdx < game.teamCrestPaths.length)
                  ? game.teamCrestPaths[crestIdx]
                  : null;
          final members = game.teamPlayers[teamId] ?? [];

          return Container(
            key: TreasureDivideResultsKeys.crewRanking(index),
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: index % 2 == 0
                  ? _oceanTeal.withOpacity(0.2)
                  : _oceanTeal.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
              border: isWinner
                  ? Border.all(color: _treasureGold, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 36,
                  child: Text(
                    '${index + 1}.',
                    style: GoogleFonts.pirataOne(
                        fontSize: 18, color: _treasureGold),
                  ),
                ),
                // Crest
                SizedBox(
                  width: 36,
                  height: 36,
                  child: crestPath != null
                      ? Image.asset(crestPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.shield, color: _treasureGold))
                      : Icon(Icons.shield, color: _treasureGold),
                ),
                const SizedBox(width: 10),
                // Team members column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final pid in members)
                        Text(
                          playerProvider.getPlayerById(pid)?.name ?? pid,
                          style: GoogleFonts.merriweather(
                              fontSize: 13,
                              color: _sailWhite,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$treasure gold',
                      style: GoogleFonts.merriweather(
                          fontSize: 13,
                          color: _treasureGold,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$halvedLabel: $timesHalved',
                      style: GoogleFonts.merriweather(
                          fontSize: 11,
                          color: _sailWhite.withOpacity(0.6)),
                    ),
                  ],
                ),
                if (isWinner) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _islandGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'WIN',
                      style: GoogleFonts.pirataOne(
                          fontSize: 10, color: _sailWhite),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Action buttons ───────────────────────────────────────────────────────────

  Widget _buildActionButtons(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        // SAIL AGAIN
        SizedBox(
          width: 200,
          height: 52,
          child: ElevatedButton(
            key: TreasureDivideResultsKeys.playAgainButton,
            onPressed: () => _playAgain(context, provider, playerProvider, game),
            style: ElevatedButton.styleFrom(
              backgroundColor: _islandGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 4,
            ),
            child: Text(
              'SAIL AGAIN',
              style: GoogleFonts.pirataOne(
                  fontSize: 16, color: _sailWhite),
            ),
          ),
        ),

        // CHANGE COURSE
        SizedBox(
          width: 200,
          height: 52,
          child: ElevatedButton(
            key: TreasureDivideResultsKeys.changeSettingsButton,
            onPressed: () =>
                _changeSettings(context, provider, playerProvider, game),
            style: ElevatedButton.styleFrom(
              backgroundColor: _treasureGold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 4,
            ),
            child: Text(
              'CHANGE COURSE',
              style: GoogleFonts.pirataOne(
                  fontSize: 16, color: _oceanTeal),
            ),
          ),
        ),

        // DOCK HOME
        SizedBox(
          width: 200,
          height: 52,
          child: ElevatedButton(
            key: TreasureDivideResultsKeys.backToMenuButton,
            onPressed: () => _backToMenu(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: _bloodRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 4,
            ),
            child: Text(
              'DOCK HOME',
              style: GoogleFonts.pirataOne(
                  fontSize: 16, color: _sailWhite),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Navigation handlers ──────────────────────────────────────────────────────

  void _playAgain(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    // Navigate to menu then clear, preserving same settings
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TreasureDivideMenuScreen(
          initialGameMode: game.gameMode,
          initialTeamAssignment: game.teamAssignment,
          initialTeamCount: game.teamCount,
          initialNumberOfRounds: game.numberOfRounds,
          initialQuarterIt: game.quarterItEnabled,
          initialCustomTargets: game.customTargetsEnabled,
          initialSelectedPlayerIds: List<String>.from(game.playerIds),
          initialPlayerTeamAssignments:
              Map<String, String>.from(game.playerTeamAssignments),
        ),
      ),
      (route) => route.isFirst,
    );
    provider.clearGame();
  }

  void _changeSettings(
    BuildContext context,
    TreasureDivideProvider provider,
    PlayerProvider playerProvider,
    TreasureDivideGame game,
  ) {
    // Navigate first, then clear (prevents race with results pop)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TreasureDivideMenuScreen(
          initialGameMode: game.gameMode,
          initialTeamAssignment: game.teamAssignment,
          initialTeamCount: game.teamCount,
          initialNumberOfRounds: game.numberOfRounds,
          initialQuarterIt: game.quarterItEnabled,
          initialCustomTargets: game.customTargetsEnabled,
          initialSelectedPlayerIds: List<String>.from(game.playerIds),
          initialPlayerTeamAssignments:
              Map<String, String>.from(game.playerTeamAssignments),
        ),
      ),
      (route) => route.isFirst,
    );
    provider.clearGame();
  }

  void _backToMenu(BuildContext context, TreasureDivideProvider provider) {
    provider.clearGame();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildTitleWithOutline(String text) {
    return Stack(
      children: [
        // Outline layer (rendered behind with slight offsets)
        for (final offset in [
          const Offset(-2, -2),
          const Offset(2, -2),
          const Offset(-2, 2),
          const Offset(2, 2),
        ])
          Transform.translate(
            offset: offset,
            child: Text(
              text,
              style: GoogleFonts.pirataOne(
                  fontSize: 36, color: _plankBrown),
              textAlign: TextAlign.center,
            ),
          ),
        Text(
          text,
          style: GoogleFonts.pirataOne(fontSize: 36, color: _treasureGold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAvatarCircle(String name, {double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _sailWhite,
        border: Border.all(color: _treasureGold, width: 2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.pirataOne(
            fontSize: size * 0.4,
            color: _plankBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<String> _getRankedSoloPlayers(TreasureDivideGame game) {
    final players = List<String>.from(game.playerIds);
    players.sort((a, b) {
      final aScore = game.totalForPlayer(a);
      final bScore = game.totalForPlayer(b);
      if (aScore != bScore) return bScore.compareTo(aScore);
      final aHalved = game.timesHalvedPerPlayer[a] ?? 0;
      final bHalved = game.timesHalvedPerPlayer[b] ?? 0;
      return aHalved.compareTo(bHalved);
    });
    return players;
  }

  List<String> _getRankedTeams(TreasureDivideGame game) {
    final teams = game.teamPlayers.keys.toList();
    teams.sort((a, b) {
      final aScore = game.totalForTeam(a);
      final bScore = game.totalForTeam(b);
      if (aScore != bScore) return bScore.compareTo(aScore);
      final aHalved = game.timesHalvedPerTeam[a] ?? 0;
      final bHalved = game.timesHalvedPerTeam[b] ?? 0;
      return aHalved.compareTo(bHalved);
    });
    return teams;
  }
}
