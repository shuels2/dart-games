import 'dart:convert';
import 'package:flutter/material.dart';
import 'clockwork_quest_menu_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../constants/test_keys.dart';
import '../../../providers/clockwork_quest_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../services/victory_music_service.dart';
import '../../../services/save_game_service.dart';

class ClockworkQuestResultsScreen extends StatefulWidget {
  const ClockworkQuestResultsScreen({super.key});

  @override
  State<ClockworkQuestResultsScreen> createState() =>
      _ClockworkQuestResultsScreenState();
}

class _ClockworkQuestResultsScreenState
    extends State<ClockworkQuestResultsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _musicPlayed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playVictoryMusic();
      _autoDeleteSavedGame();
    });
  }

  Future<void> _autoDeleteSavedGame() async {
    if (!mounted) return;
    final clockworkProvider =
        Provider.of<ClockworkQuestProvider>(context, listen: false);
    final savedGameId = clockworkProvider.resumedSavedGameId;
    if (savedGameId != null) {
      await SaveGameService().deleteSavedGame('clockwork_quest', savedGameId);
      clockworkProvider.clearResumedSavedGameId();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playVictoryMusic() async {
    if (_musicPlayed) return;
    _musicPlayed = true;

    try {
      final musicService = VictoryMusicService();
      final customMusicSource = await musicService.getRandomMusicSource();

      await _audioPlayer.setVolume(0.7);

      if (customMusicSource != null && customMusicSource.isNotEmpty) {
        if (customMusicSource.startsWith('data:')) {
          await _audioPlayer.play(UrlSource(customMusicSource));
        } else {
          await _audioPlayer.play(DeviceFileSource(customMusicSource));
        }
      } else {
        await _audioPlayer.play(UrlSource(
            'https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'));
      }
    } catch (e) {
      debugPrint('Error playing victory music: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clockworkProvider = Provider.of<ClockworkQuestProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context);

    final game = clockworkProvider.currentGame;
    if (game == null || game.winnerId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.pop(context);
        }
      });
      return const SizedBox();
    }

    final winner = playerProvider.getPlayerById(game.winnerId!);
    if (winner == null) {
      return const SizedBox();
    }

    // Build rankings
    final rankedPlayerIds = _getRankedPlayers(game, playerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C34), // Dark Iron
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C34),
        leading: const SizedBox(), // No back button on results
        title: Text(
          'CLOCKWORK QUEST',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF5F0E8),
            letterSpacing: 1.5,
          ),
        ),
        actions: [
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

          Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Winner Section
              _buildWinnerSection(winner, clockworkProvider),

              const SizedBox(height: 40),

              // Rankings List
              _buildRankingsList(
                  rankedPlayerIds, playerProvider, clockworkProvider),

              const SizedBox(height: 40),

              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildWinnerSection(
      dynamic winner, ClockworkQuestProvider provider) {
    final winnerId = provider.currentGame!.winnerId!;
    final lapsCompleted = provider.getPlayerLapsCompleted(winnerId);

    return Column(
      children: [
        // Crown title
        Text(
          'THE CLOCKWORK CROWN!',
          key: ClockworkQuestResultsKeys.winnerTitle,
          style: GoogleFonts.cinzelDecorative(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFBF00), // Amber Glow
            letterSpacing: 2.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Inventor character image — separate from player avatar
        if (provider.getInventorImagePath(winnerId) != null)
          Image.asset(
            provider.getInventorImagePath(winnerId)!,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),

        // Player photo avatar (photo or initials only — not character image)
        if (provider.getInventorImagePath(winnerId) == null)
          if (winner.photoPath != null)
            CircleAvatar(
              radius: 60,
              backgroundImage: winner.photoPath!.startsWith('data:')
                  ? MemoryImage(
                      base64Decode(winner.photoPath!.split(',')[1]))
                  : NetworkImage(winner.photoPath!) as ImageProvider,
            )
          else
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFC5A54E),
              child: Text(
                winner.name[0].toUpperCase(),
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C2C34),
                ),
              ),
            ),
        const SizedBox(height: 16),

        // Winner name
        Text(
          winner.name,
          key: ClockworkQuestResultsKeys.winnerName,
          style: GoogleFonts.cinzelDecorative(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF5F0E8),
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Winner stats
        Text(
          provider.currentGame!.numberOfLaps > 1
              ? 'Lap ${lapsCompleted + 1}/${provider.currentGame!.numberOfLaps}'
              : 'All gears activated!',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 18,
            color: const Color(0xFFFFBF00),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsList(
    List<String> rankedPlayerIds,
    PlayerProvider playerProvider,
    ClockworkQuestProvider clockworkProvider,
  ) {
    return Expanded(
      child: Container(
        key: ClockworkQuestResultsKeys.rankingsList,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C34).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB87333).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: rankedPlayerIds.length,
          itemBuilder: (context, index) {
            final playerId = rankedPlayerIds[index];
            final player = playerProvider.getPlayerById(playerId);
            if (player == null) return const SizedBox();

            final laps = clockworkProvider.getPlayerLapsCompleted(playerId);
            final target =
                clockworkProvider.getPlayerCurrentTarget(playerId);
            final isWinner =
                playerId == clockworkProvider.currentGame!.winnerId;

            return Container(
              key: ClockworkQuestResultsKeys.playerRankTile(playerId),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: index % 2 == 0
                    ? const Color(0xFF2C2C34)
                    : const Color(0xFF3C3C44),
                borderRadius: BorderRadius.circular(8),
                border: isWinner
                    ? Border.all(color: const Color(0xFFFFBF00), width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${index + 1}.',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC5A54E),
                      ),
                    ),
                  ),

                  // Inventor image or player avatar — character image separate from CircleAvatar
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: clockworkProvider.getInventorImagePath(playerId) != null
                        ? Image.asset(
                            clockworkProvider.getInventorImagePath(playerId)!,
                            fit: BoxFit.contain,
                          )
                        : player.photoPath != null
                            ? CircleAvatar(
                                radius: 20,
                                backgroundImage: player.photoPath!.startsWith('data:')
                                    ? MemoryImage(base64Decode(
                                        player.photoPath!.split(',')[1]))
                                    : NetworkImage(player.photoPath!)
                                        as ImageProvider,
                              )
                            : CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFB87333),
                                child: Text(
                                  player.name[0].toUpperCase(),
                                  style: GoogleFonts.cinzelDecorative(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C2C34),
                                  ),
                                ),
                              ),
                  ),
                  const SizedBox(width: 12),

                  // Name
                  Expanded(
                    child: Text(
                      player.name,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF5F0E8),
                      ),
                    ),
                  ),

                  // Progress — show gears activated (target - 1), winner clamped to maxTarget
                  Text(
                    () {
                      final maxTarget =
                          clockworkProvider.currentGame!.maxTarget;
                      final gearsActivated = isWinner
                          ? maxTarget
                          : (target - 1).clamp(0, maxTarget);
                      return 'Gear $gearsActivated/$maxTarget${clockworkProvider.currentGame!.numberOfLaps > 1 ? " (Lap ${laps + 1})" : ""}';
                    }(),
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: const Color(0xFFF5F0E8).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Wind Again
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: ClockworkQuestResultsKeys.playAgainButton,
            onPressed: () => _playAgain(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43B3AE), // Verdigris Green
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'WIND AGAIN',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF5F0E8),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Change Settings
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: ClockworkQuestResultsKeys.changeSettingsButton,
            onPressed: () => _changeSettings(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A54E), // Brass Gold
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'CHANGE SETTINGS',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C2C34),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Leave Tower
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: ClockworkQuestResultsKeys.leaveTowerButton,
            onPressed: () => _leaveTower(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFB87333), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'LEAVE TOWER',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB87333),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getRankedPlayers(dynamic game, PlayerProvider playerProvider) {
    final players = List<String>.from(game.playerIds);
    players.sort((a, b) {
      final aLaps = game.lapsCompleted[a] ?? 0;
      final bLaps = game.lapsCompleted[b] ?? 0;
      if (aLaps != bLaps) return bLaps.compareTo(aLaps);

      final aTarget = game.currentTarget[a] ?? 1;
      final bTarget = game.currentTarget[b] ?? 1;
      return bTarget.compareTo(aTarget);
    });
    return players;
  }

  void _playAgain(BuildContext context) {
    final clockworkProvider =
        Provider.of<ClockworkQuestProvider>(context, listen: false);
    final playerProvider =
        Provider.of<PlayerProvider>(context, listen: false);

    final game = clockworkProvider.currentGame!;
    final players = playerProvider.allPlayers
        .where((p) => game.playerIds.contains(p.id))
        .toList();

    clockworkProvider.clearGame();
    clockworkProvider.startGame(
      players,
      game.includeBullseye,
      game.speedMode,
      game.numberOfLaps,
    );

    Navigator.pushReplacementNamed(context, '/clockwork_quest_game');
  }

  void _changeSettings(BuildContext context) {
    final clockworkProvider =
        Provider.of<ClockworkQuestProvider>(context, listen: false);
    final game = clockworkProvider.currentGame!;
    final preselectedPlayerIds = List<String>.from(game.playerIds);
    final includeBullseye = game.includeBullseye;
    final speedMode = game.speedMode;
    final numberOfLaps = game.numberOfLaps;
    // Navigate first, then clear game — clearing before navigation triggers a
    // rebuild of the results screen which sees game==null and schedules a pop
    // that races with the pushAndRemoveUntil.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ClockworkQuestMenuScreen(
          preselectedPlayerIds: preselectedPlayerIds,
          initialIncludeBullseye: includeBullseye,
          initialSpeedMode: speedMode,
          initialNumberOfLaps: numberOfLaps,
        ),
      ),
      (route) => false,
    );
    clockworkProvider.clearGame();
  }

  void _leaveTower(BuildContext context) {
    final clockworkProvider =
        Provider.of<ClockworkQuestProvider>(context, listen: false);
    // Navigate first, then clear — same race condition as _changeSettings
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    clockworkProvider.clearGame();
  }
}
