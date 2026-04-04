import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/test_keys.dart';
import '../../../models/player.dart';
import '../../../providers/clockwork_quest_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/player_list_panel/dual_player_list_panel.dart';
import '../../../widgets/player_list_panel/dual_player_list_panel_config.dart';
import '../../../services/save_game_service.dart';
import '../../../widgets/resume_game_button.dart';
import '../../../widgets/resume_game_modal/resume_game_modal.dart';
import '../../../widgets/resume_game_modal/resume_game_modal_config.dart';

class ClockworkQuestMenuScreen extends StatefulWidget {
  final List<String>? preselectedPlayerIds;
  final bool? initialIncludeBullseye;
  final bool? initialSpeedMode;
  final int? initialNumberOfLaps;

  const ClockworkQuestMenuScreen({
    super.key,
    this.preselectedPlayerIds,
    this.initialIncludeBullseye,
    this.initialSpeedMode,
    this.initialNumberOfLaps,
  });

  @override
  State<ClockworkQuestMenuScreen> createState() =>
      _ClockworkQuestMenuScreenState();
}

class _ClockworkQuestMenuScreenState extends State<ClockworkQuestMenuScreen> {
  bool _includeBullseye = false;
  bool _speedMode = false;
  int _numberOfLaps = 1;
  bool _showResumeModal = false;
  bool _hasSavedGames = false;
  PlayerProvider? _playerProvider;

  @override
  void initState() {
    super.initState();

    if (widget.initialIncludeBullseye != null) _includeBullseye = widget.initialIncludeBullseye!;
    if (widget.initialSpeedMode != null) _speedMode = widget.initialSpeedMode!;
    if (widget.initialNumberOfLaps != null) _numberOfLaps = widget.initialNumberOfLaps!;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerProvider = context.read<PlayerProvider>();
      _playerProvider = playerProvider;
      playerProvider.loadPlayers();
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
      final hasSaved = await SaveGameService().hasSavedGames('clockwork_quest');
      if (mounted) {
        setState(() {
          _hasSavedGames = hasSaved;
          _showResumeModal = hasSaved;
        });
      }
    });
  }

  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('clockwork_quest');
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
    final clockworkProvider = Provider.of<ClockworkQuestProvider>(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF2C2C34), // Dark Iron
          appBar: AppBar(
            backgroundColor: const Color(0xFF2C2C34),
            leading: IconButton(
              key: ClockworkQuestMenuKeys.backButton,
              icon: const Icon(Icons.arrow_back, color: Color(0xFFF5F0E8), size: 32),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'CLOCKWORK QUEST SETUP',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF5F0E8), // Steam White
                letterSpacing: 1.5,
              ),
            ),
            actions: [
              ResumeGameButton(
                key: ClockworkQuestMenuKeys.resumeGameButton,
                hasSavedGames: _hasSavedGames,
                onPressed: () => setState(() => _showResumeModal = true),
                color: const Color(0xFFC5A54E), // Brass Gold
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.clockworkQuest(),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Background image with dark overlay
              Positioned.fill(
                child: Image.asset(
                  'assets/games/clockwork_quest/images/background.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF2C2C34).withOpacity(0.80),
                ),
              ),

              Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel - Game Description
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C34).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFB87333).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOW TO PLAY',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFBF00),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Race to activate all 20 gears on the clocktower before your opponents!',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            color: const Color(0xFFF5F0E8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '1.  Hit numbers 1 through 20 on the dartboard in order. Each hit activates that gear on the clock.',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            color: const Color(0xFFF5F0E8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '2.  You get 3 darts per turn. Only hits on your current target advance you — everything else is a miss.',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            color: const Color(0xFFF5F0E8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '3.  First inventor to activate all gears earns the Clockwork Crown!',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            color: const Color(0xFFF5F0E8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'OPTIONS:',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC5A54E),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '⚙  Include Bullseye — Adds the bullseye as gear 21, making the game longer.',
                          style: GoogleFonts.lato(
                            fontSize: 19,
                            color: const Color(0xFFF5F0E8).withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '⚙  Speed Mode — Hit any gear in any order instead of 1→20. Great for a faster, more chaotic game.',
                          style: GoogleFonts.lato(
                            fontSize: 19,
                            color: const Color(0xFFF5F0E8).withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '⚙  Laps — Set how many full circuits (1–5) players must complete to win.',
                          style: GoogleFonts.lato(
                            fontSize: 19,
                            color: const Color(0xFFF5F0E8).withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Right Panel - Settings + Players + Start
              Expanded(
                flex: 6,
                child: Consumer<PlayerProvider>(
                  builder: (context, playerProvider, child) {
                    final selectedPlayers = playerProvider.selectedPlayers;
                    final bool canStart =
                        selectedPlayers.length >= 2 && selectedPlayers.length <= 8;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                          child: _buildSettingsSection(),
                        ),

                        const SizedBox(height: 16),

                        // Player Selection
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                            child: DualPlayerListPanel(
                              key: ClockworkQuestMenuKeys.playerListView,
                              config: DualPlayerListPanelConfig.clockworkQuest(),
                              addPlayerButtonKey:
                                  ClockworkQuestMenuKeys.addPlayerButton,
                              addPlayerButtonEmptyStateKey:
                                  ClockworkQuestMenuKeys.addPlayerButtonEmptyState,
                              playerTileKey: (id) =>
                                  ClockworkQuestMenuKeys.playerTile(id),
                              removePlayerButtonKey: (id) =>
                                  ClockworkQuestMenuKeys.removePlayerButton(id),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Start Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              key: ClockworkQuestMenuKeys.startButton,
                              onPressed: canStart
                                  ? () => _startGame(context, selectedPlayers)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF43B3AE), // Verdigris Green
                                disabledBackgroundColor:
                                    const Color(0xFF43B3AE).withOpacity(0.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'WIND THE CLOCK!',
                                style: GoogleFonts.cinzelDecorative(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF5F0E8),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
            ],
          ),
        ),

        // Resume game modal overlay
        if (_showResumeModal)
          ResumeGameModal(
            config: ResumeGameModalConfig.clockworkQuest(),
            gameType: 'clockwork_quest',
            onStartNewGame: () {
              setState(() => _showResumeModal = false);
              _checkForSavedGames();
            },
            onResumeGame: (savedGame) {
              setState(() => _showResumeModal = false);
              final clockworkProv = context.read<ClockworkQuestProvider>();
              clockworkProv.restoreGame(savedGame);
              Navigator.pushNamed(context, '/clockwork_quest_game')
                  .then((_) => _checkForSavedGames());
            },
            onClose: () {
              setState(() => _showResumeModal = false);
              _checkForSavedGames();
            },
          ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildSettingBox(
            'Include Bullseye',
            _includeBullseye,
            ClockworkQuestMenuKeys.includeBullseyeCheckbox,
            (value) => setState(() => _includeBullseye = value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSettingBox(
            'Speed Mode',
            _speedMode,
            ClockworkQuestMenuKeys.speedModeCheckbox,
            (value) => setState(() => _speedMode = value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLapsDropdown(),
        ),
      ],
    );
  }

  Widget _buildSettingBox(
    String label,
    bool value,
    Key key,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C34).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFB87333).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF5F0E8),
            ),
          ),
          Switch(
            key: key,
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFC5A54E), // Brass Gold
            activeTrackColor: const Color(0xFFC5A54E).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLapsDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C34).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFB87333).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Laps:',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF5F0E8),
            ),
          ),
          DropdownButton<int>(
            key: ClockworkQuestMenuKeys.numberOfLapsDropdown,
            value: _numberOfLaps,
            dropdownColor: const Color(0xFF2C2C34),
            underline: const SizedBox(),
            items: [1, 2, 3, 4, 5].map((laps) {
              return DropdownMenuItem(
                value: laps,
                child: Text(
                  '$laps',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFC5A54E),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _numberOfLaps = value);
              }
            },
          ),
        ],
      ),
    );
  }

  void _startGame(BuildContext context, List<Player> selectedPlayers) {
    final clockworkProvider =
        Provider.of<ClockworkQuestProvider>(context, listen: false);

    clockworkProvider.startGame(
      selectedPlayers,
      _includeBullseye,
      _speedMode,
      _numberOfLaps,
    );

    Navigator.pushNamed(context, '/clockwork_quest_game')
        .then((_) => _checkForSavedGames());
  }
}
