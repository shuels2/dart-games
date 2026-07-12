// Measurement-only test (not part of the production suite). Builds each
// game's AppBar title TextStyle via the same GoogleFonts call the screen
// uses, lays it out with a TextPainter, and prints the actual rendered
// height + width to stdout so we can compare per-game title metrics.
//
// CAVEAT: in flutter test, GoogleFonts cannot fetch its WOFF files (no
// network), so the renderer falls back to the platform default font when
// it can't find the requested family. The reported numbers therefore
// reflect Flutter's text-layout pipeline using whatever the test-binding
// resolves each font family to, NOT the actual font seen in-app. The
// per-fontSize comparisons are still useful — the same fallback applies
// uniformly across games, so smaller fontSize = smaller measured height.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // testWidgets is used (instead of plain `test`) so the
  // TestWidgetsFlutterBinding initializes — GoogleFonts needs
  // ServicesBinding.instance for its (no-op-in-tests) asset lookup.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('measure each game AppBar title rendered height',
      (WidgetTester tester) async {
    final entries = <_Entry>[
      _Entry(
        'Carnival Horse Race',
        'Carnival Derby Race',
        GoogleFonts.rye(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: const Color(0xFFF1FAEE),
        ),
      ),
      _Entry(
        'Clockwork Quest',
        'CLOCKWORK QUEST',
        GoogleFonts.cinzelDecorative(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: const Color(0xFFF5F0E8),
        ),
      ),
      _Entry(
        'Gladiator Arena',
        'GLADIATOR ARENA',
        GoogleFonts.cinzel(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: const Color(0xFFF5F0E8),
        ),
      ),
      _Entry(
        'Lunar Lander',
        'LUNAR LANDER',
        GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: const Color(0xFFE8F0FF),
        ),
      ),
      _Entry(
        'Monster Mash',
        "It's Monster Mashin' Time!",
        GoogleFonts.creepster(
          fontSize: 39,
          letterSpacing: 1.5,
        ),
      ),
      _Entry(
        "Pirate's Grid",
        "PIRATE'S GRID",
        GoogleFonts.pirataOne(
          fontSize: 35,
          color: const Color(0xFFF5E6C8),
        ),
      ),
      _Entry(
        'Reef Royale',
        'Reef Royale',
        GoogleFonts.fredoka(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: const Color(0xFFFFF8F0),
        ),
      ),
      _Entry(
        'Target Tag',
        'Target Tag Game On!',
        GoogleFonts.luckiestGuy(
          fontSize: 36,
          letterSpacing: 1.5,
        ),
      ),
      _Entry(
        'Tiki Golf',
        'Tiki Golf',
        GoogleFonts.fugazOne(
          fontSize: 36,
          letterSpacing: 1.2,
          color: const Color(0xFFFFF8E1),
        ),
      ),
      _Entry(
        'Treasure Divide',
        'TREASURE DIVIDE',
        GoogleFonts.pirataOne(
          fontSize: 38,
          color: const Color(0xFFFFD700),
        ),
      ),
    ];

    // Right-pad name + text columns for legible output.
    String pad(String s, int n) =>
        s.length >= n ? s : s + ' ' * (n - s.length);

    debugPrint('');
    debugPrint(
        '${pad("Game", 20)}${pad("fontSize", 10)}${pad("textHeight", 12)}${pad("textWidth", 12)}${pad("ratio (h/fs)", 14)}  title');
    debugPrint(
        '${pad("-" * 20, 20)}${pad("-" * 8, 10)}${pad("-" * 10, 12)}${pad("-" * 9, 12)}${pad("-" * 12, 14)}  ${"-" * 30}');

    for (final e in entries) {
      final tp = TextPainter(
        text: TextSpan(text: e.text, style: e.style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      tp.layout();
      final fs = e.style.fontSize ?? 0;
      final ratio = fs == 0 ? 0.0 : (tp.height / fs);
      debugPrint(
        '${pad(e.name, 20)}'
        '${pad(fs.toStringAsFixed(0), 10)}'
        '${pad(tp.height.toStringAsFixed(2), 12)}'
        '${pad(tp.width.toStringAsFixed(2), 12)}'
        '${pad(ratio.toStringAsFixed(3), 14)}'
        '  "${e.text}"',
      );
    }
    debugPrint('');
    // No expects — this test exists to print measurements.
  });
}

class _Entry {
  final String name;
  final String text;
  final TextStyle style;
  _Entry(this.name, this.text, this.style);
}
