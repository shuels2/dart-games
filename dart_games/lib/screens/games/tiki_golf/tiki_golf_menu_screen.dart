import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/saved_game_metadata.dart';
import '../../../models/tiki_golf_game.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/tiki_golf_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/player_list_panel/team_player_list_panel.dart';
import '../../../widgets/player_list_panel/team_player_list_panel_config.dart';
import '../../../widgets/resume_game_button.dart';
import '../../../widgets/resume_game_modal/resume_game_modal.dart';
import 'tiki_golf_game_screen.dart';

// ─── Color palette ────────────────────────────────────────────────────────────
const Color _lagoonBlue = Color(0xFF00B4D8);
const Color _palmGreen = Color(0xFF2D6A4F);
const Color _tikiBrown = Color(0xFF8B5E3C);
// ignore: unused_element
const Color _hibiscusPink = Color(0xFFFF69B4); // used in Pass 2/3 — kept for palette completeness
const Color _sandWhite = Color(0xFFFFF5E1);
const Color _tropicalOrange = Color(0xFFFF8C42); // substitution — NOT 0xFFFF6B35
// ignore: unused_element
const Color _skyBlue = Color(0xFF87CEEB);
// ignore: unused_element
const Color _coconutCream = Color(0xFFFFFDD0);

/// Shadow applied to key display labels (4-corner outline text shadow).
List<Shadow> _labelShadow(Color color) => [
      Shadow(color: color, offset: const Offset(1, 1), blurRadius: 0),
      Shadow(color: color, offset: const Offset(-1, -1), blurRadius: 0),
      Shadow(color: color, offset: const Offset(1, -1), blurRadius: 0),
      Shadow(color: color, offset: const Offset(-1, 1), blurRadius: 0),
    ];

/// All 6 available team crest paths (shuffled at initState, 4 used).
const _kAllCrestPaths = [
  'assets/games/tiki_golf/teams/Sharks.png',
  'assets/games/tiki_golf/teams/SeaTurtles.png',
  'assets/games/tiki_golf/teams/Hibiscus.png',
  'assets/games/tiki_golf/teams/Volcanoes.png',
  'assets/games/tiki_golf/teams/Coconuts.png',
  'assets/games/tiki_golf/teams/Parrots.png',
];

class TikiGolfMenuScreen extends StatefulWidget {
  // Settings restored on Change-Settings navigation (Rule §8)
  final TikiGolfGameMode? initialGameMode;
  final TikiGolfTeamAssignment? initialTeamAssignment;
  final int? initialTeamCount;
  final int? initialMaxStrokes;
  final bool? initialMulliganEnabled;
  final List<String>? initialSelectedPlayerIds;
  final Map<String, String>? initialManualTeamAssignments;

  const TikiGolfMenuScreen({
    super.key,
    this.initialGameMode,
    this.initialTeamAssignment,
    this.initialTeamCount,
    this.initialMaxStrokes,
    this.initialMulliganEnabled,
    this.initialSelectedPlayerIds,
    this.initialManualTeamAssignments,
  });

  @override
  State<TikiGolfMenuScreen> createState() => _TikiGolfMenuScreenState();
}

class _TikiGolfMenuScreenState extends State<TikiGolfMenuScreen> {
  // ─── Settings state ───────────────────────────────────────────────────────
  TikiGolfGameMode _gameMode = TikiGolfGameMode.solo;
  TikiGolfTeamAssignment _teamAssignment = TikiGolfTeamAssignment.random;
  int _teamCount = 4;
  int _maxStrokes = 3;
  bool _mulliganEnabled = false;

  // ─── Player / team state ──────────────────────────────────────────────────
  final Map<String, String> _playerTeamAssignments = {};

  // Team icon paths — shuffled once at init so icons vary game to game.
  // Only 4 of the 6 available crests are shown (first 4 after shuffle).
  List<String> _teamIconPaths = [];

  // ─── Resume game state ────────────────────────────────────────────────────
  bool _hasSavedGames = false;
  bool _showResumeModal = false;
  bool _initialSavedCheckDone = false;

  @override
  void initState() {
    super.initState();

    // Shuffle 6 crests and pick first 4 for this game session
    final allCrests = List<String>.from(_kAllCrestPaths)..shuffle();
    _teamIconPaths = allCrests.take(4).toList();

    // Restore settings from prior game (Change-Settings nav) or widget params
    final lastGame = context.read<TikiGolfProvider>().currentGame;
    _gameMode =
        widget.initialGameMode ?? lastGame?.gameMode ?? TikiGolfGameMode.solo;
    _teamAssignment = widget.initialTeamAssignment ??
        lastGame?.teamAssignment ??
        TikiGolfTeamAssignment.random;
    _teamCount = widget.initialTeamCount ?? lastGame?.teamCount ?? 4;
    _maxStrokes = widget.initialMaxStrokes ?? lastGame?.maxStrokes ?? 3;
    _mulliganEnabled =
        widget.initialMulliganEnabled ?? lastGame?.mulliganEnabled ?? false;

    if (widget.initialManualTeamAssignments != null) {
      _playerTeamAssignments.addAll(widget.initialManualTeamAssignments!);
    }

    // Post-frame: load players, clear cross-game stale selection (Rule §41/§34),
    // re-select prior selection if provided, then check saved games.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.loadPlayers();
      playerProvider.clearSelection();

      if (widget.initialSelectedPlayerIds != null) {
        final maxP =
            _gameMode == TikiGolfGameMode.team ? 16 : 4;
        for (final id in widget.initialSelectedPlayerIds!) {
          final player = playerProvider.allPlayers
              .where((p) => p.id == id)
              .firstOrNull;
          if (player != null) {
            playerProvider.selectPlayer(player, maxPlayers: maxP);
          }
        }
      }

      _checkForSavedGames();
    });
  }

  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('tiki_golf');
    if (mounted) {
      setState(() {
        _hasSavedGames = hasSaved;
        if (hasSaved && !_initialSavedCheckDone) {
          _showResumeModal = true;
          _initialSavedCheckDone = true;
        }
      });
    }
  }

  // ─── Computed helpers ─────────────────────────────────────────────────────

  /// Whether the TEE OFF button should be enabled.
  bool _canStart(List selectedPlayers) {
    final n = selectedPlayers.length;
    if (_gameMode == TikiGolfGameMode.solo) {
      return n >= 2 && n <= 4;
    }
    // Team mode
    if (n < 3) return false;
    if (_teamAssignment == TikiGolfTeamAssignment.manual) {
      // All selected players must be assigned
      final allAssigned =
          selectedPlayers.every((p) => _playerTeamAssignments.containsKey(p.id));
      if (!allAssigned) return false;
      // No team can be empty
      final usedTeams = _playerTeamAssignments.values.toSet();
      // At least 2 teams must have players
      if (usedTeams.length < 2) return false;
    }
    return true;
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void _startGame(List selectedPlayers) {
    final provider = context.read<TikiGolfProvider>();

    Map<String, String>? manualAssignments;
    if (_gameMode == TikiGolfGameMode.team &&
        _teamAssignment == TikiGolfTeamAssignment.manual) {
      manualAssignments = Map.from(_playerTeamAssignments);
    }

    provider.startGame(
      playerIds: selectedPlayers.map<String>((p) => p.id).toList(),
      maxStrokes: _maxStrokes,
      mulliganEnabled: _mulliganEnabled,
      gameMode: _gameMode,
      teamAssignment: _teamAssignment,
      teamCount: _gameMode == TikiGolfGameMode.team ? _teamCount : null,
      manualTeamAssignments: manualAssignments,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TikiGolfGameScreen()),
    ).then((_) => _checkForSavedGames()); // Rule §19
  }

  void _resumeGame(SavedGameMetadata savedGame) {
    context.read<TikiGolfProvider>().restoreGame(savedGame);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TikiGolfGameScreen()),
    ).then((_) => _checkForSavedGames()); // Rule §19
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final isLoading = playerProvider.isLoading;

    return Stack(
      children: [
        Scaffold(
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              // Background image with Palm Green overlay
              const Positioned.fill(
                child: Image(
                  image: AssetImage(
                      'assets/games/tiki_golf/images/TikiGolf-Background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                    color: _palmGreen.withOpacity(0.60)),
              ),
              // Content
              if (isLoading)
                const Center(child: CircularProgressIndicator()) // Rule §34
              else
                _buildMainContent(playerProvider),
            ],
          ),
        ),
        // Resume game modal (covers entire screen incl. AppBar)
        if (_showResumeModal)
          ResumeGameModal(
            config: ResumeGameModalConfig.tikiGolf(),
            gameType: 'tiki_golf',
            onStartNewGame: () {
              setState(() => _showResumeModal = false);
              _checkForSavedGames();
            },
            onResumeGame: (savedGame) {
              setState(() => _showResumeModal = false);
              _resumeGame(savedGame);
            },
            onClose: () {
              setState(() => _showResumeModal = false);
              _checkForSavedGames();
            },
          ),
        // Dartboard paused modal — last child, paints on top
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status != DartboardConnectionStatus.connected &&
            dartboardProvider.status != DartboardConnectionStatus.emulator)
          DartboardPausedModal(
            config: DartboardPausedModalConfig.tikiGolf(),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _tikiBrown,
      foregroundColor: _sandWhite,
      leading: IconButton(
        key: TikiGolfMenuKeys.backButton,
        icon: const Icon(Icons.arrow_back, color: _sandWhite, size: 32),
        onPressed: () => Navigator.of(context).pop(),
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      title: Text(
        'TIKI GOLF SETUP',
        style: GoogleFonts.boogaloo(
          fontSize: 34,
          color: _sandWhite,
          shadows: _labelShadow(_tikiBrown),
        ),
      ),
      actions: [
        // Resume game button (only when saved games exist)
        ResumeGameButton(
          key: TikiGolfMenuKeys.resumeGameButton,
          hasSavedGames: _hasSavedGames,
          onPressed: () => setState(() => _showResumeModal = true),
          color: _sandWhite,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: DartboardConnectionInfo(
            config: DartboardConnectionInfoConfig.tikiGolf(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(PlayerProvider playerProvider) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 800) {
        // Tablet/desktop: left "How To Play" (43.7% — was 38%, +15% per user)
        // + right panel (remaining ~56.3%)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start, // top-align so left panel doesn't stretch full-height
          children: [
            SizedBox(
              width: constraints.maxWidth * 0.437,
              // 16px top inset matches the right panel's `EdgeInsets.all(16)`
              // top padding, so the how-to container's top edge aligns with
              // the top edge of the first option row.
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 16),
                child: _buildLeftPanel(),
              ),
            ),
            Expanded(child: _buildRightPanel(playerProvider, scrollable: false)),
          ],
        );
      } else {
        // Mobile: single column with scroll
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildLeftPanel(),
              _buildRightPanel(playerProvider),
            ],
          ),
        );
      }
    });
  }

  // ─── Left panel: How To Play ──────────────────────────────────────────────

  Widget _buildLeftPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _palmGreen.withOpacity(0.82),
        border: Border.all(color: _tikiBrown.withOpacity(0.55), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TIKI GOLF',
              style: GoogleFonts.boogaloo(
                fontSize: 46,
                color: _sandWhite,
                shadows: _labelShadow(_tikiBrown),
              ),
            ),
            Text(
              'Tropical Dart Golf!',
              style: GoogleFonts.boogaloo(
                fontSize: 28,
                color: _tropicalOrange,
                shadows: _labelShadow(_tikiBrown),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'HOW TO PLAY',
              style: GoogleFonts.boogaloo(
                fontSize: 30,
                color: _sandWhite,
                shadows: _labelShadow(_tikiBrown),
              ),
            ),
            const SizedBox(height: 8),
            _buildHowToStep('1', 'Hit each hole target:',
                'Each game shuffles 9 holes — every hole gets a random dartboard number as its target.'),
            _buildHowToStep('2', 'Tee off!',
                'On your turn, throw darts at the hole\'s target number. Each dart is one stroke. You can change the Max Strokes per hole in the options.'),
            _buildHowToStep('3', 'Score like golf:',
                'Hit the target on dart 1 = Birdie! Dart 2 = Par. Dart 3+ = Bogey. Miss all darts = Splash (worst score)!'),
            _buildHowToStep('4', 'Lowest score wins:',
                'Play all 9 holes and tally up. Lowest total stroke count wins the Golden Tiki trophy!'),
            const SizedBox(height: 16),
            Text(
              'TEAM MODE',
              style: GoogleFonts.boogaloo(
                fontSize: 28,
                color: _lagoonBlue,
                shadows: _labelShadow(_tikiBrown),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'In Team mode, everyone still plays every hole. Your team\'s score for each hole is the BEST (lowest) score among your teammates. Lowest team total wins — and everyone on the winning team gets credit!',
              style: GoogleFonts.nunito(
                fontSize: 20,
                color: _sandWhite,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: GoogleFonts.boogaloo(
              fontSize: 22,
              color: _tropicalOrange,
              shadows: _labelShadow(_tikiBrown),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.nunito(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: _sandWhite,
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      color: _sandWhite.withOpacity(0.85),
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

  // ─── Right panel: settings + player list + TEE OFF ───────────────────────

  Widget _buildRightPanel(PlayerProvider playerProvider,
      {bool scrollable = true}) {
    final selectedPlayers = playerProvider.selectedPlayers;
    final canStart = _canStart(selectedPlayers);

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Settings grid (2×2)
        _buildSettingsGrid(),
        const SizedBox(height: 8),

        // Player list panel (single list, team-assignment via shared widget).
        // Header (label + ADD PLAYER) gets 12px horizontal indent via the
        // config's headerPadding so the visible header content aligns with
        // the option labels / values above. The list rows themselves stay
        // at full panel width (per user — list layout was correct as-is).
        // No outer Expanded wrapper — when useFixedHeight is false the panel
        // wraps its content in its own Expanded internally; an additional
        // outer Expanded triggers a ParentDataWidget conflict.
        TeamPlayerListPanel(
          config: TeamPlayerListPanelConfig.tikiGolf(),
          addPlayerButtonKey: TikiGolfMenuKeys.addPlayerButton,
          addPlayerButtonEmptyStateKey:
              TikiGolfMenuKeys.addPlayerButtonEmptyState,
          playerListViewKey: TikiGolfMenuKeys.playerListView,
          playerTileKey: (id) => TikiGolfMenuKeys.playerTile(id),
          isTeamMode: _gameMode == TikiGolfGameMode.team,
          isManualTeamAssignment:
              _teamAssignment == TikiGolfTeamAssignment.manual,
          teamIconPaths: _teamIconPaths,
          useFixedHeight: scrollable,
          teamDialogContainerKey: TeamAssignmentDialogKeys.dialogContainer,
          teamDialogDropdownKey: (id) =>
              TeamAssignmentDialogKeys.playerTeamDropdown(id),
          teamDialogCancelKey: TeamAssignmentDialogKeys.cancelButton,
          onTeamAssignmentsChanged: (assignments) {
            setState(() {
              _playerTeamAssignments.clear();
              _playerTeamAssignments.addAll(assignments);
            });
          },
        ),

        const SizedBox(height: 8),

        // TEE OFF button
        _buildTeeOffButton(canStart, selectedPlayers),
      ],
    );

    return Container(
      // Left padding 8 (was 16) per user — halves the gap between the
      // how-to-play container and the options/player list.
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: scrollable
          ? SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - kToolbarHeight - 80,
                child: column,
              ),
            )
          : column,
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
        // Row 2: Max Strokes | Mulligan
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildMaxStrokesBox()),
              const SizedBox(width: 8),
              Expanded(child: _buildMulliganBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsBox({required Widget child, bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _palmGreen.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? _lagoonBlue : _tikiBrown,
          width: 2,
        ),
      ),
      // Vertically center the label + control inside the box.
      child: Center(child: child),
    );
  }

  Widget _buildGameModeBox() {
    final isTeam = _gameMode == TikiGolfGameMode.team;
    return _buildSettingsBox(
      highlighted: isTeam,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Game Mode',
                style: GoogleFonts.boogaloo(
                  fontSize: 22,
                  color: _sandWhite,
                  shadows: _labelShadow(_tikiBrown),
                ),
              ),
              Row(
                key: TikiGolfMenuKeys.gameModeToggle,
                mainAxisSize: MainAxisSize.min,
                children: [
              GestureDetector(
                key: TikiGolfMenuKeys.gameModeSolo,
                onTap: () =>
                    setState(() => _gameMode = TikiGolfGameMode.solo),
                child: Text(
                  'SOLO',
                  style: GoogleFonts.boogaloo(
                    fontSize: 20,
                    color: !isTeam ? _lagoonBlue : _sandWhite.withOpacity(0.5),
                    fontWeight: !isTeam ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isTeam,
                  activeColor: _lagoonBlue,
                  onChanged: (value) => setState(() {
                    _gameMode = value
                        ? TikiGolfGameMode.team
                        : TikiGolfGameMode.solo;
                  }),
                ),
              ),
              GestureDetector(
                key: TikiGolfMenuKeys.gameModeTeam,
                onTap: () =>
                    setState(() => _gameMode = TikiGolfGameMode.team),
                child: Text(
                  'TEAM',
                  style: GoogleFonts.boogaloo(
                    fontSize: 20,
                    color: isTeam ? _lagoonBlue : _sandWhite.withOpacity(0.5),
                    fontWeight: isTeam ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
                ],
              ),
            ],
          ),
          // Team Count dropdown removed per user — defaults to 4 teams.
          // _teamCount state still exists and is used downstream when
          // building the game; just not user-configurable from the menu.
        ],
      ),
    );
  }

  Widget _buildTeamAssignmentBox() {
    final isTeam = _gameMode == TikiGolfGameMode.team;
    final isManual = _teamAssignment == TikiGolfTeamAssignment.manual;
    return Opacity(
      opacity: isTeam ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !isTeam,
        child: _buildSettingsBox(
          highlighted: isTeam && isManual,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Team Assignment',
                style: GoogleFonts.boogaloo(
                  fontSize: 22,
                  color: _sandWhite,
                  shadows: _labelShadow(_tikiBrown),
                ),
              ),
              Row(
                key: TikiGolfMenuKeys.assignmentModeToggle,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    key: TikiGolfMenuKeys.assignmentModeManual,
                    onTap: isTeam
                        ? () => setState(() =>
                            _teamAssignment = TikiGolfTeamAssignment.manual)
                        : null,
                    child: Text(
                      'MANUAL',
                      style: GoogleFonts.boogaloo(
                        fontSize: 20,
                        color: isManual
                            ? _lagoonBlue
                            : _sandWhite.withOpacity(0.5),
                        fontWeight:
                            isManual ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: !isManual, // ON = Random
                      activeColor: _lagoonBlue,
                      onChanged: isTeam
                          ? (value) => setState(() {
                                _teamAssignment = value
                                    ? TikiGolfTeamAssignment.random
                                    : TikiGolfTeamAssignment.manual;
                              })
                          : null,
                    ),
                  ),
                  GestureDetector(
                    key: TikiGolfMenuKeys.assignmentModeRandom,
                    onTap: isTeam
                        ? () => setState(() =>
                            _teamAssignment = TikiGolfTeamAssignment.random)
                        : null,
                    child: Text(
                      'RANDOM',
                      style: GoogleFonts.boogaloo(
                        fontSize: 20,
                        color: !isManual
                            ? _lagoonBlue
                            : _sandWhite.withOpacity(0.5),
                        fontWeight:
                            !isManual ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildMaxStrokesBox() {
    return _buildSettingsBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Max Strokes',
            style: GoogleFonts.boogaloo(
              fontSize: 22,
              color: _sandWhite,
              shadows: _labelShadow(_tikiBrown),
            ),
          ),
          DropdownButton<int>(
            key: TikiGolfMenuKeys.maxStrokesDropdown,
            value: _maxStrokes,
            dropdownColor: _palmGreen,
            underline: const SizedBox(),
            style: GoogleFonts.boogaloo(
              fontSize: 20,
              color: _sandWhite,
            ),
            items: [3, 4, 5, 6]
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        '$v',
                        style: GoogleFonts.boogaloo(
                          fontSize: 20,
                          color: _sandWhite,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _maxStrokes = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMulliganBox() {
    return _buildSettingsBox(
      highlighted: _mulliganEnabled,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label + parenthetical subtitle on a single line so this box
          // matches the height of the top-row option boxes.
          Flexible(
            child: RichText(
              overflow: TextOverflow.visible,
              text: TextSpan(children: [
                TextSpan(
                  text: 'Mulligan ',
                  style: GoogleFonts.boogaloo(
                    fontSize: 22,
                    color: _sandWhite,
                    shadows: _labelShadow(_tikiBrown),
                  ),
                ),
                TextSpan(
                  text: '(1 do-over per player)',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: _sandWhite.withOpacity(0.75),
                  ),
                ),
              ]),
            ),
          ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'OFF',
                    style: GoogleFonts.boogaloo(
                      fontSize: 20,
                      color: !_mulliganEnabled
                          ? _lagoonBlue
                          : _sandWhite.withOpacity(0.5),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      key: TikiGolfMenuKeys.mulliganSwitch,
                      value: _mulliganEnabled,
                      activeColor: _lagoonBlue,
                      onChanged: (v) => setState(() => _mulliganEnabled = v),
                    ),
                  ),
                  Text(
                    'ON',
                    style: GoogleFonts.boogaloo(
                      fontSize: 20,
                      color: _mulliganEnabled
                          ? _lagoonBlue
                          : _sandWhite.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  // ─── TEE OFF button ───────────────────────────────────────────────────────

  Widget _buildTeeOffButton(bool canStart, List selectedPlayers) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        key: TikiGolfMenuKeys.startGameButton,
        onPressed: canStart ? () => _startGame(selectedPlayers) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canStart
              ? _lagoonBlue
              : _lagoonBlue.withOpacity(0.5),
          foregroundColor: _sandWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: canStart ? 4 : 0,
        ),
        child: Text(
          'TEE OFF!',
          style: GoogleFonts.boogaloo(
            fontSize: 28,
            color: _sandWhite,
            shadows: _labelShadow(_tikiBrown),
          ),
        ),
      ),
    );
  }
}
