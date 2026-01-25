import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/horse_race_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../widgets/horse_race/player_avatar_widget.dart';
import '../../../widgets/dartboard_status_indicator.dart';
import '../../../widgets/compact_dartboard_info.dart';
import '../../../services/dart_announcer_service.dart';
import 'horse_race_menu_screen.dart';
import 'horse_race_game_screen.dart';

class HorseRaceResultsScreen extends StatefulWidget {
  const HorseRaceResultsScreen({super.key});

  @override
  State<HorseRaceResultsScreen> createState() => _HorseRaceResultsScreenState();
}

class _HorseRaceResultsScreenState extends State<HorseRaceResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  DartAnnouncerService? _announcer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    _animationController.forward();

    // Update player stats and announce winner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePlayerStats();
      _announceGameCompletion();
      // Start confetti after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _confettiController.play();
      });
      // Play victory music when winner is announced (same timing as voice)
      Future.delayed(const Duration(milliseconds: 1500), () {
        _playVictoryMusic();
      });
    });
  }

  void _playVictoryMusic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customMusicPath = prefs.getString('victory_music_path');

      await _audioPlayer.setVolume(0.7);

      if (customMusicPath != null && customMusicPath.isNotEmpty) {
        // Play custom music file
        await _audioPlayer.play(DeviceFileSource(customMusicPath));
        debugPrint('Playing custom victory music: $customMusicPath');
      } else {
        // Play default victory fanfare
        await _audioPlayer.play(UrlSource(
            'https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'));
        debugPrint('Playing default victory music');
      }
    } catch (e) {
      debugPrint('Error playing victory music: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updatePlayerStats() async {
    final horseRaceProvider = context.read<HorseRaceProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final currentGame = horseRaceProvider.currentGame;

    if (currentGame == null) return;

    // Update stats for all players
    for (final playerId in currentGame.playerIds) {
      final isWinner = playerId == currentGame.winnerId;
      await playerProvider.updatePlayerStats(playerId, won: isWinner);
    }
  }

  void _announceGameCompletion() async {
    _announcer = DartAnnouncerService();

    // Load and apply saved announcer settings
    await _loadAnnouncerSettings();

    final horseRaceProvider = context.read<HorseRaceProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final players = horseRaceProvider.currentGame!.playerIds
        .map((id) => playerProvider.getPlayerById(id))
        .whereType<Player>()
        .toList();

    final winner = horseRaceProvider.getWinner(players);

    if (winner != null) {
      // Announce game completion first
      _announcer?.speak('The game is complete');

      // Then announce the winner after a delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        _announcer?.speak('${winner.name} is the winner');
      });
    }
  }

  Future<void> _loadAnnouncerSettings() async {
    if (_announcer == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Load voice engine
    final engineStr = prefs.getString('voice_engine') ?? 'responsiveVoice';
    final voiceEngine = VoiceEngine.values.firstWhere(
      (e) => e.name == engineStr,
      orElse: () => VoiceEngine.responsiveVoice,
    );

    // Load announcer style
    final styleStr = prefs.getString('announcer_style') ?? 'professional';
    final announcerVoice = AnnouncerVoice.values.firstWhere(
      (v) => v.name == styleStr,
      orElse: () => AnnouncerVoice.professional,
    );

    // Apply voice style
    _announcer!.setVoice(announcerVoice);

    // Apply voice engine settings
    if (voiceEngine == VoiceEngine.responsiveVoice) {
      _announcer!.useResponsiveVoice();
      final responsiveVoice = prefs.getString('responsive_voice') ?? 'Australian Female';
      _announcer!.setResponsiveVoice(responsiveVoice);
    } else {
      _announcer!.useBrowserVoices();
      final systemVoice = prefs.getString('system_voice') ?? '';
      if (systemVoice.isNotEmpty) {
        await _announcer!.setSystemVoice(systemVoice);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Results'),
        backgroundColor: Colors.amber,
        automaticallyImplyLeading: false,
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
      body: Stack(
        children: [
          Consumer2<HorseRaceProvider, PlayerProvider>(
            builder: (context, horseRaceProvider, playerProvider, child) {
              final currentGame = horseRaceProvider.currentGame;
              if (currentGame == null) {
                return const Center(child: Text('No game data'));
              }

              final players = currentGame.playerIds
                  .map((id) => playerProvider.getPlayerById(id))
                  .whereType<Player>()
                  .toList();

              final winner = horseRaceProvider.getWinner(players);
              final standings = horseRaceProvider.getFinalStandings();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Trophy icon
                    const Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Colors.amber,
                    ),

                    const SizedBox(height: 16),

                    // Winner announcement
                    const Text(
                      'Winner!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Winner avatar and name
                    if (winner != null)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            PlayerAvatarWidget(
                              player: winner,
                              size: 60.0,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              winner.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Final Score: ${currentGame.getPlayerScore(winner.id)}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Congratulations message
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '🏆 Congratulations! 🏆',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Final Standings
                    _buildFinalStandings(standings, players),

                    const SizedBox(height: 32),

                    // Action buttons
                    _buildActionButtons(context, horseRaceProvider),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
          // Confetti widgets - positioned at different locations
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 4,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3 * pi / 4,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStandings(
    List<MapEntry<String, int>> standings,
    List<Player> players,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Final Standings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: standings.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = standings[index];
              final player = players.firstWhere((p) => p.id == entry.key);
              final position = index + 1;
              final medal = _getMedal(position);

              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        medal ?? '${position}.',
                        style: TextStyle(
                          fontSize: medal != null ? 24 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PlayerAvatarWidget(
                      player: player,
                      size: 20.0,
                    ),
                  ],
                ),
                title: Text(
                  player.name,
                  style: TextStyle(
                    fontWeight:
                        position <= 3 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  '${entry.value} pts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String? _getMedal(int position) {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    HorseRaceProvider horseRaceProvider,
  ) {
    final playerProvider = context.read<PlayerProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Play Again button (full width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Start new game with same players and settings
                final currentGame = horseRaceProvider.currentGame;
                if (currentGame != null) {
                  final playerIds = currentGame.playerIds;
                  final targetScore = currentGame.targetScore;

                  // Get player objects from IDs
                  final players = playerIds
                      .map((id) => playerProvider.getPlayerById(id))
                      .whereType<Player>()
                      .toList();

                  // Clear the current game
                  horseRaceProvider.clearGame();

                  // Start new game with same settings
                  horseRaceProvider.startGame(players, targetScore);

                  // Navigate to game screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HorseRaceGameScreen(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Get current game info before clearing
                    final currentGame = horseRaceProvider.currentGame;
                    final playerIds = currentGame?.playerIds ?? [];
                    final targetScore = currentGame?.targetScore ?? 150;

                    // Clear game and go back to menu with preselected values
                    horseRaceProvider.clearGame();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HorseRaceMenuScreen(
                          preselectedPlayerIds: playerIds,
                          initialTargetScore: targetScore,
                        ),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Change game players and settings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.amber, width: 2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Clear game and go back to home
                    horseRaceProvider.clearGame();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Select a different game'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.amber, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
