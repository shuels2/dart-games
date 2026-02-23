import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/target_tag_provider.dart';
import '../../../widgets/target_tag/tech_neon_background.dart';
import '../../../widgets/player_list_panel/player_list_panel.dart';
import '../../../constants/test_keys.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
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
  final Map<String, String> _playerTeamAssignments = {}; // playerId -> teamId
  late AnimationController _pulseController;
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DartboardConnectionInfo(
              config: DartboardConnectionInfoConfig.targetTag(),
            ),
          ),
        ],
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

        // Player selection
        if (scrollable)
          TeamPlayerListPanel(
            config: TeamPlayerListPanelConfig.targetTag(),
            addPlayerButtonKey: TargetTagMenuKeys.addPlayerButton,
            addPlayerButtonEmptyStateKey: TargetTagMenuKeys.addPlayerButtonEmptyState,
            playerListViewKey: TargetTagMenuKeys.playerListView,
            playerTileKey: (id) => TargetTagMenuKeys.playerTile(id),
            isTeamMode: _isTeamMode,
            isManualTeamAssignment: !_isRandomTeams,
            teamIconPaths: _teamIconPaths,
            useFixedHeight: true,
            teamDialogContainerKey: TeamAssignmentDialogKeys.dialogContainer,
            teamDialogDropdownKey: (id) => TeamAssignmentDialogKeys.playerTeamDropdown(id),
            teamDialogCancelKey: TeamAssignmentDialogKeys.cancelButton,
            onTeamAssignmentsChanged: (assignments) {
              setState(() {
                _playerTeamAssignments.clear();
                _playerTeamAssignments.addAll(assignments);
              });
            },
          )
        else
          TeamPlayerListPanel(
            config: TeamPlayerListPanelConfig.targetTag(),
            addPlayerButtonKey: TargetTagMenuKeys.addPlayerButton,
            addPlayerButtonEmptyStateKey: TargetTagMenuKeys.addPlayerButtonEmptyState,
            playerListViewKey: TargetTagMenuKeys.playerListView,
            playerTileKey: (id) => TargetTagMenuKeys.playerTile(id),
            isTeamMode: _isTeamMode,
            isManualTeamAssignment: !_isRandomTeams,
            teamIconPaths: _teamIconPaths,
            useFixedHeight: false,
            teamDialogContainerKey: TeamAssignmentDialogKeys.dialogContainer,
            teamDialogDropdownKey: (id) => TeamAssignmentDialogKeys.playerTeamDropdown(id),
            teamDialogCancelKey: TeamAssignmentDialogKeys.cancelButton,
            onTeamAssignmentsChanged: (assignments) {
              setState(() {
                _playerTeamAssignments.clear();
                _playerTeamAssignments.addAll(assignments);
              });
            },
          ),

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
