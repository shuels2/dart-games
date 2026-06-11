import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/treasure_divide_game.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/treasure_divide_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/player_list_panel/team_player_list_panel.dart';
import '../../../widgets/player_list_panel/team_player_list_panel_config.dart';
import '../../../widgets/resume_game_button.dart';
import '../../../widgets/resume_game_modal/resume_game_modal.dart';

// ─── Color palette ────────────────────────────────────────────────────────────
const Color _treasureGold = Color(0xFFFFD700);
const Color _oceanTeal = Color(0xFF008B8B);
const Color _plankBrown = Color(0xFF8B6914);
const Color _sailWhite = Color(0xFFFFF8E7);
// ignore: unused_element
const Color _bloodRed = Color(0xFFC41E3A);
// ignore: unused_element
const Color _islandGreen = Color(0xFF228B22);

/// All 6 available team crest paths (index-locked per asset_paths.md).
const _kAllCrestPaths = [
  'assets/games/treasure_divide/teams/CrossedCutlasses.png',
  'assets/games/treasure_divide/teams/GoldDoubloon.png',
  'assets/games/treasure_divide/teams/CompassRose.png',
  'assets/games/treasure_divide/teams/ShipsWheel.png',
  'assets/games/treasure_divide/teams/Anchor.png',
  'assets/games/treasure_divide/teams/Kraken.png',
];

// ─── TreasureDivideMenuScreen ─────────────────────────────────────────────────

class TreasureDivideMenuScreen extends StatefulWidget {
  // Settings restored on Change-Settings navigation (Rule §8)
  final TreasureDivideGameMode? initialGameMode;
  final TreasureDivideTeamAssignment? initialTeamAssignment;
  final int? initialTeamCount;
  final int? initialNumberOfRounds;
  final bool? initialQuarterIt;
  final bool? initialCustomTargets;
  final List<String>? initialSelectedPlayerIds;
  final Map<String, String>? initialPlayerTeamAssignments;

  const TreasureDivideMenuScreen({
    super.key,
    this.initialGameMode,
    this.initialTeamAssignment,
    this.initialTeamCount,
    this.initialNumberOfRounds,
    this.initialQuarterIt,
    this.initialCustomTargets,
    this.initialSelectedPlayerIds,
    this.initialPlayerTeamAssignments,
  });

  @override
  State<TreasureDivideMenuScreen> createState() =>
      _TreasureDivideMenuScreenState();
}

class _TreasureDivideMenuScreenState extends State<TreasureDivideMenuScreen> {
  // ─── Settings state ───────────────────────────────────────────────────────
  TreasureDivideGameMode _gameMode = TreasureDivideGameMode.solo;
  TreasureDivideTeamAssignment _teamAssignment =
      TreasureDivideTeamAssignment.random;
  int _teamCount = 2;
  int _numberOfRounds = 9;
  bool _quarterIt = false;
  bool _customTargets = false;

  // ─── Player/team state ────────────────────────────────────────────────────
  Map<String, String> _playerTeamAssignments = {};

  // Crests shuffled once at initState so icons vary game to game.
  // 5 crests max (one per team slot — max 5 crews).
  List<String> _activeCrestPaths = [];

  // ─── Resume state ─────────────────────────────────────────────────────────
  bool _hasSavedGames = false;
  bool _showResumeModal = false;

  // ─── initState ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Shuffle crests and take first 5 (max teams = 5 crews)
    final allCrests = List<String>.from(_kAllCrestPaths)..shuffle();
    _activeCrestPaths = allCrests.take(5).toList();

    // Hydrate settings from widget params ONLY — no provider.currentGame
    // fallback (Rule §8: fresh-entry defaults when params are null).
    _gameMode = widget.initialGameMode ?? TreasureDivideGameMode.solo;
    _teamAssignment =
        widget.initialTeamAssignment ?? TreasureDivideTeamAssignment.random;
    _teamCount = widget.initialTeamCount ?? 2;
    _numberOfRounds = widget.initialNumberOfRounds ?? 9;
    _quarterIt = widget.initialQuarterIt ?? false;
    _customTargets = widget.initialCustomTargets ?? false;
    _playerTeamAssignments =
        Map.from(widget.initialPlayerTeamAssignments ?? {});

    // Post-frame: load players, clear stale selection (Rule §34/§41),
    // re-select previous players if provided (Rule §8 round-trip), then
    // check for saved games (auto-opens modal on first entry only).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.loadPlayers();
      // Guard after async HTTP roundtrip — widget may have been disposed
      // (user navigated back, test teardown, etc.) (Rule §72).
      if (!mounted) return;
      playerProvider.clearSelection();

      // Re-select players from initialSelectedPlayerIds (Change-Settings round-trip)
      if (widget.initialSelectedPlayerIds != null) {
        final maxP = _gameMode == TreasureDivideGameMode.team ? 10 : 8;
        for (final id in widget.initialSelectedPlayerIds!) {
          final player = playerProvider.allPlayers
              .where((p) => p.id == id)
              .firstOrNull;
          if (player != null) {
            playerProvider.selectPlayer(player, maxPlayers: maxP);
          }
        }
      }

      final hasSaved =
          await SaveGameService().hasSavedGames('treasure_divide');
      if (mounted) {
        setState(() {
          _hasSavedGames = hasSaved;
          _showResumeModal = hasSaved; // auto-open on initial entry ONLY
        });
      }
    });
  }

  /// Refresh the Resume button state. Called after returning from the game
  /// screen. Does NOT re-open the modal (auto-popup is initial-entry only).
  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('treasure_divide');
    if (mounted) {
      setState(() => _hasSavedGames = hasSaved);
    }
  }

  // ─── Computed helpers ─────────────────────────────────────────────────────

  bool _canStart(List selectedPlayers) {
    final n = selectedPlayers.length;
    if (_gameMode == TreasureDivideGameMode.solo) {
      return n >= 2;
    }
    // Team mode
    if (n < 3) return false;
    if (_teamAssignment == TreasureDivideTeamAssignment.manual) {
      // Every selected player must have a team assignment
      final allAssigned =
          selectedPlayers.every((p) => _playerTeamAssignments.containsKey(p.id));
      if (!allAssigned) return false;
      // At least 2 distinct crews
      final usedTeams = _playerTeamAssignments.values.toSet();
      if (usedTeams.length < 2) return false;
      // No crew can have more than 2 players (doubles format)
      for (final teamId in usedTeams) {
        final count = _playerTeamAssignments.values
            .where((t) => t == teamId)
            .length;
        if (count > 2) return false;
      }
      // At least teamCount distinct crews represented
      if (usedTeams.length < _teamCount) return false;
    }
    return true;
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _startGame(List selectedPlayers) {
    final provider = context.read<TreasureDivideProvider>();
    final playerProvider = context.read<PlayerProvider>();

    int actualTeamCount = _teamCount;
    Map<String, String>? actualAssignments;

    if (_gameMode == TreasureDivideGameMode.team) {
      if (_teamAssignment == TreasureDivideTeamAssignment.random) {
        // Provider startGame will shuffle + deal; no manual map needed.
        final dist = TreasureDivideProvider.randomDistribution(
            playerProvider.selectedPlayers.length);
        actualTeamCount = dist.teamCount;
        actualAssignments = null;
      } else {
        actualAssignments = Map.from(_playerTeamAssignments);
      }
    }

    provider.startGame(
      playerIds: playerProvider.selectedPlayers.map((p) => p.id).toList(),
      numberOfRounds: _numberOfRounds,
      quarterItEnabled: _quarterIt,
      customTargetsEnabled: _customTargets,
      gameMode: _gameMode,
      teamAssignment: _teamAssignment,
      teamCount: actualTeamCount,
      manualTeamAssignments: actualAssignments,
    );

    // Rule §19: push (not replace) so menu stays on back-stack for
    // back/save navigation.
    Navigator.of(context)
        .pushNamed('/treasure-divide/game')
        .then((_) => _checkForSavedGames());
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();

    return Stack(
      children: [
        // ── 1. Scaffold ───────────────────────────────────────────────────
        Scaffold(
          appBar: _buildAppBar(),
          body: Consumer<PlayerProvider>(
            builder: (context, pp, _) {
              if (pp.isLoading) {
                // Rule §34 — spinner while player list loads
                return const Center(child: CircularProgressIndicator());
              }
              return Stack(
                children: [
                  // a. Background image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/games/treasure_divide/images/TreasureDivide-Background.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: _oceanTeal),
                    ),
                  ),
                  // b. 65% Ocean Teal overlay (AR-1 h — mandatory)
                  Positioned.fill(
                    child: Container(
                        color: _oceanTeal.withOpacity(0.65)),
                  ),
                  // c. Foreground content
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Rule §58 — top-align panels
                          children: [
                            // Left panel — Captain's Log (~50%)
                            SizedBox(
                              width: constraints.maxWidth * 0.50,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 16, left: 16),
                                child: _buildCaptainsLog(),
                              ),
                            ),
                            // Right panel — settings + player list + Set Sail
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    8, 16, 16, 16), // Rule §59 — asymmetric gap
                                child: _buildRightPanel(pp),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── 2. ResumeGameModal (conditional) ─────────────────────────────
        if (_showResumeModal)
          ResumeGameModal(
            config: ResumeGameModalConfig.treasureDivide(),
            gameType: 'treasure_divide',
            onStartNewGame: () {
              setState(() => _showResumeModal = false);
              _checkForSavedGames();
            },
            onResumeGame: (savedGame) {
              setState(() => _showResumeModal = false);
              context.read<TreasureDivideProvider>().restoreGame(savedGame);
              Navigator.of(context)
                  .pushNamed('/treasure-divide/game')
                  .then((_) => _checkForSavedGames());
            },
            onClose: () {
              setState(() => _showResumeModal = false);
              _checkForSavedGames();
            },
          ),

        // ── 3. DartboardPausedModal (last child — paints on top) ──────────
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status !=
                DartboardConnectionStatus.connected &&
            dartboardProvider.status !=
                DartboardConnectionStatus.emulator)
          DartboardPausedModal(
            config: DartboardPausedModalConfig.treasureDivide(),
          ),
      ],
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        key: TreasureDivideMenuKeys.backButton,
        icon: const Icon(Icons.arrow_back, color: _treasureGold, size: 32),
        onPressed: () => Navigator.of(context).pop(),
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      title: Text(
        'TREASURE DIVIDE SETUP',
        style: GoogleFonts.pirataOne(fontSize: 38, color: _treasureGold),
      ),
      centerTitle: false,
      backgroundColor: _oceanTeal,
      actions: [
        // ResumeGameButton — LEFT of DartboardConnectionInfo (Rule from docs)
        ResumeGameButton(
          key: TreasureDivideMenuKeys.resumeGameButton,
          hasSavedGames: _hasSavedGames,
          onPressed: () => setState(() => _showResumeModal = true),
          color: _treasureGold,
        ),
        const SizedBox(width: 4),
        DartboardConnectionInfo(
          config: DartboardConnectionInfoConfig.treasureDivide(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── Left panel: Captain's Log ────────────────────────────────────────────

  Widget _buildCaptainsLog() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.80),
        border: Border.all(color: _plankBrown, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(
                "CAPTAIN'S LOG",
                style: GoogleFonts.pirataOne(
                  fontSize: 38,
                  color: _treasureGold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '⚓ ════════════════ ⚓',
                style: GoogleFonts.pirataOne(
                  fontSize: 20,
                  color: _treasureGold.withOpacity(0.7),
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Rules list
            _logBody(
              children: [
                _logRule(
                  '1.',
                  'Each round targets a different number on the dartboard '
                      '— sail from island to island on the treasure map.',
                ),
                _logRule(
                  '2.',
                  'Throw 3 darts at the round\'s target number. Every dart '
                      'that hits scores its face value — singles, doubles, '
                      'and triples all count!',
                ),
                _logRule(
                  '3.',
                  'Miss all 3 darts and your treasure goes overboard '
                      '— HALF your gold is lost! Hit at least one dart '
                      'and you keep everything you earned.',
                ),
                _logRule(
                  '4.',
                  'Special rounds:\n'
                      '🎯 Any Double — hit any double ring\n'
                      '🏆 Any Triple — hit any triple ring\n'
                      '☠️  Bull — Treasure Island! Hit the bullseye',
                ),
                _logRule(
                  '5.',
                  'After all rounds, the pirate with the most gold is '
                      'crowned Pirate Captain!',
                ),
              ],
            ),

            const SizedBox(height: 8),
            _logSectionHeader('⚓ OPTIONAL PERILS:'),
            const SizedBox(height: 4),
            _logBody(
              children: [
                _logBullet(
                  boldPart: 'Quarter It',
                  rest: ' — Feeling cruel, Captain? When ON, missing all 3 darts '
                      'doesn\'t just halve your gold — a merciless storm sinks '
                      'three-quarters of your treasure into the deep!',
                ),
                _logBullet(
                  boldPart: 'Custom Targets',
                  rest: ' — Sail into uncharted waters! Each island\'s target '
                      'stays hidden until your crew reaches it. More adventure, '
                      'less strategy.',
                ),
              ],
            ),

            const SizedBox(height: 8),
            _logSectionHeader('⚓ FOR YOUNG PIRATES:'),
            const SizedBox(height: 4),
            _logBody(
              children: [
                _logBullet(
                    boldPart: '7 rounds',
                    rest: ' for a quicker adventure'),
                _logBullet(
                    boldPart: 'Pirate crews',
                    rest:
                        ' — share treasure and protect each other from halving!'),
                _logBullet(
                    boldPart: 'Any Double',
                    rest:
                        ' and Any Triple rounds let you aim anywhere on the board'),
              ],
            ),

            const SizedBox(height: 8),
            _logSectionHeader('⚓ QUICK STRATEGY:'),
            const SizedBox(height: 4),
            _logBody(
              children: [
                _logBullet(
                    boldPart: 'Triple rings',
                    rest: ' — when confident, aim Triple-20 = 60 gold!'),
                _logBullet(
                    boldPart: 'Any Double rounds',
                    rest: ' — target Double-20 for maximum haul'),
                _logBullet(
                    boldPart: 'Low score?',
                    rest:
                        ' Sometimes the risk is worth it — halving zero is still zero!'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logSectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.pirataOne(
        fontSize: 30,
        color: _treasureGold,
      ),
    );
  }

  Widget _logBody({required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _logRule(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number ',
            style: GoogleFonts.merriweather(
              fontSize: 17,
              color: _treasureGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.merriweather(
                fontSize: 17,
                color: _sailWhite,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logBullet({required String boldPart, required String rest}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.merriweather(
                fontSize: 17, color: _sailWhite),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: boldPart,
                    style: GoogleFonts.merriweather(
                      fontSize: 17,
                      color: _treasureGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: rest,
                    style: GoogleFonts.merriweather(
                      fontSize: 17,
                      color: _sailWhite,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Right panel: settings + player list + SET SAIL ──────────────────────

  Widget _buildRightPanel(PlayerProvider pp) {
    final selectedPlayers = pp.selectedPlayers;
    final canStart = _canStart(selectedPlayers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Settings grid (2 rows)
        _buildSettingsGrid(),
        const SizedBox(height: 8),

        // Player list — panel returns Expanded itself when useFixedHeight: false
        // (matches Tiki Golf menu, line ~520). Wrapping in another Expanded
        // produces a Competing ParentDataWidgets error.
        TeamPlayerListPanel(
          config: TeamPlayerListPanelConfig.treasureDivide(),
          addPlayerButtonKey: TreasureDivideMenuKeys.addPlayerButton,
          addPlayerButtonEmptyStateKey:
              TreasureDivideMenuKeys.addPlayerButtonEmptyState,
          playerListViewKey: TreasureDivideMenuKeys.playerListView,
          playerTileKey: (id) => TreasureDivideMenuKeys.playerTile(id),
          isTeamMode: _gameMode == TreasureDivideGameMode.team,
          isManualTeamAssignment:
              _teamAssignment == TreasureDivideTeamAssignment.manual,
          teamIconPaths: _activeCrestPaths,
          useFixedHeight: false,
          teamDialogContainerKey:
              TreasureDivideMenuKeys.teamDialogContainer,
          teamDialogDropdownKey: (id) =>
              TreasureDivideMenuKeys.teamDialogDropdown(id),
          teamDialogCancelKey: TreasureDivideMenuKeys.teamDialogCancel,
          onTeamAssignmentsChanged: (assignments) {
            setState(() {
              _playerTeamAssignments = Map.from(assignments);
            });
          },
        ),

        const SizedBox(height: 8),

        // SET SAIL! button
        ElevatedButton(
          key: TreasureDivideMenuKeys.startGameButton,
          onPressed: canStart ? () => _startGame(selectedPlayers) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _treasureGold,
            foregroundColor: _oceanTeal,
            disabledBackgroundColor: _treasureGold.withOpacity(0.35),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            elevation: 4,
          ),
          child: Text(
            'SET SAIL!',
            style: GoogleFonts.pirataOne(
              fontSize: 34,
              color: canStart ? _oceanTeal : _oceanTeal.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Settings grid ────────────────────────────────────────────────────────

  Widget _buildSettingsGrid() {
    return Column(
      children: [
        // Row 1: Game Mode | Team Assignment
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildGameModeBox()),
              const SizedBox(width: 8),
              Expanded(child: _buildTeamAssignmentBox()),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Row 2: Rounds | Quarter It | Custom Targets
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildRoundsBox()),
              const SizedBox(width: 8),
              Expanded(child: _buildQuarterItBox()),
              const SizedBox(width: 8),
              Expanded(child: _buildCustomTargetsBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsBox({required Widget child}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _oceanTeal.withOpacity(0.90),
        border: Border.all(color: _plankBrown, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: child),
    );
  }

  // ── Game Mode box ──────────────────────────────────────────────────────────

  Widget _buildGameModeBox() {
    final isTeam = _gameMode == TreasureDivideGameMode.team;
    return _buildSettingsBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SOLO | TEAM toggle
          Row(
            key: TreasureDivideMenuKeys.gameModeToggle,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Game Mode',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 17,
                    color: _sailWhite,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    key: TreasureDivideMenuKeys.gameModeSolo,
                    onTap: () => setState(
                        () => _gameMode = TreasureDivideGameMode.solo),
                    child: Text(
                      'SOLO',
                      style: GoogleFonts.merriweather(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: !isTeam
                            ? _treasureGold
                            : _sailWhite.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.70,
                    child: Switch(
                      value: isTeam,
                      activeColor: _treasureGold,
                      onChanged: (v) => setState(() {
                        _gameMode = v
                            ? TreasureDivideGameMode.team
                            : TreasureDivideGameMode.solo;
                      }),
                    ),
                  ),
                  GestureDetector(
                    key: TreasureDivideMenuKeys.gameModeTeam,
                    onTap: () => setState(
                        () => _gameMode = TreasureDivideGameMode.team),
                    child: Text(
                      'TEAM',
                      style: GoogleFonts.merriweather(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isTeam
                            ? _treasureGold
                            : _sailWhite.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Inline Crews dropdown — only visible when Team + Manual
          if (isTeam &&
              _teamAssignment == TreasureDivideTeamAssignment.manual) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Crews',
                  style: GoogleFonts.merriweather(
                    fontSize: 17,
                    color: _sailWhite.withOpacity(0.85),
                  ),
                ),
                DropdownButton<int>(
                  key: TreasureDivideMenuKeys.teamCountDropdown,
                  value: _teamCount,
                  dropdownColor: const Color(0xFF005F5F),
                  style: GoogleFonts.merriweather(
                    fontSize: 17,
                    color: _treasureGold,
                    fontWeight: FontWeight.w700,
                  ),
                  underline: Container(
                      height: 1, color: _plankBrown),
                  items: [2, 3, 4, 5]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _teamCount = v);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Team Assignment box ────────────────────────────────────────────────────

  Widget _buildTeamAssignmentBox() {
    final isTeam = _gameMode == TreasureDivideGameMode.team;
    final isManual = _teamAssignment == TreasureDivideTeamAssignment.manual;
    return Opacity(
      opacity: isTeam ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !isTeam,
        child: _buildSettingsBox(
          child: Row(
            key: TreasureDivideMenuKeys.assignmentModeToggle,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Team Assignment',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 17,
                    color: _sailWhite,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    key: TreasureDivideMenuKeys.assignmentModeRandom,
                    onTap: isTeam
                        ? () => setState(() => _teamAssignment =
                            TreasureDivideTeamAssignment.random)
                        : null,
                    child: Text(
                      'RANDOM',
                      style: GoogleFonts.merriweather(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: !isManual
                            ? _treasureGold
                            : _sailWhite.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.70,
                    child: Switch(
                      value: isManual,
                      activeColor: _treasureGold,
                      onChanged: isTeam
                          ? (v) => setState(() {
                                _teamAssignment = v
                                    ? TreasureDivideTeamAssignment.manual
                                    : TreasureDivideTeamAssignment.random;
                              })
                          : null,
                    ),
                  ),
                  GestureDetector(
                    key: TreasureDivideMenuKeys.assignmentModeManual,
                    onTap: isTeam
                        ? () => setState(() => _teamAssignment =
                            TreasureDivideTeamAssignment.manual)
                        : null,
                    child: Text(
                      'MANUAL',
                      style: GoogleFonts.merriweather(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isManual
                            ? _treasureGold
                            : _sailWhite.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rounds dropdown ────────────────────────────────────────────────────────

  Widget _buildRoundsBox() {
    return _buildSettingsBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Rounds',
            style: GoogleFonts.merriweather(
              fontSize: 17,
              color: _sailWhite,
            ),
          ),
          DropdownButton<int>(
            key: TreasureDivideMenuKeys.roundsDropdown,
            value: _numberOfRounds,
            dropdownColor: const Color(0xFF005F5F),
            style: GoogleFonts.merriweather(
              fontSize: 17,
              color: _treasureGold,
              fontWeight: FontWeight.w700,
            ),
            underline: Container(height: 1, color: _plankBrown),
            items: [7, 9, 12]
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text('$v'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _numberOfRounds = v);
            },
          ),
        ],
      ),
    );
  }

  // ── Quarter It switch ──────────────────────────────────────────────────────

  Widget _buildQuarterItBox() {
    return _buildSettingsBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'Quarter It',
              style: GoogleFonts.merriweather(
                fontSize: 17,
                color: _sailWhite,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.80,
                child: Switch(
                  key: TreasureDivideMenuKeys.quarterItSwitch,
                  value: _quarterIt,
                  activeColor: _treasureGold,
                  onChanged: (v) => setState(() => _quarterIt = v),
                ),
              ),
              Text(
                _quarterIt ? 'ON' : 'OFF',
                style: GoogleFonts.merriweather(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _quarterIt
                      ? _treasureGold
                      : _sailWhite.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Custom Targets switch ──────────────────────────────────────────────────

  Widget _buildCustomTargetsBox() {
    return _buildSettingsBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'Custom Targets',
              style: GoogleFonts.merriweather(
                fontSize: 17,
                color: _sailWhite,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.80,
                child: Switch(
                  key: TreasureDivideMenuKeys.customTargetsSwitch,
                  value: _customTargets,
                  activeColor: _treasureGold,
                  onChanged: (v) => setState(() => _customTargets = v),
                ),
              ),
              Text(
                _customTargets ? 'ON' : 'OFF',
                style: GoogleFonts.merriweather(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _customTargets
                      ? _treasureGold
                      : _sailWhite.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
