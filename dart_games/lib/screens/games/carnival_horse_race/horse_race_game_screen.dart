import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/horse_race_provider.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../services/mock_scolia_api_service.dart';
import '../../../services/dart_announcer_service.dart';
import '../../../widgets/interactive_dartboard.dart';
import '../../../widgets/horse_race/race_track_widget.dart';
import '../../../widgets/horse_race/player_avatar_widget.dart';
import '../../../widgets/dartboard_status_indicator.dart';
import '../../../widgets/compact_dartboard_info.dart';
import 'horse_race_results_screen.dart';

class HorseRaceGameScreen extends StatefulWidget {
  const HorseRaceGameScreen({super.key});

  @override
  State<HorseRaceGameScreen> createState() => _HorseRaceGameScreenState();
}

class _HorseRaceGameScreenState extends State<HorseRaceGameScreen> {
  StreamSubscription? _dartboardSubscription;
  final GlobalKey<InteractiveDartboardState> _dartboardKey =
      GlobalKey<InteractiveDartboardState>();

  MockScoliaApiService? _mockApi;
  DartAnnouncerService? _announcer;

  @override
  void initState() {
    super.initState();

    // Get services after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dartboardProvider = context.read<DartboardProvider>();
      _mockApi = dartboardProvider.apiService;
      _announcer = DartAnnouncerService();

      // Load and apply saved announcer settings
      _loadAnnouncerSettings();

      // Listen to dartboard events if API service is available
      if (_mockApi != null) {
        _dartboardSubscription = _mockApi!.eventStream.listen((event) {
          _handleDartboardEvent(event);
        });
      }

      // Announce the first player's turn
      _announceFirstPlayerTurn();
    });
  }

  void _announceFirstPlayerTurn() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      final horseRaceProvider = context.read<HorseRaceProvider>();
      final playerProvider = context.read<PlayerProvider>();

      final players = horseRaceProvider.currentGame!.playerIds
          .map((id) => playerProvider.getPlayerById(id))
          .whereType<Player>()
          .toList();

      final firstPlayer = horseRaceProvider.getCurrentPlayer(players);
      if (firstPlayer != null) {
        _announcer?.speak('${firstPlayer.name}, it\'s your turn');
      }
    });
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
  void dispose() {
    _dartboardSubscription?.cancel();
    super.dispose();
  }

  void _handleDartboardEvent(Map<String, dynamic> event) {
    final type = event['type'];
    final horseRaceProvider = context.read<HorseRaceProvider>();

    if (type == 'throw_detected') {
      final throwData = event['data']['payload'];
      final score = _calculateScore(throwData['sector']);

      // Get player info before processing throw
      final playerProvider = context.read<PlayerProvider>();
      final players = horseRaceProvider.currentGame!.playerIds
          .map((id) => playerProvider.getPlayerById(id))
          .whereType<Player>()
          .toList();
      final currentPlayer = horseRaceProvider.getCurrentPlayer(players);

      // Process the dart throw
      horseRaceProvider.processDartThrow(score);

      // Announce the score
      _announcer?.announceDart(
        score,
        _getMultiplierFromSector(throwData['sector']),
      );

      // Check if game is won
      if (horseRaceProvider.hasWinner) {
        // Winner found - announce to remove darts and trigger takeout
        if (currentPlayer != null) {
          // Wait for score announcement to complete (~1.5s) + 1 second
          Future.delayed(const Duration(milliseconds: 2500), () {
            _announcer?.speak('${currentPlayer.name}, remove your darts');

            // Trigger takeout events
            Future.delayed(const Duration(milliseconds: 2000), () {
              _mockApi?.simulateTakeoutStarted();

              // Auto-complete takeout after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                _mockApi?.simulateTakeoutFinished();
              });
            });
          });
        }
      } else {
        // If this was the 3rd dart, announce to remove darts after score finishes + 1 second
        final dartsThrown = horseRaceProvider.getCurrentPlayerDartsThrown();
        if (dartsThrown >= 3) {
          if (currentPlayer != null) {
            // Wait for score announcement to complete (~1.5s) + 1 second
            Future.delayed(const Duration(milliseconds: 2500), () {
              _announcer?.speak('${currentPlayer.name}, remove your darts');
            });
          }
        }
      }
    }

    if (type == 'takeout_finished') {
      horseRaceProvider.handleTakeoutFinished();

      // Check if game is won after takeout
      if (horseRaceProvider.hasWinner) {
        _handleGameWon();
      } else {
        // Announce next player's turn (before they throw)
        final playerProvider = context.read<PlayerProvider>();
        final players = horseRaceProvider.currentGame!.playerIds
            .map((id) => playerProvider.getPlayerById(id))
            .whereType<Player>()
            .toList();
        final nextPlayer = horseRaceProvider.getCurrentPlayer(players);
        if (nextPlayer != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _announcer?.speak('${nextPlayer.name}, it\'s your turn');
          });
        }
      }
    }
  }

  int _calculateScore(String sector) {
    if (sector == 'Bull') return 50;
    if (sector == '25') return 25;
    if (sector == 'None') return 0;

    // Extract number from sector (e.g., "D20" -> 20, "T19" -> 19, "S18" -> 18)
    final match = RegExp(r'[A-Z](\d+)').firstMatch(sector);
    if (match == null) return 0;

    final baseScore = int.parse(match.group(1)!);

    if (sector.startsWith('D')) return baseScore * 2;
    if (sector.startsWith('T')) return baseScore * 3;
    if (sector.startsWith('S')) return baseScore;

    return 0;
  }

  String _getMultiplierFromSector(String sector) {
    if (sector == 'Bull') return 'bullseye';
    if (sector == '25') return 'outer_bull';
    if (sector == 'None') return 'miss';
    if (sector.startsWith('D')) return 'double';
    if (sector.startsWith('T')) return 'triple';
    if (sector.startsWith('S')) return 'single';
    return 'single';
  }

  int _getBaseScoreFromSector(String sector) {
    if (sector == 'Bull') return 50;
    if (sector == '25') return 25;
    if (sector == 'None') return 0;

    final match = RegExp(r'[A-Z](\d+)').firstMatch(sector);
    if (match == null) return 0;
    return int.parse(match.group(1)!);
  }

  void _handleGameWon() {
    // Wait for final score announcement to complete before transitioning
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      final horseRaceProvider = context.read<HorseRaceProvider>();
      final playerProvider = context.read<PlayerProvider>();
      final winner = horseRaceProvider.getWinner(playerProvider.allPlayers);

      if (winner != null) {
        // Navigate to results screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HorseRaceResultsScreen(),
          ),
        );
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
      body: Consumer2<HorseRaceProvider, PlayerProvider>(
        builder: (context, horseRaceProvider, playerProvider, child) {
          final currentGame = horseRaceProvider.currentGame;
          if (currentGame == null) {
            return const Center(child: Text('No active game'));
          }

          final players = currentGame.playerIds
              .map((id) => playerProvider.getPlayerById(id))
              .whereType<Player>()
              .toList();

          final currentPlayer = horseRaceProvider.getCurrentPlayer(players);
          final dartsThrown = horseRaceProvider.getCurrentPlayerDartsThrown();
          final shouldPromptTakeout = horseRaceProvider.shouldPromptTakeout;

          return Column(
            children: [
              // Current player info
              _buildCurrentPlayerSection(
                currentPlayer,
                dartsThrown,
                currentGame.targetScore,
                horseRaceProvider,
              ),

              // Takeout prompt banner (only show when using emulator)
              if (shouldPromptTakeout && !dartboardProvider.isConnected)
                _buildTakeoutPrompt(),

              // Race track
              Expanded(
                child: RaceTrackWidget(
                  players: players,
                  targetScore: currentGame.targetScore,
                ),
              ),

              // Dartboard emulator (only show when not connected to real dartboard)
              if (!dartboardProvider.isConnected)
                _buildDartboardSection(shouldPromptTakeout),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentPlayerSection(
    Player? currentPlayer,
    int dartsThrown,
    int targetScore,
    HorseRaceProvider provider,
  ) {
    if (currentPlayer == null) return const SizedBox.shrink();

    final score = provider.getPlayerScore(currentPlayer.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        border: const Border(
          bottom: BorderSide(color: Colors.amber, width: 3),
        ),
      ),
      child: Row(
        children: [
          PlayerAvatarWidget(
            player: currentPlayer,
            size: 30.0,
            showName: true,
            isHighlighted: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: $score / $targetScore',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Darts: ',
                      style: TextStyle(fontSize: 14),
                    ),
                    ...List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(
                          index < dartsThrown
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: index < dartsThrown
                              ? Colors.amber[700]
                              : Colors.grey,
                        ),
                      ),
                    ),
                    Text(
                      '($dartsThrown/3)',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeoutPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: const BoxDecoration(
        color: Colors.red,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'REMOVE YOUR DARTS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDartboardSection(bool disabled) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Click dartboard to throw',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              AbsorbPointer(
                absorbing: disabled,
                child: Opacity(
                  opacity: disabled ? 0.5 : 1.0,
                  child: InteractiveDartboard(
                    key: _dartboardKey,
                    size: 250,
                    onDartThrow: (score, multiplier, baseScore, position) {
                      if (_mockApi != null) {
                        _mockApi!.simulateDartThrow(
                          score: score,
                          multiplier: multiplier,
                          playerName: 'Player',
                          baseScore: baseScore,
                          widgetX: position.dx,
                          widgetY: position.dy,
                          widgetSize: 250,
                        );
                      }
                    },
                    onRemoveDarts: () {
                      // This is called when dartboard is cleared
                    },
                  ),
                ),
              ),
              if (disabled)
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pan_tool,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Remove Your Darts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            // Simulate takeout finished
                            _mockApi?.simulateTakeoutFinished();
                            // Also clear the dartboard visually
                            _dartboardKey.currentState?.removeDarts();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text(
                            'Darts Removed',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
