import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/player.dart';
import '../../../models/reef_royale_game.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/reef_royale_provider.dart';
import '../../../widgets/player_list_panel/player_list_panel.dart';
import '../../../constants/test_keys.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../models/saved_game_metadata.dart';
import '../../../services/save_game_service.dart';
import '../../../widgets/resume_game_modal/resume_game_modal.dart';
import '../../../widgets/resume_game_button.dart';
import 'reef_royale_game_screen.dart';

class ReefRoyaleMenuScreen extends StatefulWidget {
  final List<String>? preselectedPlayerIds;
  final ReefRoyaleGameMode? initialGameMode;
  final bool? initialEasyClaim;
  final bool? initialNeighborNumbers;
  final bool? initialRandomReefs;
  final bool? initialBonusBuffs;
  final bool? initialShowHints;
  final bool? initialSpeedPlay;
  final int? initialRoundLimit;

  const ReefRoyaleMenuScreen({
    super.key,
    this.preselectedPlayerIds,
    this.initialGameMode,
    this.initialEasyClaim,
    this.initialNeighborNumbers,
    this.initialRandomReefs,
    this.initialBonusBuffs,
    this.initialShowHints,
    this.initialSpeedPlay,
    this.initialRoundLimit,
  });

  @override
  State<ReefRoyaleMenuScreen> createState() => _ReefRoyaleMenuScreenState();
}

class _ReefRoyaleMenuScreenState extends State<ReefRoyaleMenuScreen> {
  ReefRoyaleGameMode _gameMode = ReefRoyaleGameMode.standard;
  bool _easyClaim = false;
  bool _neighborNumbers = false;
  bool _randomReefs = false;
  bool _bonusBuffs = false;
  bool _showHints = false;
  bool _speedPlay = false;
  double _roundLimit = 10.0;
  bool _showResumeModal = false;
  bool _hasSavedGames = false;
  PlayerProvider? _playerProvider;

  // Reef Royale color palette
  static const _deepReefBlue = Color(0xFF0B3D91);
  static const _seafoamGreen = Color(0xFF48D1CC);
  static const _sunlitAqua = Color(0xFF00CED1);
  static const _pearlWhite = Color(0xFFFFF8F0);
  static const _sandyGold = Color(0xFFF4D03F);
  static const _coralPink = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();

    if (widget.initialGameMode != null) _gameMode = widget.initialGameMode!;
    if (widget.initialEasyClaim != null) _easyClaim = widget.initialEasyClaim!;
    if (widget.initialNeighborNumbers != null) _neighborNumbers = widget.initialNeighborNumbers!;
    if (widget.initialRandomReefs != null) _randomReefs = widget.initialRandomReefs!;
    if (widget.initialBonusBuffs != null) _bonusBuffs = widget.initialBonusBuffs!;
    if (widget.initialShowHints != null) _showHints = widget.initialShowHints!;
    if (widget.initialSpeedPlay != null) _speedPlay = widget.initialSpeedPlay!;
    if (widget.initialRoundLimit != null) _roundLimit = widget.initialRoundLimit!.toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerProvider = context.read<PlayerProvider>();
      _playerProvider = playerProvider;
      await playerProvider.loadPlayers();
      playerProvider.clearSelection();

      if (widget.preselectedPlayerIds != null) {
        for (final playerId in widget.preselectedPlayerIds!) {
          final player = playerProvider.getPlayerById(playerId);
          if (player != null) {
            playerProvider.selectPlayer(player, maxPlayers: 8);
          }
        }
        setState(() {});
      }

      // Check for saved games
      final hasSaved = await SaveGameService().hasSavedGames('reef_royale');
      if (mounted) {
        setState(() {
          _hasSavedGames = hasSaved;
          _showResumeModal = hasSaved;
        });
      }
    });
  }

  /// Check for saved games and update button state
  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('reef_royale');
    if (mounted) {
      setState(() => _hasSavedGames = hasSaved);
    }
  }

  @override
  void dispose() {
    _playerProvider?.markPlayersSorted();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: _deepReefBlue,
          appBar: AppBar(
            leading: IconButton(
              key: ReefRoyaleMenuKeys.backButton,
              icon: const Icon(Icons.arrow_back, color: _pearlWhite, size: 32),
              onPressed: () => Navigator.of(context).pop(),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            title: Transform.translate(
              offset: const Offset(0, -3),
              child: Text(
                'Reef Royale Game Setup',
                style: GoogleFonts.fredoka(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _pearlWhite,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: _seafoamGreen.withOpacity(0.6), blurRadius: 12),
                    const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_deepReefBlue, _deepReefBlue, _seafoamGreen],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              ResumeGameButton(
                key: ReefRoyaleMenuKeys.resumeGameButton,
                hasSavedGames: _hasSavedGames,
                onPressed: () => setState(() => _showResumeModal = true),
                color: _pearlWhite,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.reefRoyale(),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/games/reef_royale/images/ReefRoyale-Background.png',
                  fit: BoxFit.cover,
                ),
              ),
              Consumer<PlayerProvider>(
                builder: (context, playerProvider, child) {
                  if (playerProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _buildLeftPanel()),
                      Expanded(flex: 1, child: _buildRightPanel(playerProvider)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        // Resume game modal overlay - covers entire screen including AppBar
        if (_showResumeModal)
          ResumeGameModal(
            config: ResumeGameModalConfig.reefRoyale(),
            gameType: 'reef_royale',
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
      ],
    );
  }

  Widget _buildLeftPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
        decoration: BoxDecoration(
          color: _deepReefBlue.withOpacity(0.85),
          border: Border.all(color: _seafoamGreen.withOpacity(0.5), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REEF ROYALE',
                  style: GoogleFonts.fredoka(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: _seafoamGreen,
                    shadows: [
                      Shadow(color: _seafoamGreen.withOpacity(0.5), blurRadius: 12),
                      const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dive into the reef and claim your coral! Hit your numbers to grow coral colonies, then harvest pearls from your rivals\' unclaimed reefs.',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _pearlWhite,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'How to Play:',
                  style: GoogleFonts.fredoka(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: _pearlWhite,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(color: _seafoamGreen.withOpacity(0.5), blurRadius: 10),
                      const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildStep('1', 'Mark Your Targets:', 'Hit a number 3 times to claim its coral (it blooms!).'),
                _buildStep('2', 'Score Pearls:', 'Once claimed, keep hitting it to score pearls while opponents haven\'t claimed it.'),
                _buildStep('3', 'Lock the Reef:', 'When ALL players claim a number, it locks — no more pearls for anyone.'),
                _buildStep('4', 'Win the Reef:', 'Claim all 7 corals AND have the most pearls to win!'),
                const SizedBox(height: 12),
                Text(
                  'Game Modes:',
                  style: GoogleFonts.fredoka(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: _pearlWhite,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(color: _seafoamGreen.withOpacity(0.5), blurRadius: 10),
                      const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildBullet('Cursed Tide:', 'A devious twist — when you score pearls, they go to your opponents instead! The winner is the player with the fewest pearls.'),
                _buildBullet('Random Reefs:', 'Shuffles the 7 target numbers each game so you never play the same reef twice. Bull is always the 7th coral.'),
                const SizedBox(height: 12),
                Text(
                  'Beginner Tips:',
                  style: GoogleFonts.fredoka(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: _pearlWhite,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(color: _seafoamGreen.withOpacity(0.5), blurRadius: 10),
                      const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildBullet('Easy Claim:', 'Only 2 marks needed instead of 3 — great for younger players!'),
                _buildBullet('Neighbor Numbers:', 'Adjacent dartboard numbers also count — more hits, more fun!'),
                _buildBullet('Show Hints:', 'Highlights valid target areas on the dartboard.'),
                const SizedBox(height: 8),
                Text(
                  'Dive in and rule the reef!',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _sandyGold,
                    height: 1.5,
                    shadows: [
                      Shadow(color: _sandyGold.withOpacity(0.5), blurRadius: 10),
                      const Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _seafoamGreen,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _pearlWhite,
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: _pearlWhite.withOpacity(0.8),
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

  Widget _buildBullet(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022 ',
            style: TextStyle(color: _seafoamGreen, fontSize: 22),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _pearlWhite,
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: _pearlWhite.withOpacity(0.8),
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

  Widget _buildRightPanel(PlayerProvider playerProvider) {
    final selectedPlayers = playerProvider.selectedPlayers;
    final bool canStart = selectedPlayers.length >= 2 && selectedPlayers.length <= 8;

    return Column(
      children: [
        // Row 1: Game Mode dropdown | Easy Claim switch
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
          child: Row(
            children: [
              Expanded(child: _buildGameModeBox()),
              const SizedBox(width: 8),
              Expanded(child: _buildSwitchBox(
                'Easy Claim',
                _easyClaim,
                ReefRoyaleMenuKeys.easyClaimSwitch,
                (value) => setState(() => _easyClaim = value),
              )),
            ],
          ),
        ),

        // Row 2: Neighbor Numbers switch | Random Reefs switch
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              Expanded(child: _buildSwitchBox(
                'Neighbor Numbers',
                _neighborNumbers,
                ReefRoyaleMenuKeys.neighborNumbersSwitch,
                (value) => setState(() => _neighborNumbers = value),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildSwitchBox(
                'Random Reefs',
                _randomReefs,
                ReefRoyaleMenuKeys.randomReefsSwitch,
                (value) => setState(() => _randomReefs = value),
              )),
            ],
          ),
        ),

        // Row 3: Bonus Buffs switch | Show Hints switch
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              Expanded(child: _buildSwitchBox(
                'Bonus Buffs',
                _bonusBuffs,
                ReefRoyaleMenuKeys.bonusBuffsSwitch,
                (value) => setState(() => _bonusBuffs = value),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildSwitchBox(
                'Show Hints',
                _showHints,
                ReefRoyaleMenuKeys.showHintsSwitch,
                (value) => setState(() => _showHints = value),
              )),
            ],
          ),
        ),

        // Row 4: Speed Play switch | Round Limit slider
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              Expanded(child: _buildSwitchBox(
                'Speed Play',
                _speedPlay,
                ReefRoyaleMenuKeys.speedPlaySwitch,
                (value) => setState(() => _speedPlay = value),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildRoundLimitBox()),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Player list panel
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: DualPlayerListPanel(
              config: DualPlayerListPanelConfig.reefRoyale(),
              addPlayerButtonKey: ReefRoyaleMenuKeys.addPlayerButton,
              addPlayerButtonEmptyStateKey: ReefRoyaleMenuKeys.addPlayerButtonEmptyState,
              playerListViewKey: ReefRoyaleMenuKeys.playerListView,
              playerTileKey: (id) => ReefRoyaleMenuKeys.playerTile(id),
            ),
          ),
        ),

        // Start button
        _buildStartButton(canStart, selectedPlayers),
      ],
    );
  }

  Widget _buildGameModeBox() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _deepReefBlue.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _gameMode == ReefRoyaleGameMode.cursedTide
              ? _coralPink
              : _seafoamGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mode',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _pearlWhite,
            ),
          ),
          DropdownButton<ReefRoyaleGameMode>(
            key: ReefRoyaleMenuKeys.gameModeDropdown,
            value: _gameMode,
            dropdownColor: _deepReefBlue,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _pearlWhite,
            ),
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: ReefRoyaleGameMode.standard,
                child: Text('Standard', style: GoogleFonts.fredoka(color: _pearlWhite)),
              ),
              DropdownMenuItem(
                value: ReefRoyaleGameMode.cursedTide,
                child: Text('Cursed Tide', style: GoogleFonts.fredoka(color: _coralPink)),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _gameMode = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchBox(
    String label,
    bool value,
    Key switchKey,
    ValueChanged<bool> onChanged, {
    Color activeColor = _seafoamGreen,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _deepReefBlue.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? _sandyGold : _seafoamGreen.withOpacity(0.3),
          width: value ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: value ? _pearlWhite : _pearlWhite.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Off',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: !value ? FontWeight.bold : FontWeight.normal,
                  color: !value ? _pearlWhite : _pearlWhite.withOpacity(0.4),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  key: switchKey,
                  value: value,
                  activeColor: _sandyGold,
                  activeTrackColor: _sandyGold.withOpacity(0.5),
                  inactiveThumbColor: _pearlWhite.withOpacity(0.5),
                  inactiveTrackColor: _deepReefBlue.withOpacity(0.5),
                  onChanged: onChanged,
                ),
              ),
              Text(
                'On',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                  color: value ? _sandyGold : _pearlWhite.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundLimitBox() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _speedPlay
            ? _deepReefBlue.withOpacity(0.85)
            : _deepReefBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _speedPlay
              ? _seafoamGreen.withOpacity(0.3)
              : _seafoamGreen.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Rounds: ${_roundLimit.toInt()}',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _speedPlay ? _pearlWhite : _pearlWhite.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              key: ReefRoyaleMenuKeys.roundLimitSlider,
              value: _roundLimit,
              min: 5,
              max: 20,
              divisions: 15,
              label: _roundLimit.toInt().toString(),
              activeColor: _sandyGold,
              onChanged: _speedPlay
                  ? (value) => setState(() => _roundLimit = value)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(bool canStart, List<Player> selectedPlayers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: canStart
              ? [
                  BoxShadow(color: _seafoamGreen.withOpacity(0.6), blurRadius: 16, spreadRadius: 2),
                  BoxShadow(color: _seafoamGreen.withOpacity(0.3), blurRadius: 32, spreadRadius: 4),
                ]
              : [],
        ),
        child: ElevatedButton(
          key: ReefRoyaleMenuKeys.startGameButton,
          onPressed: canStart ? () => _startGame(selectedPlayers) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canStart ? _seafoamGreen : _deepReefBlue,
            foregroundColor: canStart ? _deepReefBlue : _pearlWhite.withOpacity(0.5),
            disabledBackgroundColor: _deepReefBlue.withOpacity(0.85),
            disabledForegroundColor: _pearlWhite.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: canStart ? _pearlWhite.withOpacity(0.5) : _seafoamGreen.withOpacity(0.3),
                width: 2,
              ),
            ),
            elevation: canStart ? 8 : 2,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'DI'),
                TextSpan(text: ' ', style: TextStyle(fontSize: 2, letterSpacing: 0)),
                TextSpan(text: 'VE IN!'),
              ],
            ),
            style: GoogleFonts.fredoka(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              shadows: canStart
                  ? [
                      Shadow(color: _deepReefBlue.withOpacity(0.4), blurRadius: 4, offset: const Offset(1, 1)),
                    ]
                  : [],
            ),
          ),
        ),
      ),
    );
  }

  void _resumeGame(SavedGameMetadata savedGame) {
    context.read<ReefRoyaleProvider>().restoreGame(savedGame);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReefRoyaleGameScreen()),
    ).then((_) => _checkForSavedGames());
  }

  void _startGame(List<Player> selectedPlayers) {
    final reefRoyaleProvider = context.read<ReefRoyaleProvider>();

    reefRoyaleProvider.startGame(
      selectedPlayers,
      _gameMode,
      _easyClaim,
      _neighborNumbers,
      _randomReefs,
      _bonusBuffs,
      _showHints,
      _speedPlay,
      _roundLimit.toInt(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReefRoyaleGameScreen(),
      ),
    ).then((_) => _checkForSavedGames());
  }
}
