import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/target_tag_provider.dart';
import '../../../widgets/add_player/add_player.dart';
import '../../../widgets/target_tag/team_setup_widget.dart';
import '../../../widgets/target_tag/tech_neon_background.dart';
import '../../../widgets/horse_race/player_selection_card.dart';
import '../../../widgets/horse_race/player_avatar_widget.dart';
import '../../../constants/test_keys.dart';
import 'target_tag_game_screen.dart';

class TargetTagMenuScreen extends StatefulWidget {
  final List<String>? preselectedPlayerIds;
  final int? initialShieldMax;
  final bool? initialIsTeamMode;
  final bool? initialSoloHeroBonus;

  const TargetTagMenuScreen({
    super.key,
    this.preselectedPlayerIds,
    this.initialShieldMax,
    this.initialIsTeamMode,
    this.initialSoloHeroBonus,
  });

  @override
  State<TargetTagMenuScreen> createState() => _TargetTagMenuScreenState();
}

class _TargetTagMenuScreenState extends State<TargetTagMenuScreen> with SingleTickerProviderStateMixin {
  double _shieldMax = 5.0;
  bool _isTeamMode = false;
  bool _isRandomTeams = true;
  bool _soloHeroBonus = false;
  final Set<String> _selectedPlayerIds = {};
  Map<String, List<Player>> _manualTeams = {};
  final Map<String, String> _playerTeamAssignments = {}; // playerId -> teamId
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();
  PlayerProvider? _playerProvider;

  // Team icon paths — shuffled once at init so icons vary game to game
  List<String> _teamIconPaths = [];

  @override
  void initState() {
    super.initState();

    // Shuffle team icons once per menu load so each game session looks different
    _teamIconPaths = [
      'assets/games/target_tag/icons/TargetTag-TeamIcon-01.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-02.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-03.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-04.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-05.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-06.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-07.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-08.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-09.png',
      'assets/games/target_tag/icons/TargetTag-TeamIcon-10.png',
    ]..shuffle();

    // Initialize pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Initialize from widget parameters
    if (widget.initialShieldMax != null) {
      _shieldMax = widget.initialShieldMax!.toDouble();
    }
    if (widget.initialIsTeamMode != null) {
      _isTeamMode = widget.initialIsTeamMode!;
    }
    if (widget.initialSoloHeroBonus != null) {
      _soloHeroBonus = widget.initialSoloHeroBonus!;
    }

    // Load players and preselect if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = context.read<PlayerProvider>();
      _playerProvider = playerProvider;
      playerProvider.loadPlayers();
      playerProvider.clearSelection();

      if (widget.preselectedPlayerIds != null) {
        for (final playerId in widget.preselectedPlayerIds!) {
          final player = playerProvider.getPlayerById(playerId);
          if (player != null) {
            _selectedPlayerIds.add(playerId);
            playerProvider.selectPlayer(player, maxPlayers: 10);
          }
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Mark players as sorted when leaving screen
    _playerProvider?.markPlayersSorted();

    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        leading: IconButton(
          key: TargetTagMenuKeys.backButton,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 32, // Bigger size
          ),
          onPressed: () => Navigator.of(context).pop(),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'TARGET TAG GAME SETUP',
            style: GoogleFonts.luckiestGuy(
              fontSize: 36,
              letterSpacing: 1.5,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFFF007A), // Hot pink
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Tech/Neon background
          const Positioned.fill(
            child: TechNeonBackground(),
          ),
          // Main content
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                // Desktop/tablet: 2-column layout
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildLeftPanel()),
                    Expanded(child: _buildRightPanel(scrollable: false)),
                  ],
                );
              } else {
                // Mobile: single column with scroll
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
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game title
            Text(
              'TARGET TAG',
              style: GoogleFonts.luckiestGuy(
                fontSize: 40,
                color: const Color(0xFFFF007A),
                letterSpacing: 2,
              ),
            ),
            Text(
              'Shield Showdown!',
              style: GoogleFonts.luckiestGuy(
                fontSize: 24,
                color: const Color(0xFF00FFA3),
              ),
            ),
            const SizedBox(height: 24),

            // Description from RTF
            Text(
              'Think you\'ve got the golden arm? It\'s time to prove it in the most colorful, high-stakes game in the Dart Games collection!',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'In Target Tag, you aren\'t just throwing darts—you\'re building a high-tech Shield to become an elite Super-Striker.',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // How to Play
            Text(
              'How to Play:',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildNumberedStep('1', 'Fuel Your Shield:',
              'Play Solo mode or as a Team of 2 and hit your assigned number to power up your lives.'),
            _buildNumberedStep('2', 'Get "Tagged In":',
              'Once your Shield is at max power, you\'re TAGGED IN! You\'ll glow with arcade energy and gain the power to tag your opponents out of the game.'),
            _buildNumberedStep('3', 'Defend & Attack:',
              'Stay sharp! If an opponent tags you, you\'ll lose your power-up and have to rebuild your shield.'),
            _buildNumberedStep('4', 'Be the Champion:',
              'Outlast the competition to trigger the victory music and a confetti explosion!'),
            const SizedBox(height: 24),

            // Why You'll Love It
            Text(
              'Why You\'ll Love It:',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Play Your Way:',
              'Fly solo or team up with a buddy for 2v2 tactical action.'),
            _buildBulletPoint('Hero Bonus:',
              'Hit the Hero Buff and power up your shield while taking shields away from all your opponents to change the game momentum in a single throw!'),
            _buildBulletPoint('Arcade Vibes:',
              'Massive sound effects, a high-energy announcer, and a vibrant neon design.'),
            const SizedBox(height: 12),

            Text(
              'Grab your darts, find your target, and get TAGGED IN! Who will be the last one standing?',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF007A),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberedStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF007A),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      color: Colors.white70,
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

  Widget _buildBulletPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF00FFA3),
              fontSize: 20,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      color: Colors.white70,
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

  Widget _buildRightPanel({bool scrollable = true}) {
    final playerProvider = context.watch<PlayerProvider>();
    final allPlayers = playerProvider.allPlayers;
    final selectedPlayers = playerProvider.selectedPlayers;

    final int minPlayers = _isTeamMode ? 3 : 2;
    final int maxPlayers = 10;

    // Check if all players meet requirements
    bool canStart = selectedPlayers.length >= minPlayers && selectedPlayers.length <= maxPlayers;

    // In team manual mode, all selected players must be assigned to a team
    if (canStart && _isTeamMode && !_isRandomTeams) {
      canStart = selectedPlayers.every((player) => _playerTeamAssignments.containsKey(player.id));
    }

    // Check if any team has only 1 player
    bool hasTeamWithOnePlayer = false;
    if (_isTeamMode && !_isRandomTeams) {
      final teamCounts = <String, int>{};
      for (final player in selectedPlayers) {
        final teamId = _playerTeamAssignments[player.id];
        if (teamId != null) {
          teamCounts[teamId] = (teamCounts[teamId] ?? 0) + 1;
        }
      }
      hasTeamWithOnePlayer = teamCounts.values.any((count) => count == 1);
    }

    // Hero Bonus is now available for all games
    final bool soloHeroBonusEnabled = true;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Game Mode and Shield Max
        Row(
          children: [
            // Game Mode setting
            Expanded(
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isTeamMode ? const Color(0xFF00FFA3) : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Team mode',
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Solo',
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: _isTeamMode ? FontWeight.normal : FontWeight.bold,
                            color: _isTeamMode ? Colors.white60 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            key: TargetTagMenuKeys.teamModeSwitch,
                            value: _isTeamMode,
                            activeColor: const Color(0xFF00FFA3),
                            onChanged: (value) {
                              setState(() {
                                _isTeamMode = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Team',
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: _isTeamMode ? FontWeight.bold : FontWeight.normal,
                            color: _isTeamMode ? Colors.white : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Shield Max slider in box
            Expanded(
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white24,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Shield Max: ${_shieldMax.toInt()}',
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        key: TargetTagMenuKeys.shieldMaxSlider,
                        value: _shieldMax,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _shieldMax.toInt().toString(),
                        activeColor: const Color(0xFFFF007A),
                        onChanged: (value) {
                          setState(() {
                            _shieldMax = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 2: Team Assignment and Hero Bonus
        Row(
          children: [
            // Team Assignment setting (always visible, disabled when not in team mode)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _isTeamMode ? const Color(0xFF2A2A3E).withOpacity(0.85) : const Color(0xFF1A1A2E).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isTeamMode
                      ? (!_isRandomTeams ? const Color(0xFFFF007A) : Colors.white24)
                      : Colors.white12,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assign teams',
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isTeamMode ? Colors.white : Colors.white38,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Random',
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: _isRandomTeams ? FontWeight.bold : FontWeight.normal,
                            color: _isTeamMode
                              ? (_isRandomTeams ? Colors.white : Colors.white60)
                              : Colors.white38,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            key: TargetTagMenuKeys.manualTeamAssignmentSwitch,
                            value: !_isRandomTeams,
                            activeColor: const Color(0xFFFF007A),
                            onChanged: _isTeamMode ? (value) {
                              setState(() {
                                _isRandomTeams = !value;
                              });
                            } : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Manually',
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: !_isRandomTeams ? FontWeight.bold : FontWeight.normal,
                            color: _isTeamMode
                              ? (!_isRandomTeams ? Colors.white : Colors.white60)
                              : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Hero Bonus
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                color: soloHeroBonusEnabled
                    ? const Color(0xFF2A2A3E).withOpacity(0.85)
                    : const Color(0xFF1A1A2E).withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: soloHeroBonusEnabled
                      ? (_soloHeroBonus ? const Color(0xFF00FFA3) : Colors.white24)
                      : Colors.white12,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hero Bonus',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: soloHeroBonusEnabled
                          ? Colors.white
                          : Colors.white38,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Off',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: !_soloHeroBonus ? FontWeight.bold : FontWeight.normal,
                          color: !_soloHeroBonus ? Colors.white : Colors.white60,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          key: TargetTagMenuKeys.heroBonusSwitch,
                          value: _soloHeroBonus,
                          activeColor: const Color(0xFF00FFA3),
                          onChanged: (value) {
                            setState(() {
                              _soloHeroBonus = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'On',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: _soloHeroBonus ? FontWeight.bold : FontWeight.normal,
                          color: _soloHeroBonus ? Colors.white : Colors.white60,
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
        const SizedBox(height: 24),

        // Player selection - different for scrollable (fixed heights) vs expanded
        if (scrollable) ...[
          if (!_isTeamMode || _isRandomTeams) ...[
            // === SOLO / RANDOM TEAM: fixed height 485 ===
            Row(
              children: [
                Text(
                  'Available Players',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${selectedPlayers.length}/$maxPlayers selected)',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: selectedPlayers.length >= minPlayers
                        ? const Color(0xFF00FFA3)
                        : Colors.white60,
                  ),
                ),
                const Spacer(),
                if (allPlayers.isNotEmpty)
                  ElevatedButton.icon(
                    key: TargetTagMenuKeys.addPlayerButton,
                    onPressed: _handleAddPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF007A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'NEW PLAYER',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 485,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E).withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedPlayers.length >= minPlayers
                      ? const Color(0xFFFF007A) // Pink border
                      : Colors.white24,
                  width: 2,
                ),
              ),
              child: allPlayers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No players yet. Add your first player!',
                            style: GoogleFonts.fredoka(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            key: TargetTagMenuKeys.addPlayerButtonEmptyState,
                            onPressed: _handleAddPlayer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF007A),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(
                              'NEW PLAYER',
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      key: TargetTagMenuKeys.playerListView,
                      controller: _scrollController,
                      itemCount: allPlayers.length,
                      itemBuilder: (context, index) {
                        final player = allPlayers[index];
                        final isSelected = selectedPlayers.any((p) => p.id == player.id);

                        return PlayerSelectionCard(
                          key: TargetTagMenuKeys.playerTile(player.id),
                          player: player,
                          isSelected: isSelected,
                          selectedColor: const Color(0xFFFF007A), // Hot pink for Target Tag
                          selectedBorderColor: const Color(0xFFFF007A), // Hot pink border
                          onTap: () {
                            if (isSelected) {
                              playerProvider.deselectPlayer(player.id);
                            } else {
                              playerProvider.selectPlayer(player, maxPlayers: 10);
                            }
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // === MANUAL TEAM: fixed height 300 + team boxes ===
            Row(
              children: [
                Text(
                  'Available Players',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${selectedPlayers.length}/$maxPlayers selected)',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: selectedPlayers.length >= minPlayers
                        ? const Color(0xFF00FFA3)
                        : Colors.white60,
                  ),
                ),
                const Spacer(),
                if (allPlayers.isNotEmpty)
                  ElevatedButton.icon(
                    key: TargetTagMenuKeys.addPlayerButton,
                    onPressed: _handleAddPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF007A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'NEW PLAYER',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E).withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedPlayers.length >= minPlayers
                      ? const Color(0xFFFF007A) // Pink border
                      : Colors.white24,
                  width: 2,
                ),
              ),
              child: allPlayers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No players yet. Add your first player!',
                            style: GoogleFonts.fredoka(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            key: TargetTagMenuKeys.addPlayerButtonEmptyState,
                            onPressed: _handleAddPlayer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF007A),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(
                              'NEW PLAYER',
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      key: TargetTagMenuKeys.playerListView,
                      controller: _scrollController,
                      itemCount: allPlayers.length,
                      itemBuilder: (context, index) {
                        final player = allPlayers[index];
                        final isSelected = selectedPlayers.any((p) => p.id == player.id);
                        final assignedTeamId = _playerTeamAssignments[player.id];

                        return _buildPlayerCardWithTeamIcon(
                          player,
                          isSelected,
                          assignedTeamId,
                          onTap: () {
                            // Toggle selection - clicking tile selects/deselects
                            if (isSelected) {
                              playerProvider.deselectPlayer(player.id);
                              // Remove team assignment when deselecting
                              setState(() {
                                _playerTeamAssignments.remove(player.id);
                              });
                            } else {
                              playerProvider.selectPlayer(player, maxPlayers: 10);
                            }
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Team boxes - Full width
            Text(
              'Team Assignment',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _buildTeamAssignmentBoxes(selectedPlayers),
          ],
        ] else ...[
          // === DESKTOP EXPANDED: player list fills available space ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row - same for both solo/random and manual
                Row(
                  children: [
                    Text(
                      'Available Players',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${selectedPlayers.length}/10 selected)',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        color: selectedPlayers.length >= minPlayers
                            ? const Color(0xFF00FFA3)
                            : Colors.white60,
                      ),
                    ),
                    const Spacer(),
                    if (allPlayers.isNotEmpty)
                      ElevatedButton.icon(
                        key: TargetTagMenuKeys.addPlayerButton,
                        onPressed: _handleAddPlayer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF007A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'NEW PLAYER',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Expanded player list (fills remaining space)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedPlayers.length >= minPlayers
                            ? const Color(0xFFFF007A)
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: allPlayers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No players yet. Add your first player!',
                                  style: GoogleFonts.fredoka(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  key: TargetTagMenuKeys.addPlayerButtonEmptyState,
                                  onPressed: _handleAddPlayer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF007A),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    'NEW PLAYER',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (!_isTeamMode || _isRandomTeams)
                            ? ListView.builder(
                                key: TargetTagMenuKeys.playerListView,
                                controller: _scrollController,
                                itemCount: allPlayers.length,
                                itemBuilder: (context, index) {
                                  final player = allPlayers[index];
                                  final isSelected = selectedPlayers.any((p) => p.id == player.id);
                                  return PlayerSelectionCard(
                                    key: TargetTagMenuKeys.playerTile(player.id),
                                    player: player,
                                    isSelected: isSelected,
                                    selectedColor: const Color(0xFFFF007A),
                                    selectedBorderColor: const Color(0xFFFF007A),
                                    onTap: () {
                                      if (isSelected) {
                                        playerProvider.deselectPlayer(player.id);
                                      } else {
                                        playerProvider.selectPlayer(player, maxPlayers: 10);
                                      }
                                    },
                                  );
                                },
                              )
                            : ListView.builder(
                                key: TargetTagMenuKeys.playerListView,
                                controller: _scrollController,
                                itemCount: allPlayers.length,
                                itemBuilder: (context, index) {
                                  final player = allPlayers[index];
                                  final isSelected = selectedPlayers.any((p) => p.id == player.id);
                                  final assignedTeamId = _playerTeamAssignments[player.id];
                                  return _buildPlayerCardWithTeamIcon(
                                    player,
                                    isSelected,
                                    assignedTeamId,
                                    onTap: () {
                                      if (isSelected) {
                                        playerProvider.deselectPlayer(player.id);
                                        setState(() {
                                          _playerTeamAssignments.remove(player.id);
                                        });
                                      } else {
                                        playerProvider.selectPlayer(player, maxPlayers: 10);
                                      }
                                    },
                                  );
                                },
                              ),
                  ),
                ),
                // Team assignment boxes (manual mode only, fixed below the list)
                if (_isTeamMode && !_isRandomTeams) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Team Assignment',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTeamAssignmentBoxes(selectedPlayers),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
        // Start button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: _buildStartButton(canStart, selectedPlayers),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      child: scrollable
          ? SingleChildScrollView(child: column)
          : column,
    );
  }

  void _showTeamSelectionDialog(Player player) {
    // Get current team counts
    final teamCounts = <String, int>{};
    for (var entry in _playerTeamAssignments.entries) {
      final teamId = entry.value;
      teamCounts[teamId] = (teamCounts[teamId] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          String? _highlightedTeam;

          return AlertDialog(
            key: TeamAssignmentDialogKeys.dialogContainer,
            backgroundColor: const Color(0xFF1A1A2E).withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Select Team for ${player.name}',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            content: SizedBox(
              width: 400,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  for (int i = 0; i < 5; i++)
                    Builder(
                      builder: (context) {
                        final teamId = 'team${i + 1}';
                        final currentPlayerTeam = _playerTeamAssignments[player.id];
                        // Team is full if it has 2 players AND the current player is not already on that team
                        final teamCount = teamCounts[teamId] ?? 0;
                        final isTeamFull = teamCount >= 2 && currentPlayerTeam != teamId;

                        return Opacity(
                          opacity: isTeamFull ? 0.4 : 1.0,
                          child: GestureDetector(
                            key: TeamAssignmentDialogKeys.playerTeamDropdown(player.id + '_' + teamId),
                            onTap: isTeamFull ? null : () async {
                              // Show highlight effect
                              setDialogState(() {
                                _highlightedTeam = teamId;
                              });

                              // Set the team assignment
                              setState(() {
                                _playerTeamAssignments[player.id] = teamId;
                              });

                              // Wait for highlight to be visible
                              await Future.delayed(const Duration(milliseconds: 250));

                              // Close dialog
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: _highlightedTeam == teamId
                                    ? const Color(0xFF00FFA3).withOpacity(0.3)
                                    : (isTeamFull
                                        ? const Color(0xFF1A1A2E)
                                        : const Color(0xFF2A2A3E)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _highlightedTeam == teamId
                                      ? const Color(0xFF00FFA3)
                                      : (_playerTeamAssignments[player.id] == teamId
                                          ? const Color(0xFF00FFA3)
                                          : (isTeamFull ? Colors.red.withOpacity(0.5) : Colors.white24)),
                                  width: _highlightedTeam == teamId ? 4 : 3,
                                ),
                                boxShadow: _highlightedTeam == teamId
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00FFA3).withOpacity(0.6),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Stack(
                                children: [
                                  Image.asset(
                                    _teamIconPaths[i],
                                    fit: BoxFit.contain,
                                  ),
                                  if (isTeamFull)
                                    Positioned.fill(
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'FULL',
                                            style: GoogleFonts.fredoka(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_playerTeamAssignments[player.id] != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _playerTeamAssignments.remove(player.id);
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Remove from Team',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  if (_playerTeamAssignments[player.id] != null)
                    const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      key: TeamAssignmentDialogKeys.cancelButton,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2A3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Colors.white38,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamAssignmentBoxes(List<Player> selectedPlayers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < 5; i++)
          _buildTeamBox(i, selectedPlayers),
      ],
    );
  }

  Widget _buildTeamBox(int teamIndex, List<Player> selectedPlayers) {
    final teamId = 'team${teamIndex + 1}';
    final teamPlayers = selectedPlayers
        .where((p) => _playerTeamAssignments[p.id] == teamId)
        .toList();

    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: teamPlayers.isNotEmpty ? const Color(0xFF00FFA3) : Colors.white24,
              width: 2,
            ),
          ),
          child: Image.asset(
            _teamIconPaths[teamIndex],
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${teamPlayers.length}',
          style: GoogleFonts.fredoka(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: teamPlayers.isNotEmpty ? const Color(0xFF00FFA3) : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCardWithTeamIcon(
    Player player,
    bool isSelected,
    String? assignedTeamId,
    {required VoidCallback onTap}
  ) {
    // Get team icon index if player is assigned to a team
    int? teamIconIndex;
    if (assignedTeamId != null) {
      final teamNumber = int.tryParse(assignedTeamId.replaceAll('team', ''));
      if (teamNumber != null && teamNumber >= 1 && teamNumber <= 5) {
        teamIconIndex = teamNumber - 1;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00FFA3).withOpacity(0.2)
            : const Color(0xFF2A2A3E),
        border: Border.all(
          color: isSelected ? const Color(0xFF00FFA3) : Colors.white24,
          width: isSelected ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                // Player avatar
                PlayerAvatarWidget(
                  player: player,
                  size: 22.0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: GoogleFonts.fredoka(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Games: ${player.gamesPlayed} | Wins: ${player.gamesWon}',
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Show team icon next to name and wins info if assigned
                if (teamIconIndex != null) ...[
                  GestureDetector(
                    onTap: isSelected ? () => _showTeamSelectionDialog(player) : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF00FFA3),
                          width: 2,
                        ),
                      ),
                      child: Image.asset(
                        _teamIconPaths[teamIconIndex],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Show "Assign team" button if selected but no team assigned
                if (isSelected && teamIconIndex == null)
                  ElevatedButton(
                    onPressed: () => _showTeamSelectionDialog(player),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF007A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Assign team',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF00FFA3), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF007A) : const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF007A) : Colors.white24,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(bool canStart, List<Player> selectedPlayers) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = canStart ? (0.7 + (_pulseController.value * 0.3)) : 1.0;

        return Container(
          decoration: BoxDecoration(
            color: canStart ? const Color(0xFFFF007A).withOpacity(0.85) : Colors.grey.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canStart ? const Color(0xFFFFB3D9) : Colors.grey, // Light pink border
              width: canStart ? 3 : 1,
            ),
            boxShadow: canStart
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF007A).withOpacity(0.8 * pulseValue),
                      blurRadius: 30 * pulseValue,
                      spreadRadius: 6 * pulseValue,
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: TargetTagMenuKeys.startButton,
              onTap: canStart ? () => _startGame(selectedPlayers) : null,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    'LET\'S PLAY TAG!',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 30,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAddPlayer() async {
    final player = await showAddPlayerDialog(
      context: context,
      config: AddPlayerDialogConfig.targetTag(),
    );

    if (player != null && mounted) {
      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.savePlayer(player);

      // Auto-select the newly added player only if max not reached
      if (playerProvider.selectedPlayers.length < 10) {
        playerProvider.selectPlayer(player, maxPlayers: 10);
      }

      // Scroll to show the new player after dialog closes
      _scrollToNewPlayer();
    }
  }

  void _scrollToNewPlayer() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            // Add buffer to ensure full tile is visible
            final targetPosition = _scrollController.position.maxScrollExtent + 150;
            _scrollController.animateTo(
              targetPosition,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  void _startGame(List<Player> selectedPlayers) {
    final targetTagProvider = context.read<TargetTagProvider>();

    if (_isTeamMode) {
      // Team mode
      Map<String, List<String>> teams;

      if (_isRandomTeams) {
        // Random team assignment
        teams = _randomlyAssignTeams(selectedPlayers);
      } else {
        // Manual team assignment - build teams from player assignments
        teams = {};
        for (final player in selectedPlayers) {
          final teamId = _playerTeamAssignments[player.id];
          if (teamId != null) {
            teams[teamId] ??= [];
            teams[teamId]!.add(player.id);
          }
        }
      }

      // Map each team ID to the icon shown on the menu so the game screen
      // displays the same icons players saw when they picked their team.
      final teamIconMap = <String, String>{
        'team1': _teamIconPaths[0],
        'team2': _teamIconPaths[1],
        'team3': _teamIconPaths[2],
        'team4': _teamIconPaths[3],
        'team5': _teamIconPaths[4],
      };
      targetTagProvider.startTeamGame(
        teams,
        _shieldMax.toInt(),
        _soloHeroBonus,
        teamIconMap,
      );
    } else {
      // Solo mode
      targetTagProvider.startSoloGame(
        selectedPlayers,
        _shieldMax.toInt(),
        _soloHeroBonus,
      );
    }

    // Navigate to game screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TargetTagGameScreen(),
      ),
    );
  }

  Map<String, List<String>> _randomlyAssignTeams(List<Player> players) {
    final shuffled = List<Player>.from(players)..shuffle();
    final teams = <String, List<String>>{};
    final teamIds = ['team1', 'team2', 'team3', 'team4', 'team5'];

    // Prioritize filling teams of 2 before creating teams of 1
    final teamsOf2 = shuffled.length ~/ 2; // Number of complete pairs
    final remainingSolo = shuffled.length % 2; // 0 or 1 solo player

    int playerIndex = 0;
    int teamIndex = 0;

    // First, create all teams of 2
    for (int i = 0; i < teamsOf2; i++) {
      final teamId = teamIds[teamIndex];
      teams[teamId] = [
        shuffled[playerIndex].id,
        shuffled[playerIndex + 1].id,
      ];
      playerIndex += 2;
      teamIndex++;
    }

    // Then, if there's a remaining solo player, add them as a team of 1
    if (remainingSolo == 1) {
      final teamId = teamIds[teamIndex];
      teams[teamId] = [shuffled[playerIndex].id];
    }

    return teams;
  }
}
