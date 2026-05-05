import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/player.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/monster_mash_provider.dart';
import '../../../widgets/player_list_panel/player_list_panel.dart';
import '../../../constants/test_keys.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../models/saved_game_metadata.dart';
import '../../../services/save_game_service.dart';
import '../../../widgets/resume_game_modal/resume_game_modal.dart';
import '../../../widgets/resume_game_button.dart';
import 'monster_mash_game_screen.dart';

class MonsterMashMenuScreen extends StatefulWidget {
  final List<String>? preselectedPlayerIds;
  final int? initialHealthMax;
  final bool? initialBonusBuffs;
  final bool? initialSpeedPlay;
  final int? initialRoundLimit;

  const MonsterMashMenuScreen({
    super.key,
    this.preselectedPlayerIds,
    this.initialHealthMax,
    this.initialBonusBuffs,
    this.initialSpeedPlay,
    this.initialRoundLimit,
  });

  @override
  State<MonsterMashMenuScreen> createState() => _MonsterMashMenuScreenState();
}

class _MonsterMashMenuScreenState extends State<MonsterMashMenuScreen>
    with TickerProviderStateMixin {
  double _healthMax = 20.0;
  bool _bonusBuffs = false;
  bool _speedPlay = false;
  double _roundLimit = 10.0;
  bool _showResumeModal = false;
  bool _hasSavedGames = false;
  late AnimationController _pulseController;
  late AnimationController _lightningController;
  PlayerProvider? _playerProvider;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _lightningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    if (widget.initialHealthMax != null) {
      _healthMax = widget.initialHealthMax!.toDouble();
    }
    if (widget.initialBonusBuffs != null) {
      _bonusBuffs = widget.initialBonusBuffs!;
    }
    if (widget.initialSpeedPlay != null) {
      _speedPlay = widget.initialSpeedPlay!;
    }
    if (widget.initialRoundLimit != null) {
      _roundLimit = widget.initialRoundLimit!.toDouble();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerProvider = context.read<PlayerProvider>();
      _playerProvider = playerProvider;
      await playerProvider.loadPlayers();
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
      final hasSaved = await SaveGameService().hasSavedGames('monster_mash');
      if (mounted) {
        setState(() {
          _hasSavedGames = hasSaved;
          _showResumeModal = hasSaved;
        });
      }
    });
  }

  /// Check for saved games and update button state
  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('monster_mash');
    if (mounted) {
      setState(() => _hasSavedGames = hasSaved);
    }
  }

  @override
  void dispose() {
    _playerProvider?.markPlayersSorted();
    _pulseController.dispose();
    _lightningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            leading: IconButton(
              key: MonsterMashMenuKeys.backButton,
              icon: Icon(
                Icons.arrow_back,
                color: const Color(0xFFF5F5DC),
                size: 32,
                shadows: [
                  Shadow(
                    color: const Color(0xFF7FFF00),
                    blurRadius: 20,
                  ),
                  Shadow(
                    color: const Color(0xFF7FFF00).withOpacity(0.8),
                    blurRadius: 40,
                  ),
                ],
              ),
              onPressed: () => Navigator.of(context).pop(),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Text(
                'Monster Mash Game Setup',
                style: GoogleFonts.creepster(
                  fontSize: 39,
                  letterSpacing: 1.5,
                  color: const Color(0xFFF5F5DC),
                  shadows: [
                    Shadow(
                      color: const Color(0xFF7FFF00).withOpacity(0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF1A1A2E),
                    Color(0xFF7FFF00),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              ResumeGameButton(
                key: MonsterMashMenuKeys.resumeGameButton,
                hasSavedGames: _hasSavedGames,
                onPressed: () => setState(() => _showResumeModal = true),
                color: const Color(0xFFEEF0F2), // Mist
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DartboardConnectionInfo(
                  config: DartboardConnectionInfoConfig.monsterMash(),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/games/monster_mash/images/MonsterMash-Background.png',
                  fit: BoxFit.cover,
                ),
              ),
              Consumer<PlayerProvider>(
                builder: (context, playerProvider, child) {
                  if (playerProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildLeftPanel(),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildRightPanel(playerProvider),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        // Resume game modal overlay - covers entire screen including AppBar
        if (_showResumeModal)
          ResumeGameModal(
            config: ResumeGameModalConfig.monsterMash(),
            gameType: 'monster_mash',
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
            config: DartboardPausedModalConfig.monsterMash(),
          ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2F4F4F).withOpacity(0.80),
          border: Border.all(color: const Color(0xFF7FFF00), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    'assets/games/monster_mash/images/MonsterMash-Background.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONSTER MASH',
                  style: GoogleFonts.creepster(
                    fontSize: 60,
                    color: const Color(0xFF7FFF00),
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF7FFF00).withOpacity(0.6),
                        blurRadius: 12,
                      ),
                      Shadow(
                        color: const Color(0xFF7FFF00).withOpacity(0.3),
                        blurRadius: 24,
                      ),
                      const Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The creatures of the night have gathered for the ultimate showdown! Choose your monster and battle for survival in this classic horror-themed dart game.',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF5F5DC),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Each player is assigned a random classic monster and a target number on the dartboard.',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: const Color(0xFFF5F5DC).withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'How to Play:',
                  style: GoogleFonts.creepster(
                    fontSize: 38,
                    color: const Color(0xFFF5F5DC),
                    shadows: [
                      Shadow(
                        color: const Color(0xFFF5F5DC).withOpacity(0.4),
                        blurRadius: 8,
                      ),
                      const Shadow(
                        color: Colors.black,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildStep('1', 'Heal Yourself:',
                    'Hit YOUR assigned number to restore health points.'),
                _buildStep('2', 'Attack Opponents:',
                    'Hit an OPPONENT\'S number to deal damage equal to the multiplier.'),
                _buildStep('3', 'Bullseye Power:',
                    'Bullseye restores you to full health! Outer Bull heals +5.'),
                _buildStep('4', 'Last Monster Standing:',
                    'Reduce opponents to 0 HP to eliminate them. Be the last one alive!'),
                const SizedBox(height: 24),
                Text(
                  'Optional Features:',
                  style: GoogleFonts.creepster(
                    fontSize: 38,
                    color: const Color(0xFFF5F5DC),
                    shadows: [
                      Shadow(
                        color: const Color(0xFFF5F5DC).withOpacity(0.4),
                        blurRadius: 8,
                      ),
                      const Shadow(
                        color: Colors.black,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildBullet('Bonus Buffs:',
                    'Random supernatural effects can trigger each round - double damage, boosted healing, shadow protection, or lightning strikes!'),
                _buildBullet('Speed Play:',
                    'Set a round limit to keep games fast and competitive. When time runs out, the healthiest monster wins!'),
                const SizedBox(height: 16),
                Text(
                  'Grab your darts and let the Monster Mash begin!',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF8C00),
                    height: 1.5,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFF8C00).withOpacity(0.5),
                        blurRadius: 10,
                      ),
                      const Shadow(
                        color: Colors.black,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: GoogleFonts.creepster(
              fontSize: 20,
              color: const Color(0xFF7FFF00),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5F5DC),
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: const Color(0xFFF5F5DC).withOpacity(0.8),
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

  Widget _buildBullet(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022 ',
            style: TextStyle(color: const Color(0xFF7FFF00), fontSize: 22),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5F5DC),
                    ),
                  ),
                  TextSpan(
                    text: ' $description',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: const Color(0xFFF5F5DC).withOpacity(0.8),
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

  Widget _buildRightPanel(PlayerProvider playerProvider) {
    final allPlayers = playerProvider.allPlayers;
    final selectedPlayers = playerProvider.selectedPlayers;
    final bool canStart =
        selectedPlayers.length >= 2 && selectedPlayers.length <= 8;

    return Column(
      children: [
        // Row 1: Health Points slider | Bonus Buffs switch
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4F4F).withOpacity(0.80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFF5F5DC).withOpacity(0.3),
                        width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Health: ${_healthMax.toInt()}',
                        style: GoogleFonts.pirataOne(
                          fontSize: 22,
                          color: const Color(0xFFF5F5DC),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          key: MonsterMashMenuKeys.healthPointsSlider,
                          value: _healthMax,
                          min: 10,
                          max: 50,
                          divisions: 8,
                          label: _healthMax.toInt().toString(),
                          activeColor: const Color(0xFF7FFF00),
                          onChanged: (value) {
                            setState(() {
                              _healthMax = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4F4F).withOpacity(0.80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _bonusBuffs
                          ? const Color(0xFF7FFF00)
                          : const Color(0xFFF5F5DC).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bonus Buffs',
                        style: GoogleFonts.pirataOne(
                          fontSize: 22,
                          color: const Color(0xFFF5F5DC),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Off',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: !_bonusBuffs
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: !_bonusBuffs
                                  ? const Color(0xFFF5F5DC)
                                  : const Color(0xFFF5F5DC).withOpacity(0.5),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              key: MonsterMashMenuKeys.bonusBuffsSwitch,
                              value: _bonusBuffs,
                              activeColor: const Color(0xFF7FFF00),
                              onChanged: (value) {
                                setState(() {
                                  _bonusBuffs = value;
                                });
                              },
                            ),
                          ),
                          Text(
                            'On',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: _bonusBuffs
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _bonusBuffs
                                  ? const Color(0xFFF5F5DC)
                                  : const Color(0xFFF5F5DC).withOpacity(0.5),
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

        // Row 2: Speed Play switch | Round Limit slider
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4F4F).withOpacity(0.80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _speedPlay
                          ? const Color(0xFFFF8C00)
                          : const Color(0xFFF5F5DC).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Speed Play',
                        style: GoogleFonts.pirataOne(
                          fontSize: 22,
                          color: const Color(0xFFF5F5DC),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Off',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: !_speedPlay
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: !_speedPlay
                                  ? const Color(0xFFF5F5DC)
                                  : const Color(0xFFF5F5DC).withOpacity(0.5),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              key: MonsterMashMenuKeys.speedPlaySwitch,
                              value: _speedPlay,
                              activeColor: const Color(0xFFFF8C00),
                              onChanged: (value) {
                                setState(() {
                                  _speedPlay = value;
                                });
                              },
                            ),
                          ),
                          Text(
                            'On',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: _speedPlay
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _speedPlay
                                  ? const Color(0xFFF5F5DC)
                                  : const Color(0xFFF5F5DC).withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _speedPlay
                        ? const Color(0xFF2F4F4F).withOpacity(0.80)
                        : const Color(0xFF1A1A2E).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _speedPlay
                          ? const Color(0xFFF5F5DC).withOpacity(0.3)
                          : const Color(0xFFF5F5DC).withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rounds: ${_roundLimit.toInt()}',
                        style: GoogleFonts.pirataOne(
                          fontSize: 22,
                          color: _speedPlay
                              ? const Color(0xFFF5F5DC)
                              : const Color(0xFFF5F5DC).withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          key: MonsterMashMenuKeys.roundLimitSlider,
                          value: _roundLimit,
                          min: 3,
                          max: 20,
                          divisions: 17,
                          label: _roundLimit.toInt().toString(),
                          activeColor: const Color(0xFFFF8C00),
                          onChanged: _speedPlay
                              ? (value) {
                                  setState(() {
                                    _roundLimit = value;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Row 3: Available Players | Selected Players
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DualPlayerListPanel(
              config: DualPlayerListPanelConfig.monsterMash(),
              addPlayerButtonKey: MonsterMashMenuKeys.addPlayerButton,
              addPlayerButtonEmptyStateKey:
                  MonsterMashMenuKeys.addPlayerButtonEmptyState,
              playerListViewKey: MonsterMashMenuKeys.playerListView,
              playerTileKey: (id) => MonsterMashMenuKeys.playerTile(id),
              customAddPlayerButton: (
                  {required Key key,
                  required VoidCallback onPressed,
                  required bool isEmptyState}) {
                return _buildStoneNewPlayerButton(
                  key: key,
                  onPressed: onPressed,
                  fontSize: isEmptyState ? 24 : 18,
                  iconSize: isEmptyState ? 24 : 18,
                  width: isEmptyState ? 210 : 170,
                  height: isEmptyState ? 44 : 36,
                  seed: isEmptyState
                      ? 'NEW_PLAYER_EMPTY'.hashCode
                      : 'NEW_PLAYER_HEADER'.hashCode,
                );
              },
            ),
          ),
        ),

        // Row 4: Start button
        _buildStartButton(canStart, selectedPlayers),
      ],
    );
  }

  Widget _buildStartButton(bool canStart, List<Player> selectedPlayers) {
    final jaggedClipper = _JaggedEdgeClipper(
        seed: 'MONSTER_MASH_START'.hashCode,
        jagAmount: 4.0,
        segmentsPerSide: 30);

    final buttonContent = SizedBox(
      width: double.infinity,
      height: 56,
      child: CustomPaint(
        painter: _StoneTabletPainter(jaggedClipper: jaggedClipper),
        child: ClipPath(
          clipper: jaggedClipper,
          child: Stack(
            children: [
              // Stone gradient fill
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: canStart
                        ? const RadialGradient(
                            center: Alignment(-0.4, -0.4),
                            radius: 1.2,
                            colors: [
                              Color(0xFFa8a8a8),
                              Color(0xFF888888),
                              Color(0xFF707070),
                            ],
                          )
                        : const RadialGradient(
                            center: Alignment(-0.4, -0.4),
                            radius: 1.2,
                            colors: [
                              Color(0xFF707070),
                              Color(0xFF585858),
                              Color(0xFF484848),
                            ],
                          ),
                  ),
                ),
              ),
              // Inner bevel: top/bottom edges
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.15, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
              // Inner bevel: left/right edges
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                      ],
                      stops: const [0.0, 0.08, 0.92, 1.0],
                    ),
                  ),
                ),
              ),
              // Cracked stone texture overlay
              Positioned.fill(
                child: Opacity(
                  opacity: canStart ? 1.0 : 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage(
                            'assets/games/monster_mash/images/stone-texture.png'),
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                ),
              ),
              // Lightning effect overlay
              if (canStart)
                Positioned.fill(
                  child: RepaintBoundary(child: AnimatedBuilder(
                    animation: _lightningController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _LightningPainter(
                          animationValue: _lightningController.value,
                        ),
                      );
                    },
                  )),
                ),
              // Button content - chiseled text
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: MonsterMashMenuKeys.startGameButton,
                    onTap: canStart ? () => _startGame(selectedPlayers) : null,
                    child: Center(
                      child: Text(
                        "LET'S DO THE MONSTER MASH!",
                        style: GoogleFonts.creepster(
                          fontSize: 40,
                          color: canStart
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF555555),
                          letterSpacing: 1.5,
                          shadows: canStart
                              ? [
                                  Shadow(
                                      color: Colors.white.withOpacity(0.5),
                                      offset: const Offset(1, 1),
                                      blurRadius: 0),
                                  const Shadow(
                                      color: Colors.black,
                                      offset: Offset(-1, -1),
                                      blurRadius: 0),
                                ]
                              : [],
                        ),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: RepaintBoundary(child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glowOpacity =
              canStart ? (0.3 + (_pulseController.value * 0.5)) : 0.0;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: canStart
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7FFF00).withOpacity(glowOpacity),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFF7FFF00)
                            .withOpacity(glowOpacity * 0.5),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: buttonContent,
          );
        },
      )),
    );
  }

  void _resumeGame(SavedGameMetadata savedGame) {
    context.read<MonsterMashProvider>().restoreGame(savedGame);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MonsterMashGameScreen()),
    ).then((_) => _checkForSavedGames());
  }

  void _startGame(List<Player> selectedPlayers) {
    final monsterMashProvider = context.read<MonsterMashProvider>();

    monsterMashProvider.startGame(
      selectedPlayers,
      _healthMax.toInt(),
      _bonusBuffs,
      _speedPlay,
      _roundLimit.toInt(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonsterMashGameScreen(),
      ),
    ).then((_) => _checkForSavedGames());
  }

  Widget _buildStoneNewPlayerButton({
    required Key key,
    required VoidCallback onPressed,
    required double fontSize,
    required double iconSize,
    required double width,
    required double height,
    required int seed,
  }) {
    final jaggedClipper =
        _JaggedEdgeClipper(seed: seed, jagAmount: 3.0, segmentsPerSide: 20);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _StoneTabletPainter(jaggedClipper: jaggedClipper),
        child: ClipPath(
          clipper: jaggedClipper,
          child: Stack(
            children: [
              // Stone gradient fill
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.4, -0.4),
                      radius: 1.2,
                      colors: [
                        Color(0xFFa8a8a8),
                        Color(0xFF888888),
                        Color(0xFF707070),
                      ],
                    ),
                  ),
                ),
              ),
              // Inner bevel: top/bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.15, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
              // Inner bevel: left/right
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                      ],
                      stops: const [0.0, 0.08, 0.92, 1.0],
                    ),
                  ),
                ),
              ),
              // Stone texture
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/games/monster_mash/images/stone-texture.png'),
                      repeat: ImageRepeat.repeat,
                      fit: BoxFit.none,
                    ),
                  ),
                ),
              ),
              // Lightning effect
              Positioned.fill(
                child: RepaintBoundary(child: AnimatedBuilder(
                  animation: _lightningController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _LightningPainter(
                        animationValue:
                            (_lightningController.value + 0.5) % 1.0,
                        lightningColor: const Color(0xFFF5F5DC),
                        seedOffset: seed,
                      ),
                    );
                  },
                )),
              ),
              // Button content
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: key,
                    onTap: onPressed,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: iconSize,
                            color: const Color(0xFF1A1A1A),
                            shadows: [
                              Shadow(
                                  color: Colors.white.withOpacity(0.5),
                                  offset: const Offset(1, 1),
                                  blurRadius: 0),
                              const Shadow(
                                  color: Colors.black,
                                  offset: Offset(-1, -1),
                                  blurRadius: 0),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NEW PLAYER',
                            style: GoogleFonts.pirataOne(
                              fontSize: fontSize,
                              color: const Color(0xFF1A1A1A),
                              shadows: [
                                Shadow(
                                    color: Colors.white.withOpacity(0.5),
                                    offset: const Offset(1, 1),
                                    blurRadius: 0),
                                const Shadow(
                                    color: Colors.black,
                                    offset: Offset(-1, -1),
                                    blurRadius: 0),
                              ],
                            ),
                          ),
                        ],
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
  }
}

/// Clips a rectangle with jagged/chipped stone edges
class _JaggedEdgeClipper extends CustomClipper<Path> {
  final int seed;
  final double jagAmount;
  final int segmentsPerSide;

  _JaggedEdgeClipper({
    this.seed = 0,
    this.jagAmount = 3.5,
    this.segmentsPerSide = 20,
  });

  @override
  Path getClip(Size size) {
    final rng = Random(seed);
    final path = Path();

    final w = size.width;
    final h = size.height;

    path.moveTo(jagAmount, jagAmount);

    // Top edge
    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = (w - jagAmount * 2) * i / segmentsPerSide + jagAmount;
      final y = (rng.nextDouble() - 0.5) * jagAmount * 2;
      path.lineTo(x, y.clamp(0, jagAmount * 2));
    }

    // Right edge
    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = w - (rng.nextDouble() - 0.5) * jagAmount * 2;
      final y = (h - jagAmount * 2) * i / segmentsPerSide + jagAmount;
      path.lineTo(x.clamp(w - jagAmount * 2, w), y);
    }

    // Bottom edge
    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = w - (w - jagAmount * 2) * i / segmentsPerSide - jagAmount;
      final y = h - (rng.nextDouble() - 0.5) * jagAmount * 2;
      path.lineTo(x, y.clamp(h - jagAmount * 2, h));
    }

    // Left edge
    for (int i = 1; i <= segmentsPerSide; i++) {
      final x = (rng.nextDouble() - 0.5) * jagAmount * 2;
      final y = h - (h - jagAmount * 2) * i / segmentsPerSide - jagAmount;
      path.lineTo(x.clamp(0, jagAmount * 2), y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Paints the stone border and shadow following the jagged path
class _StoneTabletPainter extends CustomPainter {
  final _JaggedEdgeClipper jaggedClipper;

  _StoneTabletPainter({required this.jaggedClipper});

  @override
  void paint(Canvas canvas, Size size) {
    final path = jaggedClipper.getClip(size);

    // Floor shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.save();
    canvas.translate(5, 5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Stone border
    final borderPaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LightningPainter extends CustomPainter {
  final double animationValue;
  final Color lightningColor;
  final int seedOffset;

  _LightningPainter(
      {required this.animationValue,
      this.lightningColor = const Color(0xFF7FFF00),
      this.seedOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    _maybeDrawBolt(canvas, size,
        phase: 0.0, duration: 0.08, seed: 42 + seedOffset);
    _maybeDrawBolt(canvas, size,
        phase: 0.05, duration: 0.04, seed: 43 + seedOffset);
    _maybeDrawBolt(canvas, size,
        phase: 0.45, duration: 0.06, seed: 77 + seedOffset);
    _maybeDrawBolt(canvas, size,
        phase: 0.50, duration: 0.03, seed: 78 + seedOffset);

    final flashOpacity = _getFlashOpacity();
    if (flashOpacity > 0) {
      final flashPaint = Paint()
        ..color = lightningColor.withOpacity(flashOpacity * 0.15);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }
  }

  double _getFlashOpacity() {
    // Flash during bolt windows
    for (final window in [
      (0.0, 0.08),
      (0.05, 0.04),
      (0.45, 0.06),
      (0.50, 0.03)
    ]) {
      final start = window.$1;
      final dur = window.$2;
      if (animationValue >= start && animationValue <= start + dur) {
        final t = (animationValue - start) / dur;
        return 1.0 - (2.0 * (t - 0.5)).abs(); // peak at midpoint
      }
    }
    return 0.0;
  }

  void _maybeDrawBolt(
    Canvas canvas,
    Size size, {
    required double phase,
    required double duration,
    required int seed,
  }) {
    if (animationValue < phase || animationValue > phase + duration) return;

    final t = (animationValue - phase) / duration;
    // Fade in fast, fade out
    final opacity = t < 0.3 ? t / 0.3 : 1.0 - ((t - 0.3) / 0.7);

    final rng = Random(seed);
    final startX = size.width * (0.15 + rng.nextDouble() * 0.7);
    final segments = 5 + rng.nextInt(4);

    final path = Path();
    path.moveTo(startX, 0);

    double x = startX;
    double y = 0;
    final segHeight = size.height / segments;

    for (int i = 0; i < segments; i++) {
      x += (rng.nextDouble() - 0.5) * size.width * 0.3;
      x = x.clamp(4.0, size.width - 4.0);
      y += segHeight;
      path.lineTo(x, y);
    }

    // Core bright bolt
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, corePaint);

    // Outer glow
    final glowPaint = Paint()
      ..color = lightningColor.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    // Wide ambient glow
    final ambientPaint = Paint()
      ..color = lightningColor.withOpacity(opacity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, ambientPaint);
  }

  @override
  bool shouldRepaint(covariant _LightningPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.lightningColor != lightningColor ||
        oldDelegate.seedOffset != seedOffset;
  }
}
