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

  const HorseRaceMenuScreen({
    super.key,
    this.preselectedPlayerIds,
    this.initialTargetScore,
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
            const Text('Carnival Derby'),
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

          return Stack(
            children: [
              Column(
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
            ],
          );
        },
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
            'Target Score: ${_targetScore.toInt()} points',
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
                'Require exact score to win the game',
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
                        'Must hit exact target score. Going over ends turn without scoring.',
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
                        'Any score greater than or equal to target wins.',
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
            'Selected Players (${selectedPlayers.length}/8)',
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
            'Available Players',
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
          'Start Race!',
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
