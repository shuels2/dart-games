import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/horse_race_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../services/photo_service.dart';
import '../../../widgets/horse_race/player_selection_card.dart';
import '../../../widgets/dartboard_status_indicator.dart';
import '../../../widgets/compact_dartboard_info.dart';
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              height: 48,
              width: 48,
            ),
            const SizedBox(width: 8),
            const Text('Game Setup'),
          ],
        ),
        backgroundColor: Colors.amber,
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
      body: Consumer<PlayerProvider>(
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

                    // Selected Players Section
                    _buildSelectedPlayersSection(playerProvider),
                    const Divider(),

                    // Available Players Section
                    Expanded(
                      child: _buildAvailablePlayersSection(playerProvider),
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
    );
  }

  Widget _buildGameDescription() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: 'Step right up! Transform your game room into a high-stakes midway with '),
                TextSpan(
                  text: 'Carnival Derby',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ', the fast-paced horse racing game where your aim determines your fame!'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The Race is On!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: 'In '),
                TextSpan(
                  text: 'Carnival Derby',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ', you aren\'t just a spectator—you\'re the engine! Every player commands a horse at the starting gate, but speed is measured in bullseyes.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: 'The mechanics are simple but addictive: '),
                TextSpan(
                  text: 'Throw your darts to move your horse.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' The better your shot, the faster your steed gallops down the track toward the finish line. It\'s a heart-pounding blend of precision and racing strategy that keeps everyone on the edge of their seats until the final throw.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Customize Your Challenge',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Whether you\'re looking for a quick sprint or an epic endurance test, Carnival Derby lets you control the reins:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: '• '),
                TextSpan(
                  text: 'Set the Distance:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' Want a lightning-fast "Quarter Horse" dash? Set a low point total. Looking for a grueling "Triple Crown" marathon? Crank up the points required to win!'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: '• '),
                TextSpan(
                  text: 'The "Perfect Finish" Rule:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' For the ultimate test of skill, turn on '),
                TextSpan(
                  text: 'Perfect Finish',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' mode. In this game, you can\'t just blast past the finish line—you have to land your final dart to hit the winning number exactly. If you over-score, your horse stays put, giving your rivals a chance to catch up!'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Why You\'ll Love It',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: '• '),
                TextSpan(
                  text: 'Interactive Fun:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' Unlike traditional darts, every point has a visual impact as you watch your horse pull ahead of the pack.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: '• '),
                TextSpan(
                  text: 'All Skill Levels:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' Beginners can aim for the big slices, while pros can hunt for triples to leapfrog the competition.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: '• '),
                TextSpan(
                  text: 'High Tension:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' Nothing beats the roar of the crowd (or your friends!) as three horses neck-and-neck approach the final few points.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Do you have the steady hand needed to take the winner\'s circle? Grab your darts and let the derby begin!',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetScoreSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target score: ${_targetScore.toInt()} points',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _targetScore,
            min: 20,
            max: 250,
            divisions: 46,
            label: _targetScore.toInt().toString(),
            activeColor: Colors.amber,
            onChanged: (value) {
              setState(() {
                _targetScore = value;
              });
            },
          ),
          const Text(
            'Range: 20-250 points',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Require "Perfect Finish" to win the game',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Yes'),
                      subtitle: const Text(
                        'A player must hit the exact Target score to win the game. Going over the target score ends the player turn and leaves their score at the value it was before the last dart throw.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: true,
                      groupValue: _exactScoreMode,
                      activeColor: Colors.amber,
                      onChanged: (value) {
                        setState(() {
                          _exactScoreMode = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No'),
                      subtitle: const Text(
                        'A player wins the game when their score is greater than or equal to the Target score.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: false,
                      groupValue: _exactScoreMode,
                      activeColor: Colors.amber,
                      onChanged: (value) {
                        setState(() {
                          _exactScoreMode = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlayersSection(PlayerProvider playerProvider) {
    final selectedPlayers = playerProvider.selectedPlayers;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected players (${selectedPlayers.length}/8)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (selectedPlayers.isEmpty)
            const Text(
              'Select at least 1 player',
              style: TextStyle(color: Colors.grey),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedPlayers.length,
                itemBuilder: (context, index) {
                  final player = selectedPlayers[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    child: PlayerSelectionCard(
                      player: player,
                      isSelected: true,
                      compact: true,
                      onTap: () {},
                      onRemove: () {
                        playerProvider.deselectPlayer(player.id);
                      },
                    ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Available players',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (allPlayers.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showAddPlayerDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Player'),
              ),
            ),
          ),
        Expanded(
          child: allPlayers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No players yet. Add your first player!',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPlayerDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'New Player',
                          style: TextStyle(fontSize: 16),
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
          backgroundColor: Colors.amber,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: const Text(
          'Start the Race!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          title: const Text('Add New Player'),
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
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    border: const OutlineInputBorder(),
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
                const Text(
                  'Photo (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final path = await _photoService.takePhoto(context: context);
                        if (path != null) {
                          setDialogState(() {
                            photoPath = path;
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final path = await _photoService.selectFromGallery();
                        if (path != null) {
                          setDialogState(() {
                            photoPath = path;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
              child: const Text('Add Player'),
            ),
          ],
        ),
      ),
    );
  }
}
