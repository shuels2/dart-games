import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/monster_mash_provider.dart';
import '../../../widgets/add_player/add_player.dart';
import '../../../widgets/horse_race/player_selection_card.dart';
import '../../../constants/test_keys.dart';
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
    with SingleTickerProviderStateMixin {
  double _healthMax = 20.0;
  bool _bonusBuffs = false;
  bool _speedPlay = false;
  double _roundLimit = 10.0;
  final ScrollController _availablePlayersScrollController = ScrollController();
  final ScrollController _selectedPlayersScrollController = ScrollController();
  late AnimationController _pulseController;
  PlayerProvider? _playerProvider;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  @override
  void dispose() {
    _playerProvider?.markPlayersSorted();
    _pulseController.dispose();
    _availablePlayersScrollController.dispose();
    _selectedPlayersScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    fontSize: 52,
                    color: const Color(0xFF7FFF00),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
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
                    fontSize: 30,
                    color: const Color(0xFFF5F5DC),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStep('1', 'Heal Yourself:', 'Hit YOUR assigned number to restore health points.'),
                _buildStep('2', 'Attack Opponents:', 'Hit an OPPONENT\'S number to deal damage equal to the multiplier.'),
                _buildStep('3', 'Bullseye Power:', 'Bullseye restores you to full health! Outer Bull heals +5.'),
                _buildStep('4', 'Last Monster Standing:', 'Reduce opponents to 0 HP to eliminate them. Be the last one alive!'),
                const SizedBox(height: 24),
                Text(
                  'Optional Features:',
                  style: GoogleFonts.creepster(
                    fontSize: 30,
                    color: const Color(0xFFF5F5DC),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBullet('Bonus Buffs:', 'Random supernatural effects can trigger each round - double damage, boosted healing, shadow protection, or lightning strikes!'),
                _buildBullet('Speed Play:', 'Set a round limit to keep games fast and competitive. When time runs out, the healthiest monster wins!'),
                const SizedBox(height: 16),
                Text(
                  'Grab your darts and let the Monster Mash begin!',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF8C00),
                    height: 1.5,
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
    final bool canStart = selectedPlayers.length >= 2 && selectedPlayers.length <= 8;

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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4F4F).withOpacity(0.80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF5F5DC).withOpacity(0.3), width: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4F4F).withOpacity(0.80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _bonusBuffs ? const Color(0xFF7FFF00) : const Color(0xFFF5F5DC).withOpacity(0.3),
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
                              fontWeight: !_bonusBuffs ? FontWeight.bold : FontWeight.normal,
                              color: !_bonusBuffs ? const Color(0xFFF5F5DC) : const Color(0xFFF5F5DC).withOpacity(0.5),
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
                              fontWeight: _bonusBuffs ? FontWeight.bold : FontWeight.normal,
                              color: _bonusBuffs ? const Color(0xFFF5F5DC) : const Color(0xFFF5F5DC).withOpacity(0.5),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4F4F).withOpacity(0.80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _speedPlay ? const Color(0xFFFF8C00) : const Color(0xFFF5F5DC).withOpacity(0.3),
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
                              fontWeight: !_speedPlay ? FontWeight.bold : FontWeight.normal,
                              color: !_speedPlay ? const Color(0xFFF5F5DC) : const Color(0xFFF5F5DC).withOpacity(0.5),
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
                              fontWeight: _speedPlay ? FontWeight.bold : FontWeight.normal,
                              color: _speedPlay ? const Color(0xFFF5F5DC) : const Color(0xFFF5F5DC).withOpacity(0.5),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAvailablePlayersSection(playerProvider)),
                const SizedBox(width: 16),
                Expanded(child: _buildSelectedPlayersSection(playerProvider)),
              ],
            ),
          ),
        ),

        // Row 4: Start button
        _buildStartButton(canStart, selectedPlayers),
      ],
    );
  }

  Widget _buildAvailablePlayersSection(PlayerProvider playerProvider) {
    final allPlayers = playerProvider.allPlayers;
    final selectedPlayers = playerProvider.selectedPlayers;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2F4F4F).withOpacity(0.80),
        border: Border.all(color: const Color(0xFFF5F5DC).withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Players',
                style: GoogleFonts.pirataOne(
                  fontSize: 22,
                  color: const Color(0xFFF5F5DC),
                ),
              ),
              if (allPlayers.isNotEmpty)
                ElevatedButton.icon(
                  key: MonsterMashMenuKeys.addPlayerButton,
                  onPressed: _handleAddPlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B0082),
                    foregroundColor: const Color(0xFFF5F5DC),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    side: const BorderSide(color: Color(0xFF7FFF00), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    'NEW PLAYER',
                    style: GoogleFonts.pirataOne(fontSize: 22, color: const Color(0xFFF5F5DC)),
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
                            color: const Color(0xFFF5F5DC).withOpacity(0.7),
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _handleAddPlayer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B0082),
                            foregroundColor: const Color(0xFFF5F5DC),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            side: const BorderSide(color: Color(0xFF7FFF00), width: 2),
                          ),
                          icon: const Icon(Icons.add, size: 24),
                          label: Text(
                            'NEW PLAYER',
                            style: GoogleFonts.pirataOne(fontSize: 24, color: const Color(0xFFF5F5DC)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    key: MonsterMashMenuKeys.playerListView,
                    controller: _availablePlayersScrollController,
                    itemCount: allPlayers.length,
                    itemBuilder: (context, index) {
                      final player = allPlayers[index];
                      final isSelected = selectedPlayers.any((p) => p.id == player.id);

                      return PlayerSelectionCard(
                        key: MonsterMashMenuKeys.playerTile(player.id),
                        player: player,
                        isSelected: isSelected,
                        selectedColor: const Color(0xFF4B0082),
                        selectedBorderColor: const Color(0xFF7FFF00),
                        onTap: () {
                          if (isSelected) {
                            playerProvider.deselectPlayer(player.id);
                          } else {
                            playerProvider.selectPlayer(player, maxPlayers: 8);
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted && _selectedPlayersScrollController.hasClients) {
                                    final targetPosition = _selectedPlayersScrollController.position.maxScrollExtent + 150;
                                    _selectedPlayersScrollController.animateTo(
                                      targetPosition,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              }
                            });
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

  Widget _buildSelectedPlayersSection(PlayerProvider playerProvider) {
    final selectedPlayers = playerProvider.selectedPlayers;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2F4F4F).withOpacity(0.80),
        border: Border.all(
          color: selectedPlayers.length >= 2 ? const Color(0xFF7FFF00) : const Color(0xFFF5F5DC).withOpacity(0.3),
          width: selectedPlayers.length >= 2 ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Players (${selectedPlayers.length}/8)',
            style: GoogleFonts.pirataOne(
              fontSize: 22,
              color: selectedPlayers.length >= 2 ? const Color(0xFF7FFF00) : const Color(0xFFF5F5DC),
            ),
          ),
          const SizedBox(height: 8),
          if (selectedPlayers.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Select at least 2 players',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFFF5F5DC).withOpacity(0.7),
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _selectedPlayersScrollController,
                itemCount: selectedPlayers.length,
                itemBuilder: (context, index) {
                  final player = selectedPlayers[index];
                  return PlayerSelectionCard(
                    player: player,
                    isSelected: true,
                    compact: false,
                    selectedColor: const Color(0xFF4B0082),
                    selectedBorderColor: const Color(0xFF7FFF00),
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

  Widget _buildStartButton(bool canStart, List<Player> selectedPlayers) {
    final jaggedClipper = _JaggedEdgeClipper(seed: 'MONSTER_MASH_START'.hashCode, jagAmount: 4.0, segmentsPerSide: 30);

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
                        image: AssetImage('assets/games/monster_mash/images/stone-texture.png'),
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                ),
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
                          color: canStart ? const Color(0xFF1A1A1A) : const Color(0xFF555555),
                          letterSpacing: 1.5,
                          shadows: canStart
                              ? [
                                  Shadow(color: Colors.white.withOpacity(0.5), offset: const Offset(1, 1), blurRadius: 0),
                                  const Shadow(color: Colors.black, offset: Offset(-1, -1), blurRadius: 0),
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
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glowOpacity = canStart ? (0.3 + (_pulseController.value * 0.5)) : 0.0;
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
                        color: const Color(0xFF7FFF00).withOpacity(glowOpacity * 0.5),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: buttonContent,
          );
        },
      ),
    );
  }

  void _handleAddPlayer() async {
    final player = await showAddPlayerDialog(
      context: context,
      config: AddPlayerDialogConfig.monsterMash(),
    );

    if (player != null && mounted) {
      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.savePlayer(player);

      if (playerProvider.selectedPlayers.length < 8) {
        playerProvider.selectPlayer(player, maxPlayers: 8);
      }

      _scrollToNewPlayer();
    }
  }

  void _scrollToNewPlayer() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (_availablePlayersScrollController.hasClients) {
              final targetPosition = _availablePlayersScrollController.position.maxScrollExtent + 150;
              _availablePlayersScrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            if (_selectedPlayersScrollController.hasClients) {
              final targetPosition = _selectedPlayersScrollController.position.maxScrollExtent + 150;
              _selectedPlayersScrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        });
      }
    });
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
