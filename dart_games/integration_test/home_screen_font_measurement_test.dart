// Visual HOME-SCREEN game-card title ribbon in Chrome. For every game
// the test renders THREE strips of the home card's label-strip
// height (44 px — matches the SizedBox(height: 44) that wraps the
// game name label in home_screen.dart):
//   - LEFT   = title in its current home-card fontSize
//   - MIDDLE = title in the recommended home-card fontSize
//   - RIGHT  = baseline-aligned overlay showing Target Tag's home-card
//     title (white) with the game's title (red) painted on top,
//     alphabetic baselines aligned — so you can eyeball whether the
//     caps really line up.
//
// Baseline = "Target Tag" home-card title at fontSize 22
// (titleMedium.fontSize=18 in the app theme + 4 offset in
// home_screen.dart).
//
// Companion to `appbar_title_measurement_test.dart` — same
// three-column layout, but sized for the home-screen game cards
// instead of the AppBar.
//
// Run with:
//   ./chromedriver/chromedriver-win64/chromedriver.exe --port=4444 &
//   flutter drive --driver=test_driver/screenshot_test.dart \
//     --target=integration_test/home_screen_font_measurement_test.dart \
//     -d chrome --web-browser-flag=--start-maximized \
//     --browser-dimension=1920x1080
// Screenshot lands at temp_screenshots/home_screen_font_ribbon.png.
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
// Home-card fontSizes come from `lib/screens/home_screen.dart`:
// each game's title uses `titleMedium.fontSize + N` where the app
// theme sets `titleMedium.fontSize = 18` (lib/main.dart) and N is a
// per-game offset. Text = game name as shown on the card.
//
// Home card label strip has a light card background; the label
// color is `theme.colorScheme.onSurface` (dark text on light card).
// Backgrounds here match that context — a neutral light card so the
// legibility test mirrors what you'd see on the running home screen.
const Color _kCardBg = Color(0xFFF2F3F5);
const Color _kCardText = Color(0xFF1F2126);

const List<_Entry> _kEntries = [
  _Entry(
    name: 'Carnival Derby',
    text: 'Carnival Derby',
    fontFamily: 'Rye',
    currentFs: 18, // titleMedium + 0
    fontWeight: FontWeight.bold,
    color: _kCardText,
    background: _kCardBg,
    // Rye's strokes are moderate — at pure cap parity (fs 17) the
    // caps come in at 15 px but read as smaller than LuckiestGuy's
    // heavy caps. Weight-parity bump.
    overrideRecFs: 20,
  ),
  _Entry(
    name: 'Clockwork Quest',
    text: 'Clockwork Quest',
    fontFamily: 'CinzelDecorative',
    currentFs: 22, // titleMedium + 4
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: _kCardText,
    background: _kCardBg,
  ),
  _Entry(
    name: 'Gladiator Arena',
    text: 'Gladiator Arena',
    fontFamily: 'Cinzel',
    currentFs: 21, // titleMedium + 3
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    color: _kCardText,
    background: _kCardBg,
  ),
  _Entry(
    name: 'Lunar Lander',
    text: 'Lunar Lander',
    fontFamily: 'Orbitron',
    currentFs: 21, // titleMedium + 3
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    color: _kCardText,
    background: _kCardBg,
  ),
  _Entry(
    name: 'Monster Mash',
    text: 'Monster Mash',
    fontFamily: 'Creepster',
    currentFs: 25, // titleMedium + 7
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    color: _kCardText,
    background: _kCardBg,
    // Creepster is a thin spiky horror face — at pure cap parity
    // (fs 20) it reads much smaller than LuckiestGuy. Weight-parity
    // bump keeps it close to current size.
    overrideRecFs: 24,
  ),
  _Entry(
    name: "Pirate's Grid",
    text: "Pirate's Grid",
    fontFamily: 'PirataOne',
    currentFs: 26, // titleMedium + 8
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    color: _kCardText,
    background: _kCardBg,
    // PirataOne is a thin decorative serif — at pure cap parity
    // (fs 20) it reads much smaller than LuckiestGuy. Weight-parity
    // bump keeps it close to current size.
    overrideRecFs: 24,
  ),
  _Entry(
    name: 'Reef Royale',
    text: 'Reef Royale',
    fontFamily: 'Fredoka',
    currentFs: 24, // titleMedium + 6
    fontWeight: FontWeight.bold,
    color: _kCardText,
    background: _kCardBg,
  ),
  _Entry(
    name: 'Target Tag  (baseline)',
    text: 'Target Tag',
    fontFamily: 'LuckiestGuy',
    currentFs: 22, // titleMedium + 4 — BASELINE
    letterSpacing: 1.2,
    color: _kCardText,
    background: _kCardBg,
  ),
  _Entry(
    name: 'Tiki Golf',
    text: 'Tiki Golf',
    fontFamily: 'Boogaloo',
    currentFs: 25, // titleMedium + 7
    fontWeight: FontWeight.bold,
    color: _kCardText,
    background: _kCardBg,
    // Metric said 22 but the caps came in 1 px short at fs 22.
    // Small bump for parity with Target Tag baseline.
    overrideRecFs: 24,
  ),
  _Entry(
    name: 'Treasure Divide',
    text: 'Treasure Divide',
    fontFamily: 'PirataOne',
    currentFs: 24, // titleMedium + 6
    letterSpacing: 1.0,
    color: _kCardText,
    background: _kCardBg,
    // Same PirataOne thin-stroke bump as Pirate's Grid so both
    // pirate-themed games read at the same visual weight.
    overrideRecFs: 24,
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
    // Matches home_screen.dart's `SizedBox(height: 44)` around each
    // game card's title label — the visual budget for a home-card
    // font is 44 px, not the AppBar's 56.
    const appBarH = 44.0;

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
                'Home-card title ribbon — above-baseline target = $baselineCap px (Target Tag @ fs ${baseline.currentFs})'),
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
    await binding.takeScreenshot('home_screen_font_ribbon');

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
        '[TITLE] Screenshot saved to temp_screenshots/home_screen_font_ribbon.png');
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
    // ignore: unused_element_parameter
    this.overrideRecFs,
  });
}
