// Visual AppBar-title ribbon in Chrome. For every game the test
// renders TWO strips of the AppBar's toolbarHeight (56 px):
//   - LEFT  = title in its current fontSize
//   - RIGHT = title in the recommended fontSize (targeted so the
//     UPPERCASE cap height ("H") matches Target Tag's cap height —
//     the previous "total ink" metric mixed up descender depth
//     with cap height and pulled mixed-case titles too small).
//
// The test also prints raw ink-height measurements to stdout — same
// pixel-walk logic as before (any Shadow with blurRadius > 0 is
// stripped so we only measure core text + solid outlines, not soft
// glows). Look for `[TITLE]` lines in the drive log.
//
// After the pump the test idles for ~2 minutes so you can inspect
// the ribbon in Chrome. Close Chrome or Ctrl+C to end.
//
// Run with:
//   ./chromedriver/chromedriver-win64/chromedriver.exe --port=4444 &
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/appbar_title_measurement_test.dart \
//     -d chrome
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';

// Metric: ABOVE-BASELINE height of the ACTUAL title text — i.e. from
// the top of drawn glyph pixels down to the alphabetic baseline of
// the rendered title. Recommendation is back-solved so each game's
// above-baseline height matches Target Tag's at fs 36.
//
// Why this beats "measure an isolated H":
//   * The H may not appear in the actual title.
//   * When it doesn't, GoogleFonts's cached font substitution can
//     resolve the isolated H against a fallback family whose H is
//     taller/shorter than the actual title glyphs.
//   * Measuring the actual title uses the real font's real caps
//     (e.g. Rye's 'C' in "Carnival Derby Race", Cinzel's 'G' in
//     "GLADIATOR ARENA") so the comparison is honest.
const List<_Entry> _kEntries = [
  _Entry(
    name: 'Carnival Derby',
    text: 'Carnival Derby Race',
    fontFamily: 'Rye',
    currentFs: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFFF1FAEE),
    background: Color(0xFF1D3557),
    // Metric said 31 (cap was 2 px short of Target Tag in the
    // baseline-aligned overlay). Bump for exact cap parity.
    overrideRecFs: 33,
  ),
  _Entry(
    name: 'Clockwork Quest',
    text: 'CLOCKWORK QUEST',
    fontFamily: 'CinzelDecorative',
    currentFs: 26,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: Color(0xFFF5F0E8),
    background: Color(0xFF2C2C34),
    // At fs 27 the caps came in 2 px short of Target Tag in the
    // baseline-aligned overlay; bump for exact cap parity.
    overrideRecFs: 29,
  ),
  _Entry(
    name: 'Gladiator Arena',
    text: 'GLADIATOR ARENA',
    fontFamily: 'Cinzel',
    currentFs: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: Color(0xFFF5F0E8),
    background: Color(0xFF4A3520),
  ),
  _Entry(
    name: 'Lunar Lander',
    text: 'LUNAR LANDER',
    fontFamily: 'Orbitron',
    currentFs: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: Color(0xFFE8F0FF),
    background: Color(0xFF0D1B2A),
    // Metric said 38, but the eye read the caps as ~3 px too tall
    // (Orbitron's heavy square strokes make its caps read bigger
    // than their pixel height). Trim for visual parity.
    overrideRecFs: 35,
  ),
  _Entry(
    name: 'Monster Mash',
    text: "It's Monster Mashin' Time!",
    fontFamily: 'Creepster',
    currentFs: 39,
    letterSpacing: 1.5,
    color: Color(0xFFF5F5DC),
    background: Color(0xFF2F4F4F),
  ),
  _Entry(
    name: "Pirate's Grid",
    text: "PIRATE'S GRID",
    fontFamily: 'PirataOne',
    currentFs: 35,
    color: Color(0xFFF5E6C8),
    background: Color(0xFF1B2838),
    // At fs 40 the caps came in 6 px too tall in the
    // baseline-aligned overlay; trim for cap parity.
    overrideRecFs: 35,
  ),
  _Entry(
    name: 'Reef Royale',
    text: 'Reef Royale',
    fontFamily: 'Fredoka',
    currentFs: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
    color: Color(0xFFFFF8F0),
    background: Color(0xFF0B3D91),
    // Metric said 38 but the caps came in ~3 px too tall in the
    // baseline-aligned overlay. Trim for cap parity.
    overrideRecFs: 35,
  ),
  _Entry(
    name: 'Target Tag  (baseline)',
    text: 'Target Tag Game On!',
    fontFamily: 'LuckiestGuy',
    currentFs: 36,
    letterSpacing: 1.5,
    color: Color(0xFFFFFFFF),
    background: Color(0xFF1A1A2E),
  ),
  _Entry(
    name: 'Tiki Golf',
    // Actual gameplay title is all-caps "TIKI GOLF" — no descenders.
    text: 'TIKI GOLF',
    // App uses Boogaloo, not FugazOne (earlier test was wrong).
    fontFamily: 'Boogaloo',
    currentFs: 36,
    color: Color(0xFFFFF8E1),
    background: Color(0xFF2D6A4F),
  ),
  _Entry(
    name: 'Treasure Divide',
    text: 'TREASURE DIVIDE',
    fontFamily: 'PirataOne',
    currentFs: 38,
    color: Color(0xFFFFD700),
    background: Color(0xFF008B8B),
    // At fs 40 the caps came in ~6 px too tall in the baseline-aligned
    // overlay; trim for cap parity.
    overrideRecFs: 34,
  ),
];

TextStyle _styleFor(_Entry e, double fs) {
  // Route through GoogleFonts so the same fetch+cache pipeline the
  // running app uses populates the font before the ribbon renders.
  switch (e.fontFamily) {
    case 'Rye':
      return GoogleFonts.rye(fontSize: fs, fontWeight: e.fontWeight, color: e.color);
    case 'CinzelDecorative':
      return GoogleFonts.cinzelDecorative(
          fontSize: fs,
          fontWeight: e.fontWeight,
          letterSpacing: e.letterSpacing,
          color: e.color);
    case 'Cinzel':
      return GoogleFonts.cinzel(
          fontSize: fs,
          fontWeight: e.fontWeight,
          letterSpacing: e.letterSpacing,
          color: e.color);
    case 'Orbitron':
      return GoogleFonts.orbitron(
          fontSize: fs,
          fontWeight: e.fontWeight,
          letterSpacing: e.letterSpacing,
          color: e.color);
    case 'Creepster':
      return GoogleFonts.creepster(
          fontSize: fs, letterSpacing: e.letterSpacing, color: e.color);
    case 'PirataOne':
      return GoogleFonts.pirataOne(fontSize: fs, color: e.color);
    case 'Fredoka':
      return GoogleFonts.fredoka(
          fontSize: fs,
          fontWeight: e.fontWeight,
          letterSpacing: e.letterSpacing,
          color: e.color);
    case 'LuckiestGuy':
      return GoogleFonts.luckiestGuy(
          fontSize: fs, letterSpacing: e.letterSpacing, color: e.color);
    case 'Boogaloo':
      return GoogleFonts.boogaloo(
          fontSize: fs, letterSpacing: e.letterSpacing, color: e.color);
    default:
      return TextStyle(fontSize: fs, color: e.color);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppBar-title visual ribbon: current vs. recommended fontSize',
      (WidgetTester tester) async {
    const appBarH = 56.0; // Material default AppBar toolbarHeight

    // Pre-pump every title so GoogleFonts fetches each family, then
    // let the fetches complete before we measure or render the ribbon.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final e in _kEntries)
                  Text(e.text, style: _styleFor(e, e.currentFs.toDouble())),
              ],
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Baseline: above-baseline height of Target Tag's ACTUAL title at fs 36.
    final baseline =
        _kEntries.firstWhere((e) => e.name.startsWith('Target Tag'));
    final baselineCap = await _measureAboveBaseline(
        baseline.text, _styleFor(baseline, baseline.currentFs.toDouble()));

    // For each entry, measure above-baseline height at the current
    // fontSize using the actual title text, then back-solve a
    // recommended fontSize whose above-baseline height would match
    // the baseline.
    final capNow = <String, int>{};
    final recFs = <String, int>{};
    for (final e in _kEntries) {
      final cap = await _measureAboveBaseline(
          e.text, _styleFor(e, e.currentFs.toDouble()));
      capNow[e.name] = cap;
      final computed = cap == 0
          ? e.currentFs
          : (e.currentFs * baselineCap / cap).round();
      recFs[e.name] = e.overrideRecFs ?? computed;
    }

    // Build the ribbon: for every entry, a row with
    //   [label] [current-fs strip] [recommended-fs strip] [overlay strip]
    // The overlay strip renders Target Tag's title in low-opacity WHITE
    // underneath the game title in RED, with both texts anchored at
    // their ALPHABETIC BASELINES (the imaginary line where the flat
    // bottoms of T, A, R, M, N etc. sit — where non-descender letters
    // rest). Same-baseline alignment lets the eye judge whether the
    // caps of the two fonts are actually the same visual height.
    Widget ribbon() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: const [
                SizedBox(
                  width: 200,
                  child: Text(
                    'Game (current fs → recommended fs)',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text('CURRENT fontSize',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('RECOMMENDED fontSize',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('BASELINE-ALIGNED OVERLAY\n(white = Target Tag @ fs 36 · red = game title)',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          for (final e in _kEntries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      '${e.name}\n'
                      'fs ${e.currentFs} → ${recFs[e.name]}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: _RibbonStrip(
                      height: appBarH,
                      background: e.background,
                      child: Text(
                        e.text,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: _styleFor(e, e.currentFs.toDouble()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RibbonStrip(
                      height: appBarH,
                      background: e.background,
                      child: Text(
                        e.text,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: _styleFor(e, recFs[e.name]!.toDouble()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BaselineOverlayStrip(
                      height: appBarH,
                      background: const Color(0xFF14161C),
                      ttStyle: _styleFor(baseline, baseline.currentFs.toDouble())
                          .copyWith(
                            color: const Color(0x99FFFFFF),
                            shadows: const <Shadow>[],
                          ),
                      ttText: baseline.text,
                      gameStyle: _styleFor(e, recFs[e.name]!.toDouble()).copyWith(
                        color: const Color(0xFFFF3D00),
                        shadows: const <Shadow>[],
                      ),
                      gameText: e.text,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF111318),
          appBar: AppBar(
            backgroundColor: const Color(0xFF20232A),
            title: Text(
                'AppBar title ribbon — above-baseline target = $baselineCap px (Target Tag @ fs ${baseline.currentFs})'),
          ),
          body: SingleChildScrollView(child: ribbon()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Capture a screenshot of the ribbon so I (Claude) can iterate
    // on the metric without asking the user to Photoshop screenshots.
    // Requires driver=test_driver/screenshot_test.dart, which handles
    // the `onScreenshot` callback and writes into temp_screenshots/.
    if (kIsWeb) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    await binding.takeScreenshot('appbar_title_ribbon');

    // ---- print measurements ----
    String pad(String s, int n) =>
        s.length >= n ? s : s + ' ' * (n - s.length);
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print(
        '[TITLE] Baseline above-baseline height at Target Tag fs=${baseline.currentFs}: $baselineCap px');
    // ignore: avoid_print
    print(
        '[TITLE] ${pad("Game", 22)}${pad("cur.fs", 8)}${pad("cur.cap", 10)}${pad("rec.fs", 8)}${pad("rec.cap", 10)}  title');
    // ignore: avoid_print
    print(
        '[TITLE] ${pad("-" * 22, 22)}${pad("-" * 6, 8)}${pad("-" * 7, 10)}${pad("-" * 6, 8)}${pad("-" * 7, 10)}  ${"-" * 30}');
    for (final e in _kEntries) {
      final rec = recFs[e.name]!;
      final recCap = await _measureAboveBaseline(
          e.text, _styleFor(e, rec.toDouble()));
      // ignore: avoid_print
      print(
        '[TITLE] '
        '${pad(e.name, 22)}'
        '${pad(e.currentFs.toString(), 8)}'
        '${pad(capNow[e.name].toString(), 10)}'
        '${pad(rec.toString(), 8)}'
        '${pad(recCap.toString(), 10)}'
        '  "${e.text}"',
      );
    }
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print(
        '[TITLE] Screenshot saved to temp_screenshots/appbar_title_ribbon.png');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// Above-baseline pixel height of the ACTUAL title text as rendered
/// in [style]. Returns the number of pixels between the top of the
/// highest drawn glyph pixel and the alphabetic baseline. This is
/// essentially the "cap height" of the tallest character actually
/// used in the title.
Future<int> _measureAboveBaseline(String text, TextStyle style) async {
  final coreStyle = _stripShadowGlows(style);
  final tp = TextPainter(
    text: TextSpan(text: text, style: coreStyle),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );
  tp.layout();
  final baselinePx =
      tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  const int margin = 4;
  final w = tp.width.ceil() + margin * 2;
  final h = tp.height.ceil() + margin * 2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  tp.paint(canvas, const Offset(4, 4));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final byteData =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = byteData!.buffer.asUint8List();
  int minY = h;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final a = bytes[(y * w + x) * 4 + 3];
      if (a > 8) {
        if (y < minY) minY = y;
        break;
      }
    }
  }
  image.dispose();
  if (minY >= h) return 0;
  // baselinePx is measured from top of paragraph = top of TextPainter
  // (before we added our +4 offset for the paint). minY is measured
  // in the picture coord space (with the +4 offset).
  final capPx = (baselinePx - (minY - 4)).round();
  return capPx > 0 ? capPx : 0;
}

TextStyle _stripShadowGlows(TextStyle style) {
  final ss = style.shadows;
  if (ss == null || ss.isEmpty) return style;
  final kept = ss.where((s) => s.blurRadius == 0).toList();
  return style.copyWith(shadows: kept.isEmpty ? null : kept);
}

/// A fixed-height horizontal strip that mimics an AppBar. Centers its
/// child vertically so the title glyphs sit inside the ribbon the
/// way they would in a real AppBar.
class _RibbonStrip extends StatelessWidget {
  const _RibbonStrip({
    required this.height,
    required this.background,
    required this.child,
  });

  final double height;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: background,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // No FittedBox — if the recommended fontSize overflows the
      // 56 px AppBar height it should CLIP, not shrink; that's a
      // real signal the recommendation is too aggressive.
      child: ClipRect(child: child),
    );
  }
}

/// Renders TWO texts stacked inside a fixed-height strip, both
/// anchored at the same alphabetic baseline so the eye can see
/// whether their caps really line up.
///
/// - [ttText] painted first, in [ttStyle] (Target Tag reference —
///   white / semi-transparent).
/// - [gameText] painted OVER it, in [gameStyle] (game title in a
///   contrasting color — red).
///
/// Uses CustomPainter (raw Canvas, not the Text widget) so the
/// baseline positioning is exact — Text widget layout adds strut /
/// leading that shifts the render, which doesn't match what
/// `TextPainter.computeDistanceToActualBaseline` reports.
class _BaselineOverlayStrip extends StatelessWidget {
  const _BaselineOverlayStrip({
    required this.height,
    required this.background,
    required this.ttText,
    required this.ttStyle,
    required this.gameText,
    required this.gameStyle,
  });

  final double height;
  final Color background;
  final String ttText;
  final TextStyle ttStyle;
  final String gameText;
  final TextStyle gameStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _BaselineOverlayPainter(
          background: background,
          ttText: ttText,
          ttStyle: ttStyle,
          gameText: gameText,
          gameStyle: gameStyle,
        ),
      ),
    );
  }
}

class _BaselineOverlayPainter extends CustomPainter {
  _BaselineOverlayPainter({
    required this.background,
    required this.ttText,
    required this.ttStyle,
    required this.gameText,
    required this.gameStyle,
  });

  final Color background;
  final String ttText;
  final TextStyle ttStyle;
  final String gameText;
  final TextStyle gameStyle;

  TextPainter _paint(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background.
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    // Anchor the shared baseline at ~72% down the strip so both
    // texts have room above for caps AND room below for descenders.
    final anchorY = size.height * 0.72;
    const leftPad = 12.0;

    final tt = _paint(ttText, ttStyle);
    final game = _paint(gameText, gameStyle);
    final ttBaseline =
        tt.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final gameBaseline =
        game.computeDistanceToActualBaseline(TextBaseline.alphabetic);

    // Paint reference first (gets covered by game text).
    tt.paint(canvas, Offset(leftPad, anchorY - ttBaseline));
    game.paint(canvas, Offset(leftPad, anchorY - gameBaseline));

    // Draw a thin baseline guide across the whole strip so any
    // misalignment is visually obvious.
    canvas.drawLine(
      Offset(0, anchorY),
      Offset(size.width, anchorY),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BaselineOverlayPainter old) =>
      old.ttText != ttText ||
      old.gameText != gameText ||
      old.ttStyle != ttStyle ||
      old.gameStyle != gameStyle ||
      old.background != background;
}

class _Entry {
  final String name;
  final String text;
  final String fontFamily;
  final int currentFs;
  final FontWeight? fontWeight;
  final double? letterSpacing;
  final Color color;
  final Color background;
  /// Optional hand-tuned recommendation. When non-null, overrides the
  /// metric-derived recommendation. Used to tame mixed-case titles
  /// with big descenders (Reef Royale's "y", Tiki Golf's "f", etc.)
  /// where the above-baseline metric leaves total glyph ink much
  /// bigger than Target Tag's — so the recommendation looks too big
  /// even though cap height matches.
  final int? overrideRecFs;
  const _Entry({
    required this.name,
    required this.text,
    required this.fontFamily,
    required this.currentFs,
    this.fontWeight,
    this.letterSpacing,
    required this.color,
    required this.background,
    this.overrideRecFs,
  });
}
