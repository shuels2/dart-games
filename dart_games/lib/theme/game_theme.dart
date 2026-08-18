import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Signature every game's font builders share.
///
/// Matches the shape of the `GoogleFonts.*` helpers so a theme can name a
/// font family once (`GoogleFonts.creepster`) and every config call it with
/// whatever size/colour/weight that particular widget needs.
typedef GameFont = TextStyle Function({
  double? fontSize,
  Color? color,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
});

/// The six ingredients every shared-widget config re-expresses per game.
///
/// WS03 §3.1. Ten config files — emulator, add-player, resume-modal,
/// edit-score, team-list, dual-list, connection-info, remove-darts,
/// save-modal, paused-modal — each carry ten or eleven per-game factories,
/// ~5,300 lines in total. Almost all of that is the SAME half-dozen values
/// restated: the same `Color(0xFF1D3557)` for Carnival Derby appears in every
/// one of those files independently, so retheming a game means finding ten
/// literals, and adding game #11 means editing ten files.
///
/// A `GameTheme` states them once. Configs read from it; anything a
/// particular widget genuinely does differently stays explicit at that
/// widget's factory, because those deviations are real design decisions
/// (Carnival's save modal uses a 56px icon where everyone else uses 48) and
/// flattening them would change rendered output.
///
/// ─── SCOPE NOTE ────────────────────────────────────────────────────────────
/// This deliberately does NOT touch dartboard-emulator BEHAVIOUR. Per
/// CLAUDE.md the emulator is off-limits without explicit permission; only its
/// config-factory colour/font layer is in scope, and only when that migration
/// is done.
@immutable
class GameTheme {
  const GameTheme({
    required this.gameId,
    required this.background,
    required this.accent,
    required this.onDark,
    required this.titleFont,
    required this.bodyFont,
    required this.shadow,
    required this.shadowOpacity,
    Color? surface,
  }) : _surface = surface;

  /// Snake-case id, matching the `gameType` used for saved games.
  final String gameId;

  /// Deep panel colour behind modals and cards.
  final Color background;

  /// Borders, highlights, primary buttons.
  final Color accent;

  /// Text on dark surfaces.
  final Color onDark;

  /// Display font — titles, headings, buttons.
  final GameFont titleFont;

  /// Reading font — body copy, labels.
  final GameFont bodyFont;

  /// Drop-shadow colour. Half the games shadow in black; the other half
  /// shadow in their own accent for a glow, which is a real per-game look
  /// and not a value worth collapsing.
  final Color shadow;

  /// Opacity the shadow is applied at.
  final double shadowOpacity;

  final Color? _surface;

  /// Card/box colour. Defaults to [background] for the games that use one
  /// flat panel colour.
  Color get surface => _surface ?? background;

  /// Every game, keyed by [gameId]. Adding game #11 means one entry here.
  static const Map<String, GameTheme> all = {
    'carnival_derby': carnivalDerby,
    'target_tag': targetTag,
    'monster_mash': monsterMash,
    'reef_royale': reefRoyale,
    'lunar_lander': lunarLander,
    'pirates_grid': piratesGrid,
    'gladiator_arena': gladiatorArena,
    'clockwork_quest': clockworkQuest,
    'tiki_golf': tikiGolf,
    'treasure_divide': treasureDivide,
  };

  static GameTheme of(String gameId) {
    final theme = all[gameId];
    if (theme == null) {
      throw ArgumentError.value(gameId, 'gameId', 'No GameTheme registered');
    }
    return theme;
  }

  static const carnivalDerby = GameTheme(
    gameId: 'carnival_derby',
    background: Color(0xFF1D3557),
    accent: Color(0xFFFFD700),
    onDark: Color(0xFFF1FAEE),
    titleFont: GoogleFonts.luckiestGuy,
    bodyFont: GoogleFonts.bangers,
    shadow: Colors.black,
    shadowOpacity: 0.5,
  );

  static const targetTag = GameTheme(
    gameId: 'target_tag',
    background: Color(0xFF1A1A2E),
    accent: Color(0xFFFF007A),
    onDark: Colors.white,
    titleFont: GoogleFonts.luckiestGuy,
    bodyFont: GoogleFonts.fredoka,
    shadow: Colors.black,
    shadowOpacity: 0.5,
  );

  static const monsterMash = GameTheme(
    gameId: 'monster_mash',
    background: Color(0xFF2F4F4F),
    accent: Color(0xFF7FFF00),
    onDark: Color(0xFFF5F5DC),
    titleFont: GoogleFonts.creepster,
    bodyFont: GoogleFonts.pirataOne,
    shadow: Color(0xFF7FFF00),
    shadowOpacity: 0.3,
  );

  static const reefRoyale = GameTheme(
    gameId: 'reef_royale',
    background: Color(0xFF0B3D91),
    accent: Color(0xFF48D1CC),
    onDark: Color(0xFFFFF8F0),
    titleFont: GoogleFonts.fredoka,
    bodyFont: GoogleFonts.fredoka,
    shadow: Color(0xFF48D1CC),
    shadowOpacity: 0.3,
  );

  static const lunarLander = GameTheme(
    gameId: 'lunar_lander',
    background: Color(0xFF1B4965),
    accent: Color(0xFFF26430),
    onDark: Color(0xFFFAFDF6),
    titleFont: GoogleFonts.orbitron,
    bodyFont: GoogleFonts.exo2,
    shadow: Color(0xFFF26430),
    shadowOpacity: 0.3,
  );

  static const piratesGrid = GameTheme(
    gameId: 'pirates_grid',
    background: Color(0xFF1B2838),
    accent: Color(0xFFCD7F32),
    onDark: Color(0xFFF5E6C8),
    titleFont: GoogleFonts.pirataOne,
    bodyFont: GoogleFonts.lora,
    shadow: Color(0xFFCD7F32),
    shadowOpacity: 0.3,
  );

  // Gladiator shadows in gold (0xFFDAA520) rather than its bronze accent —
  // preserved, not normalised.
  static const gladiatorArena = GameTheme(
    gameId: 'gladiator_arena',
    background: Color(0xFF3A2010),
    accent: Color(0xFFCD7F32),
    onDark: Color(0xFFF5F0E8),
    titleFont: GoogleFonts.cinzel,
    bodyFont: GoogleFonts.lato,
    shadow: Color(0xFFDAA520),
    shadowOpacity: 0.3,
  );

  // Clockwork likewise shadows in amber (0xFFFFBF00), not its brass accent,
  // and at 0.4 rather than 0.3.
  static const clockworkQuest = GameTheme(
    gameId: 'clockwork_quest',
    background: Color(0xFF2C2C34),
    accent: Color(0xFFC5A54E),
    onDark: Color(0xFFF5F0E8),
    titleFont: GoogleFonts.cinzelDecorative,
    bodyFont: GoogleFonts.lato,
    shadow: Color(0xFFFFBF00),
    shadowOpacity: 0.4,
  );

  static const tikiGolf = GameTheme(
    gameId: 'tiki_golf',
    background: Color(0xFF2D6A4F),
    accent: Color(0xFF00B4D8),
    onDark: Color(0xFFFFF5E1),
    titleFont: GoogleFonts.boogaloo,
    bodyFont: GoogleFonts.nunito,
    shadow: Colors.black,
    shadowOpacity: 0.5,
  );

  static const treasureDivide = GameTheme(
    gameId: 'treasure_divide',
    background: Color(0xFF008B8B),
    accent: Color(0xFFFFD700),
    onDark: Color(0xFFFFF8E7),
    titleFont: GoogleFonts.pirataOne,
    bodyFont: GoogleFonts.merriweather,
    shadow: Color(0xFFFFD700),
    shadowOpacity: 0.3,
  );
}
