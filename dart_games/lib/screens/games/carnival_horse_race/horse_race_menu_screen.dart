import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/horse_race_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../services/photo_service.dart';
import '../../../widgets/horse_race/player_selection_card.dart';
import '../../../widgets/dartboard_status_indicator.dart';
import '../../../widgets/compact_dartboard_info.dart';
import '../../../widgets/carnival_string_lights.dart';
import '../../../widgets/carnival_target_logo.dart';
import 'horse_race_game_screen.dart';

class HorseRaceMenuScreen extends StatefulWidget {
  final List<String>? preselectedPlayerIds;
  final int? initialTargetScore;
  final bool? initialExactScoreMode;

  const HorseRaceMenuScreen({
    super.key,
    this.preselectedPlayerIds,
    this.initialTargetScore,
    this.initialExactScoreMode,
  });

  @override
  State<HorseRaceMenuScreen> createState() => _HorseRaceMenuScreenState();
}

class _HorseRaceMenuScreenState extends State<HorseRaceMenuScreen> {
  final PhotoService _photoService = PhotoService();
  late double _targetScore;
  bool _exactScoreMode = false;

  @override
  void initState() {
    super.initState();
    _targetScore = widget.initialTargetScore?.toDouble() ?? 150;
    _exactScoreMode = widget.initialExactScoreMode ?? false;

    // Load players when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayers();
      context.read<PlayerProvider>().clearSelection();

      // Preselect players if provided
      if (widget.preselectedPlayerIds != null && widget.preselectedPlayerIds!.isNotEmpty) {
        final playerProvider = context.read<PlayerProvider>();
        for (final playerId in widget.preselectedPlayerIds!) {
          final player = playerProvider.getPlayerById(playerId);
          if (player != null) {
            playerProvider.selectPlayer(player);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF8B5E3C), // Warm Cedar base color
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFE63946), // Lava Red (left)
                Color(0xFFFFD700), // Canary Yellow (center)
                Color(0xFF48CAE4), // Electric Teal (right)
              ],
              stops: [0.0, 0.66, 1.0], // Red lasts twice as long
            ),
          ),
          child: AppBar(
            title: Text(
              'Carnival Derby Game Setup',
              style: GoogleFonts.rye(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: const Color(0xFFF1FAEE), // Cloud Dancer
                shadows: [
                  Shadow(
                    color: const Color(0xFFFFD700), // Canary Yellow glow
                    blurRadius: 10,
                  ),
                  Shadow(
                    color: const Color(0xFFFFD700),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CompactDartboardInfo(provider: dartboardProvider),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: DartboardStatusIndicator(),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Rotated wood plank background
          Positioned.fill(
            child: Transform.scale(
              scale: 2.0, // Scale up to ensure coverage
              child: Transform.rotate(
                angle: 1.5708, // 90 degrees in radians (π/2)
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5E3C), // Warm Cedar base color
                    image: DecorationImage(
                      image: AssetImage('assets/images/CarnivalDerby-WoodPlanks.jpg'),
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeat,
                      colorFilter: ColorFilter.mode(
                        const Color(0xFF8B5E3C).withOpacity(0.7), // Lighter tint with reduced opacity
                        BlendMode.multiply,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Radial gradient spotlight overlay - warm overhead lamp effect
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6), // Top-middle (50% 20%)
                    radius: 1.2,
                    colors: [
                      const Color.fromRGBO(255, 230, 150, 0.4), // Warm soft amber center glow
                      const Color.fromRGBO(255, 230, 150, 0.1), // Transparent warm wash
                      const Color.fromRGBO(13, 27, 42, 0.8), // Deep moody navy-black edges
                    ],
                    stops: const [0.0, 0.4, 1.0], // Center → Mid-falloff → Outer shadows
                  ),
                  backgroundBlendMode: BlendMode.overlay, // Interact with wood grain
                ),
              ),
            ),
          ),
          // Carnival target logo (centered, in front of background, behind string lights)
          const Center(
            child: CarnivalTargetLogo(size: 700.0),
          ),
          // Carnival string lights (behind content, in front of background)
          const CarnivalStringLights(),
          // Content
          Consumer<PlayerProvider>(
              builder: (context, playerProvider, child) {
                if (playerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Game Description
              Expanded(
                flex: 1,
                child: _buildGameDescription(),
              ),

              const VerticalDivider(width: 1),

              // Right side: Game Settings
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Target Score Slider
                    _buildTargetScoreSection(),
                    const Divider(),

                    // Player Selection (Available and Selected side-by-side)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Available Players Section (Left)
                          Expanded(
                            child: _buildAvailablePlayersSection(playerProvider),
                          ),

                          const SizedBox(width: 16),

                          // Selected Players Section (Right)
                          Expanded(
                            child: _buildSelectedPlayersSection(playerProvider),
                          ),
                        ],
                      ),
                    ),

                    // Start Button
                    _buildStartButton(playerProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
        ],
      ),
    );
  }

  Widget _buildGameDescription() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1D3557).withOpacity(0.85), // Dark navy 85% opacity
          border: Border.all(
            color: const Color(0xFFF1FAEE), // Off-white border
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w900,
              ),
              children: [
                const TextSpan(text: 'Step right up! Transform your game room into a high-stakes midway with '),
                TextSpan(
                  text: 'Carnival Derby',
                  style: GoogleFonts.rye(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const TextSpan(text: ', the fast-paced horse racing game where your aim determines your fame!'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The Race is On!',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: const Color(0xFFFFD700), // Canary Yellow
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'In '),
                TextSpan(
                  text: 'Carnival Derby',
                  style: GoogleFonts.rye(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ', you aren\'t just a spectator—you\'re the engine! Every player commands a horse at the starting gate, but speed is measured in bullseyes.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'The mechanics are simple but addictive: '),
                TextSpan(
                  text: 'Throw your darts to move your horse.',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(text: ' The better your shot, the faster your steed gallops down the track toward the finish line. It\'s a heart-pounding blend of precision and racing strategy that keeps everyone on the edge of their seats until the final throw.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Customize Your Challenge',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: const Color(0xFFE63946), // Lava Red
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Whether you\'re looking for a quick sprint or an epic endurance test, Carnival Derby lets you control the reins:',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFFF1FAEE), // Off-white
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: '• '),
                TextSpan(
                  text: 'Set the Distance:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(text: ' Want a lightning-fast "Quarter Horse" dash? Set a low point total. Looking for a grueling "Triple Crown" marathon? Crank up the points required to win!'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: '• '),
                TextSpan(
                  text: 'The "Perfect Finish" Rule:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(text: ' For the ultimate test of skill, turn on '),
                TextSpan(
                  text: 'Perfect Finish',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(text: ' mode. In this game, you can\'t just blast past the finish line—you have to land your final dart to hit the winning number exactly. If you over-score, your horse stays put, giving your rivals a chance to catch up!'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Why You\'ll Love It',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: const Color(0xFF48CAE4), // Electric Teal
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: '• '),
                TextSpan(
                  text: 'Interactive Fun:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(text: ' Unlike traditional darts, every point has a visual impact as you watch your horse pull ahead of the pack.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: '• '),
                TextSpan(
                  text: 'All Skill Levels:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(text: ' Beginners can aim for the big slices, while pros can hunt for triples to leapfrog the competition.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: '• '),
                TextSpan(
                  text: 'High Tension:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(text: ' Nothing beats the roar of the crowd (or your friends!) as three horses neck-and-neck approach the final few points.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Do you have the steady hand needed to take the winner\'s circle? Grab your darts and let the derby begin!',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: const Color(0xFFF1FAEE), // Off-white
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTargetScoreSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1D3557).withOpacity(0.85), // Dark navy 85% opacity
          border: Border.all(
            color: const Color(0xFFF1FAEE), // Off-white border
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target score: ${_targetScore.toInt()} points',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: const Color(0xFFF1FAEE), // Off-white
                fontWeight: FontWeight.w900,
              ),
            ),
          Slider(
            value: _targetScore,
            min: 20,
            max: 250,
            divisions: 46,
            label: _targetScore.toInt().toString(),
            activeColor: const Color(0xFFFFD700), // Canary Yellow
            onChanged: (value) {
              setState(() {
                _targetScore = value;
              });
            },
          ),
          Text(
            'Range: 20-250 points',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFFF1FAEE), // Off-white
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Require "Perfect Finish" to win the game',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFFF1FAEE), // Off-white
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _exactScoreMode = true;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: _exactScoreMode,
                                  activeColor: const Color(0xFF48CAE4), // Electric Teal
                                  fillColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return const Color(0xFF48CAE4); // Electric Teal when selected
                                      }
                                      return const Color(0xFFF1FAEE); // Cloud Dancer white when not selected
                                    },
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _exactScoreMode = value!;
                                    });
                                  },
                                ),
                                Text(
                                  'Yes',
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFFF1FAEE), // Off-white
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'A player must hit the exact Target score to win the game. Going over the target score ends the player turn and leaves their score at the value it was before the last dart throw.',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFFF1FAEE), // Off-white
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _exactScoreMode = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Radio<bool>(
                                  value: false,
                                  groupValue: _exactScoreMode,
                                  activeColor: const Color(0xFF48CAE4), // Electric Teal
                                  fillColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return const Color(0xFF48CAE4); // Electric Teal when selected
                                      }
                                      return const Color(0xFFF1FAEE); // Cloud Dancer white when not selected
                                    },
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _exactScoreMode = value!;
                                    });
                                  },
                                ),
                                Text(
                                  'No',
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFFF1FAEE), // Off-white
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'A player wins the game when their score is greater than or equal to the Target score.',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFFF1FAEE), // Off-white
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSelectedPlayersSection(PlayerProvider playerProvider) {
    final selectedPlayers = playerProvider.selectedPlayers;

    return Container(
      margin: const EdgeInsets.only(right: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3557).withOpacity(0.85), // Dark navy 85% opacity
        border: Border.all(
          color: const Color(0xFFF1FAEE), // Off-white border
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected players (${selectedPlayers.length}/8)',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFFF1FAEE), // Off-white
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (selectedPlayers.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Select at least 1 player',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFFF1FAEE), // Off-white
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: selectedPlayers.length,
                itemBuilder: (context, index) {
                  final player = selectedPlayers[index];
                  return PlayerSelectionCard(
                    player: player,
                    isSelected: true,
                    compact: false,
                    onTap: () {},
                    onRemove: () {
                      playerProvider.deselectPlayer(player.id);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlayersSection(PlayerProvider playerProvider) {
    final allPlayers = playerProvider.allPlayers;
    final selectedPlayers = playerProvider.selectedPlayers;

    return Container(
      margin: const EdgeInsets.only(left: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3557).withOpacity(0.85), // Dark navy 85% opacity
        border: Border.all(
          color: const Color(0xFFF1FAEE), // Off-white border
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available players',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFFF1FAEE), // Off-white
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (allPlayers.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showAddPlayerDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946), // Lava Red
                    foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    side: const BorderSide(
                      color: Color(0xFFFFD700), // Canary Yellow border
                      width: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'NEW PLAYER',
                    style: GoogleFonts.bangers(
                      fontSize: 12,
                      letterSpacing: 1.0,
                      color: const Color(0xFFF1FAEE),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        Expanded(
          child: allPlayers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No players yet. Add your first player!',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFFF1FAEE), // Off-white
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPlayerDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE63946), // Lava Red
                          foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          side: const BorderSide(
                            color: Color(0xFFFFD700), // Canary Yellow border
                            width: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(
                          'NEW PLAYER',
                          style: GoogleFonts.bangers(
                            fontSize: 16,
                            letterSpacing: 1.0,
                            color: const Color(0xFFF1FAEE),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: allPlayers.length,
                  itemBuilder: (context, index) {
                    final player = allPlayers[index];
                    final isSelected =
                        selectedPlayers.any((p) => p.id == player.id);

                    return PlayerSelectionCard(
                      player: player,
                      isSelected: isSelected,
                      onTap: () {
                        if (isSelected) {
                          playerProvider.deselectPlayer(player.id);
                        } else {
                          playerProvider.selectPlayer(player);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
      ),
    );
  }

  Widget _buildStartButton(PlayerProvider playerProvider) {
    final canStart = playerProvider.selectedPlayers.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: canStart ? () => _startGame(playerProvider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE63946), // Lava Red
          foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          disabledBackgroundColor: Colors.grey[300],
          side: canStart
              ? const BorderSide(
                  color: Color(0xFFFFD700), // Canary Yellow border
                  width: 4,
                )
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'START THE RACE!',
          style: GoogleFonts.bangers(
            fontSize: 18,
            letterSpacing: 1.0,
            color: canStart ? const Color(0xFFF1FAEE) : null,
          ),
        ),
      ),
    );
  }

  void _startGame(PlayerProvider playerProvider) {
    final selectedPlayers = playerProvider.selectedPlayers;
    final horseRaceProvider = context.read<HorseRaceProvider>();

    // Start the game
    horseRaceProvider.startGame(
      selectedPlayers,
      _targetScore.toInt(),
      exactScoreMode: _exactScoreMode,
    );

    // Navigate to game screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HorseRaceGameScreen(),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context) {
    final nameController = TextEditingController();
    String? photoPath;
    bool showError = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1D3557).withOpacity(0.95), // Midnight Navy
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Add New Player',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFF1FAEE), // Cloud Dancer
              shadows: [
                const Shadow(
                  color: Color(0xFFFFD700), // Canary Yellow glow
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo preview section
                if (photoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: kIsWeb
                              ? NetworkImage(photoPath!)
                              : FileImage(File(photoPath!)) as ImageProvider,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setDialogState(() {
                                photoPath = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Color(0xFFF1FAEE)), // Cloud Dancer
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    labelStyle: const TextStyle(color: Color(0xFFF1FAEE)),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF48CAE4)),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF48CAE4)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                    errorText: showError ? 'Please enter a player name' : null,
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    // Clear error when user starts typing
                    if (showError && value.trim().isNotEmpty) {
                      setDialogState(() {
                        showError = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Photo (Optional)',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF1FAEE), // Cloud Dancer
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final path = await _photoService.takePhoto(context: context);
                          if (path != null) {
                            setDialogState(() {
                              photoPath = path;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48CAE4), // Electric Teal
                          foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
                          side: const BorderSide(
                            color: Color(0xFFFFD700), // Canary Yellow border
                            width: 2,
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          'CAMERA',
                          style: GoogleFonts.bangers(
                            fontSize: 14,
                            letterSpacing: 1.0,
                            color: const Color(0xFFF1FAEE),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 130,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final path = await _photoService.selectFromGallery();
                          if (path != null) {
                            setDialogState(() {
                              photoPath = path;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48CAE4), // Electric Teal
                          foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
                          side: const BorderSide(
                            color: Color(0xFFFFD700), // Canary Yellow border
                            width: 2,
                          ),
                        ),
                        icon: const Icon(Icons.photo_library),
                        label: Text(
                          'GALLERY',
                          style: GoogleFonts.bangers(
                            fontSize: 14,
                            letterSpacing: 1.0,
                            color: const Color(0xFFF1FAEE),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 130,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D3557), // Midnight Navy
                      foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
                      side: const BorderSide(
                        color: Color(0xFF48CAE4), // Electric Teal border
                        width: 3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.bangers(
                        fontSize: 14,
                        letterSpacing: 1.0,
                        color: const Color(0xFFF1FAEE), // Cloud Dancer
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 130,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE63946), // Lava Red
                      foregroundColor: const Color(0xFFF1FAEE), // Cloud Dancer
                      side: const BorderSide(
                        color: Color(0xFFFFD700), // Canary Yellow border
                        width: 3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        setDialogState(() {
                          showError = true;
                        });
                        return;
                      }

                      final player = Player.create(
                        name: nameController.text.trim(),
                        photoPath: photoPath,
                      );

                      final playerProvider = context.read<PlayerProvider>();
                      playerProvider.savePlayer(player);

                      // Automatically select the newly added player
                      playerProvider.selectPlayer(player);

                      Navigator.pop(dialogContext);
                    },
                    child: Text(
                      'ADD PLAYER',
                      style: GoogleFonts.bangers(
                        fontSize: 14,
                        letterSpacing: 1.0,
                        color: const Color(0xFFF1FAEE),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
