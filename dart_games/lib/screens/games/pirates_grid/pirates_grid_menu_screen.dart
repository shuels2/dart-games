import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/pirates_grid_game.dart';
import '../../../models/saved_game_metadata.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/pirates_grid_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import '../../../widgets/player_list_panel/dual_player_list_panel.dart';
import '../../../widgets/player_list_panel/dual_player_list_panel_config.dart';
import '../../../widgets/resume_game_button.dart';
import '../../../widgets/resume_game_modal/resume_game_modal.dart';
import '../../../widgets/resume_game_modal/resume_game_modal_config.dart';
import 'pirates_grid_game_screen.dart';

class PiratesGridMenuScreen extends StatefulWidget {
  final TargetDifficulty? initialDifficulty;
  final int? initialBestOf;
  final bool? initialStealMode;
  final bool? initialSpeedPlay;
  final List<String>? initialSelectedPlayerIds;

  const PiratesGridMenuScreen({
    super.key,
    this.initialDifficulty,
    this.initialBestOf,
    this.initialStealMode,
    this.initialSpeedPlay,
    this.initialSelectedPlayerIds,
  });

  @override
  State<PiratesGridMenuScreen> createState() => _PiratesGridMenuScreenState();
}

class _PiratesGridMenuScreenState extends State<PiratesGridMenuScreen> {
  // Options
  TargetDifficulty _difficulty = TargetDifficulty.easy;
  int _bestOf = 1;
  bool _stealMode = false;
  bool _speedPlay = false;

  // Resume game state
  bool _hasSavedGames = false;
  bool _showResumeModal = false;

  // Palette
  static const Color _oceanNavy = Color(0xFF1B2838);
  static const Color _treasureGold = Color(0xFFDAA520);
  static const Color _compassBronze = Color(0xFFCD7F32);
  static const Color _parchmentTan = Color(0xFFF5E6C8);


  @override
  void initState() {
    super.initState();

    // Restore settings — prefer explicitly passed values (from results screen
    // "NEW VOYAGE"), then fall back to provider's currentGame (re-entry via
    // back button during a game), then keep defaults.
    final lastGame = context.read<PiratesGridProvider>().currentGame;
    _difficulty = widget.initialDifficulty ??
        lastGame?.targetDifficulty ??
        TargetDifficulty.easy;
    _bestOf = widget.initialBestOf ?? lastGame?.bestOf ?? 1;
    _stealMode = widget.initialStealMode ?? lastGame?.stealMode ?? false;
    _speedPlay = widget.initialSpeedPlay ?? lastGame?.speedPlay ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Refresh player roster and clear cross-game selection leak
      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.loadPlayers();
      playerProvider.clearSelection();

      // Re-select players from the previous game if provided (NEW VOYAGE path)
      if (widget.initialSelectedPlayerIds != null) {
        for (final id in widget.initialSelectedPlayerIds!) {
          final player = playerProvider.allPlayers
              .where((p) => p.id == id)
              .firstOrNull;
          if (player != null) {
            playerProvider.selectPlayer(player, maxPlayers: 2);
          }
        }
      }

      // Initial saved-games check + auto-open resume modal
      final hasSaved = await SaveGameService().hasSavedGames('pirates_grid');
      if (mounted) {
        setState(() {
          _hasSavedGames = hasSaved;
          _showResumeModal = hasSaved;
        });
      }
    });
  }

  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('pirates_grid');
    if (mounted) {
      setState(() => _hasSavedGames = hasSaved);
    }
  }

  void _resumeGame(SavedGameMetadata savedGame) {
    context.read<PiratesGridProvider>().restoreGame(savedGame);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PiratesGridGameScreen()),
    ).then((_) => _checkForSavedGames());
  }

  void _startGame() {
    final playerProvider = context.read<PlayerProvider>();
    final selectedPlayers = playerProvider.selectedPlayers;
    if (selectedPlayers.length != 2) return;

    context.read<PiratesGridProvider>().startGame(
          selectedPlayers.map((p) => p.id).toList(),
          _difficulty,
          _bestOf,
          _stealMode,
          _speedPlay,
        );

    // Use push (not pushReplacement) so the menu stays on the route stack.
    // That way:
    //   - back-button on game screen pops to menu (with settings preserved)
    //   - Save modal's onSave pops to menu
    // Game→results uses its own pushReplacement, NEW VOYAGE on results uses
    // pushAndRemoveUntil(route.isFirst); both flows are unaffected.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PiratesGridGameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _oceanNavy,
          appBar: AppBar(
            backgroundColor: _oceanNavy,
            leading: IconButton(
              key: PiratesGridMenuKeys.backButton,
              icon: const Icon(
                Icons.arrow_back,
                color: _treasureGold,
                size: 32,
              ),
              onPressed: () => Navigator.of(context).pop(),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            title: Text(
              "PIRATE'S GRID GAME SETUP",
              style: GoogleFonts.pirataOne(
                color: _treasureGold,
                fontSize: 35,
                letterSpacing: 1.5,
              ),
            ),
            actions: [
              if (_hasSavedGames)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ResumeGameButton(
                    hasSavedGames: _hasSavedGames,
                    onPressed: () => setState(() => _showResumeModal = true),
                    color: _treasureGold,
                  ),
                ),
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
              // Ocean Navy 65% overlay
              Positioned.fill(
                child: Container(
                  color: const Color(0xA61B2838),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 40,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: _buildLeftPanel(),
                          ),
                        ),
                        Expanded(
                          flex: 60,
                          child: _buildRightPanel(scrollable: false),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLeftPanel(),
                          _buildRightPanel(),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        // Resume game modal overlay
        if (_showResumeModal)
          ResumeGameModal(
            config: ResumeGameModalConfig.piratesGrid(),
            gameType: 'pirates_grid',
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
            config: DartboardPausedModalConfig.piratesGrid(),
          ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 0, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _oceanNavy.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _compassBronze, width: 2),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOW TO PLAY',
              style: GoogleFonts.pirataOne(
                fontSize: 46,
                color: _treasureGold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Claim cells on a 3×3 grid by hitting the required dart targets. '
              'Get three in a row to win the round!',
              style: GoogleFonts.lora(
                fontSize: 20,
                color: _parchmentTan,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildHowToStep('1', 'Take Aim:',
                'Each turn you get 3 darts to hit the targets shown in the grid cells.'),
            _buildHowToStep('2', 'Plant Your Flag:',
                'Hit a cell\'s target to claim it — your flag appears in that cell.'),
            _buildHowToStep('3', 'Three in a Row:',
                'Get three flags in a row (horizontally, vertically, or diagonally) to win the round.'),
            _buildHowToStep('4', 'Best Of:',
                'In a Best Of 3 or 5 match, win the required number of rounds to become Captain!'),
            _buildHowToStep('5', 'Steal Mode:',
                'With Steal Mode ON, you can hit an opponent\'s cell to take it for yourself!'),
            const SizedBox(height: 16),
            Text(
              'BEGINNER TIPS',
              style: GoogleFonts.pirataOne(
                fontSize: 38,
                color: _treasureGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Start with Easy difficulty and Steal Mode OFF.'),
            _buildBulletPoint('Focus on the center cell — it\'s part of 4 winning lines!'),
            _buildBulletPoint('Block your opponent\'s two-in-a-row before completing your own.'),
            _buildBulletPoint('In Best Of 3+, alternate the starting player each round.'),
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
            style: GoogleFonts.pirataOne(
              fontSize: 26,
              color: _compassBronze,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _parchmentTan,
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      color: _parchmentTan.withOpacity(0.85),
                      height: 1.5,
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚓ ',
            style: GoogleFonts.lora(
              fontSize: 18,
              color: _compassBronze,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lora(
                fontSize: 18,
                color: _parchmentTan.withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel({bool scrollable = true}) {
    final playerProvider = context.watch<PlayerProvider>();
    final selectedPlayers = playerProvider.selectedPlayers;
    final canStart = selectedPlayers.length == 2;

    const double gap = 6.0;

    // DualPlayerListPanel wrapper — Expanded for wide, SizedBox for narrow
    final Widget playerPanelWrapper = scrollable
        ? SizedBox(
            height: 400,
            child: DualPlayerListPanel(
              config: DualPlayerListPanelConfig.piratesGrid(),
              addPlayerButtonKey: PiratesGridMenuKeys.addPlayerButton,
              addPlayerButtonEmptyStateKey:
                  PiratesGridMenuKeys.addPlayerButtonEmptyState,
              playerListViewKey: PiratesGridMenuKeys.playerListView,
              playerTileKey: (id) => PiratesGridMenuKeys.playerTile(id),
              removePlayerButtonKey: (id) =>
                  PiratesGridMenuKeys.removePlayerButton(id),
            ),
          )
        : Expanded(
            child: DualPlayerListPanel(
              config: DualPlayerListPanelConfig.piratesGrid(),
              addPlayerButtonKey: PiratesGridMenuKeys.addPlayerButton,
              addPlayerButtonEmptyStateKey:
                  PiratesGridMenuKeys.addPlayerButtonEmptyState,
              playerListViewKey: PiratesGridMenuKeys.playerListView,
              playerTileKey: (id) => PiratesGridMenuKeys.playerTile(id),
              removePlayerButtonKey: (id) =>
                  PiratesGridMenuKeys.removePlayerButton(id),
            ),
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Single-row settings grid: Difficulty | Best Of | Steal Mode | Speed Play
        SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildDifficultyBox()),
              const SizedBox(width: gap),
              Expanded(child: _buildBestOfBox()),
              const SizedBox(width: gap),
              Expanded(child: _buildStealModeBox()),
              const SizedBox(width: gap),
              Expanded(child: _buildSpeedPlayBox()),
            ],
          ),
        ),
        const SizedBox(height: gap),
        // Player list panel
        playerPanelWrapper,
        const SizedBox(height: gap),
        // SET SAIL! button
        Opacity(
          opacity: canStart ? 1.0 : 0.5,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              key: PiratesGridMenuKeys.startGameButton,
              onPressed: canStart ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _compassBronze,
                foregroundColor: _parchmentTan,
                side: const BorderSide(color: _treasureGold, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'SET SAIL!',
                style: GoogleFonts.pirataOne(
                  fontSize: 40,
                  color: _parchmentTan,
                  letterSpacing: 1.5,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 24, 24, 24),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }

  Widget _buildOptionBox({
    required Widget child,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _oceanNavy.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? _treasureGold : _compassBronze.withOpacity(0.6),
          width: highlighted ? 2 : 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildDifficultyBox() {
    return _buildOptionBox(
      child: Row(
        children: [
          Text(
            'Difficulty',
            style: GoogleFonts.pirataOne(
              fontSize: 22,
              color: _parchmentTan,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TargetDifficulty>(
                key: PiratesGridMenuKeys.difficultyDropdown,
                value: _difficulty,
                dropdownColor: _oceanNavy,
                style: GoogleFonts.lora(
                  fontSize: 20,
                  color: _parchmentTan,
                  fontWeight: FontWeight.w600,
                ),
                iconEnabledColor: _treasureGold,
                isExpanded: true,
                alignment: AlignmentDirectional.centerEnd,
                items: const [
                  DropdownMenuItem(
                    value: TargetDifficulty.easy,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text('Easy'),
                  ),
                  DropdownMenuItem(
                    value: TargetDifficulty.medium,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem(
                    value: TargetDifficulty.hard,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text('Hard'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _difficulty = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestOfBox() {
    return _buildOptionBox(
      child: Row(
        children: [
          Text(
            'Best Of',
            style: GoogleFonts.pirataOne(
              fontSize: 22,
              color: _parchmentTan,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                key: PiratesGridMenuKeys.bestOfDropdown,
                value: _bestOf,
                dropdownColor: _oceanNavy,
                style: GoogleFonts.lora(
                  fontSize: 20,
                  color: _parchmentTan,
                  fontWeight: FontWeight.w600,
                ),
                iconEnabledColor: _treasureGold,
                isExpanded: true,
                alignment: AlignmentDirectional.centerEnd,
                items: const [
                  DropdownMenuItem(value: 1, alignment: AlignmentDirectional.centerEnd, child: Text('1')),
                  DropdownMenuItem(value: 3, alignment: AlignmentDirectional.centerEnd, child: Text('3')),
                  DropdownMenuItem(value: 5, alignment: AlignmentDirectional.centerEnd, child: Text('5')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _bestOf = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStealModeBox() {
    return _buildOptionBox(
      highlighted: _stealMode,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Steal Mode',
            style: GoogleFonts.pirataOne(
              fontSize: 22,
              color: _stealMode ? _treasureGold : _parchmentTan,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Off',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  color: !_stealMode ? _parchmentTan : _parchmentTan.withOpacity(0.5),
                  fontWeight: !_stealMode ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  key: PiratesGridMenuKeys.stealModeSwitch,
                  value: _stealMode,
                  activeColor: _treasureGold,
                  onChanged: (val) => setState(() => _stealMode = val),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'On',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  color: _stealMode ? _treasureGold : _parchmentTan.withOpacity(0.5),
                  fontWeight: _stealMode ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedPlayBox() {
    return _buildOptionBox(
      highlighted: _speedPlay,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Speed Play',
            style: GoogleFonts.pirataOne(
              fontSize: 22,
              color: _speedPlay ? _treasureGold : _parchmentTan,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Off',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  color: !_speedPlay ? _parchmentTan : _parchmentTan.withOpacity(0.5),
                  fontWeight: !_speedPlay ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  key: PiratesGridMenuKeys.speedPlaySwitch,
                  value: _speedPlay,
                  activeColor: _treasureGold,
                  onChanged: (val) => setState(() => _speedPlay = val),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'On',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  color: _speedPlay ? _treasureGold : _parchmentTan.withOpacity(0.5),
                  fontWeight: _speedPlay ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
