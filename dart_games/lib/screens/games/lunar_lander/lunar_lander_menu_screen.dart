import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/saved_game_metadata.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/lunar_lander_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/player_list_panel/dual_player_list_panel.dart';
import '../../../widgets/player_list_panel/dual_player_list_panel_config.dart';
import '../../../widgets/resume_game_button.dart';
import '../../../widgets/resume_game_modal/resume_game_modal.dart';
import '../../../widgets/resume_game_modal/resume_game_modal_config.dart';
import 'lunar_lander_game_screen.dart';

class LunarLanderMenuScreen extends StatefulWidget {
  const LunarLanderMenuScreen({super.key});

  @override
  State<LunarLanderMenuScreen> createState() => _LunarLanderMenuScreenState();
}

class _LunarLanderMenuScreenState extends State<LunarLanderMenuScreen> {
  // Options
  double _startingAltitude = 200.0;
  bool _hardLandingEnabled = false;

  // Resume game state
  bool _hasSavedGames = false;
  bool _showResumeModal = false;

  static const Color _spaceBlack = Color(0xFF0D1B2A);
  static const Color _rocketFlame = Color(0xFFF26430);
  static const Color _earthBlue = Color(0xFF1B4965);
  static const Color _starWhite = Color(0xFFFAFDF6);

  @override
  void initState() {
    super.initState();

    // Restore settings from the most recent game (if any). The provider
    // retains `currentGame` after a game finishes, and CHANGE MISSION on the
    // results screen pushes a fresh menu without clearing it. Reading those
    // values here makes the menu remember the user's last settings instead
    // of resetting to defaults.
    final lastGame = context.read<LunarLanderProvider>().currentGame;
    if (lastGame != null) {
      _startingAltitude = lastGame.startingAltitude.toDouble();
      _hardLandingEnabled = lastGame.hardLandingEnabled;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initial saved-games check on menu open: if any saved Lunar Lander
      // game exists, auto-open the resume modal. Subsequent re-checks (after
      // games complete or user actions) only update _hasSavedGames; they do
      // NOT auto-open the modal. Mirrors the Clockwork Quest pattern.
      final hasSaved = await SaveGameService().hasSavedGames('lunar_lander');
      if (mounted) {
        setState(() {
          _hasSavedGames = hasSaved;
          _showResumeModal = hasSaved;
        });
      }
    });
  }

  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('lunar_lander');
    if (mounted) {
      setState(() => _hasSavedGames = hasSaved);
    }
  }

  void _resumeGame(SavedGameMetadata savedGame) {
    context.read<LunarLanderProvider>().restoreGame(savedGame);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LunarLanderGameScreen()),
    ).then((_) => _checkForSavedGames());
  }

  void _startGame() {
    final playerProvider = context.read<PlayerProvider>();
    final selectedPlayers = playerProvider.selectedPlayers;
    if (selectedPlayers.length < 2) return;

    final provider = context.read<LunarLanderProvider>();
    provider.startGame(
      playerIds: selectedPlayers.map((p) => p.id).toList(),
      startingAltitude: _startingAltitude.toInt(),
      hardLandingEnabled: _hardLandingEnabled,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LunarLanderGameScreen()),
    ).then((_) => _checkForSavedGames());
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: _spaceBlack,
          appBar: AppBar(
            leading: IconButton(
              key: LunarLanderMenuKeys.backButton,
              icon: const Icon(Icons.arrow_back, color: _starWhite, size: 32),
              onPressed: () => Navigator.of(context).pop(),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            title: Text(
              'LUNAR LANDER GAME SETUP',
              style: GoogleFonts.orbitron(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _starWhite,
                letterSpacing: 1.5,
              ),
            ),
            backgroundColor: _earthBlue,
            foregroundColor: _starWhite,
            actions: [
              if (_hasSavedGames)
                ResumeGameButton(
                  hasSavedGames: _hasSavedGames,
                  onPressed: () => setState(() => _showResumeModal = true),
                  color: _starWhite,
                ),
              DartboardConnectionInfo(
                config: DartboardConnectionInfoConfig.lunarLander(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // Background image with dark overlay
              Positioned.fill(
                child: Image.asset(
                  'assets/games/lunar_lander/images/LunarLander-Background.png',
                  fit: BoxFit.cover,
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
        // Resume game modal overlay — covers entire screen including AppBar
        if (_showResumeModal)
          ResumeGameModal(
            config: ResumeGameModalConfig.lunarLander(),
            gameType: 'lunar_lander',
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
        // Dartboard paused modal — last child, paints on top.
        if (!dartboardProvider.isEmulator &&
            dartboardProvider.status != DartboardConnectionStatus.connected &&
            dartboardProvider.status != DartboardConnectionStatus.emulator)
          DartboardPausedModal(
            config: DartboardPausedModalConfig.lunarLander(),
          ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 0, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _earthBlue.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _rocketFlame.withOpacity(0.5), width: 2),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOW TO PLAY',
              style: GoogleFonts.orbitron(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: _rocketFlame,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilot your astronaut from orbit to the moon! Subtract your dart scores from your '
              'altitude to descend toward the surface. The first astronaut to touch down safely '
              'wins the mission!',
              style: GoogleFonts.exo2(
                fontSize: 22,
                color: _starWhite,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildHowToStep('1', 'Set Altitude:',
                'Choose your starting altitude (100–500). Higher = longer game.'),
            _buildHowToStep('2', 'Throw Darts:',
                'Each turn you get 3 darts. Subtract the score from your current altitude.'),
            _buildHowToStep('3', 'Land Safely:',
                'Reach 0 to land. Overshooting is fine unless Hard Landing is ON.'),
            _buildHowToStep('4', 'Hard Landing:',
                'With Hard Landing ON, going below 0 is a crash — your turn is forfeited and altitude resets to turn start.'),
            const SizedBox(height: 20),
            Text(
              'Beginner Tips:',
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _rocketFlame,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
                'Start with altitude 200 and Hard Landing OFF for the most fun.'),
            _buildBulletPoint(
                'As you get better, turn Hard Landing ON for a real challenge.'),
            _buildBulletPoint(
                'Plan your last few darts carefully — exact landings win missions!'),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _rocketFlame,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.exo2(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _starWhite,
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.exo2(
                      fontSize: 22,
                      color: _starWhite.withOpacity(0.8),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.exo2(
              fontSize: 22,
              color: _rocketFlame,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.exo2(
                fontSize: 22,
                color: _starWhite.withOpacity(0.8),
                height: 1.5,
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
    final canStart = selectedPlayers.length >= 2 && selectedPlayers.length <= 8;

    // DualPlayerListPanel needs a bounded height. In wide (non-scrollable)
    // layout we use Expanded so it fills remaining vertical space. In narrow
    // (scrollable) layout we give it a fixed height since Expanded can't live
    // inside a SingleChildScrollView.
    final Widget playerPanelWrapper = scrollable
        ? SizedBox(
            height: 400,
            child: DualPlayerListPanel(
              config: DualPlayerListPanelConfig.lunarLander(),
              addPlayerButtonKey: LunarLanderMenuKeys.addPlayerButton,
              addPlayerButtonEmptyStateKey:
                  LunarLanderMenuKeys.addPlayerButtonEmptyState,
              playerListViewKey: LunarLanderMenuKeys.playerListView,
              playerTileKey: (id) => LunarLanderMenuKeys.playerTile(id),
              removePlayerButtonKey: (id) =>
                  LunarLanderMenuKeys.removePlayerButton(id),
            ),
          )
        : Expanded(
            child: DualPlayerListPanel(
              config: DualPlayerListPanelConfig.lunarLander(),
              addPlayerButtonKey: LunarLanderMenuKeys.addPlayerButton,
              addPlayerButtonEmptyStateKey:
                  LunarLanderMenuKeys.addPlayerButtonEmptyState,
              playerListViewKey: LunarLanderMenuKeys.playerListView,
              playerTileKey: (id) => LunarLanderMenuKeys.playerTile(id),
              removePlayerButtonKey: (id) =>
                  LunarLanderMenuKeys.removePlayerButton(id),
            ),
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings row — SizedBox gives both containers a shared height (Slider
        // does not support IntrinsicHeight, so we fix the height explicitly).
        SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Altitude slider box
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _spaceBlack.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _earthBlue, width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Altitude: ${_startingAltitude.toInt()}',
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _starWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          key: LunarLanderMenuKeys.altitudeSlider,
                          value: _startingAltitude,
                          min: 100,
                          max: 500,
                          divisions: 40, // (500-100)/10 = 40 steps
                          label: _startingAltitude.toInt().toString(),
                          activeColor: _rocketFlame,
                          onChanged: (value) {
                            // Snap to multiples of 10
                            setState(() => _startingAltitude =
                                (value / 10).round() * 10.0);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Hard Landing toggle box
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _spaceBlack.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _hardLandingEnabled ? _rocketFlame : _earthBlue,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hard Landing',
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _starWhite,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Off',
                            style: GoogleFonts.exo2(
                              fontSize: 13,
                              fontWeight: !_hardLandingEnabled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: !_hardLandingEnabled
                                  ? _starWhite
                                  : _starWhite.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              key: LunarLanderMenuKeys.hardLandingSwitch,
                              value: _hardLandingEnabled,
                              activeColor: _rocketFlame,
                              onChanged: (value) {
                                setState(() => _hardLandingEnabled = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'On',
                            style: GoogleFonts.exo2(
                              fontSize: 13,
                              fontWeight: _hardLandingEnabled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _hardLandingEnabled
                                  ? _rocketFlame
                                  : _starWhite.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Player list panel — wrapped per the scrollable mode (see top of
        // method). In wide layout: Expanded. In narrow scrollable layout:
        // fixed-height SizedBox.
        playerPanelWrapper,

        const SizedBox(height: 24),

        // Launch button
        Opacity(
          opacity: canStart ? 1.0 : 0.5,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              key: LunarLanderMenuKeys.startGameButton,
              onPressed: canStart ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _rocketFlame,
                foregroundColor: _starWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: Text(
                'LAUNCH!',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _starWhite,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}
