import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/test_keys.dart';
import '../../../models/saved_game_metadata.dart';
import '../../../providers/dartboard_provider.dart';
import '../../../providers/gladiator_arena_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/save_game_service.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../../../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal.dart';
import '../../../widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart';
import '../../../widgets/player_list_panel/dual_player_list_panel.dart';
import '../../../widgets/player_list_panel/dual_player_list_panel_config.dart';
import '../../../widgets/resume_game_button.dart';
import '../../../widgets/resume_game_modal/resume_game_modal.dart';
import '../../../widgets/resume_game_modal/resume_game_modal_config.dart';
import 'gladiator_arena_game_screen.dart';

// ─── Character asset paths ─────────────────────────────────────────────────────

const _kCharacterPaths = [
  'assets/games/gladiator_arena/characters/LeoLion.png',
  'assets/games/gladiator_arena/characters/AquilaEagle.png',
  'assets/games/gladiator_arena/characters/LupusWolf.png',
  'assets/games/gladiator_arena/characters/UrsusBear.png',
  'assets/games/gladiator_arena/characters/CorvusRaven.png',
  'assets/games/gladiator_arena/characters/TaurusBull.png',
  'assets/games/gladiator_arena/characters/SerpensSnake.png',
  'assets/games/gladiator_arena/characters/FalcoFalcon.png',
];

// ─── Color constants ──────────────────────────────────────────────────────────

const _kMarbleWhite = Color(0xFFF5F0E8);
const _kGladiatorGold = Color(0xFFDAA520);
const _kArenaSand = Color(0xFFD2B48C);
const _kImperialPurple = Color(0xFF7B2D8E);
const _kBronze = Color(0xFFCD7F32);
const _kColosseumGray = Color(0xFF8B8682);
const _kDarkArena = Color(0xFF2A1500);

class GladiatorArenaMenuScreen extends StatefulWidget {
  /// CHANGE RULES on the results screen passes the prior game's settings
  /// here so they persist into the new menu instance.
  final int? initialTargetScore;
  final bool? initialDoubleFinishEnabled;
  final bool? initialShieldRoundEnabled;
  final bool? initialSpeedPlayEnabled;
  final List<String>? initialSelectedPlayerIds;

  const GladiatorArenaMenuScreen({
    super.key,
    this.initialTargetScore,
    this.initialDoubleFinishEnabled,
    this.initialShieldRoundEnabled,
    this.initialSpeedPlayEnabled,
    this.initialSelectedPlayerIds,
  });

  @override
  State<GladiatorArenaMenuScreen> createState() =>
      _GladiatorArenaMenuScreenState();
}

class _GladiatorArenaMenuScreenState extends State<GladiatorArenaMenuScreen> {
  // Settings state
  double _targetScore = 200;
  bool _doubleFinishEnabled = true;
  bool _shieldRoundEnabled = false;
  bool _speedPlayEnabled = false;

  // Resume game state
  bool _hasSavedGames = false;
  bool _showResumeModal = false;

  @override
  void initState() {
    super.initState();

    // Settings hydration:
    //   - widget.initialX is supplied ONLY via "Change Rules" from the
    //     results screen (preserves the just-played settings).
    //   - On any other entry (home-screen tap, back-button re-entry, etc.)
    //     the constructor params are null and we fall back to defaults —
    //     NOT to the prior game or stored pending settings. Per user:
    //     entering a game from the home menu should always show defaults.
    _targetScore = (widget.initialTargetScore ?? 200).toDouble();
    _doubleFinishEnabled = widget.initialDoubleFinishEnabled ?? true;
    _shieldRoundEnabled = widget.initialShieldRoundEnabled ?? false;
    _speedPlayEnabled = widget.initialSpeedPlayEnabled ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Refresh roster and wipe inherited selection (Rule 41).
      final playerProvider = context.read<PlayerProvider>();
      await playerProvider.loadPlayers();
      // loadPlayers is an HTTP roundtrip; the widget may unmount during the
      // gap (user backs out, dartboard disconnect grabs nav, test teardown).
      // Touching the provider after disposal triggers a "ChangeNotifier was
      // used after being disposed" assertion.
      if (!mounted) return;
      playerProvider.clearSelection();

      // Re-select players from CHANGE RULES navigation.
      if (widget.initialSelectedPlayerIds != null) {
        for (final id in widget.initialSelectedPlayerIds!) {
          final player = playerProvider.allPlayers
              .where((p) => p.id == id)
              .firstOrNull;
          if (player != null) {
            playerProvider.selectPlayer(player, maxPlayers: 8);
          }
        }
      }

      // Initial saved-games check — auto-open resume modal on entry.
      final hasSaved = await SaveGameService().hasSavedGames('gladiator_arena');
      if (mounted) {
        setState(() {
          _hasSavedGames = hasSaved;
          _showResumeModal = hasSaved;
        });
      }
    });
  }

  /// Persists current menu settings to the provider so they survive
  /// back-navigation (menu rebuilt as a fresh widget instance).
  void _persistMenuSettings() {
    context.read<GladiatorArenaProvider>().saveMenuSettings(
          targetScore: _targetScore.toInt(),
          doubleFinishEnabled: _doubleFinishEnabled,
          shieldRoundEnabled: _shieldRoundEnabled,
          speedPlayEnabled: _speedPlayEnabled,
        );
  }

  Future<void> _checkForSavedGames() async {
    final hasSaved = await SaveGameService().hasSavedGames('gladiator_arena');
    if (mounted) {
      setState(() => _hasSavedGames = hasSaved);
    }
  }

  void _resumeGame(SavedGameMetadata savedGame) {
    context.read<GladiatorArenaProvider>().restoreGame(savedGame);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GladiatorArenaGameScreen()),
    ).then((_) => _checkForSavedGames());
  }

  void _startGame() {
    final playerProvider = context.read<PlayerProvider>();
    final selectedPlayers = playerProvider.selectedPlayers;
    if (selectedPlayers.length < 2) return;

    final selectedPlayerIds = selectedPlayers.map((p) => p.id).toList();

    // Shuffle characters and assign one per player (Rule 1 — randomise in menu).
    final shuffled = List<String>.from(_kCharacterPaths)..shuffle(Random());
    final characterPaths = <String, String>{};
    for (int i = 0; i < selectedPlayerIds.length; i++) {
      characterPaths[selectedPlayerIds[i]] = shuffled[i % shuffled.length];
    }

    context.read<GladiatorArenaProvider>().startGame(
          playerIds: selectedPlayerIds,
          targetScore: _targetScore.toInt(),
          doubleFinishEnabled: _doubleFinishEnabled,
          shieldRoundEnabled: _shieldRoundEnabled,
          speedPlayEnabled: _speedPlayEnabled,
          playerCharacterPaths: characterPaths,
        );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GladiatorArenaGameScreen()),
    ).then((_) => _checkForSavedGames());
  }

  @override
  Widget build(BuildContext context) {
    final dartboardProvider = context.watch<DartboardProvider>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _kDarkArena,
          appBar: AppBar(
            leading: IconButton(
              key: GladiatorArenaMenuKeys.backButton,
              icon: const Icon(Icons.arrow_back, color: _kMarbleWhite, size: 32),
              onPressed: () => Navigator.of(context).pop(),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            title: Transform.translate(
              // Cinzel's ascender pushes the visual baseline high in
              // the AppBar strip; nudge down 2 px so caps sit centered.
              offset: const Offset(0, 2),
              child: Text(
                'GLADIATOR ARENA GAME SETUP',
                style: GoogleFonts.cinzel(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _kMarbleWhite,
                  letterSpacing: 1.5,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 4,
                        offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
            backgroundColor: const Color(0xFF4A3520),
            foregroundColor: _kMarbleWhite,
            actions: [
              if (_hasSavedGames)
                ResumeGameButton(
                  hasSavedGames: _hasSavedGames,
                  onPressed: () => setState(() => _showResumeModal = true),
                  color: _kGladiatorGold,
                ),
              DartboardConnectionInfo(
                config: DartboardConnectionInfoConfig.gladiatorArena(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // Background image with dark overlay for readability
              Positioned.fill(
                child: Image.asset(
                  'assets/games/gladiator_arena/images/GladiatorArena-Background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _kDarkArena,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
              Consumer<PlayerProvider>(
                builder: (context, playerProvider, child) {
                  if (playerProvider.isLoading) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: _kGladiatorGold));
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 40,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: _buildLeftPanel(),
                              ),
                            ),
                            Expanded(
                              flex: 60,
                              child: _buildRightPanel(scrollable: false),
                            ),
                          ],
                        );
                      } else {
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
                  );
                },
              ),
            ],
          ),
        ),
        // Resume game modal — covers entire screen including AppBar.
        if (_showResumeModal)
          ResumeGameModal(
            config: ResumeGameModalConfig.gladiatorArena(),
            gameType: 'gladiator_arena',
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
            config: DartboardPausedModalConfig.gladiatorArena(),
          ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 0, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3520).withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBronze.withOpacity(0.5), width: 2),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOW TO PLAY',
              style: GoogleFonts.cinzel(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: _kGladiatorGold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter the colosseum and battle for glory! Race to the target score, '
              'but beware — land on an opponent\'s exact score and you\'ll knock them '
              'off their podium back to zero!',
              style: GoogleFonts.lato(
                fontSize: 20,
                color: _kMarbleWhite,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildStep('1', 'Throw darts to score Glory Points and race to the target.'),
            _buildStep(
                '2',
                'Keep your opponents at bay. If your score at the end of a turn '
                "EXACTLY matches an opponents score, they are knocked off the "
                'podium and reset to 0 points.'),
            _buildStep('3', 'First to reach the target score wins!'),
            const SizedBox(height: 16),
            Text(
              'OPTIONS:',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kGladiatorGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _buildOptionBullet(
                'Double Finish',
                'If Double Finish is on, your last dart to win must be a double '
                'or your score is reset to the start of your turn.'),
            _buildOptionBullet(
                'Shield Round',
                'Every 5th round you cannot knock an opponent off their podium.'),
            _buildOptionBullet(
                'Speed Play',
                'Keep the game moving with a 25 second turn clock.'),
            const SizedBox(height: 16),
            Text(
              'BEGINNER TIPS:',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kGladiatorGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _buildBullet('Turn off Double Finish for younger players '
                '(any dart reaching the target wins).'),
            _buildBullet('Slide Target Score toward 100-150 for shorter games.'),
            _buildBullet('Shield Round protects players every 5th round.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ',
              style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kGladiatorGold)),
          Expanded(
            child: Text(text,
                style: GoogleFonts.lato(
                    fontSize: 20, color: _kMarbleWhite, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.lato(
                  fontSize: 20, color: _kBronze)),
          Expanded(
            child: Text(text,
                style: GoogleFonts.lato(
                    fontSize: 20,
                    color: _kMarbleWhite.withOpacity(0.85),
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  /// Bullet with a bold "Name:" prefix followed by a normal description.
  /// Used in the OPTIONS section so the option names stand out.
  Widget _buildOptionBullet(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.lato(
                  fontSize: 20, color: _kBronze)),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.lato(
                    fontSize: 20,
                    color: _kMarbleWhite.withOpacity(0.85),
                    height: 1.4),
                children: [
                  TextSpan(
                    text: '$name:',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      color: _kMarbleWhite,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  TextSpan(text: ' $description'),
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
    final selectedPlayers = playerProvider.selectedPlayers;
    final canStart = selectedPlayers.length >= 2 && selectedPlayers.length <= 8;

    final Widget playerPanelWrapper = scrollable
        ? SizedBox(
            height: 400,
            child: _buildPlayerPanel(),
          )
        : Expanded(child: _buildPlayerPanel());

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Settings Row 1: Target Score + Double Finish
        SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildTargetScoreBox()),
              const SizedBox(width: 8),
              Expanded(child: _buildToggleBox(
                label: 'Double Finish',
                value: _doubleFinishEnabled,
                key: GladiatorArenaMenuKeys.doubleFinishSwitch,
                onChanged: (v) {
                  setState(() => _doubleFinishEnabled = v);
                  _persistMenuSettings();
                },
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Settings Row 2: Shield Round + Speed Play
        SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildToggleBox(
                label: 'Shield Round',
                value: _shieldRoundEnabled,
                key: GladiatorArenaMenuKeys.shieldRoundSwitch,
                onChanged: (v) {
                  setState(() => _shieldRoundEnabled = v);
                  _persistMenuSettings();
                },
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildToggleBox(
                label: 'Speed Play',
                value: _speedPlayEnabled,
                key: GladiatorArenaMenuKeys.speedPlaySwitch,
                onChanged: (v) {
                  setState(() => _speedPlayEnabled = v);
                  _persistMenuSettings();
                },
              )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Player list panel
        playerPanelWrapper,
        const SizedBox(height: 16),
        // Start button
        Opacity(
          opacity: canStart ? 1.0 : 0.5,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              key: GladiatorArenaMenuKeys.startGameButton,
              onPressed: canStart ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBronze,
                foregroundColor: _kMarbleWhite,
                // Tighter padding so the larger text fits inside the
                // fixed 56px button height (default vertical padding
                // would push 26pt text outside the box).
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: _kGladiatorGold, width: 1.5),
                ),
                elevation: 4,
              ),
              child: Text(
                'ENTER THE ARENA!',
                style: GoogleFonts.cinzel(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _kMarbleWhite,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }

  Widget _buildTargetScoreBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _kArenaSand.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBronze, width: 2),
      ),
      child: Row(
        children: [
          // Target Score label + value on a single horizontal line
          Text('Target Score:',
              style: GoogleFonts.cinzel(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _kDarkArena)),
          const SizedBox(width: 8),
          Text(
            '${_targetScore.toInt()}',
            key: GladiatorArenaMenuKeys.targetScoreValue,
            style: GoogleFonts.cinzel(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _kImperialPurple),
          ),
          // Gap between the target-score number and the slider's left edge —
          // the previous SliderTheme(noOverlay) + Slider(padding: zero) tweak
          // pushed the slider track flush against the value text.
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _kImperialPurple,
                inactiveTrackColor: _kBronze.withOpacity(0.4),
                thumbColor: _kGladiatorGold,
                // Tighter overlay/thumb so the visible track extends closer
                // to the slider's right edge — aligns the track end with
                // the toggle boxes' "On" label x-position.
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackShape: const RectangularSliderTrackShape(),
                trackHeight: 4,
              ),
              child: Slider(
                key: GladiatorArenaMenuKeys.targetScoreSlider,
                value: _targetScore,
                min: 100,
                max: 500,
                divisions: 16, // (500-100)/25 = 16 stops
                label: '${_targetScore.toInt()}',
                padding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() => _targetScore =
                      (value / 25).round() * 25.0);
                  _persistMenuSettings();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBox({
    required String label,
    required bool value,
    required Key key,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _kArenaSand.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? _kGladiatorGold : _kBronze,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cinzel(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _kDarkArena,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Off',
                  style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight:
                          !value ? FontWeight.bold : FontWeight.normal,
                      color: !value ? _kDarkArena : _kColosseumGray)),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  key: key,
                  value: value,
                  activeColor: _kImperialPurple,
                  onChanged: onChanged,
                ),
              ),
              Text('On',
                  style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight:
                          value ? FontWeight.bold : FontWeight.normal,
                      color: value ? _kImperialPurple : _kColosseumGray)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPanel() {
    return DualPlayerListPanel(
      config: DualPlayerListPanelConfig.gladiatorArena(),
      addPlayerButtonKey: GladiatorArenaMenuKeys.addPlayerButton,
      addPlayerButtonEmptyStateKey:
          GladiatorArenaMenuKeys.addPlayerButtonEmptyState,
      playerListViewKey: GladiatorArenaMenuKeys.playerListView,
      playerTileKey: (id) => GladiatorArenaMenuKeys.playerTile(id),
      removePlayerButtonKey: (id) =>
          GladiatorArenaMenuKeys.removePlayerButton(id),
    );
  }
}
