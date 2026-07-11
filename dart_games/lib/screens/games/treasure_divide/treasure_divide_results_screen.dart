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
import 'treasure_divide_game_screen.dart';
import 'treasure_divide_menu_screen.dart';

// ─── Color palette ────────────────────────────────────────────────────────────
const Color _treasureGold = Color(0xFFFFD700);
const Color _oceanTeal = Color(0xFF008B8B);
const Color _plankBrown = Color(0xFF8B6914);
const Color _sailWhite = Color(0xFFFFF8E7);
const Color _bloodRed = Color(0xFFC41E3A);
const Color _islandGreen = Color(0xFF228B22);
// Warm coral / amber — matches the "Halved N times" / "Quartered N times"
// pill on the game play screen (treasure_divide_game_screen.dart uses the
// same 0xFFFF8C42) so the stat reads as the same thing across screens.
const Color _halveCoral = Color(0xFFFF8C42);

// Text shadow stack — mirrors treasure_divide_game_screen.dart so every
// piece of copy on the results screen carries the same 2/2 drop-shadow
// plus teal glow the game screen uses. Without these, gold/coral text
// disappears against the wooden background image; with them it pops
// cleanly on both dark and light patches of the artwork.
const List<Shadow> _treasureTextShadows = [
  Shadow(color: Color(0xCC000000), offset: Offset(2, 2), blurRadius: 4),
  Shadow(color: Color(0xAA008B8B), offset: Offset(0, 0), blurRadius: 10),
];

// Shadow stack for text sitting on the GOLD button background (e.g.
// CHANGE COURSE — ocean-teal letters over a treasure-gold fill). The
// full _treasureTextShadows adds a teal glow, which blends into
// ocean-teal glyphs and mushes the edges. This variant uses a sail-
// white halo instead so the teal reads clearly against gold, then the
// same dark drop-shadow underneath for depth.
const List<Shadow> _treasureButtonGoldShadows = [
  Shadow(color: Color(0xCC000000), offset: Offset(2, 2), blurRadius: 4),
  Shadow(color: Color(0xFFFFF8E7), offset: Offset(0, 0), blurRadius: 3),
];

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
              style: GoogleFonts.pirataOne(
                fontSize: 34,
                color: _treasureGold,
                shadows: const [
                  Shadow(
                      color: Color(0xCC000000),
                      offset: Offset(2, 2),
                      blurRadius: 4),
                  Shadow(
                      color: Color(0xAA008B8B),
                      offset: Offset(0, 0),
                      blurRadius: 10),
                ],
              ),
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
                child: Container(color: _oceanTeal.withOpacity(0.10)),
              ),
              // SafeArea + Positioned.fill so the body Column uses the
              // full available height (below AppBar, above system chrome)
              // instead of collapsing to intrinsic height. The winner
              // section pins to the top, the rankings expand into all
              // remaining space (scroll internally if too tall), and
              // the action buttons pin to the bottom — no more empty
              // dead-zone under the content.
              Positioned.fill(
                child: SafeArea(
                  child: _buildResultsBody(
                      context, provider, playerProvider, game),
                ),
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
    // Column pattern (borrowed from Tiki Golf results): winner at top,
    // Expanded(SingleChildScrollView(rankings)) in the middle, buttons
    // pinned at the bottom. This uses the full body height instead of
    // the old outer SingleChildScrollView which let the Column collapse
    // to intrinsic height and cluster everything in the top 50% of the
    // screen.
    //
    // Responsive scaling: rather than plumb a scale factor through
    // every _build* helper (this screen has 4 winner variants + 4
    // ranking variants + action buttons + title, each with dozens of
    // hardcoded font sizes and dimensions), we render the whole body
    // at a fixed 1600×900 design baseline and let a FittedBox scale
    // the entire subtree to fit the actual viewport. BoxFit.contain
    // preserves aspect ratio (letterboxing when the viewport aspect
    // differs), so proportions and readability stay intact at every
    // window size — no widget-level RenderFlex overflow possible
    // because the Column always sees its full 900 px design height.
    // The internal SingleChildScrollView still scrolls inside its
    // scaled area if the rankings list is unusually tall.
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 1600,
        height: 900,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Winner section — hero content, fixed height.
              _buildWinnerSection(context, provider, playerProvider, game),
              const SizedBox(height: 20),

              // Rankings — expand into remaining vertical space; scroll
              // internally when the ranked list is taller than fits.
              Expanded(
                child: SingleChildScrollView(
                  child:
                      _buildRankings(context, provider, playerProvider, game),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons — pinned at the bottom.
              _buildActionButtons(context, provider, playerProvider, game),
            ],
          ),
        ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + avatar in a Stack so the title paints IN FRONT of
        // the avatar's out-of-bounds accessories (pirate hats often
        // extend well above the avatar's 300×300 box because
        // PirateAvatarWidget's Stack uses Clip.none for accessory
        // overhang). Column paint order would put the avatar layer
        // on top and hide the title text behind the hat sprite; the
        // Stack pattern below preserves the same vertical layout
        // (invisible placeholder title reserves space) but repaints
        // the visible title last so it stays legible.
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _buildTitleWithOutline('PIRATE CAPTAIN!'),
                ),
                const SizedBox(height: 40),
                if (winner != null)
                  PirateAvatarWidget(
                    player: winner,
                    themeIndex: game.playerPirateThemes[winner.id] ?? 0,
                    size: 300,
                    isActive: true,
                  ),
              ],
            ),
            // Visible title — last child paints on top.
            _buildTitleWithOutline('PIRATE CAPTAIN!'),
          ],
        ),
        const SizedBox(height: 16),

        // Winner name
        Text(
          winner?.name ?? '',
          key: TreasureDivideResultsKeys.winnerName,
          style: GoogleFonts.pirataOne(
              fontSize: 40,
              color: _sailWhite,
              shadows: _treasureTextShadows),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // Stats line — treasure in gold, halve/quarter tally in the
        // same warm coral used by the game play screen tile so both
        // screens read the stat identically. Shadows match the game
        // screen so the labels stay legible over the wooden BG.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Treasure: ',
              key: TreasureDivideResultsKeys.treasureScore,
              style: GoogleFonts.merriweather(
                  fontSize: 20,
                  color: _treasureGold,
                  shadows: _treasureTextShadows),
            ),
            Text(
              '$treasure gold',
              style: GoogleFonts.merriweather(
                  fontSize: 20,
                  color: _treasureGold,
                  fontWeight: FontWeight.bold,
                  shadows: _treasureTextShadows),
            ),
            const SizedBox(width: 10),
            Text(
              '($halvedLabel: ',
              key: TreasureDivideResultsKeys.timesHalved,
              style: GoogleFonts.merriweather(
                  fontSize: 18,
                  color: _halveCoral,
                  fontWeight: FontWeight.w600,
                  shadows: _treasureTextShadows),
            ),
            Text(
              '$timesHalved)',
              style: GoogleFonts.merriweather(
                  fontSize: 18,
                  color: _halveCoral,
                  fontWeight: FontWeight.w600,
                  shadows: _treasureTextShadows),
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
    // Halve/quarter count intentionally NOT surfaced on the solo-tie
    // top section: tied players share the same treasure total but
    // often reach it via different halve/quarter histories, so a
    // single number would be misleading. Per-player counts still
    // appear on each scorecard row below.

    // Tier the avatar + name sizing on the number of tied players
    // (mirrors Reef Royale's _buildWinnerNamesAndAvatars) so a 2-way
    // tie shows big hero portraits and an 8-way tie still fits on a
    // single row without overlap. Horizontal padding scales with size
    // so the space BETWEEN portraits reads consistent across tiers.
    //
    // Calibrated for the kiosk display (1920px wide → 1872px body
    // after the 24px outer screen padding). The 8-way row consumes
    // ~92% of the available body width (8×180 + 16×18 = 1728);
    // smaller tiers are proportionally larger since they don't need
    // to pack as many portraits.
    final tieCount = winnerIds.length;
    final double avatarSize;
    final double horizontalPad;
    final double nameFontSize;
    if (tieCount <= 2) {
      avatarSize = 300;
      horizontalPad = 36;
      nameFontSize = 34;
    } else if (tieCount <= 4) {
      avatarSize = 230;
      horizontalPad = 26;
      nameFontSize = 28;
    } else if (tieCount <= 6) {
      avatarSize = 190;
      horizontalPad = 20;
      nameFontSize = 24;
    } else {
      avatarSize = 180;
      horizontalPad = 18;
      nameFontSize = 22;
    }

    // Local builder for the title + subtitle stack (used both as the
    // invisible spatial placeholder and the visible top-layer overlay).
    // Internal spacing tightened to 2px so "DIVIDED TREASURE!" and
    // "A TIE BETWEEN CAPTAINS" read as one unit — the outer 40→70
    // avatar gap below now provides the breathing room instead.
    Widget buildTitleGroup() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitleWithOutline('DIVIDED TREASURE!'),
            const SizedBox(height: 2),
            Text(
              'A TIE BETWEEN CAPTAINS',
              style: GoogleFonts.pirataOne(
                  fontSize: 24,
                  color: _sailWhite,
                  shadows: _treasureTextShadows),
              textAlign: TextAlign.center,
            ),
          ],
        );

    // One (avatar + name) column per tied captain, tier-sized.
    Widget buildTiedCaptain(String id) {
      final tiedPlayer = playerProvider.getPlayerById(id);
      final name = tiedPlayer?.name ?? id;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            tiedPlayer == null
                ? _buildAvatarCircle(id, size: avatarSize)
                : PirateAvatarWidget(
                    player: tiedPlayer,
                    themeIndex: game.playerPirateThemes[id] ?? 0,
                    size: avatarSize,
                    isActive: true,
                  ),
            const SizedBox(height: 10),
            SizedBox(
              width: avatarSize,
              child: Text(
                name,
                style: GoogleFonts.pirataOne(
                    fontSize: nameFontSize,
                    color: _sailWhite,
                    shadows: _treasureTextShadows),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + subtitle repainted on top of tied avatars so pirate
        // hat overhang doesn't hide the copy. See _buildSoloSingleWinner
        // for the pattern rationale.
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: buildTitleGroup(),
                ),
                // Extra breathing room here (was 40) so tall pirate
                // hats on the tied avatars don't crash into the
                // "A TIE BETWEEN CAPTAINS" subtitle above.
                const SizedBox(height: 70),
                // Row of (avatar + name) columns, tier-sized so all
                // eight possible tied captains fit on one line. Row
                // (not Wrap) keeps the group visually cohesive; the
                // sizing ladder above guarantees width fits within
                // the outer 24px screen padding on a kiosk display.
                // Key: TreasureDivideResultsKeys.winnerName is kept
                // on this Row so tests that look up the winner name
                // anchor still resolve to something on the tie
                // variant.
                Row(
                  key: TreasureDivideResultsKeys.winnerName,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final id in winnerIds) buildTiedCaptain(id),
                  ],
                ),
              ],
            ),
            buildTitleGroup(),
          ],
        ),
        const SizedBox(height: 18),

        // Treasure only — halved/quartered tally intentionally omitted
        // (see comment at top of _buildSoloTieWinner). Per-player
        // halve counts appear on each scorecard row below.
        // The former "Name & Name" joined listing above the stats was
        // dropped now that each avatar shows its own name inline.
        Text(
          'Treasure: $treasure gold each',
          key: TreasureDivideResultsKeys.treasureScore,
          style: GoogleFonts.merriweather(
              fontSize: 18,
              color: _treasureGold,
              fontWeight: FontWeight.bold,
              shadows: _treasureTextShadows),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitleWithOutline("CAPTAIN'S CREW!"),
        const SizedBox(height: 40),

        // Winning crew crest — 50% smaller again (143 → 72). The two
        // crew members' 300px portraits carry all the visual weight;
        // the crest is now a compact "team identity" mark.
        Container(
          key: TreasureDivideResultsKeys.winnerCrewCrest,
          width: 72,
          height: 72,
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
                        Icon(Icons.shield, color: _treasureGold, size: 40),
                  ),
                )
              : Icon(Icons.shield, color: _treasureGold, size: 40),
        ),
        const SizedBox(height: 16),

        // Row of winning crew members — avatars sized to MATCH the
        // solo single winner (300) and names in the same 40pt
        // pirataOne face solo single uses. Extra horizontal spacing
        // (24 → 48) keeps the two 300px portraits from crowding
        // each other.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 48,
          runSpacing: 16,
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
                        return _buildAvatarCircle(pid, size: 300);
                      }
                      return PirateAvatarWidget(
                        player: memberPlayer,
                        themeIndex: game.playerPirateThemes[pid] ?? 0,
                        size: 300,
                        isActive: true,
                      );
                    }),
                    const SizedBox(height: 10),
                    Text(
                      playerProvider.getPlayerById(pid)?.name ?? pid,
                      style: GoogleFonts.pirataOne(
                          fontSize: 40,
                          color: _sailWhite,
                          shadows: _treasureTextShadows),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Stats — treasure in gold, halve/quarter tally in coral to
        // match the game play screen.
        Text.rich(
          key: TreasureDivideResultsKeys.treasureScore,
          TextSpan(
            children: [
              TextSpan(
                text: 'Crew Treasure: $treasure gold ',
                style: GoogleFonts.merriweather(
                    fontSize: 22,
                    color: _treasureGold,
                    fontWeight: FontWeight.bold,
                    shadows: _treasureTextShadows),
              ),
              TextSpan(
                text: '($halvedLabel: $timesHalved)',
                style: GoogleFonts.merriweather(
                    fontSize: 22,
                    color: _halveCoral,
                    fontWeight: FontWeight.bold,
                    shadows: _treasureTextShadows),
              ),
            ],
          ),
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

    // Tier the crest + avatar + name sizing on the number of tied
    // crews. Sizes are unchanged from the previous pass (user was
    // happy with them at 5-way); only the INTER-CREW spacing was
    // bumped tier-by-tier to fill more of the ~1872px kiosk body
    // width — the 3/4/5-way rows sit around 95% now, and the 2-way
    // row spreads the two crews further apart without touching
    // portrait sizes.
    //
    // Verified widths per tier (approx):
    //   2 crews × (2×220 + 20) + 1×200 = 1120  (60%)
    //   3 crews × (2×255 + 20) + 2×100 = 1790  (96%)
    //   4 crews × (2×182 + 20) + 3× 80 = 1776  (95%)
    //   5 crews × (2×140 + 20) + 4× 70 = 1780  (95%)
    final int tieCount = winnerTeamIds.length;
    final double crestSize;
    final double avatarSize;
    final double nameFontSize;
    final double interCrewSpacing;
    if (tieCount <= 2) {
      crestSize = 80;
      avatarSize = 220;
      nameFontSize = 26;
      interCrewSpacing = 200;
    } else if (tieCount <= 3) {
      crestSize = 90;
      avatarSize = 255;
      nameFontSize = 28;
      interCrewSpacing = 100;
    } else if (tieCount <= 4) {
      crestSize = 70;
      avatarSize = 182;
      nameFontSize = 22;
      interCrewSpacing = 80;
    } else {
      crestSize = 55;
      avatarSize = 140;
      nameFontSize = 18;
      interCrewSpacing = 70;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitleWithOutline('DIVIDED TREASURE!'),
        // Title / subtitle spacing tightened to 2 (was 12) so the two
        // lines read as one unit — matches the solo tie title group.
        const SizedBox(height: 2),
        Text(
          'A TIE BETWEEN CREWS',
          style: GoogleFonts.pirataOne(
              fontSize: 24,
              color: _sailWhite,
              shadows: _treasureTextShadows),
          textAlign: TextAlign.center,
        ),
        // Subtitle → crew group gap tightened (40 → 0). The tied
        // crew group starts with a crest (80px at 2-way tie), which
        // already adds visual bulk between the subtitle and the
        // avatars — leaving a 40px SizedBox on top of that made the
        // team tie feel much more spacious than the solo tie's
        // 70px subtitle→avatar gap. Dropping the SizedBox brings
        // the subtitle-to-avatar-top distance from ~132 down to ~92,
        // as close as we can get to the solo tie's 70 without
        // shrinking the crest.
        const SizedBox(height: 0),

        // Tied crew groups — each crew renders as a "team badge above
        // the middle of its 2 member avatars" pattern (mirrors the
        // team single winner layout). The decorative "&" separator
        // between crests was dropped per user; crews now sit in a
        // Wrap with generous inter-crew spacing.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: interCrewSpacing,
          runSpacing: 20,
          children: [
            for (final teamId in winnerTeamIds)
              _buildTiedCrewColumn(
                game,
                playerProvider,
                teamId,
                teamIds,
                crestSize: crestSize,
                avatarSize: avatarSize,
                nameFontSize: nameFontSize,
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Treasure only — halved/quartered tally intentionally omitted
        // (same rationale as the solo tie): tied crews share the
        // treasure total but often reach it via different halve
        // histories, so a single number would be misleading. Per-crew
        // halve counts still appear on each scorecard row below.
        Text(
          'Crew Treasure: $treasure gold each',
          key: TreasureDivideResultsKeys.treasureScore,
          style: GoogleFonts.merriweather(
              fontSize: 18,
              color: _treasureGold,
              fontWeight: FontWeight.bold,
              shadows: _treasureTextShadows),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTiedCrewColumn(
    TreasureDivideGame game,
    PlayerProvider playerProvider,
    String teamId,
    List<String> teamIdList, {
    required double crestSize,
    required double avatarSize,
    required double nameFontSize,
  }) {
    final crestIdx = teamIdList.indexOf(teamId);
    final crestPath = (crestIdx >= 0 && crestIdx < game.teamCrestPaths.length)
        ? game.teamCrestPaths[crestIdx]
        : null;
    final members = game.teamPlayers[teamId] ?? [];

    // Column-centered layout puts the crest above the middle of the
    // crew's avatar row automatically (Row's mainAxisSize.min +
    // Column's crossAxisAlignment.center align the crest to the
    // horizontal center of the avatar row below).
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Crest — the team badge sits above the middle of the two
        // member avatars, matching the team single winner treatment.
        Container(
          key: TreasureDivideResultsKeys.winnerCrewCrest,
          width: crestSize,
          height: crestSize,
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
                    errorBuilder: (_, __, ___) => Icon(Icons.shield,
                        color: _treasureGold, size: crestSize * 0.55),
                  ),
                )
              : Icon(Icons.shield,
                  color: _treasureGold, size: crestSize * 0.55),
        ),
        const SizedBox(height: 12),
        // Two crew-member portraits side by side with names below —
        // same pattern as the team single winner, tier-sized so the
        // group fits alongside up to 4 other tied crews.
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < members.length; i++) ...[
              if (i > 0) const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(builder: (context) {
                    final pid = members[i];
                    final memberPlayer =
                        playerProvider.getPlayerById(pid);
                    if (memberPlayer == null) {
                      return _buildAvatarCircle(pid, size: avatarSize);
                    }
                    return PirateAvatarWidget(
                      player: memberPlayer,
                      themeIndex: game.playerPirateThemes[pid] ?? 0,
                      size: avatarSize,
                      isActive: true,
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: avatarSize,
                    child: Text(
                      playerProvider.getPlayerById(members[i])?.name ??
                          members[i],
                      style: GoogleFonts.pirataOne(
                          fontSize: nameFontSize,
                          color: _sailWhite,
                          shadows: _treasureTextShadows),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
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

    // No outer container — each ranking row provides its own
    // background; wrapping them in a padded, bordered box was just
    // stealing vertical space and making the rankings feel penned
    // in against the winner section.
    return Column(
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
                const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            margin: const EdgeInsets.only(bottom: 6),
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
                  width: 44,
                  child: Text(
                    '${globalIndex + 1}.',
                    style: GoogleFonts.pirataOne(
                        fontSize: 24,
                        color: _treasureGold,
                        shadows: _treasureTextShadows),
                  ),
                ),
                // Avatar + name on one row — matches the team
                // scorecard structure (avatar 48 + Flexible name)
                // so the two ranking layouts read as siblings and
                // the row height shrinks in step with team's.
                // Solo drops the crest slot (no crew badge) and
                // renders just the single player instead of
                // iterating members.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PirateAvatarWidget(
                          player: player,
                          themeIndex: game.playerPirateThemes[playerId] ?? 0,
                          size: 48,
                          isActive: false,
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            player.name,
                            style: GoogleFonts.pirataOne(
                                fontSize: 22,
                                color: _sailWhite,
                                shadows: _treasureTextShadows),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
                          fontSize: 17,
                          color: _treasureGold,
                          fontWeight: FontWeight.bold,
                          shadows: _treasureTextShadows),
                    ),
                    Text(
                      '$halvedLabel: $timesHalved',
                      style: GoogleFonts.merriweather(
                          fontSize: 14,
                          color: _halveCoral,
                          fontWeight: FontWeight.w600,
                          shadows: _treasureTextShadows),
                    ),
                  ],
                ),
                if (isWinner) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _islandGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'WIN',
                      style: GoogleFonts.pirataOne(
                          fontSize: 14,
                          color: _sailWhite,
                          shadows: _treasureTextShadows),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
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

    // No outer container — see _buildSoloRankingColumn for rationale.
    return Column(
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
                const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            margin: const EdgeInsets.only(bottom: 6),
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
                  width: 44,
                  child: Text(
                    '${index + 1}.',
                    style: GoogleFonts.pirataOne(
                        fontSize: 24,
                        color: _treasureGold,
                        shadows: _treasureTextShadows),
                  ),
                ),
                // Crest — matched to the solo ranking avatar size
                // (both dropped 20% for scorecard breathing room).
                SizedBox(
                  width: 54,
                  height: 54,
                  child: crestPath != null
                      ? Image.asset(crestPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.shield, color: _treasureGold, size: 38))
                      : Icon(Icons.shield, color: _treasureGold, size: 38),
                ),
                const SizedBox(width: 12),
                // Team members — themed pirate avatar to the LEFT of
                // the name. Names use Flexible (loose) so they take
                // only their intrinsic width, which pulls the SECOND
                // member's avatar LEFT to a fixed 40px gap after the
                // first name — instead of anchoring each member to
                // an equal half-share of the row (which parked the
                // second member's avatar much further right on
                // short-name pairs).
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (int i = 0; i < members.length; i++) ...[
                          if (i > 0) const SizedBox(width: 40),
                          Builder(builder: (context) {
                            final pid = members[i];
                            final memberPlayer =
                                playerProvider.getPlayerById(pid);
                            if (memberPlayer == null) {
                              return const SizedBox(width: 48, height: 48);
                            }
                            return PirateAvatarWidget(
                              player: memberPlayer,
                              themeIndex:
                                  game.playerPirateThemes[pid] ?? 0,
                              size: 48,
                              isActive: false,
                            );
                          }),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              playerProvider
                                      .getPlayerById(members[i])
                                      ?.name ??
                                  members[i],
                              style: GoogleFonts.pirataOne(
                                  fontSize: 22,
                                  color: _sailWhite,
                                  shadows: _treasureTextShadows),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                          fontSize: 17,
                          color: _treasureGold,
                          fontWeight: FontWeight.bold,
                          shadows: _treasureTextShadows),
                    ),
                    Text(
                      '$halvedLabel: $timesHalved',
                      style: GoogleFonts.merriweather(
                          fontSize: 14,
                          color: _halveCoral,
                          fontWeight: FontWeight.w600,
                          shadows: _treasureTextShadows),
                    ),
                  ],
                ),
                if (isWinner) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _islandGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'WIN',
                      style: GoogleFonts.pirataOne(
                          fontSize: 14,
                          color: _sailWhite,
                          shadows: _treasureTextShadows),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
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
          width: 300,
          height: 60,
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
                  fontSize: 32,
                  color: _sailWhite,
                  shadows: _treasureTextShadows),
            ),
          ),
        ),

        // CHANGE COURSE
        SizedBox(
          width: 300,
          height: 60,
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
                  fontSize: 32,
                  color: _oceanTeal,
                  shadows: _treasureButtonGoldShadows),
            ),
          ),
        ),

        // DOCK HOME
        SizedBox(
          width: 300,
          height: 60,
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
                  fontSize: 32,
                  color: _sailWhite,
                  shadows: _treasureTextShadows),
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
    // SAIL AGAIN: launch a fresh game with the SAME settings, players,
    // and (for manual team mode) team assignments. Skip the setup
    // screen entirely — that's what CHANGE COURSE is for. Random team
    // mode reshuffles crews on each launch (menu behavior).
    //
    // Order matters: startGame BEFORE the navigation so the fresh game
    // is already on the provider when the game screen mounts. Pattern
    // mirrors Tiki Golf's results screen.
    provider.startGame(
      playerIds: List<String>.from(game.playerIds),
      numberOfRounds: game.numberOfRounds,
      quarterItEnabled: game.quarterItEnabled,
      customTargetsEnabled: game.customTargetsEnabled,
      gameMode: game.gameMode,
      teamAssignment: game.teamAssignment,
      teamCount: game.teamCount,
      manualTeamAssignments:
          game.teamAssignment == TreasureDivideTeamAssignment.manual
              ? Map<String, String>.from(game.playerTeamAssignments)
              : null,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TreasureDivideGameScreen()),
    );
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
        // Outline layer (rendered behind with slight offsets) — kept
        // for the plank-brown edge; the top gold layer carries the
        // same drop-shadow + teal glow the game screen uses so the
        // headline pops off the wooden background.
        for (final offset in [
          const Offset(-2.5, -2.5),
          const Offset(2.5, -2.5),
          const Offset(-2.5, 2.5),
          const Offset(2.5, 2.5),
        ])
          Transform.translate(
            offset: offset,
            child: Text(
              text,
              style: GoogleFonts.pirataOne(
                  fontSize: 54, color: _plankBrown),
              textAlign: TextAlign.center,
            ),
          ),
        Text(
          text,
          style: GoogleFonts.pirataOne(
              fontSize: 54,
              color: _treasureGold,
              shadows: _treasureTextShadows),
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
